import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_models.dart';
import '../models/user_settings.dart' as models;

/// Service for managing expenses and user settings in Supabase
class ExpenseSupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== USER MANAGEMENT ====================

  /// Create a new user
  static Future<models.User> createUser(String userName) async {
    try {
      final response = await _supabase
          .from('users')
          .insert({
            'user_name': userName,
          })
          .select()
          .single();
      return models.User.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get user by ID
  static Future<models.User?> getUserById(int userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null ? models.User.fromSupabase(response) : null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Get user by username
  static Future<models.User?> getUserByUsername(String userName) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_name', userName)
          .maybeSingle();
      return response != null ? models.User.fromSupabase(response) : null;
    } catch (e) {
      throw Exception('Failed to get user by username: $e');
    }
  }

  /// Check if username exists
  static Future<bool> isUsernameTaken(String userName) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('user_name', userName)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get all users
  static Future<List<models.User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => models.User.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // ==================== USER SETTINGS ====================

  /// Create default user settings for a new user
  static Future<models.UserSettings> createDefaultUserSettings(int userId) async {
    try {
      final now = DateTime.now();
      final defaultSettings = models.UserSettings(
        userId: userId,
        monthlyBudget: 25000.0,
        currency: '₹',
        categoryBudgets: {},
        customCategories: [],
        createdAt: now,
        updatedAt: now,
      );

      await _supabase
          .from('user_settings')
          .insert(defaultSettings.toSupabase());

      return defaultSettings;
    } catch (e) {
      throw Exception('Failed to create default user settings: $e');
    }
  }

  /// Get user settings from Supabase
  static Future<models.UserSettings> getUserSettings({required int userId}) async {
    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) {
        // Create default settings if none exist
        return await createDefaultUserSettings(userId);
      }
      
      return models.UserSettings.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch user settings: $e');
    }
  }

  /// Save user settings to Supabase
  static Future<void> saveUserSettings(models.UserSettings settings) async {
    try {
      await _supabase
          .from('user_settings')
          .upsert(settings.toSupabase(), onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to save user settings: $e');
    }
  }

  /// Update user name
  static Future<void> updateUserName(String userName, {required int userId}) async {
    try {
      await _supabase
          .from('users')
          .update({
            'user_name': userName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user name: $e');
    }
  }

  /// Update monthly budget
  static Future<void> updateMonthlyBudget(double budget, {required int userId}) async {
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

  /// Update category budget
  static Future<void> updateCategoryBudget(String categoryId, double budget, {required int userId}) async {
    try {
      final settings = await getUserSettings(userId: userId);
      settings.categoryBudgets[categoryId] = budget;
      await saveUserSettings(settings);
    } catch (e) {
      throw Exception('Failed to update category budget: $e');
    }
  }

  /// Save custom categories
  static Future<void> saveCustomCategories(List<ExpenseCategory> categories, {required int userId}) async {
    try {
      final settings = await getUserSettings(userId: userId);
      final updatedSettings = settings.copyWith(
        customCategories: categories,
        updatedAt: DateTime.now(),
      );
      await saveUserSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to save custom categories: $e');
    }
  }

  /// Save bank accounts
  static Future<void> saveAccounts(List<BankAccount> accounts, {required int userId}) async {
    try {
      final settings = await getUserSettings(userId: userId);
      final updatedSettings = settings.copyWith(
        accounts: accounts,
        updatedAt: DateTime.now(),
      );
      await saveUserSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to save accounts: $e');
    }
  }

  // ==================== EXPENSE MANAGEMENT ====================

  /// Add a new expense to Supabase
  static Future<String> addExpense(Expense expense, int userId) async {
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
  static Future<void> updateExpense(Expense expense, int userId) async {
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
  static Future<void> deleteExpense(String expenseId, int userId) async {
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
    required int userId,
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

  /// Get expenses for analytics
  static Future<List<Expense>> getExpensesForPeriod(DateTime startDate, DateTime endDate, {required int userId}) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
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
  static Future<List<Expense>> searchExpenses(String query, {required int userId}) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .or('description.ilike.%$query%,payee.ilike.%$query%,category.ilike.%$query%')
          .order('date', ascending: false);

      return (response as List)
          .map((item) => Expense.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search expenses: $e');
    }
  }
}
