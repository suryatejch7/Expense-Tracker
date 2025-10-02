import 'package:flutter/material.dart';
import '../../providers/expense_provider.dart';
import 'spending_trend_painter.dart';
import 'pie_chart_painter.dart';
import 'monthly_comparison_painter.dart';

class AnalyticsWidgets {
  static Widget buildAnalyticsCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  static Widget buildPeriodSelector({
    required String selectedPeriod,
    required List<String> periods,
    required Function(String) onPeriodChanged,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget buildTotalSpendingCard({
    required ExpenseProvider provider,
    required String selectedPeriod,
    required double periodData,
    required double previousPeriodData,
  }) {
    final changePercent = previousPeriodData > 0
        ? ((periodData - previousPeriodData) / previousPeriodData * 100)
        : 0.0;

    return buildAnalyticsCard(
      title: 'Total Spending - $selectedPeriod',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${periodData.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (changePercent != 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changePercent > 0 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changePercent > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'vs Previous $selectedPeriod: ₹${previousPeriodData.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static Widget buildSpendingTrendCard({
    required ExpenseProvider provider,
    required String selectedPeriod,
  }) {
    return buildAnalyticsCard(
      title: 'Spending Trend',
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          painter: SpendingTrendPainter(
            expenses: provider.expenses,
            period: selectedPeriod,
          ),
          size: const Size.fromHeight(150),
        ),
      ),
    );
  }

  static Widget buildCategoryPieChart(ExpenseProvider provider) {
    final categoryTotals = provider.categoryTotals;
    if (categoryTotals.isEmpty) {
      return buildAnalyticsCard(
        title: 'Category Breakdown',
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return buildAnalyticsCard(
      title: 'Category Breakdown',
      child: SizedBox(
        height: 200,
        child: CustomPaint(
          painter: PieChartPainter(categoryTotals: categoryTotals),
          size: const Size.fromHeight(200),
        ),
      ),
    );
  }

  static Widget buildMonthlyComparison(ExpenseProvider provider) {
    return buildAnalyticsCard(
      title: 'Monthly Comparison',
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          painter: MonthlyComparisonPainter(expenses: provider.expenses),
          size: const Size.fromHeight(150),
        ),
      ),
    );
  }
}
