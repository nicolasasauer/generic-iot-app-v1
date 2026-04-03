import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants.dart';
import '../models/data_point.dart';

/// Status of the Bluetooth service
enum BluetoothStatus {
  idle,
  scanning,
  connecting,
  connected,
  disconnecting,
  disconnected,
  error,
}

/// Bluetooth Low Energy service for ESP32 communication
class BluetoothService {
  // Stream controllers
  final _statusController = StreamController<BluetoothStatus>.broadcast();
  final _discoveredDevicesController =
      StreamController<List<ScanResult>>.broadcast();
  final _dataController = StreamController<DataPoint>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // State
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BluetoothCharacteristic> _txCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _rxCharacteristics = {};
  final List<ScanResult> _discoveredDevices = [];
  
  BluetoothStatus _currentStatus = BluetoothStatus.idle;
  StreamSubscription? _scanSubscription;

  // Getters
  Stream<BluetoothStatus> get statusStream => _statusController.stream;
  Stream<List<ScanResult>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;
  Stream<DataPoint> get dataStream => _dataController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  BluetoothStatus get currentStatus => _currentStatus;
  List<ScanResult> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  Map<String, BluetoothDevice> get connectedDevices =>
      Map.unmodifiable(_connectedDevices);

  /// Initialize the Bluetooth service
  Future<void> initialize() async {
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        _updateStatus(BluetoothStatus.error);
        _errorController.add('Bluetooth not supported on this device');
        return;
      }

      // Listen to adapter state
      FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on && _currentStatus != BluetoothStatus.error) {
          _updateStatus(BluetoothStatus.idle);
        }
      });

      _updateStatus(BluetoothStatus.idle);
    } catch (e) {
      _updateStatus(BluetoothStatus.error);
      _errorController.add('Bluetooth initialization error: $e');
    }
  }

  /// Start scanning for BLE devices
  Future<void> scanForDevices({int durationSeconds = 10}) async {
    try {
      // Stop any existing scan
      await stopScan();

      _discoveredDevices.clear();
      _updateStatus(BluetoothStatus.scanning);

      // Start scan
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: durationSeconds),
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          _discoveredDevices.clear();
          _discoveredDevices.addAll(results);
          _discoveredDevicesController.add(_discoveredDevices);
        },
        onError: (error) {
          _errorController.add('Scan error: $error');
        },
      );

      // Auto-stop after duration
      Future.delayed(Duration(seconds: durationSeconds), () {
        if (_currentStatus == BluetoothStatus.scanning) {
          stopScan();
        }
      });
    } catch (e) {
      _updateStatus(BluetoothStatus.error);
      _errorController.add('Failed to start scan: $e');
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      
      if (_currentStatus == BluetoothStatus.scanning) {
        _updateStatus(_connectedDevices.isEmpty 
            ? BluetoothStatus.idle 
            : BluetoothStatus.connected);
      }
    } catch (e) {
      _errorController.add('Failed to stop scan: $e');
    }
  }

  /// Connect to a device by its ID
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _updateStatus(BluetoothStatus.connecting);

      // Find the device
      final scanResult = _discoveredDevices.firstWhere(
        (result) => result.device.remoteId.str == deviceId,
        orElse: () => throw Exception('Device not found in scan results'),
      );

      final device = scanResult.device;

      // Connect
      await device.connect(
        license: License.free,
        timeout: Duration(seconds: AppConstants.connectionTimeoutSeconds),
        autoConnect: false,
      );

      // Discover services
      final services = await device.discoverServices();

      // Find our custom service
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == 
               AppConstants.bleServiceUuid.toLowerCase(),
        orElse: () => throw Exception('UART service not found'),
      );

      // Find TX and RX characteristics
      final txChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == 
               AppConstants.bleTxCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('TX characteristic not found'),
      );

      final rxChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == 
               AppConstants.bleRxCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('RX characteristic not found'),
      );

      // Store references
      _connectedDevices[deviceId] = device;
      _txCharacteristics[deviceId] = txChar;
      _rxCharacteristics[deviceId] = rxChar;

      // Subscribe to notifications
      await txChar.setNotifyValue(true);
      txChar.lastValueStream.listen(
        (value) => _handleIncomingData(deviceId, value),
        onError: (error) => _errorController.add('Data stream error: $error'),
      );

      // Listen to connection state
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDeviceDisconnected(deviceId);
        }
      });

      _updateStatus(BluetoothStatus.connected);
      return true;
    } catch (e) {
      _updateStatus(BluetoothStatus.error);
      _errorController.add('Connection failed: $e');
      return false;
    }
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      _updateStatus(BluetoothStatus.disconnecting);

      final device = _connectedDevices[deviceId];
      if (device != null) {
        await device.disconnect();
      }

      _connectedDevices.remove(deviceId);
      _txCharacteristics.remove(deviceId);
      _rxCharacteristics.remove(deviceId);

      _updateStatus(_connectedDevices.isEmpty
          ? BluetoothStatus.disconnected
          : BluetoothStatus.connected);
    } catch (e) {
      _errorController.add('Disconnect failed: $e');
    }
  }

  /// Send a command to a device
  Future<bool> sendCommand(String deviceId, String command) async {
    try {
      final rxChar = _rxCharacteristics[deviceId];
      if (rxChar == null) {
        throw Exception('Device not connected');
      }

      // Add newline terminator if not present
      final message = command.endsWith(AppConstants.messageTerminator)
          ? command
          : command + AppConstants.messageTerminator;

      await rxChar.write(
        utf8.encode(message),
        withoutResponse: false,
      );

      return true;
    } catch (e) {
      _errorController.add('Send command failed: $e');
      return false;
    }
  }

  /// Handle incoming data from device
  void _handleIncomingData(String deviceId, List<int> data) {
    try {
      final message = utf8.decode(data).trim();
      if (message.isEmpty) return;

      // Parse JSON message
      final json = jsonDecode(message) as Map<String, dynamic>;
      
      // Create data point
      final dataPoint = DataPoint(
        sensorId: json['sensor'] as String? ?? 'unknown',
        deviceId: deviceId,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String? ?? '',
        timestamp: json['ts'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['ts'] as int)
            : DateTime.now(),
      );

      _dataController.add(dataPoint);
    } catch (e) {
      _errorController.add('Failed to parse data: $e');
    }
  }

  /// Handle device disconnection
  void _handleDeviceDisconnected(String deviceId) {
    _connectedDevices.remove(deviceId);
    _txCharacteristics.remove(deviceId);
    _rxCharacteristics.remove(deviceId);

    if (_connectedDevices.isEmpty) {
      _updateStatus(BluetoothStatus.disconnected);
    }

    _errorController.add('Device $deviceId disconnected');
  }

  /// Update current status
  void _updateStatus(BluetoothStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    _statusController.close();
    _discoveredDevicesController.close();
    _dataController.close();
    _errorController.close();

    // Disconnect all devices
    for (final deviceId in _connectedDevices.keys.toList()) {
      disconnectFromDevice(deviceId);
    }
  }
}
