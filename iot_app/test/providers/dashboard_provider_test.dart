import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_app/providers/dashboard_provider.dart';
import 'package:iot_app/models/widget_config.dart';

void main() {
  group('DashboardProvider', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should start with empty widget list', () {
      final widgets = container.read(dashboardProvider);
      expect(widgets, isEmpty);
    });

    test('should add widget', () async {
      final notifier = container.read(dashboardProvider.notifier);
      
      final widget = WidgetConfig(
        id: 'widget_1',
        title: 'Temperature',
        type: WidgetType.gauge,
      );

      await notifier.addWidget(widget);

      final widgets = container.read(dashboardProvider);
      expect(widgets.length, 1);
      expect(widgets.first.id, 'widget_1');
    });

    test('should remove widget', () async {
      final notifier = container.read(dashboardProvider.notifier);
      
      final widget = WidgetConfig(
        id: 'widget_1',
        title: 'Temperature',
        type: WidgetType.gauge,
      );

      await notifier.addWidget(widget);
      await notifier.removeWidget('widget_1');

      final widgets = container.read(dashboardProvider);
      expect(widgets, isEmpty);
    });

    test('should update widget', () async {
      final notifier = container.read(dashboardProvider.notifier);
      
      final widget = WidgetConfig(
        id: 'widget_1',
        title: 'Temperature',
        type: WidgetType.gauge,
      );

      await notifier.addWidget(widget);

      final updated = widget.copyWith(title: 'Updated Title');
      await notifier.updateWidget(updated);

      final widgets = container.read(dashboardProvider);
      expect(widgets.first.title, 'Updated Title');
    });

    test('should clear all widgets', () async {
      final notifier = container.read(dashboardProvider.notifier);
      
      await notifier.addWidget(WidgetConfig(
        id: 'widget_1',
        title: 'Widget 1',
        type: WidgetType.gauge,
      ));

      await notifier.addWidget(WidgetConfig(
        id: 'widget_2',
        title: 'Widget 2',
        type: WidgetType.chart,
      ));

      await notifier.clearAllWidgets();

      final widgets = container.read(dashboardProvider);
      expect(widgets, isEmpty);
    });
  });
}
