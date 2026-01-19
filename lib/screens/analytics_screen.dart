import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_models.dart';
import '../providers/expense_provider.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Day', 'Week', 'Month', 'Year'];
  String? _selectedAccountId; // null means all accounts

  @override
  void initState() {
    super.initState();
    // Note: Data is already loaded by UserProvider initialization
    // Manual refresh is available via the refresh button if needed
  }

  // Get filtered expenses based on selected account
  List<Expense> _getFilteredExpenses(ExpenseProvider provider) {
    if (_selectedAccountId == null) {
      return provider.expenses;
    }
    return provider.expenses.where((e) => e.accountId == _selectedAccountId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<ExpenseProvider>().forceRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics refreshed'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 12),

                // Account Selector
                _buildAccountSelector(provider),
                const SizedBox(height: 20),

                // Total Spending Overview
                _buildTotalSpendingCard(provider),
                const SizedBox(height: 20),

                // Spending Trend Chart
                _buildSpendingTrendCard(provider),
                const SizedBox(height: 20),

                // Category Pie Chart
                _buildCategoryPieChart(provider),
                const SizedBox(height: 20),

                // Top Categories
                _buildTopCategoriesCard(provider),
                const SizedBox(height: 20),

                // Budget Tracking
                _buildBudgetTrackingCard(provider),
                const SizedBox(height: 20),

                // Spending Insights
                _buildSpendingInsights(provider),
                const SizedBox(height: 20),

                // Monthly Comparison
                _buildMonthlyComparison(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
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

  Widget _buildAccountSelector(ExpenseProvider provider) {
    final accounts = provider.accounts;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedAccountId,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
          hint: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('All Accounts', style: TextStyle(color: Colors.white)),
            ],
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('All Accounts', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            ...accounts.map((account) => DropdownMenuItem<String?>(
              value: account.id,
              child: Row(
                children: [
                  Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(account.name, style: const TextStyle(color: Colors.white)),
                ],
              ),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAccountId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTotalSpendingCard(ExpenseProvider provider) {
    final periodData = _getPeriodData(provider);
    final previousPeriodData = _getPreviousPeriodData(provider);
    final changePercent = previousPeriodData > 0
        ? ((periodData - previousPeriodData) / previousPeriodData * 100)
        : 0.0;

    return _buildAnalyticsCard(
      title: 'Total Spending - $_selectedPeriod',
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
            'vs Previous $_selectedPeriod: ₹${previousPeriodData.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendCard(ExpenseProvider provider) {
    return _buildAnalyticsCard(
      title: 'Spending Trend',
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          painter: SpendingTrendPainter(
            expenses: _getFilteredExpenses(provider),
            period: _selectedPeriod,
          ),
          size: const Size.fromHeight(150),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(ExpenseProvider provider) {
    final categoryTotals = _getCategoryTotalsForPeriod(provider);
    if (categoryTotals.isEmpty) {
      return _buildAnalyticsCard(
        title: 'Category Breakdown - $_selectedPeriod',
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildAnalyticsCard(
      title: 'Category Breakdown - $_selectedPeriod',
      child: SizedBox(
        height: 200,
        child: CustomPaint(
          painter: PieChartPainter(categoryTotals: categoryTotals),
          size: const Size.fromHeight(200),
        ),
      ),
    );
  }

  Widget _buildTopCategoriesCard(ExpenseProvider provider) {
    final categoryTotals = _getCategoryTotalsForPeriod(provider);
    final periodTotal = _getPeriodData(provider);
    final categories = provider.categories;
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return _buildAnalyticsCard(
        title: 'Top Categories - $_selectedPeriod',
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildAnalyticsCard(
      title: 'Top Categories - $_selectedPeriod',
      child: Column(
        children: sortedCategories.take(5).map((entry) {
          final categoryName = entry.key;
          final amount = entry.value;
          final percentage = periodTotal > 0 ? (amount / periodTotal * 100) : 0.0;
          // Only show over budget for monthly view
          final isOverBudget = _selectedPeriod == 'Month' && provider.isCategoryOverBudget(categoryName);

          // Find the category object
          final category = categories.firstWhere(
            (cat) => cat.name == categoryName,
            orElse: () => ExpenseCategory(
              id: categoryName,
              name: categoryName,
              icon: '📦',
              colorHex: '#747D8C',
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

  Widget _buildBudgetTrackingCard(ExpenseProvider provider) {
    // Only show budget tracking for Month view since budgets are monthly
    if (_selectedPeriod != 'Month') {
      return _buildAnalyticsCard(
        title: 'Budget Tracking',
        child: const Center(
          child: Text(
            'Budget tracking is available in Month view',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

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
                    value: (provider.currentMonthTotalExpense / provider.monthlyBudget).clamp(0.0, 1.0),
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
                        'Spent: ₹${provider.currentMonthTotalExpense.toStringAsFixed(0)}',
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

  Widget _buildSpendingInsights(ExpenseProvider provider) {
    final insights = _generateInsights(provider);

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
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  insight['icon'],
                  color: insight['color'],
                  size: 24,
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

  Widget _buildMonthlyComparison(ExpenseProvider provider) {
    String title;
    switch (_selectedPeriod) {
      case 'Day':
        title = 'Last 7 Days';
        break;
      case 'Week':
        title = 'Last 4 Weeks';
        break;
      case 'Month':
        title = 'Last 6 Months';
        break;
      case 'Year':
        title = 'Last 3 Years';
        break;
      default:
        title = 'Monthly Comparison';
    }

    return _buildAnalyticsCard(
      title: title,
      child: SizedBox(
        height: 120,
        child: CustomPaint(
          painter: ComparisonBarPainter(expenses: _getFilteredExpenses(provider), period: _selectedPeriod),
          size: const Size.fromHeight(120),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({required String title, required Widget child}) {
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

  double _getPeriodData(ExpenseProvider provider) {
    final now = DateTime.now();
    // Ensure we're using the most up-to-date expenses, filtered by account
    final baseExpenses = _getFilteredExpenses(provider);
    final expenses = baseExpenses.where((expense) {
      switch (_selectedPeriod) {
        case 'Day':
          return expense.date.year == now.year &&
                 expense.date.month == now.month &&
                 expense.date.day == now.day;
        case 'Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return expense.date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'Month':
          return expense.date.year == now.year && expense.date.month == now.month;
        case 'Year':
          return expense.date.year == now.year;
        default:
          return false;
      }
    }).toList(); // Convert to list to ensure we have fresh data
    
    final total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    return total;
  }

  double _getPreviousPeriodData(ExpenseProvider provider) {
    final now = DateTime.now();
    // Ensure we're using the most up-to-date expenses, filtered by account
    final baseExpenses = _getFilteredExpenses(provider);
    final expenses = baseExpenses.where((expense) {
      switch (_selectedPeriod) {
        case 'Day':
          final yesterday = now.subtract(const Duration(days: 1));
          return expense.date.year == yesterday.year &&
                 expense.date.month == yesterday.month &&
                 expense.date.day == yesterday.day;
        case 'Week':
          final lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
          final lastWeekEnd = now.subtract(Duration(days: now.weekday));
          return expense.date.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
                 expense.date.isBefore(lastWeekEnd);
        case 'Month':
          final lastMonth = DateTime(now.year, now.month - 1);
          return expense.date.year == lastMonth.year && expense.date.month == lastMonth.month;
        case 'Year':
          return expense.date.year == now.year - 1;
        default:
          return false;
      }
    }).toList(); // Convert to list to ensure we have fresh data
    
    final total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    return total;
  }

  List<Map<String, dynamic>> _generateInsights(ExpenseProvider provider) {
    final insights = <Map<String, dynamic>>[];
    final categoryTotals = _getCategoryTotalsForPeriod(provider);
    final periodTotal = _getPeriodData(provider);
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
          colorHex: '#747D8C',
        ),
      );

      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'text': '${topCategoryObj.displayName} is your highest spending category this $_selectedPeriod (₹${topCategory.value.toStringAsFixed(0)})',
      });
    }

    // Only show budget warnings for Month view
    if (_selectedPeriod == 'Month') {
      if (provider.isOverBudget) {
        insights.add({
          'icon': Icons.warning,
          'color': Colors.red,
          'text': 'You\'ve exceeded your monthly budget by ₹${provider.budgetExcess.toStringAsFixed(0)}',
        });
      }

      final overBudgetCategories = categories.where((category) =>
          provider.isCategoryOverBudget(category.name)).length;
      if (overBudgetCategories > 0) {
        insights.add({
          'icon': Icons.category,
          'color': Colors.orange,
          'text': '$overBudgetCategories ${overBudgetCategories == 1 ? 'category is' : 'categories are'} over budget',
        });
      }
    }

    // Calculate average based on period
    final averageSpending = _calculateAverageSpending(provider, periodTotal);
    insights.add({
      'icon': Icons.calendar_today,
      'color': Colors.green,
      'text': averageSpending,
    });

    return insights;
  }

  /// Calculate average spending based on selected period
  String _calculateAverageSpending(ExpenseProvider provider, double periodTotal) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Day':
        return 'Total today: ₹${periodTotal.toStringAsFixed(0)}';
      case 'Week':
        final daysInWeek = now.weekday;
        final avg = daysInWeek > 0 ? periodTotal / daysInWeek : 0;
        return 'Average daily spending this week: ₹${avg.toStringAsFixed(0)}';
      case 'Month':
        final avg = now.day > 0 ? periodTotal / now.day : 0;
        return 'Average daily spending this month: ₹${avg.toStringAsFixed(0)}';
      case 'Year':
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
        final avg = dayOfYear > 0 ? periodTotal / dayOfYear : 0;
        return 'Average daily spending this year: ₹${avg.toStringAsFixed(0)}';
      default:
        return 'Average daily spending: ₹${(periodTotal / now.day).toStringAsFixed(0)}';
    }
  }

  /// Get category totals filtered by selected period and account
  Map<String, double> _getCategoryTotalsForPeriod(ExpenseProvider provider) {
    final now = DateTime.now();
    final baseExpenses = _getFilteredExpenses(provider);
    final filteredExpenses = baseExpenses.where((expense) {
      switch (_selectedPeriod) {
        case 'Day':
          return expense.date.year == now.year &&
                 expense.date.month == now.month &&
                 expense.date.day == now.day;
        case 'Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return expense.date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'Month':
          return expense.date.year == now.year && expense.date.month == now.month;
        case 'Year':
          return expense.date.year == now.year;
        default:
          return false;
      }
    }).toList();

    Map<String, double> totals = {};
    for (var expense in filteredExpenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  /// Get filtered expenses for the selected period and account
  List<Expense> _getExpensesForPeriod(ExpenseProvider provider) {
    final now = DateTime.now();
    final baseExpenses = _getFilteredExpenses(provider);
    return baseExpenses.where((expense) {
      switch (_selectedPeriod) {
        case 'Day':
          return expense.date.year == now.year &&
                 expense.date.month == now.month &&
                 expense.date.day == now.day;
        case 'Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return expense.date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'Month':
          return expense.date.year == now.year && expense.date.month == now.month;
        case 'Year':
          return expense.date.year == now.year;
        default:
          return false;
      }
    }).toList();
  }
}

// Custom Painters for Charts
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

    switch (period) {
      case 'Day':
        // Show hourly breakdown for today (last 24 hours in 6 segments)
        for (int i = 5; i >= 0; i--) {
          final hourStart = now.subtract(Duration(hours: i * 4));
          final hourEnd = now.subtract(Duration(hours: (i - 1) * 4));
          final hourExpenses = expenses.where((expense) {
            return expense.date.year == now.year &&
                   expense.date.month == now.month &&
                   expense.date.day == now.day &&
                   expense.date.hour >= hourStart.hour &&
                   expense.date.hour < hourEnd.hour;
          });
          dataPoints.add(hourExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      case 'Week':
        // Show last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayExpenses = expenses.where((expense) {
            return expense.date.year == date.year &&
                   expense.date.month == date.month &&
                   expense.date.day == date.day;
          });
          dataPoints.add(dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      case 'Month':
        // Show last 4 weeks
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: (i + 1) * 7));
          final weekEnd = now.subtract(Duration(days: i * 7));
          final weekExpenses = expenses.where((expense) {
            return expense.date.isAfter(weekStart) && expense.date.isBefore(weekEnd.add(const Duration(days: 1)));
          });
          dataPoints.add(weekExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      case 'Year':
        // Show last 6 months
        for (int i = 5; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i);
          final monthExpenses = expenses.where((expense) {
            return expense.date.year == month.year && expense.date.month == month.month;
          });
          dataPoints.add(monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      default:
        // Default to last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayExpenses = expenses.where((expense) {
            return expense.date.year == date.year &&
                   expense.date.month == date.month &&
                   expense.date.day == date.day;
          });
          dataPoints.add(dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
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

class PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;

  PieChartPainter({required this.categoryTotals});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3;
    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);

    double startAngle = -math.pi / 2;

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

    for (final entry in categoryTotals.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
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

class ComparisonBarPainter extends CustomPainter {
  final List<Expense> expenses;
  final String period;

  ComparisonBarPainter({required this.expenses, required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final now = DateTime.now();
    final data = <double>[];

    switch (period) {
      case 'Day':
        // Last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayExpenses = expenses.where((expense) {
            return expense.date.year == date.year &&
                   expense.date.month == date.month &&
                   expense.date.day == date.day;
          });
          data.add(dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      case 'Week':
        // Last 4 weeks
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: (i + 1) * 7));
          final weekEnd = now.subtract(Duration(days: i * 7));
          final weekExpenses = expenses.where((expense) {
            return expense.date.isAfter(weekStart) && expense.date.isBefore(weekEnd.add(const Duration(days: 1)));
          });
          data.add(weekExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      case 'Month':
        // Last 6 months
        for (int i = 5; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i);
          final monthExpenses = expenses.where((expense) {
            return expense.date.year == month.year && expense.date.month == month.month;
          });
          data.add(monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      case 'Year':
        // Last 3 years
        for (int i = 2; i >= 0; i--) {
          final year = now.year - i;
          final yearExpenses = expenses.where((expense) {
            return expense.date.year == year;
          });
          data.add(yearExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
        break;
      default:
        // Default to last 6 months
        for (int i = 5; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i);
          final monthExpenses = expenses.where((expense) {
            return expense.date.year == month.year && expense.date.month == month.month;
          });
          data.add(monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
        }
    }

    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max);
    if (maxValue == 0) return;

    final barWidth = size.width / data.length * 0.8;
    final spacing = size.width / data.length * 0.2;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * size.height;
      final x = i * (barWidth + spacing) + spacing / 2;
      final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
