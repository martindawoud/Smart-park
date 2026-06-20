// lib/services/bluetooth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/models.dart';

enum BtState { disconnected, connecting, connected, error }

class BluetoothService {
  static final BluetoothService instance = BluetoothService._();
  BluetoothService._();

  BluetoothConnection? _connection;
  String _buffer = '';
  BtState _state = BtState.disconnected;

  final _stateController = StreamController<BtState>.broadcast();
  final _packetController = StreamController<ParkingDataPacket>.broadcast();
  final _rawController = StreamController<String>.broadcast();

  Stream<BtState> get stateStream => _stateController.stream;
  Stream<ParkingDataPacket> get packetStream => _packetController.stream;
  Stream<String> get rawStream => _rawController.stream;
  BtState get state => _state;
  bool get isConnected => _state == BtState.connected;

  void _setState(BtState s) {
    _state = s;
    _stateController.add(s);
  }

  /// Returns list of already-paired Bluetooth devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (e) {
      return [];
    }
  }

  /// Connect to a specific paired Bluetooth device (HC-05)
  Future<bool> connect(BluetoothDevice device) async {
    if (_state == BtState.connecting || _state == BtState.connected) return false;
    _setState(BtState.connecting);
    try {
      _connection = await BluetoothConnection.toAddress(device.address)
          .timeout(const Duration(seconds: 10));
      _setState(BtState.connected);
      _buffer = '';
      _listenToStream();
      return true;
    } catch (e) {
      _setState(BtState.error);
      await Future.delayed(const Duration(seconds: 2));
      _setState(BtState.disconnected);
      return false;
    }
  }

  void _listenToStream() {
    _connection!.input!.listen(
      _onData,
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
      cancelOnError: true,
    );
  }

  void _onData(Uint8List data) {
    _buffer += utf8.decode(data, allowMalformed: true);
    // Parse all complete newline-terminated JSON lines
    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);
      if (line.isEmpty) continue;
      _rawController.add(line);
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final packet = ParkingDataPacket.fromJson(json);
        if (packet.isValid()) {
          _packetController.add(packet);
        }
      } catch (_) {
        // Malformed JSON — skip silently
      }
    }
    // Prevent buffer overflow
    if (_buffer.length > 4096) _buffer = '';
  }

  void _onDisconnected() {
    _connection = null;
    _buffer = '';
    _setState(BtState.disconnected);
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _buffer = '';
    _setState(BtState.disconnected);
  }

  Future<void> sendCommand(String cmd) async {
    if (_connection == null || !isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$cmd\n')));
      await _connection!.output.allSent;
    } catch (_) {}
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _packetController.close();
    _rawController.close();
  }
}
