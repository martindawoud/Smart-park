// lib/providers/bluetooth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import '../services/bluetooth_service.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class BluetoothProvider extends ChangeNotifier {
  final _bt = BluetoothService.instance;
  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _selectedDevice;
  BtState _connectionState = BtState.disconnected;
  ParkingDataPacket? _lastPacket;
  String _lastUpdated = '--:--:--';

  // Track previous state to detect transitions
  bool _wasFullBefore = false;
  bool _wasCriticalBefore = false;

  StreamSubscription? _stateSub;
  StreamSubscription? _packetSub;

  List<BluetoothDevice> get pairedDevices => _pairedDevices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  BtState get connectionState => _connectionState;
  bool get isConnected => _connectionState == BtState.connected;
  bool get isConnecting => _connectionState == BtState.connecting;
  ParkingDataPacket? get lastPacket => _lastPacket;
  String get lastUpdated => _lastUpdated;

  BluetoothProvider() {
    _stateSub = _bt.stateStream.listen((s) {
      _connectionState = s;
      notifyListeners();
    });
    _packetSub = _bt.packetStream.listen(_onPacket);
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  Future<void> loadPairedDevices() async {
    await requestPermissions();
    _pairedDevices = await _bt.getPairedDevices();
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    _selectedDevice = device;
    notifyListeners();
    await _bt.connect(device);
  }

  Future<void> disconnect() async {
    await _bt.disconnect();
    _lastPacket = null;
    notifyListeners();
  }

  void _onPacket(ParkingDataPacket packet) async {
    final db = DatabaseService.instance;
    final ns = NotificationService.instance;
    final uuid = const Uuid();

    // Update slot statuses in DB
    final slots = await db.getSlots();
    for (int i = 0; i < slots.length && i < packet.slots.length; i++) {
      await db.updateSlotStatus(
        slots[i].id,
        packet.slots[i] == 1,
        packet.sensorHealth.length > i ? packet.sensorHealth[i] : 'ok',
      );
    }

    // Detect: lot became available (was full, now has space)
    final previouslyFull = _lastPacket?.available == 0;
    final nowAvailable = packet.available > 0;
    if (previouslyFull && nowAvailable) {
      await ns.showAvailabilityNotification(packet.available);
      await db.insertNotification(NotificationModel(
        id: uuid.v4(),
        type: 'availability',
        title: '🟢 Parking Space Available',
        body: '${packet.available} space${packet.available > 1 ? 's' : ''} now available.',
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
        targetRole: 'ALL',
      ));
    }

    // Detect: lot became full
    final previouslyAvailable = (_lastPacket?.available ?? 0) > 0;
    final nowFull = packet.available == 0;
    if (previouslyAvailable && nowFull) {
      await ns.showLotFullNotification();
      await db.insertNotification(NotificationModel(
        id: uuid.v4(),
        type: 'lot_full',
        title: '🔴 Parking Lot Full',
        body: 'All 6 parking spaces are now occupied.',
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
        targetRole: 'ALL',
      ));
    }

    // Detect: new critical fault
    final wasNotCritical = !(_lastPacket?.criticalFault ?? false);
    if (packet.criticalFault && wasNotCritical) {
      await ns.showCriticalFaultNotification();
      await db.insertNotification(NotificationModel(
        id: uuid.v4(),
        type: 'fault_critical',
        title: '⚠️ Critical Hardware Fault',
        body: 'A critical sensor failure has been detected. Immediate admin attention required.',
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
        targetRole: 'ADMIN',
      ));
      // Log fault event
      final faultedIndex = packet.sensorHealth.indexOf('fault');
      if (faultedIndex >= 0 && faultedIndex < slots.length) {
        await db.insertFaultEvent(FaultEventModel(
          id: uuid.v4(),
          slotLabel: slots[faultedIndex].label,
          sensorId: slots[faultedIndex].sensorId,
          faultType: 'critical',
          timestamp: DateTime.now().toIso8601String(),
          resolved: false,
        ));
      }
    }

    _lastPacket = packet;
    final now = DateTime.now();
    _lastUpdated =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  Future<void> sendPing() => _bt.sendCommand('PING');
  Future<void> sendGateToggle() => _bt.sendCommand('GATE_TOGGLE');

  @override
  void dispose() {
    _stateSub?.cancel();
    _packetSub?.cancel();
    _bt.dispose();
    super.dispose();
  }
}
