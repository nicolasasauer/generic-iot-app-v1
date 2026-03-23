import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_app/services/storage_service.dart';
import 'package:iot_app/models/device.dart';
import 'package:iot_app/models/widget_config.dart';
import 'package:iot_app/models/sensor_config.dart';

void main() {
  group('StorageService', () {
    late StorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = StorageService();
      await service.initialize();
    });

    test('should save and load devices', () async {
      final device = IotDevice(
        id: 'device_123',
        name: 'ESP32 Sensor',
        address: 'AA:BB:CC:DD:EE:FF',
      );

      await service.saveDevices([device]);
      final loaded = await service.loadDevices();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'device_123');
      expect(loaded.first.name, 'ESP32 Sensor');
    });

    test('should save and load widget configs', () async {
      final widget = WidgetConfig(
        id: 'widget_123',
        title: 'Temperature',
        type: WidgetType.gauge,
      );

      await service.saveWidgetConfigs([widget]);
      final loaded = await service.loadWidgetConfigs();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'widget_123');
      expect(loaded.first.title, 'Temperature');
    });

    test('should save and load sensor configs', () async {
      final sensor = SensorConfig(
        id: 'sensor_123',
        name: 'Temperature Sensor',
        type: SensorType.analog,
      );

      await service.saveSensorConfigs([sensor]);
      final loaded = await service.loadSensorConfigs();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'sensor_123');
      expect(loaded.first.name, 'Temperature Sensor');
    });

    test('should save and load settings', () async {
      await service.saveSetting('theme', 'dark');
      await service.saveSetting('bufferSize', 10000);

      final theme = await service.getSetting('theme');
      final bufferSize = await service.getSetting('bufferSize');

      expect(theme, 'dark');
      expect(bufferSize, 10000);
    });

    test('should delete a device', () async {
      final device1 = IotDevice(
        id: 'device_1',
        name: 'Device 1',
        address: 'AA:BB:CC:DD:EE:FF',
      );

      final device2 = IotDevice(
        id: 'device_2',
        name: 'Device 2',
        address: 'FF:EE:DD:CC:BB:AA',
      );

      await service.saveDevices([device1, device2]);
      await service.deleteDevice('device_1');

      final loaded = await service.loadDevices();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'device_2');
    });

    test('should clear all data', () async {
      await service.saveDevices([
        IotDevice(id: '1', name: 'Device', address: 'AA:BB:CC:DD:EE:FF')
      ]);
      await service.saveWidgetConfigs([
        WidgetConfig(id: '1', title: 'Widget', type: WidgetType.gauge)
      ]);

      await service.clearAll();

      final devices = await service.loadDevices();
      final widgets = await service.loadWidgetConfigs();

      expect(devices, isEmpty);
      expect(widgets, isEmpty);
    });

    test('should return empty list when no data exists', () async {
      final devices = await service.loadDevices();
      final widgets = await service.loadWidgetConfigs();
      final sensors = await service.loadSensorConfigs();

      expect(devices, isEmpty);
      expect(widgets, isEmpty);
      expect(sensors, isEmpty);
    });
  });
}
