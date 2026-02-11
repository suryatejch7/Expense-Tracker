import 'package:flutter/material.dart';
import 'dart:math' as math;

class PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;

  PieChartPainter({required this.categoryTotals});

  @override
  void paint(Canvas canvas, Size size) {
    if (categoryTotals.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);

    double startAngle = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    int colorIndex = 0;
    categoryTotals.forEach((categoryName, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      paint.color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw category label
      final labelAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.7;
      final labelX = center.dx + labelRadius * math.cos(labelAngle);
      final labelY = center.dy + labelRadius * math.sin(labelAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(value / total * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = Offset(
        labelX - textPainter.width / 2,
        labelY - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      startAngle += sweepAngle;
      colorIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.categoryTotals != categoryTotals;
  }
}
