/// Types of sensors supported by the system
enum SensorType {
  uart, // UART/Serial communication
  i2c, // I2C bus sensors
  spi, // SPI bus sensors
  analog, // Analog input (ADC)
  digital; // Digital input/output

  @override
  String toString() => name.toUpperCase();

  /// Parse from string
  static SensorType fromString(String value) {
    return SensorType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SensorType.analog,
    );
  }
}

/// Configuration for a sensor channel on a device
class SensorConfig {
  final String id; // Unique sensor identifier
  final String name; // Display name (e.g., "Temperature Sensor")
  final SensorType type; // Type of sensor interface
  final String unit; // Unit of measurement
  final double minValue; // Minimum expected value (for scaling)
  final double maxValue; // Maximum expected value (for scaling)
  final int samplingRateMs; // Sampling rate in milliseconds
  final bool loggingEnabled; // Whether to log data from this sensor

  const SensorConfig({
    required this.id,
    required this.name,
    required this.type,
    this.unit = '',
    this.minValue = 0.0,
    this.maxValue = 100.0,
    this.samplingRateMs = 1000,
    this.loggingEnabled = true,
  });

  /// Create sensor config from JSON
  factory SensorConfig.fromJson(Map<String, dynamic> json) {
    return SensorConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: SensorType.fromString(json['type'] as String),
      unit: json['unit'] as String? ?? '',
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0.0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100.0,
      samplingRateMs: json['samplingRateMs'] as int? ?? 1000,
      loggingEnabled: json['loggingEnabled'] as bool? ?? true,
    );
  }

  /// Convert sensor config to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
      'samplingRateMs': samplingRateMs,
      'loggingEnabled': loggingEnabled,
    };
  }

  /// Create a copy with updated fields
  SensorConfig copyWith({
    String? id,
    String? name,
    SensorType? type,
    String? unit,
    double? minValue,
    double? maxValue,
    int? samplingRateMs,
    bool? loggingEnabled,
  }) {
    return SensorConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      samplingRateMs: samplingRateMs ?? this.samplingRateMs,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SensorConfig(id: $id, name: $name, type: $type, unit: $unit)';
  }
}
