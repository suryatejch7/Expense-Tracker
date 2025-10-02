import 'package:flutter/material.dart';
import '../../models/expense.dart';
import 'dart:math' as math;

class SpendingTrendPainter extends CustomPainter {
  final List<Expense> expenses;
  final String period;

  SpendingTrendPainter({required this.expenses, required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = _getDataPoints(size);

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);

      // Draw points
      final pointPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }
  }

  List<Offset> _getDataPoints(Size size) {
    final now = DateTime.now();
    final dataPoints = <double>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where((expense) {
        return expense.date.year == date.year &&
               expense.date.month == date.month &&
               expense.date.day == date.day;
      });
      dataPoints.add(dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
    }

    if (dataPoints.isEmpty) return [];

    final maxValue = dataPoints.reduce(math.max);
    if (maxValue == 0) return [];

    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height - (dataPoints[i] / maxValue) * size.height;
      points.add(Offset(x, y));
    }

    return points;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
