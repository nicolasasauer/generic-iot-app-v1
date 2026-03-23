import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/widget_config.dart';
import '../providers/data_provider.dart';
import 'dart:math' as math;

/// Circular gauge widget for displaying sensor values
class IotGaugeWidget extends ConsumerWidget {
  final WidgetConfig config;

  const IotGaugeWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (config.sensorId == null) {
      return const Center(child: Text('No sensor configured'));
    }

    final latestValue = ref.watch(latestValueProvider(config.sensorId!));

    if (latestValue == null) {
      return const Center(child: Text('No data'));
    }

    final minValue = config.settings['minValue'] as double? ?? 0.0;
    final maxValue = config.settings['maxValue'] as double? ?? 100.0;

    return CustomPaint(
      painter: GaugePainter(
        value: latestValue.value,
        minValue: minValue,
        maxValue: maxValue,
        unit: latestValue.unit,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              latestValue.value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              latestValue.unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for gauge
class GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;

  GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Calculate value position
    final normalizedValue =
        ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final sweepAngle = math.pi * 1.5 * normalizedValue;

    // Draw value arc with gradient
    final valuePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.green,
          Colors.yellow,
          Colors.orange,
          Colors.red,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      valuePaint,
    );

    // Draw needle
    final needleAngle = -math.pi * 0.75 + sweepAngle;
    final needleEnd = Offset(
      center.dx + radius * 0.7 * math.cos(needleAngle),
      center.dy + radius * 0.7 * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return value != oldDelegate.value;
  }
}
