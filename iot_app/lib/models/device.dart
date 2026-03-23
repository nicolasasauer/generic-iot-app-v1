import 'sensor_config.dart';

/// Represents a BLE IoT device (ESP32)
class IotDevice {
  final String id; // BLE device ID
  final String name; // Device name
  final String address; // MAC address
  bool isConnected; // Current connection status
  int rssi; // Signal strength
  DateTime? lastSeen; // Last time device was seen
  List<SensorConfig> sensors; // Configured sensors on this device

  IotDevice({
    required this.id,
    required this.name,
    required this.address,
    this.isConnected = false,
    this.rssi = 0,
    this.lastSeen,
    List<SensorConfig>? sensors,
  }) : sensors = sensors ?? [];

  /// Create device from JSON
  factory IotDevice.fromJson(Map<String, dynamic> json) {
    return IotDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      rssi: json['rssi'] as int? ?? 0,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((e) => SensorConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert device to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'isConnected': isConnected,
      'rssi': rssi,
      'lastSeen': lastSeen?.toIso8601String(),
      'sensors': sensors.map((e) => e.toJson()).toList(),
    };
  }

  /// Create a copy with updated fields
  IotDevice copyWith({
    String? id,
    String? name,
    String? address,
    bool? isConnected,
    int? rssi,
    DateTime? lastSeen,
    List<SensorConfig>? sensors,
  }) {
    return IotDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      sensors: sensors ?? this.sensors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IotDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'IotDevice(id: $id, name: $name, address: $address, isConnected: $isConnected, rssi: $rssi)';
  }
}
