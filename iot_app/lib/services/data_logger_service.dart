import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/data_point.dart';

/// Service for logging and managing sensor data
class DataLoggerService {
  // Ring buffer (circular buffer) for storing data points
  final List<DataPoint> _ringBuffer = [];
  final int _maxBufferSize;

  // Stream controllers
  final _dataStreamController = StreamController<DataPoint>.broadcast();
  final _bufferUpdateController = StreamController<int>.broadcast();

  // Statistics
  int _totalDataPointsReceived = 0;
  int _writeIndex = 0;

  DataLoggerService({int maxBufferSize = AppConstants.defaultRingBufferSize})
      : _maxBufferSize = maxBufferSize;

  // Getters
  Stream<DataPoint> get dataStream => _dataStreamController.stream;
  Stream<int> get bufferSizeStream => _bufferUpdateController.stream;
  int get currentBufferSize => _ringBuffer.length;
  int get maxBufferSize => _maxBufferSize;
  int get totalDataPointsReceived => _totalDataPointsReceived;

  /// Add a data point to the ring buffer
  void addDataPoint(DataPoint dataPoint) {
    if (_ringBuffer.length < _maxBufferSize) {
      // Buffer not full yet, just add
      _ringBuffer.add(dataPoint);
      _writeIndex = _ringBuffer.length;
    } else {
      // Buffer full, overwrite oldest entry (circular)
      _ringBuffer[_writeIndex] = dataPoint;
      _writeIndex = (_writeIndex + 1) % _maxBufferSize;
    }

    _totalDataPointsReceived++;
    _dataStreamController.add(dataPoint);
    _bufferUpdateController.add(_ringBuffer.length);
  }

  /// Get data points with optional filtering
  List<DataPoint> getDataPoints({
    String? sensorId,
    String? deviceId,
    DateTime? since,
    int? limit,
  }) {
    var filtered = List<DataPoint>.from(_ringBuffer);

    // Filter by sensor ID
    if (sensorId != null) {
      filtered = filtered.where((dp) => dp.sensorId == sensorId).toList();
    }

    // Filter by device ID
    if (deviceId != null) {
      filtered = filtered.where((dp) => dp.deviceId == deviceId).toList();
    }

    // Filter by timestamp
    if (since != null) {
      filtered = filtered.where((dp) => dp.timestamp.isAfter(since)).toList();
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply limit
    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  /// Get the latest data point for a sensor
  DataPoint? getLatestValue(String sensorId) {
    try {
      return _ringBuffer
          .where((dp) => dp.sensorId == sensorId)
          .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
    } catch (e) {
      return null;
    }
  }

  /// Get data points for a specific time window
  List<DataPoint> getDataPointsInWindow({
    required String sensorId,
    required Duration window,
  }) {
    final since = DateTime.now().subtract(window);
    return getDataPoints(sensorId: sensorId, since: since);
  }

  /// Get statistics for a sensor
  Map<String, double> getSensorStatistics(String sensorId) {
    final points = getDataPoints(sensorId: sensorId);
    
    if (points.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'avg': 0.0,
        'count': 0.0,
      };
    }

    final values = points.map((dp) => dp.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return {
      'min': min,
      'max': max,
      'avg': avg,
      'count': values.length.toDouble(),
    };
  }

  /// Export data to CSV file
  Future<String> exportToCsv({
    String? sensorId,
    String? deviceId,
    DateTime? since,
    String? filename,
  }) async {
    try {
      // Get data points to export
      var dataPoints = getDataPoints(
        sensorId: sensorId,
        deviceId: deviceId,
        since: since,
        limit: AppConstants.maxExportRows,
      );

      // Sort by timestamp (oldest first for CSV)
      dataPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Prepare CSV data
      final List<List<dynamic>> rows = [
        ['Timestamp', 'Device ID', 'Sensor ID', 'Value', 'Unit'],
      ];

      for (final dp in dataPoints) {
        rows.add(dp.toCsvRow());
      }

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = filename ?? 'iot_data_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Clear all data from the ring buffer
  void clearData() {
    _ringBuffer.clear();
    _writeIndex = 0;
    _bufferUpdateController.add(0);
  }

  /// Clear data for a specific sensor
  void clearSensorData(String sensorId) {
    _ringBuffer.removeWhere((dp) => dp.sensorId == sensorId);
    _writeIndex = _ringBuffer.length;
    _bufferUpdateController.add(_ringBuffer.length);
  }

  /// Get buffer utilization percentage
  double getBufferUtilization() {
    return (_ringBuffer.length / _maxBufferSize) * 100;
  }

  /// Stream data points for a specific sensor
  Stream<DataPoint> getSensorDataStream(String sensorId) {
    return _dataStreamController.stream
        .where((dataPoint) => dataPoint.sensorId == sensorId);
  }

  /// Dispose resources
  void dispose() {
    _dataStreamController.close();
    _bufferUpdateController.close();
  }
}
