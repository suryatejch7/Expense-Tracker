import 'package:flutter/material.dart';
import '../../models/expense_models.dart';

class MonthlyComparisonPainter extends CustomPainter {
  final List<Expense> expenses;

  MonthlyComparisonPainter({required this.expenses});

  @override
  void paint(Canvas canvas, Size size) {
    if (expenses.isEmpty) return;

    // Group expenses by month
    final Map<int, double> monthlyTotals = {};
    final now = DateTime.now();

    // Initialize last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      monthlyTotals[month.month] = 0.0;
    }

    // Calculate monthly totals
    for (final expense in expenses) {
      final month = expense.date.month;
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + expense.amount;
    }

    final values = monthlyTotals.values.toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    if (maxValue == 0) return;

    final barWidth = size.width / values.length;
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    // Draw bars
    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      final barHeight = (value / maxValue) * size.height * 0.8;
      final x = i * barWidth + barWidth * 0.1;
      final y = size.height - barHeight - 20;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth * 0.8, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Draw value text on top of bar
      if (value > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '₹${(value / 1000).toStringAsFixed(0)}k',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final textX = x + (barWidth * 0.8 - textPainter.width) / 2;
        final textY = y - textPainter.height - 4;
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }

    // Draw baseline
    final baselinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      baselinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
