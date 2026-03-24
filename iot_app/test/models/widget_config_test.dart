import 'package:flutter_test/flutter_test.dart';
import 'package:iot_app/models/widget_config.dart';

void main() {
  group('WidgetConfig', () {
    test('should create a widget config with all fields', () {
      final config = WidgetConfig(
        id: 'widget_123',
        title: 'Temperature Gauge',
        type: WidgetType.gauge,
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        settings: {'minValue': 0.0, 'maxValue': 100.0},
        gridX: 0,
        gridY: 0,
        gridWidth: 1,
        gridHeight: 1,
      );

      expect(config.id, 'widget_123');
      expect(config.title, 'Temperature Gauge');
      expect(config.type, WidgetType.gauge);
      expect(config.sensorId, 'temp_sensor');
      expect(config.deviceId, 'device_123');
      expect(config.settings['minValue'], 0.0);
    });

    test('should convert to JSON correctly', () {
      final config = WidgetConfig(
        id: 'widget_123',
        title: 'Temperature Gauge',
        type: WidgetType.gauge,
        sensorId: 'temp_sensor',
        deviceId: 'device_123',
        settings: {'minValue': 0.0},
      );

      final json = config.toJson();

      expect(json['id'], 'widget_123');
      expect(json['title'], 'Temperature Gauge');
      expect(json['type'], 'gauge');
      expect(json['sensorId'], 'temp_sensor');
      expect(json['deviceId'], 'device_123');
      expect(json['settings']['minValue'], 0.0);
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'widget_123',
        'title': 'Temperature Gauge',
        'type': 'gauge',
        'sensorId': 'temp_sensor',
        'deviceId': 'device_123',
        'settings': {'minValue': 0.0},
        'gridX': 0,
        'gridY': 0,
        'gridWidth': 1,
        'gridHeight': 1,
      };

      final config = WidgetConfig.fromJson(json);

      expect(config.id, 'widget_123');
      expect(config.title, 'Temperature Gauge');
      expect(config.type, WidgetType.gauge);
      expect(config.sensorId, 'temp_sensor');
    });

    test('WidgetType.fromString should parse correctly', () {
      expect(WidgetType.fromString('gauge'), WidgetType.gauge);
      expect(WidgetType.fromString('chart'), WidgetType.chart);
      expect(WidgetType.fromString('value'), WidgetType.value);
      expect(WidgetType.fromString('toggle'), WidgetType.toggle);
      expect(WidgetType.fromString('status'), WidgetType.status);
      expect(WidgetType.fromString('unknown'), WidgetType.value); // default
    });

    test('copyWith should create a copy with updated fields', () {
      final original = WidgetConfig(
        id: 'widget_123',
        title: 'Temperature Gauge',
        type: WidgetType.gauge,
      );

      final copy = original.copyWith(
        title: 'Updated Title',
        type: WidgetType.chart,
      );

      expect(copy.id, original.id);
      expect(copy.title, 'Updated Title');
      expect(copy.type, WidgetType.chart);
    });

    test('should support equality based on ID', () {
      final widget1 = WidgetConfig(
        id: 'widget_123',
        title: 'Widget 1',
        type: WidgetType.gauge,
      );

      final widget2 = WidgetConfig(
        id: 'widget_123',
        title: 'Widget 2',
        type: WidgetType.chart,
      );

      expect(widget1, widget2);
      expect(widget1.hashCode, widget2.hashCode);
    });
  });
}
