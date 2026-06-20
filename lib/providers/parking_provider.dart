// lib/providers/parking_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class ParkingProvider extends ChangeNotifier {
  List<ParkingSlotModel> _slots = [];
  List<AnnouncementModel> _announcements = [];
  List<ParkingRuleModel> _rules = [];
  List<NotificationModel> _notifications = [];
  List<FaultEventModel> _faultEvents = [];
  List<UserModel> _users = [];
  bool _loading = false;

  List<ParkingSlotModel> get slots => _slots;
  List<AnnouncementModel> get announcements => _announcements;
  List<ParkingRuleModel> get rules => _rules;
  List<NotificationModel> get notifications => _notifications;
  List<FaultEventModel> get faultEvents => _faultEvents;
  List<UserModel> get users => _users;
  bool get loading => _loading;

  int get totalSlots => _slots.length;
  int get occupiedCount => _slots.where((s) => s.isOccupied || s.sensorHealth == 'fault').length;
  int get availableCount => totalSlots - occupiedCount;
  bool get isFull => availableCount == 0;
  bool get hasCriticalFault => _slots.any((s) => s.sensorHealth == 'fault');
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = DatabaseService.instance;
    await db.clearExpiredReservations();
    _slots = await db.getSlots();
    _announcements = await db.getAnnouncements();
    _rules = await db.getRules();
    _notifications = await db.getNotifications();
    _faultEvents = await db.getFaultEvents();
    _users = await db.getUsers();
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshSlots() async {
    await DatabaseService.instance.clearExpiredReservations();
    _slots = await DatabaseService.instance.getSlots();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    _notifications = await DatabaseService.instance.getNotifications();
    notifyListeners();
  }

  // ── SLOTS CRUD ────────────────────────────────────────
  Future<void> addSlot(ParkingSlotModel slot) async {
    await DatabaseService.instance.insertSlot(slot);
    await refreshSlots();
  }

  Future<void> updateSlot(ParkingSlotModel slot) async {
    await DatabaseService.instance.updateSlot(slot);
    await refreshSlots();
  }

  Future<void> deleteSlot(String id) async {
    await DatabaseService.instance.deleteSlot(id);
    await refreshSlots();
  }

  // ── USERS CRUD ────────────────────────────────────────
  Future<void> addUser(UserModel user) async {
    await DatabaseService.instance.insertUser(user);
    _users = await DatabaseService.instance.getUsers();
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    await DatabaseService.instance.updateUser(user);
    _users = await DatabaseService.instance.getUsers();
    notifyListeners();
  }

  Future<void> deleteUser(String id) async {
    await DatabaseService.instance.deleteUser(id);
    _users = await DatabaseService.instance.getUsers();
    notifyListeners();
  }

  // ── ANNOUNCEMENTS CRUD ────────────────────────────────
  Future<void> addAnnouncement(AnnouncementModel a) async {
    await DatabaseService.instance.insertAnnouncement(a);
    _announcements = await DatabaseService.instance.getAnnouncements();
    notifyListeners();
  }

  Future<void> updateAnnouncement(AnnouncementModel a) async {
    await DatabaseService.instance.updateAnnouncement(a);
    _announcements = await DatabaseService.instance.getAnnouncements();
    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    await DatabaseService.instance.deleteAnnouncement(id);
    _announcements = await DatabaseService.instance.getAnnouncements();
    notifyListeners();
  }

  // ── RULES CRUD ────────────────────────────────────────
  Future<void> addRule(ParkingRuleModel r) async {
    await DatabaseService.instance.insertRule(r);
    _rules = await DatabaseService.instance.getRules();
    notifyListeners();
  }

  Future<void> updateRule(ParkingRuleModel r) async {
    await DatabaseService.instance.updateRule(r);
    _rules = await DatabaseService.instance.getRules();
    notifyListeners();
  }

  Future<void> deleteRule(String id) async {
    await DatabaseService.instance.deleteRule(id);
    _rules = await DatabaseService.instance.getRules();
    notifyListeners();
  }

  // ── NOTIFICATIONS ─────────────────────────────────────
  Future<void> markRead(String id) async {
    await DatabaseService.instance.markNotificationRead(id);
    await refreshNotifications();
  }

  Future<void> markAllRead() async {
    await DatabaseService.instance.markAllNotificationsRead();
    await refreshNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await DatabaseService.instance.deleteNotification(id);
    await refreshNotifications();
  }

  // ── FAULT EVENTS ──────────────────────────────────────
  Future<void> resolveFault(String id) async {
    await DatabaseService.instance.resolveFaultEvent(id);
    _faultEvents = await DatabaseService.instance.getFaultEvents();
    notifyListeners();
  }

  Future<void> updateSlotHealthLocally(String slotId, String health) async {
    await DatabaseService.instance.updateSlotStatus(
        slotId, health == 'fault', health);
    await refreshSlots();
  }

  // ── RESERVATIONS ──────────────────────────────────────
  /// Whether [userId] already has a slot reserved (only one reservation
  /// allowed at a time, to keep things simple for the demo).
  bool hasActiveReservation(String userId) =>
      _slots.any((s) => s.isReserved && s.reservedBy == userId);

  ParkingSlotModel? activeReservationFor(String userId) {
    try {
      return _slots.firstWhere((s) => s.isReserved && s.reservedBy == userId);
    } catch (_) {
      return null;
    }
  }

  /// Records a reservation after a successful Paymob payment, and marks
  /// the slot as reserved by [userId] until now + [durationHours].
  Future<ReservationModel> confirmReservation({
    required ParkingSlotModel slot,
    required String userId,
    required int durationHours,
    required double amount,
    String? paymobOrderId,
    String? paymobTransactionId,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: durationHours));
    final reservation = ReservationModel(
      id: const Uuid().v4(),
      slotId: slot.id,
      slotLabel: slot.label,
      userId: userId,
      durationHours: durationHours,
      amount: amount,
      status: 'PAID',
      createdAt: now.toIso8601String(),
      expiresAt: expiresAt.toIso8601String(),
      paymobOrderId: paymobOrderId,
      paymobTransactionId: paymobTransactionId,
    );

    final db = DatabaseService.instance;
    await db.insertReservation(reservation);
    await db.setSlotReservation(
      slot.id,
      reservedBy: userId,
      reservedUntil: expiresAt.toIso8601String(),
      reservationId: reservation.id,
    );
    await refreshSlots();
    return reservation;
  }

  /// Cancels the active reservation on [slot] and frees it up again.
  Future<void> cancelReservation(ParkingSlotModel slot) async {
    final db = DatabaseService.instance;
    if (slot.reservationId != null) {
      await db.updateReservationStatus(slot.reservationId!, 'CANCELLED');
    }
    await db.setSlotReservation(
      slot.id,
      reservedBy: null,
      reservedUntil: null,
      reservationId: null,
    );
    await refreshSlots();
  }
}
