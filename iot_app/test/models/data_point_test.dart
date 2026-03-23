import 'package:flutter_test/flutter_test.dart';
import 'package:iot_app/models/data_point.dart';

void main() {
  group('DataPoint', () {
    test('should create a DataPoint with all fields', () {
      final timestamp = DateTime.now();
      final dataPoint = DataPoint(
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        value: 25.5,
        unit: '°C',
        timestamp: timestamp,
      );

      expect(dataPoint.sensorId, 'temp_sensor');
      expect(dataPoint.deviceId, 'device_123');
      expect(dataPoint.value, 25.5);
      expect(dataPoint.unit, '°C');
      expect(dataPoint.timestamp, timestamp);
    });

    test('should convert to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final dataPoint = DataPoint(
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        value: 25.5,
        unit: '°C',
        timestamp: timestamp,
      );

      final json = dataPoint.toJson();

      expect(json['sensorId'], 'temp_sensor');
      expect(json['deviceId'], 'device_123');
      expect(json['value'], 25.5);
      expect(json['unit'], '°C');
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('should create from JSON correctly', () {
      final json = {
        'sensorId': 'temp_sensor',
        'deviceId': 'device_123',
        'value': 25.5,
        'unit': '°C',
        'timestamp': '2024-01-01T12:00:00.000',
      };

      final dataPoint = DataPoint.fromJson(json);

      expect(dataPoint.sensorId, 'temp_sensor');
      expect(dataPoint.deviceId, 'device_123');
      expect(dataPoint.value, 25.5);
      expect(dataPoint.unit, '°C');
    });

    test('should convert to CSV row correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final dataPoint = DataPoint(
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        value: 25.5,
        unit: '°C',
        timestamp: timestamp,
      );

      final csvRow = dataPoint.toCsvRow();

      expect(csvRow[0], timestamp.toIso8601String());
      expect(csvRow[1], 'device_123');
      expect(csvRow[2], 'temp_sensor');
      expect(csvRow[3], 25.5);
      expect(csvRow[4], '°C');
    });

    test('should support equality', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final dp1 = DataPoint(
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        value: 25.5,
        unit: '°C',
        timestamp: timestamp,
      );

      final dp2 = DataPoint(
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        value: 25.5,
        unit: '°C',
        timestamp: timestamp,
      );

      expect(dp1, dp2);
      expect(dp1.hashCode, dp2.hashCode);
    });

    test('copyWith should create a copy with updated fields', () {
      final original = DataPoint(
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        value: 25.5,
        unit: '°C',
        timestamp: DateTime.now(),
      );

      final copy = original.copyWith(value: 30.0);

      expect(copy.sensorId, original.sensorId);
      expect(copy.value, 30.0);
      expect(copy.unit, original.unit);
    });
  });
}
