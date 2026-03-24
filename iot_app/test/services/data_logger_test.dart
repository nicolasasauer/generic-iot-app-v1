import 'package:flutter_test/flutter_test.dart';
import 'package:iot_app/services/data_logger_service.dart';
import 'package:iot_app/models/data_point.dart';

void main() {
  group('DataLoggerService', () {
    late DataLoggerService service;

    setUp(() {
      service = DataLoggerService(maxBufferSize: 100);
    });

    tearDown(() {
      service.dispose();
    });

    test('should add data points to ring buffer', () {
      final dataPoint = DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      );

      service.addDataPoint(dataPoint);

      expect(service.currentBufferSize, 1);
      expect(service.totalDataPointsReceived, 1);
    });

    test('should implement ring buffer (circular buffer) behavior', () {
      final service = DataLoggerService(maxBufferSize: 5);

      // Add 7 data points to a buffer with max size 5
      for (int i = 0; i < 7; i++) {
        service.addDataPoint(DataPoint(
          sensorId: 'temp',
          deviceId: 'device_1',
          value: i.toDouble(),
          unit: '°C',
          timestamp: DateTime.now(),
        ));
      }

      // Buffer should be full at max size
      expect(service.currentBufferSize, 5);
      // But total received should be 7
      expect(service.totalDataPointsReceived, 7);

      service.dispose();
    });

    test('should filter data points by sensor ID', () {
      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'humidity',
        deviceId: 'device_1',
        value: 60.0,
        unit: '%',
        timestamp: DateTime.now(),
      ));

      final tempData = service.getDataPoints(sensorId: 'temp');
      expect(tempData.length, 1);
      expect(tempData.first.sensorId, 'temp');
    });

    test('should filter data points by device ID', () {
      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_2',
        value: 30.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      final device1Data = service.getDataPoints(deviceId: 'device_1');
      expect(device1Data.length, 1);
      expect(device1Data.first.deviceId, 'device_1');
    });

    test('should filter data points by timestamp', () {
      final now = DateTime.now();
      final past = now.subtract(const Duration(hours: 1));

      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: past,
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 30.0,
        unit: '°C',
        timestamp: now,
      ));

      final recentData = service.getDataPoints(
        since: now.subtract(const Duration(minutes: 30)),
      );

      expect(recentData.length, 1);
      expect(recentData.first.value, 30.0);
    });

    test('should return latest value for a sensor', () {
      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 30.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      final latest = service.getLatestValue('temp');
      expect(latest?.value, 30.0);
    });

    test('should calculate sensor statistics', () {
      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 20.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 30.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      final stats = service.getSensorStatistics('temp');

      expect(stats['min'], 20.0);
      expect(stats['max'], 30.0);
      expect(stats['avg'], 25.0);
      expect(stats['count'], 3.0);
    });

    test('should clear all data', () {
      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      service.clearData();

      expect(service.currentBufferSize, 0);
    });

    test('should clear data for specific sensor', () {
      service.addDataPoint(DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      ));

      service.addDataPoint(DataPoint(
        sensorId: 'humidity',
        deviceId: 'device_1',
        value: 60.0,
        unit: '%',
        timestamp: DateTime.now(),
      ));

      service.clearSensorData('temp');

      expect(service.currentBufferSize, 1);
      final remaining = service.getDataPoints();
      expect(remaining.first.sensorId, 'humidity');
    });

    test('should calculate buffer utilization', () {
      final service = DataLoggerService(maxBufferSize: 10);

      for (int i = 0; i < 5; i++) {
        service.addDataPoint(DataPoint(
          sensorId: 'temp',
          deviceId: 'device_1',
          value: i.toDouble(),
          unit: '°C',
          timestamp: DateTime.now(),
        ));
      }

      expect(service.getBufferUtilization(), 50.0);
      service.dispose();
    });

    test('should stream data points', () async {
      final dataPoint = DataPoint(
        sensorId: 'temp',
        deviceId: 'device_1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
      );

      expectLater(
        service.dataStream,
        emits(dataPoint),
      );

      service.addDataPoint(dataPoint);
    });
  });
}
