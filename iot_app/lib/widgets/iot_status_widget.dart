import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/widget_config.dart';
import '../providers/data_provider.dart';
import '../providers/bluetooth_provider.dart';

/// Status widget for displaying connection and process information
class IotStatusWidget extends ConsumerWidget {
  final WidgetConfig config;

  const IotStatusWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bufferUtilization = ref.watch(bufferUtilizationProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final bluetoothStatus = ref.watch(bluetoothStatusProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status
          _buildStatusRow(
            icon: Icons.bluetooth,
            label: 'Connection',
            value: bluetoothStatus.when(
              data: (status) => status.toString().split('.').last,
              loading: () => 'Loading...',
              error: (_, __) => 'Error',
            ),
            color: bluetoothStatus.when(
              data: (status) => status.toString().contains('connected')
                  ? Colors.green
                  : Colors.grey,
              loading: () => Colors.orange,
              error: (_, __) => Colors.red,
            ),
          ),
          const SizedBox(height: 8),

          // Devices connected
          _buildStatusRow(
            icon: Icons.devices,
            label: 'Devices',
            value: '${connectedDevices.length}',
            color: connectedDevices.isNotEmpty ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 8),

          // Buffer utilization
          _buildStatusRow(
            icon: Icons.storage,
            label: 'Buffer',
            value: '${bufferUtilization.toStringAsFixed(1)}%',
            color: bufferUtilization > 80
                ? Colors.red
                : bufferUtilization > 50
                    ? Colors.orange
                    : Colors.green,
          ),
          const SizedBox(height: 8),

          // Buffer bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: bufferUtilization / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                bufferUtilization > 80
                    ? Colors.red
                    : bufferUtilization > 50
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
