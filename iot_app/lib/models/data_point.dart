/// Represents a single sensor data point logged from a device
class DataPoint {
  final String sensorId; // Unique sensor identifier
  final String deviceId; // Device that generated this data
  final double value; // Measured value
  final String unit; // Unit of measurement (e.g., "°C", "V", "A")
  final DateTime timestamp; // When the data was captured

  const DataPoint({
    required this.sensorId,
    required this.deviceId,
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  /// Create data point from JSON
  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      sensorId: json['sensorId'] as String,
      deviceId: json['deviceId'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert data point to JSON
  Map<String, dynamic> toJson() {
    return {
      'sensorId': sensorId,
      'deviceId': deviceId,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to CSV row format
  List<dynamic> toCsvRow() {
    return [
      timestamp.toIso8601String(),
      deviceId,
      sensorId,
      value,
      unit,
    ];
  }

  /// Create a copy with updated fields
  DataPoint copyWith({
    String? sensorId,
    String? deviceId,
    double? value,
    String? unit,
    DateTime? timestamp,
  }) {
    return DataPoint(
      sensorId: sensorId ?? this.sensorId,
      deviceId: deviceId ?? this.deviceId,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataPoint &&
        other.sensorId == sensorId &&
        other.deviceId == deviceId &&
        other.value == value &&
        other.unit == unit &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(sensorId, deviceId, value, unit, timestamp);
  }

  @override
  String toString() {
    return 'DataPoint(sensor: $sensorId, device: $deviceId, value: $value $unit, time: $timestamp)';
  }
}
