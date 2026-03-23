import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/device.dart';
import '../models/widget_config.dart';
import '../models/sensor_config.dart';

/// Service for persisting application data.
/// Uses lazy initialization - preferences are loaded on first access.
class StorageService {
  SharedPreferences? _prefs;

  /// Initialize the storage service (idempotent, safe to call multiple times)
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get preferences, initializing if necessary
  Future<SharedPreferences> get _safePrefs async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  // ========== Device Management ==========

  /// Save list of devices
  Future<bool> saveDevices(List<IotDevice> devices) async {
    try {
      final prefs = await _safePrefs;
      final jsonList = devices.map((d) => d.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(AppConstants.storageKeyDevices, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Load list of devices
  Future<List<IotDevice>> loadDevices() async {
    try {
      final prefs = await _safePrefs;
      final jsonString = prefs.getString(AppConstants.storageKeyDevices);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => IotDevice.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a single device
  Future<bool> saveDevice(IotDevice device) async {
    final devices = await loadDevices();
    final index = devices.indexWhere((d) => d.id == device.id);
    
    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }
    
    return await saveDevices(devices);
  }

  /// Delete a device
  Future<bool> deleteDevice(String deviceId) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d.id == deviceId);
    return await saveDevices(devices);
  }

  // ========== Widget Configuration ==========

  /// Save widget configurations
  Future<bool> saveWidgetConfigs(List<WidgetConfig> widgets) async {
    try {
      final prefs = await _safePrefs;
      final jsonList = widgets.map((w) => w.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(AppConstants.storageKeyWidgets, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Load widget configurations
  Future<List<WidgetConfig>> loadWidgetConfigs() async {
    try {
      final prefs = await _safePrefs;
      final jsonString = prefs.getString(AppConstants.storageKeyWidgets);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WidgetConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a single widget configuration
  Future<bool> saveWidgetConfig(WidgetConfig widget) async {
    final widgets = await loadWidgetConfigs();
    final index = widgets.indexWhere((w) => w.id == widget.id);
    
    if (index >= 0) {
      widgets[index] = widget;
    } else {
      widgets.add(widget);
    }
    
    return await saveWidgetConfigs(widgets);
  }

  /// Delete a widget configuration
  Future<bool> deleteWidgetConfig(String widgetId) async {
    final widgets = await loadWidgetConfigs();
    widgets.removeWhere((w) => w.id == widgetId);
    return await saveWidgetConfigs(widgets);
  }

  // ========== Sensor Configuration ==========

  /// Save sensor configurations
  Future<bool> saveSensorConfigs(List<SensorConfig> sensors) async {
    try {
      final prefs = await _safePrefs;
      final jsonList = sensors.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(AppConstants.storageKeySensors, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Load sensor configurations
  Future<List<SensorConfig>> loadSensorConfigs() async {
    try {
      final prefs = await _safePrefs;
      final jsonString = prefs.getString(AppConstants.storageKeySensors);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SensorConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a single sensor configuration
  Future<bool> saveSensorConfig(SensorConfig sensor) async {
    final sensors = await loadSensorConfigs();
    final index = sensors.indexWhere((s) => s.id == sensor.id);
    
    if (index >= 0) {
      sensors[index] = sensor;
    } else {
      sensors.add(sensor);
    }
    
    return await saveSensorConfigs(sensors);
  }

  /// Delete a sensor configuration
  Future<bool> deleteSensorConfig(String sensorId) async {
    final sensors = await loadSensorConfigs();
    sensors.removeWhere((s) => s.id == sensorId);
    return await saveSensorConfigs(sensors);
  }

  // ========== Settings ==========

  /// Save app settings
  Future<bool> saveSetting(String key, dynamic value) async {
    try {
      final settings = await loadSettings();
      settings[key] = value;
      final prefs = await _safePrefs;
      final jsonString = jsonEncode(settings);
      return await prefs.setString(AppConstants.storageKeySettings, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Load app settings
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await _safePrefs;
      final jsonString = prefs.getString(AppConstants.storageKeySettings);
      if (jsonString == null) return {};

      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      return {};
    }
  }

  /// Get a specific setting value
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final settings = await loadSettings();
    return settings[key] as T? ?? defaultValue;
  }

  /// Clear all stored data
  Future<bool> clearAll() async {
    final prefs = await _safePrefs;
    return await prefs.clear();
  }

  /// Clear specific data type
  Future<bool> clearDevices() async {
    final prefs = await _safePrefs;
    return await prefs.remove(AppConstants.storageKeyDevices);
  }

  Future<bool> clearWidgets() async {
    final prefs = await _safePrefs;
    return await prefs.remove(AppConstants.storageKeyWidgets);
  }

  Future<bool> clearSensors() async {
    final prefs = await _safePrefs;
    return await prefs.remove(AppConstants.storageKeySensors);
  }

  Future<bool> clearSettings() async {
    final prefs = await _safePrefs;
    return await prefs.remove(AppConstants.storageKeySettings);
  }
}
