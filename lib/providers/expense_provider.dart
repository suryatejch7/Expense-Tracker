import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/custom_category.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  String _searchQuery = '';
  String _userName = 'Surya Tej';
  double _monthlyBudget = 0.0;
  final Map<ExpenseCategory, double> _categoryBudgets = {};

  // New: Custom categories management
  final List<CustomCategory> _customCategories = DefaultCategories.defaultCategories;
  final Map<String, double> _customCategoryBudgets = {};

  List<Expense> get expenses => _expenses;
  String get userName => _userName;
  double get monthlyBudget => _monthlyBudget;
  List<CustomCategory> get customCategories => _customCategories;

  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty) {
      return _expenses;
    }
    return _expenses.where((expense) {
      return expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             expense.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (expense.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  double get totalExpense {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<ExpenseCategory, double> get categoryTotals {
    Map<ExpenseCategory, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void removeExpense(String id) {
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
  }

  void updateExpense(Expense updatedExpense) {
    final index = _expenses.indexWhere((expense) => expense.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String get searchQuery => _searchQuery;

  bool get isOverBudget => _monthlyBudget > 0 && totalExpense > _monthlyBudget;
  double get budgetExcess => isOverBudget ? totalExpense - _monthlyBudget : 0;

  void updateUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void updateMonthlyBudget(double budget) {
    _monthlyBudget = budget;
    notifyListeners();
  }

  void setCategoryBudget(ExpenseCategory category, double budget) {
    if (budget <= 0) {
      _categoryBudgets.remove(category);
    } else {
      _categoryBudgets[category] = budget;
    }
    notifyListeners();
  }

  double getCategoryBudget(ExpenseCategory category) {
    return _categoryBudgets[category] ?? 0.0;
  }

  double getCategoryExpenses(ExpenseCategory category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  bool isCategoryOverBudget(ExpenseCategory category) {
    final budget = getCategoryBudget(category);
    return budget > 0 && getCategoryExpenses(category) > budget;
  }

  double getCategoryBudgetExcess(ExpenseCategory category) {
    final budget = getCategoryBudget(category);
    final spent = getCategoryExpenses(category);
    return budget > 0 && spent > budget ? spent - budget : 0;
  }

  // Enhanced backend logic for comprehensive budget tracking

  /// Get current month's expenses only
  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    return _expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  /// Get current month's total spending
  double get currentMonthSpending {
    return currentMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get spending for a specific category in current month
  double getCurrentMonthCategorySpending(ExpenseCategory category) {
    return currentMonthExpenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Check if current month spending exceeds monthly budget
  bool get isCurrentMonthOverBudget => _monthlyBudget > 0 && currentMonthSpending > _monthlyBudget;

  /// Get current month budget excess
  double get currentMonthBudgetExcess => isCurrentMonthOverBudget ? currentMonthSpending - _monthlyBudget : 0;

  /// Check if a category is over budget for current month
  bool isCurrentMonthCategoryOverBudget(ExpenseCategory category) {
    final budget = getCategoryBudget(category);
    return budget > 0 && getCurrentMonthCategorySpending(category) > budget;
  }

  /// Get category budget excess for current month
  double getCurrentMonthCategoryBudgetExcess(ExpenseCategory category) {
    final budget = getCategoryBudget(category);
    final spent = getCurrentMonthCategorySpending(category);
    return budget > 0 && spent > budget ? spent - budget : 0;
  }

  /// Get budget utilization percentage for total budget
  double get budgetUtilizationPercentage {
    if (_monthlyBudget <= 0) return 0;
    return (currentMonthSpending / _monthlyBudget * 100).clamp(0, 200); // Allow up to 200% for over-budget
  }

  /// Get budget utilization percentage for a specific category
  double getCategoryBudgetUtilizationPercentage(ExpenseCategory category) {
    final budget = getCategoryBudget(category);
    if (budget <= 0) return 0;
    return (getCurrentMonthCategorySpending(category) / budget * 100).clamp(0, 200);
  }

  /// Get daily average spending for current month
  double get dailyAverageSpending {
    final now = DateTime.now();
    final daysInMonth = now.day; // Days passed in current month
    if (daysInMonth == 0) return 0;
    return currentMonthSpending / daysInMonth;
  }

  /// Get projected monthly spending based on current daily average
  double get projectedMonthlySpending {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day; // Total days in current month
    return dailyAverageSpending * daysInMonth;
  }

  /// Check if projected spending will exceed budget
  bool get isProjectedToExceedBudget {
    if (_monthlyBudget <= 0) return false;
    return projectedMonthlySpending > _monthlyBudget;
  }

  /// Get remaining budget for current month
  double get remainingBudget {
    if (_monthlyBudget <= 0) return 0;
    return (_monthlyBudget - currentMonthSpending).clamp(0, _monthlyBudget);
  }

  /// Get remaining days in month
  int get remainingDaysInMonth {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    return lastDayOfMonth - now.day;
  }

  /// Get recommended daily spending to stay within budget
  double get recommendedDailySpending {
    if (_monthlyBudget <= 0 || remainingDaysInMonth <= 0) return 0;
    return remainingBudget / remainingDaysInMonth;
  }

  /// Get spending trend (increasing/decreasing compared to last month)
  SpendingTrend get spendingTrend {
    final thisMonth = currentMonthSpending;
    final lastMonth = getLastMonthSpending();

    if (lastMonth == 0) return SpendingTrend.noData;

    final changePercent = ((thisMonth - lastMonth) / lastMonth * 100);

    if (changePercent > 10) return SpendingTrend.increasingSignificantly;
    if (changePercent > 0) return SpendingTrend.increasingSlightly;
    if (changePercent < -10) return SpendingTrend.decreasingSignificantly;
    if (changePercent < 0) return SpendingTrend.decreasingSlightly;

    return SpendingTrend.stable;
  }

  /// Get last month's spending
  double getLastMonthSpending() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    return _expenses.where((expense) {
      return expense.date.year == lastMonth.year && expense.date.month == lastMonth.month;
    }).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get spending alerts based on current status
  List<SpendingAlert> get spendingAlerts {
    final alerts = <SpendingAlert>[];

    // Budget alerts
    if (isCurrentMonthOverBudget) {
      alerts.add(SpendingAlert(
        type: AlertType.overBudget,
        message: 'You have exceeded your monthly budget by ₹${currentMonthBudgetExcess.toStringAsFixed(0)}',
        severity: AlertSeverity.high,
      ));
    } else if (budgetUtilizationPercentage > 80) {
      alerts.add(SpendingAlert(
        type: AlertType.budgetWarning,
        message: 'You have used ${budgetUtilizationPercentage.toStringAsFixed(0)}% of your monthly budget',
        severity: AlertSeverity.medium,
      ));
    }

    // Category over-budget alerts
    for (final category in ExpenseCategory.values) {
      if (isCurrentMonthCategoryOverBudget(category)) {
        final excess = getCurrentMonthCategoryBudgetExcess(category);
        alerts.add(SpendingAlert(
          type: AlertType.categoryOverBudget,
          message: '${category.displayName} is over budget by ₹${excess.toStringAsFixed(0)}',
          severity: AlertSeverity.medium,
          category: category,
        ));
      }
    }

    // Projection alerts
    if (isProjectedToExceedBudget && !isCurrentMonthOverBudget) {
      alerts.add(SpendingAlert(
        type: AlertType.projectionWarning,
        message: 'At current rate, you may exceed budget by ₹${(projectedMonthlySpending - _monthlyBudget).toStringAsFixed(0)}',
        severity: AlertSeverity.low,
      ));
    }

    return alerts;
  }

  /// Get top spending categories for current month
  List<MapEntry<ExpenseCategory, double>> get topSpendingCategories {
    final currentMonthByCategory = <ExpenseCategory, double>{};

    for (final expense in currentMonthExpenses) {
      currentMonthByCategory[expense.category] =
          (currentMonthByCategory[expense.category] ?? 0) + expense.amount;
    }

    final sorted = currentMonthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted;
  }

  // Custom categories management

  // Add custom category
  void addCustomCategory(CustomCategory category) {
    _customCategories.add(category);
    notifyListeners();
  }

  // Remove custom category (only non-default categories)
  void removeCustomCategory(String categoryId) {
    final category = _customCategories.firstWhere((cat) => cat.id == categoryId);
    if (!category.isDefault) {
      _customCategories.removeWhere((cat) => cat.id == categoryId);
      _customCategoryBudgets.remove(categoryId);
      // Remove expenses with this category or convert them to "Other"
      for (int i = 0; i < _expenses.length; i++) {
        if (_expenses[i].customCategoryId == categoryId) {
          _expenses[i] = Expense(
            id: _expenses[i].id,
            title: _expenses[i].title,
            amount: _expenses[i].amount,
            category: ExpenseCategory.other, // Fallback to enum
            date: _expenses[i].date,
            note: _expenses[i].note,
            customCategoryId: 'other',
          );
        }
      }
      notifyListeners();
    }
  }

  // Update custom category
  void updateCustomCategory(CustomCategory updatedCategory) {
    final index = _customCategories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index != -1) {
      _customCategories[index] = updatedCategory;
      notifyListeners();
    }
  }

  // Get custom category budget
  double getCustomCategoryBudget(String categoryId) {
    return _customCategoryBudgets[categoryId] ?? 0.0;
  }

  // Set custom category budget
  void setCustomCategoryBudget(String categoryId, double budget) {
    if (budget <= 0) {
      _customCategoryBudgets.remove(categoryId);
    } else {
      _customCategoryBudgets[categoryId] = budget;
    }
    notifyListeners();
  }

  // Get expenses by custom category
  List<Expense> getExpensesByCustomCategory(String categoryId) {
    return _expenses.where((expense) => expense.customCategoryId == categoryId).toList();
  }

  // Get custom category expenses total
  double getCustomCategoryExpenses(String categoryId) {
    return getExpensesByCustomCategory(categoryId)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Check if custom category is over budget
  bool isCustomCategoryOverBudget(String categoryId) {
    final budget = getCustomCategoryBudget(categoryId);
    return budget > 0 && getCustomCategoryExpenses(categoryId) > budget;
  }

  // Get custom category budget excess
  double getCustomCategoryBudgetExcess(String categoryId) {
    final budget = getCustomCategoryBudget(categoryId);
    final spent = getCustomCategoryExpenses(categoryId);
    return budget > 0 && spent > budget ? spent - budget : 0;
  }

  // Get custom category by ID
  CustomCategory? getCustomCategoryById(String categoryId) {
    try {
      return _customCategories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }
}

// Enums for enhanced backend logic
enum SpendingTrend {
  increasingSignificantly,
  increasingSlightly,
  stable,
  decreasingSlightly,
  decreasingSignificantly,
  noData,
}

enum AlertType {
  overBudget,
  budgetWarning,
  categoryOverBudget,
  projectionWarning,
}

enum AlertSeverity {
  low,
  medium,
  high,
}

class SpendingAlert {
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final ExpenseCategory? category;

  SpendingAlert({
    required this.type,
    required this.message,
    required this.severity,
    this.category,
  });

  Color get color {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.orange.shade700;
      case AlertSeverity.high:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.overBudget:
        return Icons.error;
      case AlertType.budgetWarning:
        return Icons.warning;
      case AlertType.categoryOverBudget:
        return Icons.category;
      case AlertType.projectionWarning:
        return Icons.trending_up;
    }
  }
}
