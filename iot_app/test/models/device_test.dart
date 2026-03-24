import 'package:flutter_test/flutter_test.dart';
import 'package:iot_app/models/device.dart';
import 'package:iot_app/models/sensor_config.dart';

void main() {
  group('IotDevice', () {
    test('should create a device with all fields', () {
      final device = IotDevice(
        id: 'device_123',
        name: 'ESP32 Sensor Hub',
        address: 'AA:BB:CC:DD:EE:FF',
        isConnected: true,
        rssi: -60,
        lastSeen: DateTime.now(),
      );

      expect(device.id, 'device_123');
      expect(device.name, 'ESP32 Sensor Hub');
      expect(device.address, 'AA:BB:CC:DD:EE:FF');
      expect(device.isConnected, true);
      expect(device.rssi, -60);
      expect(device.sensors, isEmpty);
    });

    test('should convert to JSON correctly', () {
      final lastSeen = DateTime(2024, 1, 1, 12, 0);
      final sensor = SensorConfig(
        id: 'temp',
        name: 'Temperature',
        type: SensorType.analog,
      );

      final device = IotDevice(
        id: 'device_123',
        name: 'ESP32 Sensor Hub',
        address: 'AA:BB:CC:DD:EE:FF',
        isConnected: true,
        rssi: -60,
        lastSeen: lastSeen,
        sensors: [sensor],
      );

      final json = device.toJson();

      expect(json['id'], 'device_123');
      expect(json['name'], 'ESP32 Sensor Hub');
      expect(json['address'], 'AA:BB:CC:DD:EE:FF');
      expect(json['isConnected'], true);
      expect(json['rssi'], -60);
      expect(json['lastSeen'], lastSeen.toIso8601String());
      expect(json['sensors'], isList);
      expect(json['sensors'].length, 1);
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'device_123',
        'name': 'ESP32 Sensor Hub',
        'address': 'AA:BB:CC:DD:EE:FF',
        'isConnected': true,
        'rssi': -60,
        'lastSeen': '2024-01-01T12:00:00.000',
        'sensors': [],
      };

      final device = IotDevice.fromJson(json);

      expect(device.id, 'device_123');
      expect(device.name, 'ESP32 Sensor Hub');
      expect(device.address, 'AA:BB:CC:DD:EE:FF');
      expect(device.isConnected, true);
      expect(device.rssi, -60);
      expect(device.sensors, isEmpty);
    });

    test('copyWith should create a copy with updated fields', () {
      final original = IotDevice(
        id: 'device_123',
        name: 'ESP32 Sensor Hub',
        address: 'AA:BB:CC:DD:EE:FF',
        isConnected: false,
        rssi: -60,
      );

      final copy = original.copyWith(isConnected: true, rssi: -50);

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.isConnected, true);
      expect(copy.rssi, -50);
    });

    test('should support equality based on ID', () {
      final device1 = IotDevice(
        id: 'device_123',
        name: 'Device 1',
        address: 'AA:BB:CC:DD:EE:FF',
      );

      final device2 = IotDevice(
        id: 'device_123',
        name: 'Device 2',
        address: 'FF:EE:DD:CC:BB:AA',
      );

      expect(device1, device2);
      expect(device1.hashCode, device2.hashCode);
    });
  });
}
