// lib/models/models.dart

class UserModel {
  final String id;
  final String studentId;
  final String password;
  final String role; // 'STUDENT' | 'ADMIN'
  final String name;
  final String email;
  final String createdAt;

  UserModel({
    required this.id,
    required this.studentId,
    required this.password,
    required this.role,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'],
        studentId: m['studentId'],
        password: m['password'],
        role: m['role'],
        name: m['name'],
        email: m['email'],
        createdAt: m['createdAt'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'password': password,
        'role': role,
        'name': name,
        'email': email,
        'createdAt': createdAt,
      };

  UserModel copyWith({
    String? id,
    String? studentId,
    String? password,
    String? role,
    String? name,
    String? email,
    String? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        password: password ?? this.password,
        role: role ?? this.role,
        name: name ?? this.name,
        email: email ?? this.email,
        createdAt: createdAt ?? this.createdAt,
      );
}

class ParkingSlotModel {
  final String id;
  final String label;
  final String sensorId;
  final int posRow;
  final int posCol;
  bool isOccupied;
  String sensorHealth; // 'ok' | 'fault' | 'offline'
  String lastUpdated;
  // ── Reservation fields ──────────────────────────────────
  String? reservedBy;     // userId of the student who reserved, or null
  String? reservedUntil;  // ISO timestamp when the reservation expires, or null
  String? reservationId;  // id of the active ReservationModel, or null

  ParkingSlotModel({
    required this.id,
    required this.label,
    required this.sensorId,
    required this.posRow,
    required this.posCol,
    required this.isOccupied,
    required this.sensorHealth,
    required this.lastUpdated,
    this.reservedBy,
    this.reservedUntil,
    this.reservationId,
  });

  factory ParkingSlotModel.fromMap(Map<String, dynamic> m) => ParkingSlotModel(
        id: m['id'],
        label: m['label'],
        sensorId: m['sensorId'],
        posRow: m['posRow'],
        posCol: m['posCol'],
        isOccupied: m['isOccupied'] == 1,
        sensorHealth: m['sensorHealth'],
        lastUpdated: m['lastUpdated'],
        reservedBy: m['reservedBy'],
        reservedUntil: m['reservedUntil'],
        reservationId: m['reservationId'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'sensorId': sensorId,
        'posRow': posRow,
        'posCol': posCol,
        'isOccupied': isOccupied ? 1 : 0,
        'sensorHealth': sensorHealth,
        'lastUpdated': lastUpdated,
        'reservedBy': reservedBy,
        'reservedUntil': reservedUntil,
        'reservationId': reservationId,
      };

  /// True if this slot currently has a valid (non-expired) reservation.
  bool get isReserved =>
      reservedBy != null &&
      reservedUntil != null &&
      DateTime.tryParse(reservedUntil!)?.isAfter(DateTime.now()) == true;
}

class ParkingDataPacket {
  final int total;
  final int occupied;
  final int available;
  final List<int> slots;          // 1=occupied, 0=available
  final List<String> sensorHealth;
  final bool criticalFault;
  final int timestamp;

  ParkingDataPacket({
    required this.total,
    required this.occupied,
    required this.available,
    required this.slots,
    required this.sensorHealth,
    required this.criticalFault,
    required this.timestamp,
  });

  factory ParkingDataPacket.fromJson(Map<String, dynamic> j) => ParkingDataPacket(
        total: j['total'] ?? 6,
        occupied: j['occupied'] ?? 0,
        available: j['available'] ?? 6,
        slots: List<int>.from(j['slots'] ?? []),
        sensorHealth: List<String>.from(j['sensor_health'] ?? []),
        criticalFault: j['critical_fault'] ?? false,
        timestamp: j['timestamp'] ?? 0,
      );

  bool isValid() =>
      slots.length == total &&
      sensorHealth.length == total &&
      occupied + available == total;
}

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String expiryDate;
  final String createdAt;
  final String createdBy;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.expiryDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> m) => AnnouncementModel(
        id: m['id'],
        title: m['title'],
        body: m['body'],
        expiryDate: m['expiryDate'],
        createdAt: m['createdAt'],
        createdBy: m['createdBy'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'expiryDate': expiryDate,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };

  bool get isExpired =>
      DateTime.tryParse(expiryDate)?.isBefore(DateTime.now()) ?? false;
}

class ParkingRuleModel {
  final String id;
  final String title;
  final String schedule;
  final String description;
  final String createdAt;

  ParkingRuleModel({
    required this.id,
    required this.title,
    required this.schedule,
    required this.description,
    required this.createdAt,
  });

  factory ParkingRuleModel.fromMap(Map<String, dynamic> m) => ParkingRuleModel(
        id: m['id'],
        title: m['title'],
        schedule: m['schedule'],
        description: m['description'],
        createdAt: m['createdAt'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'schedule': schedule,
        'description': description,
        'createdAt': createdAt,
      };
}

class NotificationModel {
  final String id;
  final String type; // 'availability'|'lot_full'|'announcement'|'fault_critical'
  final String title;
  final String body;
  final String timestamp;
  bool isRead;
  final String targetRole; // 'ALL' | 'ADMIN'

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.targetRole,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> m) => NotificationModel(
        id: m['id'],
        type: m['type'],
        title: m['title'],
        body: m['body'],
        timestamp: m['timestamp'],
        isRead: m['isRead'] == 1,
        targetRole: m['targetRole'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'isRead': isRead ? 1 : 0,
        'targetRole': targetRole,
      };
}

class FaultEventModel {
  final String id;
  final String slotLabel;
  final String sensorId;
  final String faultType;
  final String timestamp;
  final bool resolved;
  final String? resolvedAt;

  FaultEventModel({
    required this.id,
    required this.slotLabel,
    required this.sensorId,
    required this.faultType,
    required this.timestamp,
    required this.resolved,
    this.resolvedAt,
  });

  factory FaultEventModel.fromMap(Map<String, dynamic> m) => FaultEventModel(
        id: m['id'],
        slotLabel: m['slotLabel'],
        sensorId: m['sensorId'],
        faultType: m['faultType'],
        timestamp: m['timestamp'],
        resolved: m['resolved'] == 1,
        resolvedAt: m['resolvedAt'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'slotLabel': slotLabel,
        'sensorId': sensorId,
        'faultType': faultType,
        'timestamp': timestamp,
        'resolved': resolved ? 1 : 0,
        'resolvedAt': resolvedAt,
      };
}

class ReservationModel {
  final String id;
  final String slotId;
  final String slotLabel;
  final String userId;
  final int durationHours;
  final double amount; // total amount paid (EGP)
  final String status; // 'PENDING' | 'PAID' | 'CANCELLED' | 'EXPIRED'
  final String createdAt;
  final String expiresAt;
  final String? paymobOrderId;
  final String? paymobTransactionId;

  ReservationModel({
    required this.id,
    required this.slotId,
    required this.slotLabel,
    required this.userId,
    required this.durationHours,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.paymobOrderId,
    this.paymobTransactionId,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> m) => ReservationModel(
        id: m['id'],
        slotId: m['slotId'],
        slotLabel: m['slotLabel'],
        userId: m['userId'],
        durationHours: m['durationHours'],
        amount: (m['amount'] as num).toDouble(),
        status: m['status'],
        createdAt: m['createdAt'],
        expiresAt: m['expiresAt'],
        paymobOrderId: m['paymobOrderId'],
        paymobTransactionId: m['paymobTransactionId'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'slotId': slotId,
        'slotLabel': slotLabel,
        'userId': userId,
        'durationHours': durationHours,
        'amount': amount,
        'status': status,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'paymobOrderId': paymobOrderId,
        'paymobTransactionId': paymobTransactionId,
      };
}
