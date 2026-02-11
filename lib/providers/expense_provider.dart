import 'package:flutter/material.dart';
import '../models/expense_models.dart';
import '../models/user_settings.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';
import 'managers/expense_data_manager.dart';
import 'managers/income_data_manager.dart';
import 'managers/budget_manager.dart';
import 'managers/account_manager.dart';
import 'managers/notification_manager.dart';

/// Filter period options for expenses
enum FilterPeriod {
  weekly,
  monthly,
  yearly,
  allTime,
  custom,
}

class ExpenseProvider extends ChangeNotifier {
  // ==================== INTERNAL DELEGATES ====================
  final ExpenseDataManager _expenseManager = ExpenseDataManager();
  final IncomeDataManager _incomeManager = IncomeDataManager();
  final BudgetManager _budgetManager = BudgetManager();
  final AccountManager _accountManager = AccountManager();
  final NotificationManager _notificationManager = NotificationManager();

  final List<ExpenseCategory> _customCategories = [];
  String _searchQuery = '';

  // USER SETTINGS
  int _userId = 0;
  String _userName = '';
  String _currency = '₹';

  bool _isLoading = false;
  bool _isInitialized = false;

  // ==================== GETTERS (PUBLIC API UNCHANGED) ====================
  List<Expense> get expenses => _expenseManager.expenses;
  List<Income> get incomes => _incomeManager.incomes;
  List<ExpenseCategory> get customCategories => _customCategories;
  List<BankAccount> get accounts => _accountManager.accounts;
  int get userId => _userId;
  String get userName => _userName;
  double get monthlyBudget => _budgetManager.monthlyBudget;
  String get currency => _currency;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isInitialized => _isInitialized;
  bool get hasMoreExpenses => _expenseManager.hasMoreExpenses;
  bool get isLoadingMore => _expenseManager.isLoadingMore;

  /// Get the default account
  BankAccount? get defaultAccount => _accountManager.defaultAccount;

  // Only custom categories
  List<ExpenseCategory> get categories => _customCategories;

  // ==================== INITIALIZATION ====================

  /// Initialize expense provider with user data
  /// Uses cache-first strategy for faster startup
  Future<void> initializeWithUser(
      int userId, String userName, UserSettings userSettings) async {
    _userId = userId;
    _userName = userName;
    _currency = userSettings.currency;

    _budgetManager.initialize(
        userSettings.monthlyBudget, userSettings.categoryBudgets);
    _customCategories.clear();
    _customCategories.addAll(userSettings.customCategories);
    _accountManager.initialize(userSettings.accounts);

    // Reset pagination state
    _expenseManager.resetPagination();

    // Try to load from cache first for instant UI
    final hasCachedData = await _expenseManager.loadFromCache(userId);
    if (hasCachedData) {
      _isInitialized = true;
      notifyListeners(); // Show cached data immediately

      // Then sync with server in background
      await _expenseManager.syncWithServer(userId);
      notifyListeners();
    } else {
      // No cache, load from server with pagination
      await _expenseManager.loadExpensesPaginated(userId);
      _isInitialized = true;
      notifyListeners();
    }

    // Cache settings for offline access
    await CacheService.cacheSettings(userSettings);
    await CacheService.saveCurrentUserId(userId);

    // Load incomes from server
    await loadIncomes();

    // Schedule periodic notifications
    await _notificationManager
        .schedulePeriodicNotifications(_expenseManager.expenses);
  }

  /// Clear user data when logging out
  void clearUserData() {
    _userId = 0;
    _userName = '';
    _currency = '₹';
    _budgetManager.clear();
    _customCategories.clear();
    _accountManager.clear();
    _expenseManager.clear();
    _incomeManager.clear();
    _searchQuery = '';
    _isInitialized = false;
    notifyListeners();
  }

  /// Force recalculation notification
  void _refreshCalculations() {
    notifyListeners();
  }

  /// Force refresh all data from backend
  Future<void> forceRefresh() async {
    if (_userId == 0) return;

    try {
      _isLoading = true;
      _expenseManager.resetPagination();
      notifyListeners();

      // Reload expenses from backend
      await _expenseManager.loadExpenses(_userId);

      // Reload incomes from backend
      await loadIncomes();

      // Reload user settings from backend
      final userSettings =
          await ExpenseSupabaseService.getUserSettings(userId: _userId);
      _budgetManager.initialize(
          userSettings.monthlyBudget, userSettings.categoryBudgets);
      _currency = userSettings.currency;
      _customCategories.clear();
      _customCategories.addAll(userSettings.customCategories);
      _accountManager.initialize(userSettings.accounts);

      // Update settings cache
      await CacheService.cacheSettings(userSettings);

      notifyListeners();
    } catch (e) {
      // Failed to force refresh
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SEARCH & FILTERING ====================

  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty) return _expenseManager.expenses;

    return _expenseManager.expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      return expense.description.toLowerCase().contains(query) ||
          (expense.payee?.toLowerCase().contains(query) ?? false) ||
          expense.amount.toString().contains(query) ||
          expense.amount.toStringAsFixed(0).contains(query) ||
          (expense.notes?.toLowerCase().contains(query) ?? false) ||
          expense.category.toLowerCase().contains(query);
    }).toList();
  }

  List<Income> get filteredIncomes {
    if (_searchQuery.isEmpty) return _incomeManager.incomes;

    return _incomeManager.incomes.where((income) {
      final query = _searchQuery.toLowerCase();
      return income.title.toLowerCase().contains(query) ||
          income.source.toLowerCase().contains(query) ||
          income.amount.toString().contains(query) ||
          income.amount.toStringAsFixed(0).contains(query) ||
          (income.notes?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ==================== TOTALS & AGGREGATIONS ====================

  double get totalExpense {
    return _expenseManager.expenses
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalIncome {
    return _incomeManager.incomes
        .fold(0.0, (sum, income) => sum + income.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  Map<String, double> get categoryTotals {
    Map<String, double> totals = {};
    for (var expense in _expenseManager.expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  // Budget-related getters
  bool get isOverBudget =>
      _budgetManager.isOverBudget(currentMonthTotalExpense);
  double get budgetExcess =>
      _budgetManager.budgetExcess(currentMonthTotalExpense);
  double get budgetUsed => currentMonthTotalExpense;
  double get budgetRemaining =>
      _budgetManager.budgetRemaining(currentMonthTotalExpense);
  double get budgetUsagePercentage =>
      _budgetManager.budgetUsagePercentage(currentMonthTotalExpense);

  // ==================== CURRENT MONTH GETTERS ====================

  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    return _expenseManager.expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month;
    }).toList();
  }

  double get currentMonthTotalExpense {
    return currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get currentMonthCategoryTotals {
    Map<String, double> totals = {};
    for (var expense in currentMonthExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<Expense> getCurrentMonthExpensesByCategory(String category) {
    return currentMonthExpenses
        .where((expense) => expense.category == category)
        .toList();
  }

  double getCurrentMonthCategoryExpenses(String category) {
    return currentMonthExpenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // ==================== FILTERED EXPENSES BY PERIOD ====================

  List<Expense> getExpensesByPeriodType(FilterPeriod period,
      {DateTime? customStart, DateTime? customEnd, String? accountId}) {
    final now = DateTime.now();

    List<Expense> baseExpenses = accountId != null
        ? _expenseManager.expenses
            .where((expense) => expense.accountId == accountId)
            .toList()
        : _expenseManager.expenses;

    switch (period) {
      case FilterPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return baseExpenses.where((expense) {
          return expense.date
                  .isAfter(weekStart.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(now.add(const Duration(days: 1)));
        }).toList();

      case FilterPeriod.monthly:
        return baseExpenses.where((expense) {
          return expense.date.year == now.year &&
              expense.date.month == now.month;
        }).toList();

      case FilterPeriod.yearly:
        return baseExpenses.where((expense) {
          return expense.date.year == now.year;
        }).toList();

      case FilterPeriod.allTime:
        return List.from(baseExpenses);

      case FilterPeriod.custom:
        if (customStart == null || customEnd == null) {
          return List.from(baseExpenses);
        }
        return baseExpenses.where((expense) {
          return expense.date
                  .isAfter(customStart.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(customEnd.add(const Duration(days: 1)));
        }).toList();
    }
  }

  double getTotalByPeriod(FilterPeriod period,
      {DateTime? customStart, DateTime? customEnd, String? accountId}) {
    return getExpensesByPeriodType(period,
            customStart: customStart,
            customEnd: customEnd,
            accountId: accountId)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getCategoryTotalsByPeriod(FilterPeriod period,
      {DateTime? customStart, DateTime? customEnd, String? accountId}) {
    final expenses = getExpensesByPeriodType(period,
        customStart: customStart,
        customEnd: customEnd,
        accountId: accountId);
    Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<Expense> getExpensesByCategoryAndPeriod(
      String category, FilterPeriod period,
      {DateTime? customStart, DateTime? customEnd, String? accountId}) {
    return getExpensesByPeriodType(period,
            customStart: customStart,
            customEnd: customEnd,
            accountId: accountId)
        .where((expense) => expense.category == category)
        .toList();
  }

  // ==================== EXPENSE CRUD ====================

  Future<void> addExpense(Expense expense) async {
    try {
      await _expenseManager.addExpense(expense, _userId);

      // Trigger notifications
      await _notificationManager.triggerExpenseNotifications(
        expense: expense,
        allExpenses: _expenseManager.expenses,
        monthlyBudget: _budgetManager.monthlyBudget,
        categoryBudget: getCategoryBudget(expense.category),
        categorySpent: getCategoryExpenses(expense.category),
        isFirstExpense: _expenseManager.expenses.length == 1,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _expenseManager.updateExpense(expense, _userId);
      _refreshCalculations();
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _expenseManager.deleteExpense(expenseId, _userId);
      _refreshCalculations();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more expenses (infinite scroll)
  Future<void> loadMoreExpenses() async {
    final changed = await _expenseManager.loadMoreExpenses(_userId);
    if (changed) notifyListeners();
  }

  /// Reload expenses from backend
  Future<void> reloadExpenses() async {
    if (_userId == 0) return;

    try {
      _isLoading = true;
      _expenseManager.resetPagination();
      notifyListeners();

      await _expenseManager.reloadExpenses(_userId);
      await loadIncomes();

      notifyListeners();
    } catch (e) {
      // Failed to reload - keep existing data
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check data consistency
  Future<bool> verifyDataConsistency() async {
    return _expenseManager.verifyDataConsistency(_userId);
  }

  // ==================== INCOME CRUD ====================

  Future<void> addIncome(Income income) async {
    try {
      await _incomeManager.addIncome(income, _userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add income: $e');
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _incomeManager.updateIncome(income, _userId);
      _refreshCalculations();
    } catch (e) {
      throw Exception('Failed to update income: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteIncome(String incomeId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _incomeManager.deleteIncome(incomeId, _userId);
      _refreshCalculations();
    } catch (e) {
      throw Exception('Failed to delete income: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return _incomeManager.incomes
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  double getTotalIncomeForAccount(String accountId) {
    return _incomeManager.incomes
        .where((i) => i.accountId == accountId)
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  List<Income> getIncomesByPeriod(FilterPeriod period,
      {DateTime? customStart, DateTime? customEnd, String? accountId}) {
    final now = DateTime.now();
    List<Income> filtered = accountId != null
        ? _incomeManager.incomes
            .where((i) => i.accountId == accountId)
            .toList()
        : _incomeManager.incomes;

    switch (period) {
      case FilterPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return filtered
            .where((i) => i.date
                .isAfter(weekStart.subtract(const Duration(days: 1))))
            .toList();
      case FilterPeriod.monthly:
        return filtered
            .where(
                (i) => i.date.year == now.year && i.date.month == now.month)
            .toList();
      case FilterPeriod.yearly:
        return filtered.where((i) => i.date.year == now.year).toList();
      case FilterPeriod.allTime:
        return filtered;
      case FilterPeriod.custom:
        if (customStart != null && customEnd != null) {
          return filtered
              .where((i) =>
                  i.date.isAfter(
                      customStart.subtract(const Duration(days: 1))) &&
                  i.date
                      .isBefore(customEnd.add(const Duration(days: 1))))
              .toList();
        }
        return filtered;
    }
  }

  Future<void> loadIncomes() async {
    await _incomeManager.loadIncomes(_userId);
    notifyListeners();
  }

  // ==================== BUDGET METHODS ====================

  Future<void> updateMonthlyBudget(double budget) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _budgetManager.updateMonthlyBudget(budget, _userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getCategoryBudget(String categoryName) {
    return _budgetManager.getCategoryBudget(categoryName, _customCategories);
  }

  Future<void> setCategoryBudget(String categoryName, double budget) async {
    try {
      await _budgetManager.setCategoryBudget(
          categoryName, budget, _customCategories, _userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update category budget: $e');
    }
  }

  double getCustomCategoryBudget(String categoryId) {
    return _budgetManager.getCustomCategoryBudget(categoryId);
  }

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

  Future<void> setCustomCategoryBudget(
      String categoryId, double budget) async {
    try {
      await _budgetManager.setCustomCategoryBudget(
          categoryId, budget, _userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update category budget: $e');
    }
  }

  bool isCategoryOverBudget(String category) {
    return _budgetManager.isCategoryOverBudget(
        category, getCurrentMonthCategoryExpenses(category), _customCategories);
  }

  double getCategoryBudgetExcess(String category) {
    return _budgetManager.getCategoryBudgetExcess(
        category, getCurrentMonthCategoryExpenses(category), _customCategories);
  }

  // ==================== CATEGORY METHODS ====================

  Future<void> addCustomCategory(ExpenseCategory category) async {
    try {
      _customCategories.add(category);
      await ExpenseSupabaseService.saveCustomCategories(_customCategories,
          userId: _userId);
      notifyListeners();
    } catch (e) {
      _customCategories.removeWhere((cat) => cat.id == category.id);
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> removeCustomCategory(String categoryId) async {
    try {
      _customCategories.removeWhere((cat) => cat.id == categoryId);
      await ExpenseSupabaseService.saveCustomCategories(_customCategories,
          userId: _userId);
      notifyListeners();
    } catch (e) {
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

  // ==================== ACCOUNT METHODS ====================

  BankAccount? getAccountById(String accountId) =>
      _accountManager.getAccountById(accountId);

  String getAccountName(String? accountId) =>
      _accountManager.getAccountName(accountId);

  Future<void> addAccount(BankAccount account) async {
    try {
      await _accountManager.addAccount(account, _userId);
      notifyListeners();
    } catch (e) {
      _accountManager.accounts.removeWhere((acc) => acc.id == account.id);
      throw Exception('Failed to add account: $e');
    }
  }

  Future<void> removeAccount(String accountId) async {
    try {
      await _accountManager.removeAccount(accountId, _userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to remove account: $e');
    }
  }

  Future<void> setDefaultAccount(String accountId) async {
    try {
      await _accountManager.setDefaultAccount(accountId, _userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to set default account: $e');
    }
  }

  // ==================== USER SETTINGS ====================

  void updateLocalUserName(String newName) {
    if (newName.isNotEmpty && newName != _userName) {
      _userName = newName;
      notifyListeners();
    }
  }

  // ==================== UTILITY METHODS ====================

  List<Expense> getExpensesByCategory(String category) {
    return _expenseManager.expenses
        .where((expense) => expense.category == category)
        .toList();
  }

  double getCategoryExpenses(String category) {
    return currentMonthExpenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Load user settings from Supabase
  Future<void> _loadUserSettings() async {
    try {
      final settings =
          await ExpenseSupabaseService.getUserSettings(userId: _userId);
      _budgetManager.initialize(
          settings.monthlyBudget, settings.categoryBudgets);
      _currency = settings.currency;
      _customCategories.clear();
      _customCategories.addAll(settings.customCategories);
    } catch (e) {
      // Failed to load user settings
    }
  }

  Future<void> refresh() async {
    await _loadUserSettings();
    await _expenseManager.loadExpenses(_userId);
  }

  // ==================== ANALYTICS HELPERS ====================

  Future<List<Expense>> getExpensesForPeriod(
      DateTime startDate, DateTime endDate) async {
    return _expenseManager.getExpensesForPeriod(startDate, endDate, _userId);
  }

  Future<List<Expense>> searchExpenses(String query) async {
    return _expenseManager.searchExpenses(query, _userId);
  }
}
