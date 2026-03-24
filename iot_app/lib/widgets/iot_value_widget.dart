import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/widget_config.dart';
import '../providers/data_provider.dart';

/// Simple value display widget
class IotValueWidget extends ConsumerWidget {
  final WidgetConfig config;

  const IotValueWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (config.sensorId == null) {
      return const Center(child: Text('No sensor configured'));
    }

    final latestValue = ref.watch(latestValueProvider(config.sensorId!));
    final statistics = ref.watch(sensorStatisticsProvider(config.sensorId!));

    if (latestValue == null) {
      return const Center(child: Text('No data'));
    }

    final trend = _calculateTrend(statistics);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                latestValue.value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                latestValue.unit,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              // Trend indicator
              if (trend != 0)
                Icon(
                  trend > 0 ? Icons.trending_up : Icons.trending_down,
                  color: trend > 0 ? Colors.green : Colors.red,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                'Min',
                statistics['min']?.toStringAsFixed(1) ?? '-',
                Colors.blue,
              ),
              _buildStat(
                'Avg',
                statistics['avg']?.toStringAsFixed(1) ?? '-',
                Colors.orange,
              ),
              _buildStat(
                'Max',
                statistics['max']?.toStringAsFixed(1) ?? '-',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateTrend(Map<String, double> stats) {
    final min = stats['min'] ?? 0;
    final max = stats['max'] ?? 0;
    final avg = stats['avg'] ?? 0;

    if (max == min) return 0;

    // Simple trend: if avg is closer to max, trending up
    final normalizedAvg = (avg - min) / (max - min);
    return normalizedAvg > 0.5 ? 1 : -1;
  }
}
