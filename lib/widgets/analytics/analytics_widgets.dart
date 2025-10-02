import 'package:flutter/material.dart';
import '../../models/expense_models.dart';

/// Custom painter for pie chart visualization
class PieChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryData;
  final List<Color> colors;

  PieChartPainter({
    required this.categoryData,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    double total = categoryData.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return;

    double startAngle = -90 * (3.14159 / 180); // Start from top
    int colorIndex = 0;

    for (final entry in categoryData.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for monthly comparison bar chart
class MonthlyComparisonPainter extends CustomPainter {
  final List<double> monthlyData;
  final Color barColor;
  final Color backgroundColor;

  MonthlyComparisonPainter({
    required this.monthlyData,
    required this.barColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    final maxValue = monthlyData.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    final barWidth = size.width / monthlyData.length;

    for (int i = 0; i < monthlyData.length; i++) {
      final barHeight = (monthlyData[i] / maxValue) * size.height;

      final rect = Rect.fromLTWH(
        i * barWidth + 5,
        size.height - barHeight,
        barWidth - 10,
        barHeight,
      );

      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
