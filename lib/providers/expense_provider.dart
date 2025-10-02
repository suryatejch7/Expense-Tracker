import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  String _searchQuery = '';
  String _userName = 'Surya Tej';
  double _monthlyBudget = 0.0;
  final Map<ExpenseCategory, double> _categoryBudgets = {};

  List<Expense> get expenses => _expenses;
  String get userName => _userName;
  double get monthlyBudget => _monthlyBudget;

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
}
