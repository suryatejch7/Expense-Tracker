import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_models.dart';
import '../services/supabase_service.dart';
import 'user_provider.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final List<ExpenseCategory> _customCategories = [];
  final Map<String, double> _categoryBudgets = {};
  String _searchQuery = '';

  // USER SETTINGS - NOW MUTABLE AND BACKEND-INTEGRATED
  String _userName = '';
  double _monthlyBudget = 25000.0;
  String _currency = '₹';

  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get customCategories => _customCategories;
  String get userName => _userName;
  double get monthlyBudget => _monthlyBudget;
  String get currency => _currency;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isInitialized => _isInitialized;

  // All categories (default + custom)
  List<ExpenseCategory> get categories {
    final defaultCategories = ExpenseCategory.getDefaultCategories();
    return [...defaultCategories, ..._customCategories];
  }

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
  double get budgetUsed => totalExpense;
  double get budgetRemaining => _monthlyBudget - totalExpense;
  double get budgetUsagePercentage => _monthlyBudget > 0 ? (totalExpense / _monthlyBudget) * 100 : 0;

  /// INITIALIZE PROVIDER - LOAD ALL DATA FROM BACKEND
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load user settings from Supabase
      await _loadUserSettings();

      // Load expenses from Supabase
      await _loadExpenses();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize ExpenseProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user settings from Supabase
  Future<void> _loadUserSettings() async {
    try {
      final userId = _userName;
      final settings = await ExpenseSupabaseService.getUserSettings(userId: userId);

      _userName = settings.userName;
      _monthlyBudget = settings.monthlyBudget;
      _currency = settings.currency;
      _categoryBudgets.clear();
      _categoryBudgets.addAll(settings.categoryBudgets);
      _customCategories.clear();
      _customCategories.addAll(settings.customCategories);

      debugPrint('✅ Loaded user settings: $_userName, Budget: ₹$_monthlyBudget');
    } catch (e) {
      debugPrint('❌ Failed to load user settings: $e');
    }
  }

  /// Load expenses from Supabase
  Future<void> _loadExpenses() async {
    try {
      final userId = _userName;
      final expenses = await ExpenseSupabaseService.getExpenses(userId: userId);
      _expenses.clear();
      _expenses.addAll(expenses);

      debugPrint('✅ Loaded ${expenses.length} expenses from Supabase');
    } catch (e) {
      debugPrint('❌ Failed to load expenses: $e');
    }
  }

  /// UPDATE MONTHLY BUDGET - WITH BACKEND SYNC
  Future<void> updateMonthlyBudget(double budget) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userId = _userName;
      await ExpenseSupabaseService.updateMonthlyBudget(budget, userId: userId);

      // Update local state only after successful backend update
      _monthlyBudget = budget;

      debugPrint('✅ Monthly budget updated to ₹$budget');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to update monthly budget: $e');
      throw Exception('Failed to update budget: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UPDATE USER NAME - WITH BACKEND MIGRATION
  Future<void> updateUserName(String newName, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final oldName = userProvider.userId;
    if (newName != oldName && newName.isNotEmpty) {
      // Migrate all data in Supabase
      await ExpenseSupabaseService.migrateUserId(oldName, newName);
      await userProvider.setUserId(newName);
      _userName = newName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', newName);
      notifyListeners();
      // Optionally, reload data for the new user
      await refresh();
    }
  }

  /// ADD EXPENSE - WITH BACKEND SYNC
  Future<void> addExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userId = _userName;
      final expenseId = await ExpenseSupabaseService.addExpense(expense, userId);

      // Add to local state with the returned ID
      final expenseWithId = expense.copyWith(id: expenseId);
      _expenses.insert(0, expenseWithId);

      debugPrint('✅ Added expense: ${expense.description} - ₹${expense.amount}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to add expense: $e');
      throw Exception('Failed to add expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UPDATE EXPENSE - WITH BACKEND SYNC
  Future<void> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userId = _userName;
      await ExpenseSupabaseService.updateExpense(expense, userId);

      // Update local state
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }

      debugPrint('✅ Updated expense: ${expense.description}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to update expense: $e');
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
      final userId = _userName;
      await ExpenseSupabaseService.deleteExpense(expenseId, userId);

      // Remove from local state
      _expenses.removeWhere((expense) => expense.id == expenseId);

      debugPrint('✅ Deleted expense: $expenseId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to delete expense: $e');
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

    // Then check default categories
    final defaultCategory = ExpenseCategory.getDefaultCategories()
        .firstWhere(
          (cat) => cat.name == categoryName,
          orElse: () => ExpenseCategory(id: '', name: '', icon: '', color: Colors.transparent),
        );

    if (defaultCategory.id.isNotEmpty) {
      return _categoryBudgets[defaultCategory.id] ?? 0.0;
    }

    return 0.0;
  }

  /// Set budget for any category (default or custom)
  Future<void> setCategoryBudget(String categoryName, double budget) async {
    try {
      String categoryId = '';

      // Find the category ID
      final customCategory = _customCategories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => ExpenseCategory(id: '', name: '', icon: '', color: Colors.transparent),
      );

      if (customCategory.id.isNotEmpty) {
        categoryId = customCategory.id;
      } else {
        final defaultCategory = ExpenseCategory.getDefaultCategories()
            .firstWhere(
              (cat) => cat.name == categoryName,
              orElse: () => ExpenseCategory(id: '', name: '', icon: '', color: Colors.transparent),
            );
        categoryId = defaultCategory.id;
      }

      if (categoryId.isEmpty) {
        throw Exception('Category not found: $categoryName');
      }

      final userId = _userName;
      // Update in Supabase first
      await ExpenseSupabaseService.updateCategoryBudget(categoryId, budget, userId: userId);

      // Update local state
      _categoryBudgets[categoryId] = budget;

      debugPrint('✅ Updated category budget: $categoryName = ₹$budget');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to update category budget: $e');
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
      final userId = _userName;
      // Update in Supabase first
      await ExpenseSupabaseService.updateCategoryBudget(categoryId, budget, userId: userId);

      // Update local state
      _categoryBudgets[categoryId] = budget;

      debugPrint('✅ Updated category budget: $categoryId = ₹$budget');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to update category budget: $e');
      throw Exception('Failed to update category budget: $e');
    }
  }

  /// CUSTOM CATEGORY METHODS - WITH BACKEND SYNC
  Future<void> addCustomCategory(ExpenseCategory category) async {
    try {
      _customCategories.add(category);
      final userId = _userName;
      await ExpenseSupabaseService.saveCustomCategories(_customCategories, userId: userId);

      debugPrint('✅ Added custom category: ${category.name}');
      notifyListeners();
    } catch (e) {
      // Revert local change if backend fails
      _customCategories.removeWhere((cat) => cat.id == category.id);
      debugPrint('❌ Failed to add custom category: $e');
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> removeCustomCategory(String categoryId) async {
    try {
      _customCategories.removeWhere((cat) => cat.id == categoryId);
      final userId = _userName;
      await ExpenseSupabaseService.saveCustomCategories(_customCategories, userId: userId);

      debugPrint('✅ Removed custom category: $categoryId');
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
      debugPrint('❌ Failed to remove custom category: $e');
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
      return await ExpenseSupabaseService.getExpensesForPeriod(startDate, endDate);
    } catch (e) {
      debugPrint('❌ Failed to get expenses for period: $e');
      return [];
    }
  }

  Future<List<Expense>> searchExpenses(String query) async {
    try {
      return await ExpenseSupabaseService.searchExpenses(query);
    } catch (e) {
      debugPrint('❌ Failed to search expenses: $e');
      return [];
    }
  }

  void initializeWithUser(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _userName = userProvider.userId;
    // Load other user-specific settings if needed
    notifyListeners();
  }
}
