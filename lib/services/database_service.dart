// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  Database? _db;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'smart_parking.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reservation columns to existing parking_slots table
      await db.execute('ALTER TABLE parking_slots ADD COLUMN reservedBy TEXT');
      await db.execute('ALTER TABLE parking_slots ADD COLUMN reservedUntil TEXT');
      await db.execute('ALTER TABLE parking_slots ADD COLUMN reservationId TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reservations (
          id TEXT PRIMARY KEY,
          slotId TEXT NOT NULL,
          slotLabel TEXT NOT NULL,
          userId TEXT NOT NULL,
          durationHours INTEGER NOT NULL,
          amount REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'PENDING',
          createdAt TEXT NOT NULL,
          expiresAt TEXT NOT NULL,
          paymobOrderId TEXT,
          paymobTransactionId TEXT
        )
      ''');
    }
  }

  Database get db {
    if (_db == null) throw Exception('Database not initialised');
    return _db!;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        studentId TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE parking_slots (
        id TEXT PRIMARY KEY,
        label TEXT UNIQUE NOT NULL,
        sensorId TEXT NOT NULL,
        posRow INTEGER NOT NULL,
        posCol INTEGER NOT NULL,
        isOccupied INTEGER NOT NULL DEFAULT 0,
        sensorHealth TEXT NOT NULL DEFAULT 'ok',
        lastUpdated TEXT NOT NULL,
        reservedBy TEXT,
        reservedUntil TEXT,
        reservationId TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reservations (
        id TEXT PRIMARY KEY,
        slotId TEXT NOT NULL,
        slotLabel TEXT NOT NULL,
        userId TEXT NOT NULL,
        durationHours INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL,
        paymobOrderId TEXT,
        paymobTransactionId TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE announcements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        createdBy TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE parking_rules (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        schedule TEXT NOT NULL,
        description TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        targetRole TEXT NOT NULL DEFAULT 'ALL'
      )
    ''');
    await db.execute('''
      CREATE TABLE fault_events (
        id TEXT PRIMARY KEY,
        slotLabel TEXT NOT NULL,
        sensorId TEXT NOT NULL,
        faultType TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        resolved INTEGER NOT NULL DEFAULT 0,
        resolvedAt TEXT
      )
    ''');
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();
    // Users
    await db.insert('users', {
      'id': 'u1', 'studentId': 'STU-2024001', 'password': 'pass123',
      'role': 'STUDENT', 'name': 'Ahmed Hassan',
      'email': 'ahmed@uni.edu', 'createdAt': now,
    });
    await db.insert('users', {
      'id': 'u2', 'studentId': 'STU-2024002', 'password': 'pass123',
      'role': 'STUDENT', 'name': 'Sara Mohamed',
      'email': 'sara@uni.edu', 'createdAt': now,
    });
    await db.insert('users', {
      'id': 'u3', 'studentId': 'ADM-0001', 'password': 'admin123',
      'role': 'ADMIN', 'name': 'Dr. Khaled Ibrahim',
      'email': 'admin@uni.edu', 'createdAt': now,
    });
    // Parking Slots
    final slots = [
      {'id':'s1','label':'A1','sensorId':'IR-01','posRow':0,'posCol':0},
      {'id':'s2','label':'A2','sensorId':'IR-02','posRow':0,'posCol':1},
      {'id':'s3','label':'A3','sensorId':'IR-03','posRow':0,'posCol':2},
      {'id':'s4','label':'B1','sensorId':'IR-04','posRow':1,'posCol':0},
      {'id':'s5','label':'B2','sensorId':'IR-05','posRow':1,'posCol':1},
      {'id':'s6','label':'B3','sensorId':'IR-06','posRow':1,'posCol':2},
    ];
    for (final s in slots) {
      await db.insert('parking_slots', {
        ...s,
        'isOccupied': 0,
        'sensorHealth': 'ok',
        'lastUpdated': now,
      });
    }
    // Announcements
    await db.insert('announcements', {
      'id': 'a1',
      'title': 'Parking Maintenance – Row B',
      'body': 'Row B slots will be unavailable on Saturday for routine maintenance.',
      'expiryDate': DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10),
      'createdAt': now,
      'createdBy': 'u3',
    });
    await db.insert('announcements', {
      'id': 'a2',
      'title': 'New Parking Rules Effective June 2026',
      'body': 'Please note updated parking schedule. All vehicles must display valid campus sticker.',
      'expiryDate': '2026-06-30',
      'createdAt': now,
      'createdBy': 'u3',
    });
    // Rules
    await db.insert('parking_rules', {
      'id': 'r1',
      'title': 'Campus Parking Hours',
      'schedule': 'Monday–Friday 7:00 AM – 10:00 PM',
      'description': 'All vehicles must vacate by 10PM on weekdays.',
      'createdAt': now,
    });
    await db.insert('parking_rules', {
      'id': 'r2',
      'title': 'Weekend Parking',
      'schedule': 'Saturday–Sunday 9:00 AM – 6:00 PM',
      'description': 'Staff only after 4PM on weekends.',
      'createdAt': now,
    });
  }

  // ── USERS ─────────────────────────────────────────────
  Future<UserModel?> getUserByCredentials(String studentId, String password) async {
    final rows = await db.query('users',
        where: 'studentId = ? AND password = ?',
        whereArgs: [studentId, password]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<List<UserModel>> getUsers() async {
    final rows = await db.query('users', orderBy: 'name ASC');
    return rows.map(UserModel.fromMap).toList();
  }

  Future<void> insertUser(UserModel u) =>
      db.insert('users', u.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateUser(UserModel u) =>
      db.update('users', u.toMap(), where: 'id = ?', whereArgs: [u.id]);

  Future<void> deleteUser(String id) =>
      db.delete('users', where: 'id = ?', whereArgs: [id]);

  // ── PARKING SLOTS ─────────────────────────────────────
  Future<List<ParkingSlotModel>> getSlots() async {
    final rows = await db.query('parking_slots', orderBy: 'posRow ASC, posCol ASC');
    return rows.map(ParkingSlotModel.fromMap).toList();
  }

  Future<void> insertSlot(ParkingSlotModel s) =>
      db.insert('parking_slots', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateSlot(ParkingSlotModel s) =>
      db.update('parking_slots', s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  Future<void> updateSlotStatus(String id, bool isOccupied, String sensorHealth) =>
      db.update('parking_slots', {
        'isOccupied': isOccupied ? 1 : 0,
        'sensorHealth': sensorHealth,
        'lastUpdated': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteSlot(String id) =>
      db.delete('parking_slots', where: 'id = ?', whereArgs: [id]);

  // ── ANNOUNCEMENTS ─────────────────────────────────────
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final rows = await db.query('announcements', orderBy: 'createdAt DESC');
    return rows.map(AnnouncementModel.fromMap).toList();
  }

  Future<void> insertAnnouncement(AnnouncementModel a) =>
      db.insert('announcements', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateAnnouncement(AnnouncementModel a) =>
      db.update('announcements', a.toMap(), where: 'id = ?', whereArgs: [a.id]);

  Future<void> deleteAnnouncement(String id) =>
      db.delete('announcements', where: 'id = ?', whereArgs: [id]);

  // ── RULES ─────────────────────────────────────────────
  Future<List<ParkingRuleModel>> getRules() async {
    final rows = await db.query('parking_rules', orderBy: 'createdAt ASC');
    return rows.map(ParkingRuleModel.fromMap).toList();
  }

  Future<void> insertRule(ParkingRuleModel r) =>
      db.insert('parking_rules', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateRule(ParkingRuleModel r) =>
      db.update('parking_rules', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<void> deleteRule(String id) =>
      db.delete('parking_rules', where: 'id = ?', whereArgs: [id]);

  // ── NOTIFICATIONS ─────────────────────────────────────
  Future<List<NotificationModel>> getNotifications() async {
    final rows = await db.query('notifications', orderBy: 'timestamp DESC', limit: 100);
    return rows.map(NotificationModel.fromMap).toList();
  }

  Future<void> insertNotification(NotificationModel n) =>
      db.insert('notifications', n.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> markNotificationRead(String id) =>
      db.update('notifications', {'isRead': 1}, where: 'id = ?', whereArgs: [id]);

  Future<void> markAllNotificationsRead() =>
      db.update('notifications', {'isRead': 1});

  Future<void> deleteNotification(String id) =>
      db.delete('notifications', where: 'id = ?', whereArgs: [id]);

  // ── FAULT EVENTS ──────────────────────────────────────
  Future<List<FaultEventModel>> getFaultEvents() async {
    final rows = await db.query('fault_events', orderBy: 'timestamp DESC', limit: 50);
    return rows.map(FaultEventModel.fromMap).toList();
  }

  Future<void> insertFaultEvent(FaultEventModel f) =>
      db.insert('fault_events', f.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> resolveFaultEvent(String id) =>
      db.update('fault_events', {
        'resolved': 1,
        'resolvedAt': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [id]);

  // ── RESERVATIONS ──────────────────────────────────────
  Future<List<ReservationModel>> getReservations() async {
    final rows = await db.query('reservations', orderBy: 'createdAt DESC');
    return rows.map(ReservationModel.fromMap).toList();
  }

  Future<List<ReservationModel>> getReservationsForUser(String userId) async {
    final rows = await db.query('reservations',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return rows.map(ReservationModel.fromMap).toList();
  }

  Future<void> insertReservation(ReservationModel r) =>
      db.insert('reservations', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateReservationStatus(
    String id,
    String status, {
    String? paymobOrderId,
    String? paymobTransactionId,
  }) {
    final values = <String, dynamic>{'status': status};
    if (paymobOrderId != null) values['paymobOrderId'] = paymobOrderId;
    if (paymobTransactionId != null) values['paymobTransactionId'] = paymobTransactionId;
    return db.update('reservations', values, where: 'id = ?', whereArgs: [id]);
  }

  // ── SLOT RESERVATION STATE ─────────────────────────────
  Future<void> setSlotReservation(
    String slotId, {
    required String? reservedBy,
    required String? reservedUntil,
    required String? reservationId,
  }) =>
      db.update(
        'parking_slots',
        {
          'reservedBy': reservedBy,
          'reservedUntil': reservedUntil,
          'reservationId': reservationId,
        },
        where: 'id = ?',
        whereArgs: [slotId],
      );

  /// Clears expired reservations (where reservedUntil is in the past)
  /// and marks the corresponding reservation rows as EXPIRED.
  Future<void> clearExpiredReservations() async {
    final now = DateTime.now().toIso8601String();
    final expiredSlots = await db.query(
      'parking_slots',
      where: 'reservedUntil IS NOT NULL AND reservedUntil < ?',
      whereArgs: [now],
    );
    for (final s in expiredSlots) {
      await db.update(
        'parking_slots',
        {'reservedBy': null, 'reservedUntil': null, 'reservationId': null},
        where: 'id = ?',
        whereArgs: [s['id']],
      );
      final resId = s['reservationId'];
      if (resId != null) {
        await db.update(
          'reservations',
          {'status': 'EXPIRED'},
          where: 'id = ? AND status = ?',
          whereArgs: [resId, 'PAID'],
        );
      }
    }
  }
}
