import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import '../models/expense_models.dart';
import '../services/supabase_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final List<ExpenseCategory> _categories = [];
  final List<ExpenseCategory> _customCategories = [];
  final Map<String, double> _categoryBudgets = {};
  String _searchQuery = '';
  final String _userName = 'Surya Tej';
  final double _monthlyBudget = 25000.0;
  bool _isLoading = false;

  // Getters
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  List<ExpenseCategory> get customCategories => _customCategories;
  String get userName => _userName;
  double get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty) {
      return _expenses;
    }
    return _expenses.where((expense) {
      return expense.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (expense.payee?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  double get totalExpense {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get categoryTotals {
    Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  // Budget-related getters
  bool get isOverBudget => totalExpense > _monthlyBudget;
  double get budgetExcess => totalExpense - _monthlyBudget;

  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  // Category budget methods
  double getCategoryBudget(String category) {
    return _categoryBudgets[category] ?? 0.0;
  }

  bool isCategoryOverBudget(String category) {
    final budget = getCategoryBudget(category);
    final expenses = getCategoryExpenses(category);
    return expenses > budget && budget > 0;
  }

  double getCategoryBudgetExcess(String category) {
    final budget = getCategoryBudget(category);
    final expenses = getCategoryExpenses(category);
    return expenses - budget;
  }

  double getCategoryExpenses(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Custom category methods
  void addCustomCategory(ExpenseCategory category) {
    _customCategories.add(category);
    notifyListeners();
  }

  void removeCustomCategory(String categoryId) {
    _customCategories.removeWhere((cat) => cat.id == categoryId);
    notifyListeners();
  }

  double getCustomCategoryBudget(String categoryId) {
    return _categoryBudgets[categoryId] ?? 0.0;
  }

  void setCustomCategoryBudget(String categoryId, double budget) {
    _categoryBudgets[categoryId] = budget;
    notifyListeners();
  }

  double getCustomCategoryExpenses(String categoryId) {
    final category = _customCategories.firstWhere((cat) => cat.id == categoryId);
    return getCategoryExpenses(category.name);
  }

  // Search methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // User profile methods
  void updateUserName(String name) {
    // Note: _userName is final, so this is a placeholder for future implementation
    notifyListeners();
  }

  void updateMonthlyBudget(double budget) {
    // Note: _monthlyBudget is final, so this is a placeholder for future implementation
    notifyListeners();
  }

  /// Add expense to Supabase
  Future<void> addExpense(Expense expense) async {
    try {
      // Add to local list first for immediate UI update
      _expenses.add(expense);
      notifyListeners();

      // Then save to Supabase
      final id = await ExpenseSupabaseService.addExpense(expense);

      // Update the expense with the returned ID
      final index = _expenses.indexWhere((e) => e == expense);
      if (index != -1) {
        _expenses[index] = expense.copyWith(id: id);
        notifyListeners();
      }
    } catch (e) {
      // Remove from local list if Supabase save failed
      _expenses.remove(expense);
      notifyListeners();
      debugPrint('Failed to add expense: $e');
      rethrow;
    }
  }

  /// Update expense in Supabase
  Future<void> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ExpenseSupabaseService.updateExpense(expense);

      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to update expense: $e');
      rethrow;
    }
  }

  /// Delete expense from Supabase
  Future<void> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ExpenseSupabaseService.deleteExpense(expenseId);

      _expenses.removeWhere((expense) => expense.id == expenseId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to delete expense: $e');
      rethrow;
    }
  }

  /// Load expenses from Supabase
  Future<void> loadExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();

      final expenses = await ExpenseSupabaseService.getRecentExpenses();
      _expenses.clear();
      _expenses.addAll(expenses);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to load expenses: $e');
    }
  }

  /// Load categories from Supabase
  Future<void> loadCategories() async {
    try {
      final categories = await ExpenseSupabaseService.getCategories();
      _categories.clear();
      _categories.addAll(categories);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  /// Search expenses
  Future<void> searchExpenses(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final results = await ExpenseSupabaseService.searchExpenses(query);
      _expenses.clear();
      _expenses.addAll(results);
      notifyListeners();
    } catch (e) {
      debugPrint('Search failed: $e');
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    loadExpenses(); // Reload all expenses
  }

  /// Initialize provider data
  Future<void> initialize() async {
    await Future.wait([
      loadExpenses(),
      loadCategories(),
    ]);
  }
}
