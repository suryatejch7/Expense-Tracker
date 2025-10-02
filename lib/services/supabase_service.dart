import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_models.dart';

/// Service for managing expenses in Supabase
class ExpenseSupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new expense to Supabase
  static Future<String> addExpense(Expense expense) async {
    try {
      final response = await _supabase
          .from('expenses')
          .insert(expense.toSupabase())
          .select()
          .single();

      return response['id'].toString();
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Update an existing expense
  static Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) throw Exception('Expense ID is required for update');

    try {
      await _supabase
          .from('expenses')
          .update(expense.toSupabase())
          .eq('id', expense.id!);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  static Future<void> deleteExpense(String expenseId) async {
    try {
      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Get all expenses with optional filtering
  static Future<List<Expense>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _supabase.from('expenses').select();

      // Apply filters
      if (category != null) {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final orderedQuery = query.order('date', ascending: false);

      final finalQuery = limit != null ? orderedQuery.limit(limit) : orderedQuery;

      final data = await finalQuery;
      return (data as List).map((json) => Expense.fromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  /// Get expenses for current month
  static Future<List<Expense>> getCurrentMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getExpenses(startDate: startOfMonth, endDate: endOfMonth);
  }

  /// Get recent expenses (last 30 days)
  static Future<List<Expense>> getRecentExpenses({int limit = 50}) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return getExpenses(startDate: thirtyDaysAgo, limit: limit);
  }

  /// Search expenses by description or payee
  static Future<List<Expense>> searchExpenses(String searchTerm) async {
    try {
      final List<dynamic> data = await _supabase
          .from('expenses')
          .select()
          .or('description.ilike.%$searchTerm%,payee.ilike.%$searchTerm%')
          .order('date', ascending: false);

      return data.map((json) => Expense.fromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to search expenses: $e');
    }
  }

  /// Get analytics data for a date range
  static Future<ExpenseAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final expenses = await getExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate totals
      double totalExpenses = 0;
      Map<String, double> categoryTotals = {};
      Map<String, int> categoryCount = {};

      for (final expense in expenses) {
        totalExpenses += expense.amount;

        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;

        categoryCount[expense.category] =
            (categoryCount[expense.category] ?? 0) + 1;
      }

      // Calculate monthly average
      final monthsDiff = _getMonthsDifference(
        startDate ?? DateTime.now().subtract(const Duration(days: 365)),
        endDate ?? DateTime.now(),
      );
      final monthlyAverage = monthsDiff > 0 ? (totalExpenses / monthsDiff).toDouble() : 0.0;

      // Get recent transactions
      final recentTransactions = expenses.take(10).toList();

      return ExpenseAnalytics(
        totalExpenses: totalExpenses,
        monthlyAverage: monthlyAverage,
        categoryTotals: categoryTotals,
        categoryCount: categoryCount,
        recentTransactions: recentTransactions,
        periodStart: startDate ?? DateTime.now().subtract(const Duration(days: 365)),
        periodEnd: endDate ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  /// Get monthly expense totals for the last 12 months using SQL
  static Future<Map<String, double>> getMonthlyTotals() async {
    try {
      final List<dynamic> data = await _supabase.rpc('get_monthly_totals');

      Map<String, double> monthlyTotals = {};
      for (final row in data) {
        monthlyTotals[row['month']] = row['total'].toDouble();
      }

      return monthlyTotals;
    } catch (e) {
      // Fallback to client-side calculation
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

      final expenses = await getExpenses(startDate: twelveMonthsAgo);

      Map<String, double> monthlyTotals = {};

      for (final expense in expenses) {
        final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + expense.amount;
      }

      return monthlyTotals;
    }
  }

  /// Initialize default categories if none exist
  static Future<void> initializeDefaultCategories() async {
    try {
      final existingCategories = await getCategories();
      if (existingCategories.isNotEmpty) return;

      final defaultCategories = [
        ExpenseCategory(
          id: '',
          name: 'Food & Dining',
          icon: '🍽️',
          colorHex: '#FF6B6B',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Transportation',
          icon: '🚗',
          colorHex: '#4ECDC4',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Shopping',
          icon: '🛒',
          colorHex: '#45B7D1',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Entertainment',
          icon: '🎬',
          colorHex: '#96CEB4',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Bills & Utilities',
          icon: '💡',
          colorHex: '#FECA57',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Healthcare',
          icon: '🏥',
          colorHex: '#FF9FF3',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Education',
          icon: '📚',
          colorHex: '#54A0FF',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExpenseCategory(
          id: '',
          name: 'Other',
          icon: '📦',
          colorHex: '#747D8C',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      for (final category in defaultCategories) {
        await addCategory(category);
      }
    } catch (e) {
      throw Exception('Failed to initialize categories: $e');
    }
  }

  /// Add a new category
  static Future<String> addCategory(ExpenseCategory category) async {
    try {
      final response = await _supabase
          .from('categories')
          .insert(category.toSupabase())
          .select()
          .single();

      return response['id'].toString();
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  /// Get all categories
  static Future<List<ExpenseCategory>> getCategories() async {
    try {
      final List<dynamic> data = await _supabase
          .from('categories')
          .select()
          .order('name');

      return data.map((json) => ExpenseCategory.fromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Stream of expenses for real-time updates
  static Stream<List<Expense>> getExpensesStream({
    String? category,
    int? limit,
  }) {
    var query = _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.map((data) {
      var expenses = data.map((json) => Expense.fromSupabase(json)).toList();

      if (category != null) {
        expenses = expenses.where((expense) => expense.category == category).toList();
      }

      return expenses;
    });
  }

  /// Helper method to calculate months difference
  static int _getMonthsDifference(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }
}
