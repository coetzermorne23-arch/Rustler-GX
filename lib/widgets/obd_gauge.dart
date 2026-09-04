import 'dart:math' as math;

import 'package:flutter/material.dart';

class ObdGauge extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final double min;
  final double max;
  final int decimals;

  const ObdGauge({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _GaugePainter(
          value: value,
          min: min,
          max: max,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                value == null ? '--' : value!.toStringAsFixed(decimals),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(unit, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double? value;
  final double min;
  final double max;

  const _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.42;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    const double start = math.pi * 0.75;
    const double sweep = math.pi * 1.5;

    final Paint track = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;
    canvas.drawArc(rect, start, sweep, false, track);

    if (value != null && max > min) {
      final double fraction = ((value! - min) / (max - min)).clamp(0.0, 1.0);
      final Paint active = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12;
      canvas.drawArc(rect, start, sweep * fraction, false, active);

      final double angle = start + sweep * fraction;
      final Offset needle = Offset(
        center.dx + math.cos(angle) * radius * 0.78,
        center.dy + math.sin(angle) * radius * 0.78,
      );
      final Paint needlePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, needle, needlePaint);
      canvas.drawCircle(center, 5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max;
  }
}
