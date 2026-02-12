import '../../models/expense_models.dart';
import '../../services/supabase_service.dart';
import '../../services/cache_service.dart';

class ExpenseDataManager {
  final List<Expense> _expenses = [];
  static const int pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreExpenses = true;
  bool _isLoadingMore = false;

  List<Expense> get expenses => _expenses;
  bool get hasMoreExpenses => _hasMoreExpenses;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> syncWithServer(int userId) async {
    try {
      final serverExpenses = await ExpenseSupabaseService.getExpenses(
        userId: userId,
      );
      final serverIds = serverExpenses.map((e) => e.id).toSet();
      final newLocalExpenses = _expenses
          .where((e) => !serverIds.contains(e.id))
          .toList();

      final List<Expense> mergedExpenses = [];
      mergedExpenses.addAll(newLocalExpenses);
      for (var serverExpense in serverExpenses) {
        if (!newLocalExpenses.any((e) => e.id == serverExpense.id)) {
          mergedExpenses.add(serverExpense);
        }
      }

      mergedExpenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _expenses.clear();
      _expenses.addAll(mergedExpenses);
      await CacheService.cacheExpenses(_expenses, userId);
    } catch (e) {
    }
  }

  Future<void> loadExpenses(int userId) async {
    try {
      final expenses = await ExpenseSupabaseService.getExpenses(userId: userId);
      if (expenses.isNotEmpty || _expenses.isEmpty) {
        _expenses.clear();
        _expenses.addAll(expenses);
      }
      await CacheService.cacheExpenses(expenses, userId);
    } catch (e) {
      if (_expenses.isEmpty) {
        final cached = await CacheService.getCachedExpenses(userId);
        if (cached != null && cached.isNotEmpty) {
          _expenses.clear();
          _expenses.addAll(cached);
        }
      }
    }
  }

  Future<void> loadExpensesPaginated(int userId) async {
    try {
      _currentPage = 0;
      final expenses = await ExpenseSupabaseService.getExpensesPaginated(
        userId: userId,
        limit: pageSize,
        offset: 0,
      );
      if (expenses.isNotEmpty || _expenses.isEmpty) {
        _expenses.clear();
        _expenses.addAll(expenses);
      }
      _hasMoreExpenses = expenses.length >= pageSize;
      await CacheService.cacheExpenses(expenses, userId);
    } catch (e) {
      if (_expenses.isEmpty) {
        final cached = await CacheService.getCachedExpenses(userId);
        if (cached != null && cached.isNotEmpty) {
          _expenses.clear();
          _expenses.addAll(cached);
          _hasMoreExpenses = false;
        }
      }
    }
  }

  Future<bool> loadMoreExpenses(int userId) async {
    if (!_hasMoreExpenses || _isLoadingMore || userId == 0) return false;

    try {
      _isLoadingMore = true;

      _currentPage++;
      final newExpenses = await ExpenseSupabaseService.getExpensesPaginated(
        userId: userId,
        limit: pageSize,
        offset: _currentPage * pageSize,
      );

      if (newExpenses.isEmpty) {
        _hasMoreExpenses = false;
      } else {
        for (final expense in newExpenses) {
          if (!_expenses.any((e) => e.id == expense.id)) {
            _expenses.add(expense);
          }
        }
        _hasMoreExpenses = newExpenses.length >= pageSize;
        await CacheService.cacheExpenses(_expenses, userId);
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Reload expenses from backend
  Future<void> reloadExpenses(int userId) async {
    _currentPage = 0;
    _hasMoreExpenses = true;

    final expenses = await ExpenseSupabaseService.getExpenses(userId: userId);
    final sortedExpenses = List<Expense>.from(expenses);
    sortedExpenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sortedExpenses.isNotEmpty || _expenses.isEmpty) {
      _expenses.clear();
      _expenses.addAll(sortedExpenses);
    }
    await CacheService.cacheExpenses(sortedExpenses, userId);
  }

  /// Add expense to backend and local list
  Future<void> addExpense(Expense expense, int userId) async {
    final expenseId = await ExpenseSupabaseService.addExpense(expense, userId);
    final expenseWithId = expense.copyWith(id: expenseId);

    final existingIndex = _expenses.indexWhere((e) => e.id == expenseId);
    if (existingIndex == -1) {
      _expenses.insert(0, expenseWithId);
    }
    await CacheService.addExpenseToCache(expenseWithId, userId);
  }

  /// Get the last added expense (for notification triggers)
  Expense? get lastAddedExpense =>
      _expenses.isNotEmpty ? _expenses.first : null;

  /// Update expense in backend and local list
  Future<void> updateExpense(Expense expense, int userId) async {
    await ExpenseSupabaseService.updateExpense(expense, userId);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      await CacheService.updateExpenseInCache(expense, userId);
    }
  }

  /// Delete expense from backend and local list
  Future<void> deleteExpense(String expenseId, int userId) async {
    await ExpenseSupabaseService.deleteExpense(expenseId, userId);
    _expenses.removeWhere((expense) => expense.id == expenseId);
    await CacheService.removeExpenseFromCache(expenseId, userId);
  }

  /// Load from cache for instant UI
  Future<bool> loadFromCache(int userId) async {
    final cachedExpenses = await CacheService.getCachedExpenses(userId);
    if (cachedExpenses != null && cachedExpenses.isNotEmpty) {
      _expenses.clear();
      _expenses.addAll(cachedExpenses);
      return true;
    }
    return false;
  }

  /// Verify data consistency with backend
  Future<bool> verifyDataConsistency(int userId) async {
    if (userId == 0 || _expenses.isEmpty) return true;

    try {
      final backendExpenses = await ExpenseSupabaseService.getExpenses(
        userId: userId,
      );
      if (_expenses.length != backendExpenses.length) return false;

      for (final localExpense in _expenses) {
        final existsInBackend = backendExpenses.any(
          (be) => be.id == localExpense.id,
        );
        if (!existsInBackend) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search expenses via backend
  Future<List<Expense>> searchExpenses(String query, int userId) async {
    try {
      return await ExpenseSupabaseService.searchExpenses(query, userId: userId);
    } catch (e) {
      return [];
    }
  }

  /// Get expenses for a specific date range via backend
  Future<List<Expense>> getExpensesForPeriod(
    DateTime startDate,
    DateTime endDate,
    int userId,
  ) async {
    try {
      return await ExpenseSupabaseService.getExpensesForPeriod(
        startDate,
        endDate,
        userId: userId,
      );
    } catch (e) {
      return [];
    }
  }

  /// Reset pagination state
  void resetPagination() {
    _currentPage = 0;
    _hasMoreExpenses = true;
    _isLoadingMore = false;
  }

  /// Clear all data
  void clear() {
    _expenses.clear();
    resetPagination();
  }
}
