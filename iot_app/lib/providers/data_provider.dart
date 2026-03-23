import 'package:riverpod/riverpod.dart';
import '../services/data_logger_service.dart';
import '../models/data_point.dart';
import '../models/device.dart';
import 'bluetooth_provider.dart';

/// Provider for the data logger service instance
final dataLoggerProvider = Provider<DataLoggerService>((ref) {
  final service = DataLoggerService();
  
  // Connect to Bluetooth data stream
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  bluetoothService.dataStream.listen((dataPoint) {
    service.addDataPoint(dataPoint);
  });
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for data points stream
final dataPointsStreamProvider = StreamProvider<DataPoint>((ref) {
  final service = ref.watch(dataLoggerProvider);
  return service.dataStream;
});

/// Provider for buffer size updates
final bufferSizeProvider = StreamProvider<int>((ref) {
  final service = ref.watch(dataLoggerProvider);
  return service.bufferSizeStream;
});

/// Provider for data points for a specific sensor
final sensorDataPointsProvider = Provider.family<List<DataPoint>, String>(
  (ref, sensorId) {
    final service = ref.watch(dataLoggerProvider);
    return service.getDataPoints(sensorId: sensorId, limit: 100);
  },
);

/// Provider for latest value of a sensor
final latestValueProvider = Provider.family<DataPoint?, String>(
  (ref, sensorId) {
    final service = ref.watch(dataLoggerProvider);
    return service.getLatestValue(sensorId);
  },
);

/// Provider for sensor statistics
final sensorStatisticsProvider = Provider.family<Map<String, double>, String>(
  (ref, sensorId) {
    final service = ref.watch(dataLoggerProvider);
    return service.getSensorStatistics(sensorId);
  },
);

/// Provider for buffer utilization
final bufferUtilizationProvider = Provider<double>((ref) {
  final service = ref.watch(dataLoggerProvider);
  return service.getBufferUtilization();
});

/// Process status information
class ProcessStatus {
  final String id;
  final String name;
  final String description;
  final ProcessState state;
  final double? progress; // 0.0 to 1.0, null if indeterminate
  final DateTime startTime;
  final String? error;

  const ProcessStatus({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    this.progress,
    required this.startTime,
    this.error,
  });

  ProcessStatus copyWith({
    String? id,
    String? name,
    String? description,
    ProcessState? state,
    double? progress,
    DateTime? startTime,
    String? error,
  }) {
    return ProcessStatus(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      startTime: startTime ?? this.startTime,
      error: error ?? this.error,
    );
  }
}

enum ProcessState { running, completed, failed, paused }

/// Notifier for managing active processes
class ProcessStatusNotifier extends Notifier<List<ProcessStatus>> {
  @override
  List<ProcessStatus> build() {
    // Monitor Bluetooth connections as processes
    ref.listen(connectedDevicesProvider, (previous, next) {
      _updateDeviceProcesses(next);
    });
    
    return [];
  }

  void _updateDeviceProcesses(Map<String, IotDevice> devices) {
    final processes = <ProcessStatus>[];
    
    for (final entry in devices.entries) {
      final deviceId = entry.key;
      final device = entry.value;
      
      processes.add(ProcessStatus(
        id: 'device_$deviceId',
        name: 'Device Connection',
        description: 'Connected to ${device.name}',
        state: ProcessState.running,
        startTime: DateTime.now(),
      ));
    }
    
    state = processes;
  }

  void addProcess(ProcessStatus process) {
    state = [...state, process];
  }

  void updateProcess(String id, ProcessStatus updated) {
    state = [
      for (final process in state)
        if (process.id == id) updated else process,
    ];
  }

  void removeProcess(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void clearCompleted() {
    state = state.where((p) => p.state != ProcessState.completed).toList();
  }
}

/// Provider for process status list
final processStatusProvider =
    NotifierProvider<ProcessStatusNotifier, List<ProcessStatus>>(
  () => ProcessStatusNotifier(),
);

/// Notifier for data logger operations
class DataLoggerNotifier extends Notifier<void> {
  DataLoggerService get _service => ref.read(dataLoggerProvider);

  @override
  void build() {}

  /// Export data to CSV
  Future<String> exportToCsv({
    String? sensorId,
    String? deviceId,
    DateTime? since,
    String? filename,
  }) async {
    final processId = 'export_${DateTime.now().millisecondsSinceEpoch}';
    
    ref.read(processStatusProvider.notifier).addProcess(
      ProcessStatus(
        id: processId,
        name: 'Export Data',
        description: 'Exporting data to CSV...',
        state: ProcessState.running,
        startTime: DateTime.now(),
      ),
    );

    try {
      final path = await _service.exportToCsv(
        sensorId: sensorId,
        deviceId: deviceId,
        since: since,
        filename: filename,
      );

      ref.read(processStatusProvider.notifier).updateProcess(
        processId,
        ProcessStatus(
          id: processId,
          name: 'Export Data',
          description: 'Export completed: $path',
          state: ProcessState.completed,
          progress: 1.0,
          startTime: DateTime.now(),
        ),
      );

      return path;
    } catch (e) {
      ref.read(processStatusProvider.notifier).updateProcess(
        processId,
        ProcessStatus(
          id: processId,
          name: 'Export Data',
          description: 'Export failed',
          state: ProcessState.failed,
          startTime: DateTime.now(),
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Clear all data
  void clearData() {
    _service.clearData();
  }

  /// Clear sensor data
  void clearSensorData(String sensorId) {
    _service.clearSensorData(sensorId);
  }
}

/// Provider for data logger operations
final dataLoggerNotifierProvider = NotifierProvider<DataLoggerNotifier, void>(
  () => DataLoggerNotifier(),
);
