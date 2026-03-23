/// Types of dashboard widgets supported
enum WidgetType {
  gauge, // Circular gauge display
  chart, // Line chart with historical data
  value, // Simple numeric value display
  toggle, // On/off toggle for digital output
  status; // Connection/process status display

  @override
  String toString() => name[0].toUpperCase() + name.substring(1);

  /// Parse from string
  static WidgetType fromString(String value) {
    return WidgetType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WidgetType.value,
    );
  }
}

/// Configuration for a dashboard widget
class WidgetConfig {
  final String id; // Unique widget identifier
  final String title; // Widget display title
  final WidgetType type; // Type of widget
  final String? sensorId; // Associated sensor ID (if applicable)
  final String? deviceId; // Associated device ID (if applicable)
  final Map<String, dynamic> settings; // Widget-specific settings
  final int gridX; // Grid position X (column)
  final int gridY; // Grid position Y (row)
  final int gridWidth; // Grid width (columns)
  final int gridHeight; // Grid height (rows)

  const WidgetConfig({
    required this.id,
    required this.title,
    required this.type,
    this.sensorId,
    this.deviceId,
    this.settings = const {},
    this.gridX = 0,
    this.gridY = 0,
    this.gridWidth = 1,
    this.gridHeight = 1,
  });

  /// Create widget config from JSON
  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      type: WidgetType.fromString(json['type'] as String),
      sensorId: json['sensorId'] as String?,
      deviceId: json['deviceId'] as String?,
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      gridX: json['gridX'] as int? ?? 0,
      gridY: json['gridY'] as int? ?? 0,
      gridWidth: json['gridWidth'] as int? ?? 1,
      gridHeight: json['gridHeight'] as int? ?? 1,
    );
  }

  /// Convert widget config to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'sensorId': sensorId,
      'deviceId': deviceId,
      'settings': settings,
      'gridX': gridX,
      'gridY': gridY,
      'gridWidth': gridWidth,
      'gridHeight': gridHeight,
    };
  }

  /// Create a copy with updated fields
  WidgetConfig copyWith({
    String? id,
    String? title,
    WidgetType? type,
    String? sensorId,
    String? deviceId,
    Map<String, dynamic>? settings,
    int? gridX,
    int? gridY,
    int? gridWidth,
    int? gridHeight,
  }) {
    return WidgetConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      sensorId: sensorId ?? this.sensorId,
      deviceId: deviceId ?? this.deviceId,
      settings: settings ?? this.settings,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WidgetConfig(id: $id, title: $title, type: $type, sensor: $sensorId)';
  }
}
