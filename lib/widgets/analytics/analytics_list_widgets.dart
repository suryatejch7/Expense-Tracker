import 'package:flutter/material.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_models.dart';

class AnalyticsListWidgets {
  static Widget buildTopCategoriesCard(ExpenseProvider provider) {
    final categoryTotals = provider.categoryTotals;
    final categories = provider.categories;
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildAnalyticsCard(
      title: 'Top Categories',
      child: Column(
        children: sortedCategories.take(5).map((entry) {
          final categoryName = entry.key;
          final amount = entry.value;
          final percentage = (amount / provider.totalExpense * 100);
          final isOverBudget = provider.isCategoryOverBudget(categoryName);

          // Find the category object
          final category = categories.firstWhere(
            (cat) => cat.name == categoryName,
            orElse: () => ExpenseCategory(
              id: categoryName,
              name: categoryName,
              icon: '📦',
              color: const Color(0xFF747D8C),
            ),
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverBudget
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? Colors.red.withValues(alpha: 0.2)
                        : category.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: TextStyle(
                        fontSize: 20,
                        color: isOverBudget ? Colors.red : category.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of total',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget buildBudgetTrackingCard(ExpenseProvider provider) {
    return _buildAnalyticsCard(
      title: 'Budget Tracking',
      child: Column(
        children: [
          // Overall Budget
          if (provider.monthlyBudget > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: provider.isOverBudget
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: provider.isOverBudget ? Colors.red : Colors.green,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Budget',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        provider.isOverBudget ? 'Over Budget' : 'On Track',
                        style: TextStyle(
                          color: provider.isOverBudget ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (provider.totalExpense / provider.monthlyBudget).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      provider.isOverBudget ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ₹${provider.totalExpense.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Budget: ₹${provider.monthlyBudget.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  if (provider.isOverBudget) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Over by: ₹${provider.budgetExcess.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Category Budgets
          ...provider.categories.where((category) {
            return provider.getCategoryBudget(category.name) > 0;
          }).map((category) {
            final budget = provider.getCategoryBudget(category.name);
            final spent = provider.getCategoryExpenses(category.name);
            final isOverBudget = spent > budget;
            final percentage = (spent / budget).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverBudget
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.icon,
                        style: TextStyle(
                          fontSize: 20,
                          color: isOverBudget ? Colors.red : category.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isOverBudget ? Colors.red : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? Colors.red : category.color,
                    ),
                  ),
                  if (isOverBudget) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Over by: ₹${(spent - budget).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static Widget buildSpendingInsights(ExpenseProvider provider) {
    final insights = _getSpendingInsights(provider);

    return _buildAnalyticsCard(
      title: 'Spending Insights',
      child: Column(
        children: insights.map((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: insight['color'].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    insight['icon'],
                    color: insight['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    insight['text'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildAnalyticsCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
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

  static List<Map<String, dynamic>> _getSpendingInsights(ExpenseProvider provider) {
    final insights = <Map<String, dynamic>>[];

    if (provider.expenses.isEmpty) return insights;

    // Most expensive category
    final categoryTotals = provider.categoryTotals;
    final categories = provider.categories;

    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      // Find the category object for display name
      final topCategoryObj = categories.firstWhere(
        (cat) => cat.name == topCategory.key,
        orElse: () => ExpenseCategory(
          id: topCategory.key,
          name: topCategory.key,
          icon: '📦',
          color: const Color(0xFF747D8C),
        ),
      );

      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'text': 'Highest spending: ${topCategoryObj.displayName} (₹${topCategory.value.toStringAsFixed(0)})',
      });
    }

    // Over budget categories
    final overBudgetCategories = categories.where((category) {
      return provider.getCategoryBudget(category.name) > 0 &&
             provider.getCategoryExpenses(category.name) > provider.getCategoryBudget(category.name);
    }).length;

    if (overBudgetCategories > 0) {
      insights.add({
        'icon': Icons.category,
        'color': Colors.orange,
        'text': '$overBudgetCategories ${overBudgetCategories == 1 ? 'category is' : 'categories are'} over budget',
      });
    }

    insights.add({
      'icon': Icons.calendar_today,
      'color': Colors.green,
      'text': 'Average daily spending: ₹${(provider.totalExpense / DateTime.now().day).toStringAsFixed(0)}',
    });

    return insights;
  }
}
