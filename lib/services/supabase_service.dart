import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_models.dart';
import '../models/user_settings.dart';

/// Service for managing expenses and user settings in Supabase
class ExpenseSupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new expense to Supabase
  static Future<String> addExpense(Expense expense, String userId) async {
    try {
      final data = expense.toSupabase();
      data['user_id'] = userId;
      final response = await _supabase
          .from('expenses')
          .insert(data)
          .select()
          .single();
      return response['id'].toString();
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Update an existing expense
  static Future<void> updateExpense(Expense expense, String userId) async {
    if (expense.id == null) throw Exception('Expense ID is required for update');
    try {
      final data = expense.toSupabase();
      data['user_id'] = userId;
      await _supabase
          .from('expenses')
          .update(data)
          .eq('id', expense.id!)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  static Future<void> deleteExpense(String expenseId, String userId) async {
    try {
      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Get all expenses for a user
  static Future<List<Expense>> getExpenses({
    required String userId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('expenses').select().eq('user_id', userId);
      if (category != null) {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      final response = await query.order('date', ascending: false);
      return (response as List)
          .map((item) => Expense.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  /// Get user settings from Supabase
  static Future<UserSettings> getUserSettings({required String userId}) async {
    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) {
        final defaultSettings = UserSettings(
          userId: userId,
          userName: 'User',
          monthlyBudget: 25000.0,
          currency: '₹',
          categoryBudgets: {},
          customCategories: [],
        );
        await saveUserSettings(defaultSettings, userId: userId);
        return defaultSettings;
      }
      return UserSettings.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch user settings: $e');
    }
  }

  /// Save user settings to Supabase
  static Future<void> saveUserSettings(UserSettings settings, {required String userId}) async {
    try {
      final data = settings.toSupabase();
      data['user_id'] = userId;
      await _supabase
          .from('user_settings')
          .upsert(data, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to save user settings: $e');
    }
  }

  /// Update monthly budget
  static Future<void> updateMonthlyBudget(double budget, {required String userId}) async {
    try {
      await _supabase
          .from('user_settings')
          .upsert({
            'user_id': userId,
            'monthly_budget': budget,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to update monthly budget: $e');
    }
  }

  /// Update user name
  static Future<void> updateUserName(String name, {required String userId}) async {
    try {
      await _supabase
          .from('user_settings')
          .upsert({
            'user_id': userId,
            'user_name': name,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to update user name: $e');
    }
  }

  /// Update category budget
  static Future<void> updateCategoryBudget(String categoryId, double budget, {required String userId}) async {
    try {
      final settings = await getUserSettings(userId: userId);
      settings.categoryBudgets[categoryId] = budget;
      await _supabase
          .from('user_settings')
          .upsert({
            'user_id': userId,
            'category_budgets': settings.categoryBudgets,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to update category budget: $e');
    }
  }

  /// Save custom categories
  static Future<void> saveCustomCategories(List<ExpenseCategory> categories, {required String userId}) async {
    try {
      final categoriesData = categories.map((cat) => cat.toSupabase()).toList();
      await _supabase
          .from('user_settings')
          .upsert({
            'user_id': userId,
            'custom_categories': categoriesData,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to save custom categories: $e');
    }
  }

  /// Get expenses for analytics
  static Future<List<Expense>> getExpensesForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((item) => Expense.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses for period: $e');
    }
  }

  /// Search expenses
  static Future<List<Expense>> searchExpenses(String query) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .or('description.ilike.%$query%,payee.ilike.%$query%,category.ilike.%$query%')
          .order('date', ascending: false);

      return (response as List)
          .map((item) => Expense.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search expenses: $e');
    }
  }

  /// Check if a userId is already taken in Supabase
  static Future<bool> isUserIdTaken(String userId) async {
    final response = await _supabase
        .from('user_settings')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return response != null;
  }

  /// Migrate all user data from oldUserId to newUserId in Supabase
  static Future<void> migrateUserId(String oldUserId, String newUserId) async {
    // Update all expenses
    await _supabase
      .from('expenses')
      .update({'user_id': newUserId})
      .eq('user_id', oldUserId);
    // Update user_settings
    await _supabase
      .from('user_settings')
      .update({'user_id': newUserId, 'user_name': newUserId})
      .eq('user_id', oldUserId);
  }
}
