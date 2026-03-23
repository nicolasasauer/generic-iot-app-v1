import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import '../models/data_point.dart';
import 'dart:async';

/// Screen for viewing raw data and process status
class RawDataScreen extends ConsumerStatefulWidget {
  const RawDataScreen({super.key});

  @override
  ConsumerState<RawDataScreen> createState() => _RawDataScreenState();
}

class _RawDataScreenState extends ConsumerState<RawDataScreen> {
  final List<DataPoint> _displayedData = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _filterSensorId = '';
  String _searchQuery = '';
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToData();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToData() {
    final dataLogger = ref.read(dataLoggerProvider);
    _dataSubscription = dataLogger.dataStream.listen((dataPoint) {
      if (mounted) {
        setState(() {
          _displayedData.insert(0, dataPoint);
          if (_displayedData.length > 1000) {
            _displayedData.removeLast();
          }
        });

        if (_autoScroll && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final processStatus = ref.watch(processStatusProvider);
    final bufferSize = ref.watch(bufferSizeProvider);

    return Scaffold(
      body: Column(
        children: [
          // Control panel
          _buildControlPanel(bufferSize),

          // Process status section
          if (processStatus.isNotEmpty) ...[
            _buildProcessStatusSection(processStatus),
            const Divider(height: 1),
          ],

          // Data log section
          Expanded(
            child: _buildDataLog(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(AsyncValue<int> bufferSize) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data Log',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                bufferSize.when(
                  data: (size) => Text(
                    '$size pts',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Auto-scroll toggle
                FilterChip(
                  label: const Text('Auto-scroll'),
                  selected: _autoScroll,
                  onSelected: (value) {
                    setState(() {
                      _autoScroll = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Export button
                ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 8),
                // Clear button
                OutlinedButton.icon(
                  onPressed: _clearData,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Search field
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessStatusSection(List<ProcessStatus> processes) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Processes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...processes.map((process) => _buildProcessItem(process)),
        ],
      ),
    );
  }

  Widget _buildProcessItem(ProcessStatus process) {
    Color statusColor;
    IconData statusIcon;

    switch (process.state) {
      case ProcessState.running:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_outline;
        break;
      case ProcessState.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case ProcessState.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case ProcessState.paused:
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  process.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  process.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (process.progress != null)
            SizedBox(
              width: 40,
              child: Text(
                '${(process.progress! * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataLog() {
    final filteredData = _displayedData.where((dp) {
      if (_filterSensorId.isNotEmpty && dp.sensorId != _filterSensorId) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return dp.sensorId.toLowerCase().contains(_searchQuery) ||
            dp.value.toString().contains(_searchQuery) ||
            dp.unit.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.data_array, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final dataPoint = filteredData[index];
        return _buildDataPointItem(dataPoint);
      },
    );
  }

  Widget _buildDataPointItem(DataPoint dataPoint) {
    final timeStr = _formatTime(dataPoint.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          child: Text(
            dataPoint.sensorId[0].toUpperCase(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dataPoint.sensorId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${dataPoint.value.toStringAsFixed(2)} ${dataPoint.unit}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        subtitle: Text(
          '$timeStr • Device: ${dataPoint.deviceId.substring(0, 8)}...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _exportData() async {
    try {
      final path = await ref
          .read(dataLoggerNotifierProvider.notifier)
          .exportToCsv();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data'),
        content: const Text('Are you sure you want to clear all logged data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(dataLoggerNotifierProvider.notifier).clearData();
              setState(() {
                _displayedData.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
