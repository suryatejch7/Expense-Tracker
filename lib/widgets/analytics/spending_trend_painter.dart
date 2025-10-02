import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/expense_models.dart';

class SpendingTrendPainter extends CustomPainter {
  final List<Expense> expenses;
  final Color lineColor;
  final Color fillColor;

  SpendingTrendPainter({
    required this.expenses,
    this.lineColor = Colors.blue,
    this.fillColor = Colors.blue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (expenses.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Group expenses by day and calculate daily totals
    final Map<DateTime, double> dailyTotals = {};

    for (final expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[date] = (dailyTotals[date] ?? 0.0) + expense.amount;
    }

    if (dailyTotals.isEmpty) return;

    final sortedDates = dailyTotals.keys.toList()..sort();
    final values = sortedDates.map((date) => dailyTotals[date]!).toList();

    if (values.isEmpty) return;

    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final valueRange = maxValue - minValue;

    if (valueRange == 0) return;

    final path = Path();
    final fillPath = Path();

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedValue = (values[i] - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    // Create the line path
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      // Complete the fill path
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Draw the fill area
      canvas.drawPath(fillPath, fillPaint);

      // Draw the line
      canvas.drawPath(path, paint);

      // Draw points
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 3.0, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SpendingTrendPainter oldDelegate) {
    return oldDelegate.expenses != expenses ||
           oldDelegate.lineColor != lineColor ||
           oldDelegate.fillColor != fillColor;
  }
}
