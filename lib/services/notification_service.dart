// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _ready = true;

    // Create notification channels
    const availability = AndroidNotificationChannel(
      'parking_availability',
      'Parking Availability',
      description: 'Notifies when parking spaces become available',
      importance: Importance.high,
    );
    const fault = AndroidNotificationChannel(
      'fault_critical',
      'Critical Faults',
      description: 'Critical hardware fault alerts for admin',
      importance: Importance.max,
    );
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(availability);
    await androidPlugin?.createNotificationChannel(fault);
  }

  Future<void> showAvailabilityNotification(int available) async {
    if (!_ready) return;
    await _plugin.show(
      1,
      '🟢 Parking Space Available',
      '$available space${available > 1 ? 's' : ''} now available in the campus lot.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'parking_availability',
          'Parking Availability',
          channelDescription: 'Notifies when parking spaces become available',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> showLotFullNotification() async {
    if (!_ready) return;
    await _plugin.show(
      2,
      '🔴 Parking Lot Full',
      'All 6 parking spaces are now occupied.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'parking_availability',
          'Parking Availability',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> showCriticalFaultNotification() async {
    if (!_ready) return;
    await _plugin.show(
      3,
      '⚠️ Critical Hardware Fault',
      'A critical sensor failure has been detected. Immediate attention required.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fault_critical',
          'Critical Faults',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
        ),
      ),
    );
  }
}
