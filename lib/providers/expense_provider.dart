import 'package:flutter/material.dart';
import '../models/expense_models.dart';
import '../models/user_settings.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final List<ExpenseCategory> _customCategories = [];
  final Map<String, double> _categoryBudgets = {};
  String _searchQuery = '';

  // USER SETTINGS - NOW MUTABLE AND BACKEND-INTEGRATED
  int _userId = 0;
  String _userName = '';
  double _monthlyBudget = 25000.0;
  String _currency = '₹';

  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get customCategories => _customCategories;
  int get userId => _userId;
  String get userName => _userName;
  double get monthlyBudget => _monthlyBudget;
  String get currency => _currency;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isInitialized => _isInitialized;

  // Only custom categories (no default categories)
  List<ExpenseCategory> get categories {
    return _customCategories;
  }

  /// Initialize expense provider with user data
  Future<void> initializeWithUser(int userId, String userName, UserSettings userSettings) async {
    _userId = userId;
    _userName = userName;
    _monthlyBudget = userSettings.monthlyBudget;
    _currency = userSettings.currency;
    _categoryBudgets.clear();
    _categoryBudgets.addAll(userSettings.categoryBudgets);
    _customCategories.clear();
    _customCategories.addAll(userSettings.customCategories);
    
    await _loadExpenses();
    _isInitialized = true;
    
    // Schedule periodic notifications
    await _schedulePeriodicNotifications();
    
    notifyListeners();
  }

  /// Clear user data when logging out
  void clearUserData() {
    _userId = 0;
    _userName = '';
    _monthlyBudget = 25000.0;
    _currency = '₹';
    _categoryBudgets.clear();
    _customCategories.clear();
    _expenses.clear();
    _searchQuery = '';
    _isInitialized = false;
    notifyListeners();
  }

  /// Force refresh all calculations and notify listeners
  void _refreshCalculations() {
    // Force recalculation of all computed properties by notifying listeners
    // This ensures all UI components rebuild with fresh data
    notifyListeners();
  }

  /// Force refresh all data from backend
  Future<void> forceRefresh() async {
    if (_userId == 0) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Reload expenses from backend
      await _loadExpenses();
      
      // Reload user settings from backend
      final userSettings = await ExpenseSupabaseService.getUserSettings(userId: _userId);
      _monthlyBudget = userSettings.monthlyBudget;
      _currency = userSettings.currency;
      _categoryBudgets.clear();
      _categoryBudgets.addAll(userSettings.categoryBudgets);
      _customCategories.clear();
      _customCategories.addAll(userSettings.customCategories);
      
      notifyListeners();
    } catch (e) {
      // Failed to force refresh
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty) {
      return _expenses;
    }
    return _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      
      // Search in Title (description)
      final titleMatch = expense.description.toLowerCase().contains(query);
      
      // Search in Payee
      final payeeMatch = expense.payee?.toLowerCase().contains(query) ?? false;
      
      // Search in Amount (convert to string and search)
      final amountMatch = expense.amount.toString().contains(query) ||
                         expense.amount.toStringAsFixed(0).contains(query);
      
      // Search in Notes
      final notesMatch = expense.notes?.toLowerCase().contains(query) ?? false;
      
      // Search in Category (bonus search)
      final categoryMatch = expense.category.toLowerCase().contains(query);
      
      return titleMatch || payeeMatch || amountMatch || notesMatch || categoryMatch;
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
  double get budgetUsed => totalExpense;
  double get budgetRemaining => _monthlyBudget - totalExpense;
  double get budgetUsagePercentage => _monthlyBudget > 0 ? (totalExpense / _monthlyBudget) * 100 : 0;

  // Note: initialize() method removed - use initializeWithUser() instead

  /// Load user settings from Supabase
  Future<void> _loadUserSettings() async {
    try {
      final settings = await ExpenseSupabaseService.getUserSettings(userId: _userId);
      // Note: userName is now managed by UserProvider, not UserSettings
      _monthlyBudget = settings.monthlyBudget;
      _currency = settings.currency;
      _categoryBudgets.clear();
      _categoryBudgets.addAll(settings.categoryBudgets);
      _customCategories.clear();
      _customCategories.addAll(settings.customCategories);
    } catch (e) {
      // Failed to load user settings
    }
  }

  /// Load expenses from Supabase
  Future<void> _loadExpenses() async {
    try {
      final expenses = await ExpenseSupabaseService.getExpenses(userId: _userId);
      _expenses.clear();
      _expenses.addAll(expenses);
    } catch (e) {
      // Failed to load expenses
    }
  }

  /// Reload expenses from backend to ensure data consistency
  Future<void> reloadExpenses() async {
    if (_userId == 0) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final expenses = await ExpenseSupabaseService.getExpenses(userId: _userId);
      _expenses.clear();
      _expenses.addAll(expenses);
      
      notifyListeners();
    } catch (e) {
      // Failed to reload expenses
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if expenses list is consistent with backend
  Future<bool> verifyDataConsistency() async {
    if (_userId == 0 || _expenses.isEmpty) return true;
    
    try {
      final backendExpenses = await ExpenseSupabaseService.getExpenses(userId: _userId);
      
      // Check if local list matches backend count
      if (_expenses.length != backendExpenses.length) {
        return false;
      }
      
      // Check if all local expenses exist in backend
      for (final localExpense in _expenses) {
        final existsInBackend = backendExpenses.any((backendExpense) => 
          backendExpense.id == localExpense.id);
        if (!existsInBackend) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// UPDATE MONTHLY BUDGET - WITH BACKEND SYNC
  Future<void> updateMonthlyBudget(double budget) async {
    try {
      _isLoading = true;
      notifyListeners();
      await ExpenseSupabaseService.updateMonthlyBudget(budget, userId: _userId);
      _monthlyBudget = budget;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UPDATE USER NAME - ONLY UPDATE LOCAL DISPLAY NAME
  /// Note: Database updates are handled by UserProvider
  void updateLocalUserName(String newName) {
    if (newName.isNotEmpty && newName != _userName) {
      _userName = newName;
      notifyListeners();
    }
  }

  /// ADD EXPENSE - WITH BACKEND SYNC
  Future<void> addExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Add expense to backend first
      final expenseId = await ExpenseSupabaseService.addExpense(expense, _userId);
      final expenseWithId = expense.copyWith(id: expenseId);
      
      // Add to local list (insert at beginning for most recent first)
      _expenses.insert(0, expenseWithId);
      
      // Trigger notifications after adding expense
      await _triggerExpenseNotifications(expenseWithId);
      
      // Single notifyListeners call to update UI
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    } finally {
      _isLoading = false;
      // Only notify if we're still mounted and haven't already notified
      if (_isLoading == false) {
        notifyListeners();
      }
    }
  }

  /// UPDATE EXPENSE - WITH BACKEND SYNC
  Future<void> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();
      await ExpenseSupabaseService.updateExpense(expense, _userId);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        // Force refresh all calculations
        _refreshCalculations();
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// DELETE EXPENSE - WITH BACKEND SYNC
  Future<void> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await ExpenseSupabaseService.deleteExpense(expenseId, _userId);
      _expenses.removeWhere((expense) => expense.id == expenseId);
      // Force refresh all calculations
      _refreshCalculations();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// CATEGORY BUDGET METHODS - WITH BACKEND SYNC
  double getCategoryBudget(String categoryName) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => ExpenseCategory(id: '', name: '', icon: '', color: Colors.transparent),
    );

    if (customCategory.id.isNotEmpty) {
      return _categoryBudgets[customCategory.id] ?? 0.0;
    }

    // No default categories - return 0 if not found in custom categories
    return 0.0;
  }

  /// Set budget for any category (default or custom)
  Future<void> setCategoryBudget(String categoryName, double budget) async {
    try {
      String categoryId = '';

      // Find the category ID (only in custom categories)
      final customCategory = _customCategories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => ExpenseCategory(id: '', name: '', icon: '', color: Colors.transparent),
      );

      if (customCategory.id.isNotEmpty) {
        categoryId = customCategory.id;
      }

      if (categoryId.isEmpty) {
        throw Exception('Category not found: $categoryName');
      }

      // Update in Supabase first
      await ExpenseSupabaseService.updateCategoryBudget(categoryId, budget, userId: _userId);

      // Update local state
      _categoryBudgets[categoryId] = budget;

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update category budget: $e');
    }
  }

  double getCustomCategoryBudget(String categoryId) {
    return _categoryBudgets[categoryId] ?? 0.0;
  }

  /// Get custom category expenses by category ID
  double getCustomCategoryExpenses(String categoryId) {
    final category = _customCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => ExpenseCategory(
        id: categoryId,
        name: 'Unknown Category',
        icon: '📦',
        color: Colors.grey,
      ),
    );
    return getCategoryExpenses(category.name);
  }

  Future<void> setCustomCategoryBudget(String categoryId, double budget) async {
    try {
      await ExpenseSupabaseService.updateCategoryBudget(categoryId, budget, userId: _userId);

      // Update local state
      _categoryBudgets[categoryId] = budget;

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update category budget: $e');
    }
  }

  /// CUSTOM CATEGORY METHODS - WITH BACKEND SYNC
  Future<void> addCustomCategory(ExpenseCategory category) async {
    try {
      _customCategories.add(category);
      await ExpenseSupabaseService.saveCustomCategories(_customCategories, userId: _userId);
      notifyListeners();
    } catch (e) {
      _customCategories.removeWhere((cat) => cat.id == category.id);
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> removeCustomCategory(String categoryId) async {
    try {
      _customCategories.removeWhere((cat) => cat.id == categoryId);
      await ExpenseSupabaseService.saveCustomCategories(_customCategories, userId: _userId);
      notifyListeners();
    } catch (e) {
      // Revert local change if backend fails
      if (_customCategories.every((cat) => cat.id != categoryId)) {
        _customCategories.add(ExpenseCategory(
          id: categoryId,
          name: 'Restored Category',
          icon: '📦',
          color: Colors.grey,
        ));
      }
      throw Exception('Failed to remove category: $e');
    }
  }

  /// SEARCH AND FILTER
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// UTILITY METHODS
  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  double getCategoryExpenses(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Trigger notifications after adding expense
  Future<void> _triggerExpenseNotifications(Expense expense) async {
    try {
      // Check if this is the first expense
      if (_expenses.length == 1) {
        await NotificationService.sendFirstExpenseNotification();
      }

      // Check daily budget
      final todayExpenses = _getTodayExpenses();
      final dailySpent = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final dailyBudget = _monthlyBudget / 30; // Approximate daily budget
      await NotificationService.checkDailyBudgetAlert(dailySpent, dailyBudget);

      // Check monthly budget
      final monthlyExpenses = _getMonthlyExpenses();
      final monthlySpent = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
      await NotificationService.checkMonthlyBudgetWarning(monthlySpent, _monthlyBudget);

      // Check category budget
      final categoryBudget = getCategoryBudget(expense.category);
      if (categoryBudget > 0) {
        final categorySpent = getCategoryExpenses(expense.category);
        await NotificationService.checkCategoryBudgetAlert(
          expense.category,
          categorySpent,
          categoryBudget,
        );
      }

      // Check for unusual spending
      // Analyze spending patterns
      await NotificationService.analyzeSpendingPatterns(_expenses);

      // Check budget crisis
      await NotificationService.checkBudgetCrisis(monthlySpent, _monthlyBudget);

    } catch (e) {
      // Failed to trigger notifications
    }
  }

  /// Get today's expenses
  List<Expense> _getTodayExpenses() {
    final today = DateTime.now();
    return _expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.year == today.year &&
             expenseDate.month == today.month &&
             expenseDate.day == today.day;
    }).toList();
  }

  /// Get this month's expenses
  List<Expense> _getMonthlyExpenses() {
    final now = DateTime.now();
    return _expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.year == now.year && expenseDate.month == now.month;
    }).toList();
  }

  /// Get this week's expenses
  List<Expense> _getWeeklyExpenses() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));
    
    return _expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
             expenseDate.isBefore(weekEnd.add(Duration(days: 1)));
    }).toList();
  }


  /// Schedule periodic notifications
  Future<void> _schedulePeriodicNotifications() async {
    try {
      // Schedule weekly expense review
      await NotificationService.scheduleWeeklyExpenseReview();
      
      // Send weekly spending summary if it's the end of the week
      await _sendWeeklySummaryIfNeeded();
      
      // Send monthly summary if it's the end of the month
      await _sendMonthlySummaryIfNeeded();
      
    } catch (e) {
      // Failed to schedule periodic notifications
    }
  }

  /// Send weekly summary if it's the end of the week
  Future<void> _sendWeeklySummaryIfNeeded() async {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) { // End of week
      final weeklyExpenses = _getWeeklyExpenses();
      final weeklyTotal = weeklyExpenses.fold(0.0, (sum, e) => sum + e.amount);
      
      if (weeklyTotal > 0) {
        await NotificationService.sendWeeklySpendingSummary(weeklyTotal);
      }
    }
  }

  /// Send monthly summary if it's the end of the month
  Future<void> _sendMonthlySummaryIfNeeded() async {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    
    if (now.day == lastDayOfMonth) { // End of month
      final monthlyExpenses = _getMonthlyExpenses();
      final monthlyTotal = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
      
      if (monthlyTotal > 0) {
        // Create category breakdown
        final categoryBreakdown = <String, double>{};
        for (final expense in monthlyExpenses) {
          categoryBreakdown[expense.category] = (categoryBreakdown[expense.category] ?? 0) + expense.amount;
        }
        
        await NotificationService.sendMonthlySummary(monthlyTotal, categoryBreakdown);
        await NotificationService.sendCategoryBreakdown(categoryBreakdown, monthlyTotal);
      }
    }
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

  /// REFRESH DATA FROM BACKEND
  Future<void> refresh() async {
    await _loadUserSettings();
    await _loadExpenses();
  }

  /// ANALYTICS HELPERS
  Future<List<Expense>> getExpensesForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      return await ExpenseSupabaseService.getExpensesForPeriod(startDate, endDate, userId: _userId);
    } catch (e) {
      return [];
    }
  }

  Future<List<Expense>> searchExpenses(String query) async {
    try {
      return await ExpenseSupabaseService.searchExpenses(query, userId: _userId);
    } catch (e) {
      return [];
    }
  }

}
