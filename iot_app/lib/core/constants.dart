/// Application-wide constants
class AppConstants {
  // App information
  static const String appName = 'IoT Dashboard';
  static const String appVersion = '1.0.0';

  // BLE Service and Characteristic UUIDs (Nordic UART Service)
  static const String bleServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String bleTxCharacteristicUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // TX: ESP32 -> App
  static const String bleRxCharacteristicUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // RX: App -> ESP32

  // Data logging configuration
  static const int defaultRingBufferSize = 10000; // Maximum data points in memory
  static const int maxExportRows = 100000; // Maximum rows for CSV export

  // BLE scanning configuration
  static const int scanDurationSeconds = 10;
  static const int minRssi = -100; // Minimum RSSI to show device

  // Data update intervals
  static const int chartUpdateIntervalMs = 100; // Chart refresh rate
  static const int statusUpdateIntervalMs = 500; // Status widget update rate

  // Storage keys
  static const String storageKeyDevices = 'devices';
  static const String storageKeyWidgets = 'widgets';
  static const String storageKeySensors = 'sensors';
  static const String storageKeySettings = 'settings';

  // Default sensor configurations
  static const Map<String, dynamic> defaultSensorSettings = {
    'samplingRateMs': 1000,
    'loggingEnabled': true,
    'minValue': 0.0,
    'maxValue': 100.0,
  };

  // Widget grid configuration
  static const int gridColumns = 2; // Number of columns in dashboard grid
  static const double gridSpacing = 8.0; // Spacing between grid items
  static const double gridAspectRatio = 1.2; // Aspect ratio of grid items

  // Protocol settings
  static const String messageTerminator = '\n'; // BLE message delimiter
  static const int maxMessageLength = 512; // Maximum BLE message size

  // UI configuration
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double iconSize = 24.0;
  static const double chartHeight = 200.0;

  // Timeout settings
  static const int connectionTimeoutSeconds = 10;
  static const int commandTimeoutSeconds = 5;

  // Private constructor to prevent instantiation
  AppConstants._();
}
