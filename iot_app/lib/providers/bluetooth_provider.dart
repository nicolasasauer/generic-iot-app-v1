import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod/riverpod.dart';
import '../services/bluetooth_service.dart';
import '../models/device.dart';

/// Provider for the Bluetooth service instance
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for Bluetooth connection status
final bluetoothStatusProvider = StreamProvider<BluetoothStatus>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return service.statusStream;
});

/// Provider for discovered BLE devices
final discoveredDevicesProvider = StreamProvider<List<ScanResult>>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return service.discoveredDevicesStream;
});

/// Provider for connected devices
final connectedDevicesProvider = Provider<Map<String, IotDevice>>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  final connectedBleDevices = service.connectedDevices;
  
  // Convert BluetoothDevice to IotDevice
  final Map<String, IotDevice> devices = {};
  for (final entry in connectedBleDevices.entries) {
    final bleDevice = entry.value;
    devices[entry.key] = IotDevice(
      id: bleDevice.remoteId.str,
      name: bleDevice.platformName.isNotEmpty 
          ? bleDevice.platformName 
          : 'Unknown Device',
      address: bleDevice.remoteId.str,
      isConnected: true,
      lastSeen: DateTime.now(),
    );
  }
  
  return devices;
});

/// Provider for scanning state
final isScanningProvider = Provider<bool>((ref) {
  final status = ref.watch(bluetoothStatusProvider);
  return status.when(
    data: (status) => status == BluetoothStatus.scanning,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for connection state
final isConnectedProvider = Provider<bool>((ref) {
  final connectedDevices = ref.watch(connectedDevicesProvider);
  return connectedDevices.isNotEmpty;
});

/// Provider for error messages
final bluetoothErrorProvider = StreamProvider<String>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return service.errorStream;
});

/// Notifier for managing Bluetooth operations
class BluetoothNotifier extends Notifier<BluetoothStatus> {
  BluetoothService get _service => ref.read(bluetoothServiceProvider);

  @override
  BluetoothStatus build() {
    return _service.currentStatus;
  }

  /// Start scanning for devices
  Future<void> startScan({int durationSeconds = 10}) async {
    await _service.scanForDevices(durationSeconds: durationSeconds);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await _service.stopScan();
  }

  /// Connect to a device
  Future<bool> connectToDevice(String deviceId) async {
    return await _service.connectToDevice(deviceId);
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    await _service.disconnectFromDevice(deviceId);
  }

  /// Send command to a device
  Future<bool> sendCommand(String deviceId, String command) async {
    return await _service.sendCommand(deviceId, command);
  }
}

/// Provider for Bluetooth notifier
final bluetoothNotifierProvider =
    NotifierProvider<BluetoothNotifier, BluetoothStatus>(
  () => BluetoothNotifier(),
);
