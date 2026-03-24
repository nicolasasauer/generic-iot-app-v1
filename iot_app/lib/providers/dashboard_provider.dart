import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';
import '../models/widget_config.dart';
import '../models/device.dart';
import '../models/sensor_config.dart';

/// Provider for the storage service instance
final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  service.initialize();
  return service;
});

/// Notifier for managing dashboard widgets
class DashboardNotifier extends Notifier<List<WidgetConfig>> {
  StorageService get _storage => ref.read(storageServiceProvider);
  final _uuid = const Uuid();

  @override
  List<WidgetConfig> build() {
    _loadWidgets();
    return [];
  }

  Future<void> _loadWidgets() async {
    final widgets = await _storage.loadWidgetConfigs();
    state = widgets;
  }

  Future<void> _saveWidgets() async {
    await _storage.saveWidgetConfigs(state);
  }

  /// Add a new widget to the dashboard
  Future<void> addWidget(WidgetConfig widget) async {
    // Ensure unique ID
    final widgetWithId = widget.id.isEmpty
        ? widget.copyWith(id: _uuid.v4())
        : widget;
    
    state = [...state, widgetWithId];
    await _saveWidgets();
  }

  /// Remove a widget from the dashboard
  Future<void> removeWidget(String widgetId) async {
    state = state.where((w) => w.id != widgetId).toList();
    await _saveWidgets();
  }

  /// Update an existing widget
  Future<void> updateWidget(WidgetConfig updatedWidget) async {
    state = [
      for (final widget in state)
        if (widget.id == updatedWidget.id) updatedWidget else widget,
    ];
    await _saveWidgets();
  }

  /// Reorder widgets
  Future<void> reorderWidgets(List<WidgetConfig> newOrder) async {
    state = newOrder;
    await _saveWidgets();
  }

  /// Clear all widgets
  Future<void> clearAllWidgets() async {
    state = [];
    await _saveWidgets();
  }
}

/// Provider for dashboard widgets
final dashboardProvider =
    NotifierProvider<DashboardNotifier, List<WidgetConfig>>(
  () => DashboardNotifier(),
);

/// Notifier for managing devices
class DevicesNotifier extends Notifier<List<IotDevice>> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  List<IotDevice> build() {
    _loadDevices();
    return [];
  }

  Future<void> _loadDevices() async {
    final devices = await _storage.loadDevices();
    state = devices;
  }

  Future<void> _saveDevices() async {
    await _storage.saveDevices(state);
  }

  /// Add or update a device
  Future<void> saveDevice(IotDevice device) async {
    final index = state.indexWhere((d) => d.id == device.id);
    if (index >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index) device else state[i],
      ];
    } else {
      state = [...state, device];
    }
    await _saveDevices();
  }

  /// Remove a device
  Future<void> removeDevice(String deviceId) async {
    state = state.where((d) => d.id != deviceId).toList();
    await _saveDevices();
  }

  /// Update device connection status
  void updateDeviceStatus(String deviceId, bool isConnected) {
    state = [
      for (final device in state)
        if (device.id == deviceId)
          device.copyWith(
            isConnected: isConnected,
            lastSeen: DateTime.now(),
          )
        else
          device,
    ];
  }

  /// Get device by ID
  IotDevice? getDevice(String deviceId) {
    try {
      return state.firstWhere((d) => d.id == deviceId);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for devices
final devicesProvider = NotifierProvider<DevicesNotifier, List<IotDevice>>(
  () => DevicesNotifier(),
);

/// Notifier for managing sensor configurations
class SensorConfigsNotifier extends Notifier<List<SensorConfig>> {
  StorageService get _storage => ref.read(storageServiceProvider);
  final _uuid = const Uuid();

  @override
  List<SensorConfig> build() {
    _loadSensors();
    return [];
  }

  Future<void> _loadSensors() async {
    final sensors = await _storage.loadSensorConfigs();
    state = sensors;
  }

  Future<void> _saveSensors() async {
    await _storage.saveSensorConfigs(state);
  }

  /// Add a new sensor configuration
  Future<void> addSensor(SensorConfig sensor) async {
    final sensorWithId = sensor.id.isEmpty
        ? sensor.copyWith(id: _uuid.v4())
        : sensor;
    
    state = [...state, sensorWithId];
    await _saveSensors();
  }

  /// Update a sensor configuration
  Future<void> updateSensor(SensorConfig updatedSensor) async {
    state = [
      for (final sensor in state)
        if (sensor.id == updatedSensor.id) updatedSensor else sensor,
    ];
    await _saveSensors();
  }

  /// Remove a sensor configuration
  Future<void> removeSensor(String sensorId) async {
    state = state.where((s) => s.id != sensorId).toList();
    await _saveSensors();
  }

  /// Get sensor by ID
  SensorConfig? getSensor(String sensorId) {
    try {
      return state.firstWhere((s) => s.id == sensorId);
    } catch (e) {
      return null;
    }
  }

  /// Get sensors for a specific device (by naming convention or metadata)
  List<SensorConfig> getSensorsForDevice(String deviceId) {
    // This could be enhanced with actual device-sensor relationships
    return state;
  }
}

/// Provider for sensor configurations
final sensorConfigsProvider =
    NotifierProvider<SensorConfigsNotifier, List<SensorConfig>>(
  () => SensorConfigsNotifier(),
);

/// Provider for app settings
final appSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'theme': 'dark',
    'ringBufferSize': 10000,
    'autoExport': false,
    'exportInterval': 3600, // seconds
  };
});
