import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_models.dart';
import '../models/user_settings.dart';

class CacheService {
  static const String _expensesCacheKey = 'cached_expenses';
  static const String _settingsCacheKey = 'cached_settings';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _userIdKey = 'cached_user_id';
  
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> cacheExpenses(List<Expense> expenses, int userId) async {
    try {
      final prefs = await _preferences;
      final expensesJson = expenses.map((e) => e.toSupabase()).toList();
      await prefs.setString('${_expensesCacheKey}_$userId', jsonEncode(expensesJson));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
    }
  }

  static Future<List<Expense>?> getCachedExpenses(int userId) async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString('${_expensesCacheKey}_$userId');
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Expense.fromSupabase(json)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> addExpenseToCache(Expense expense, int userId) async {
    try {
      final cached = await getCachedExpenses(userId) ?? [];
      cached.insert(0, expense);
      await cacheExpenses(cached, userId);
    } catch (e) {
    }
  }

  static Future<void> updateExpenseInCache(Expense expense, int userId) async {
    try {
      final cached = await getCachedExpenses(userId) ?? [];
      final index = cached.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        cached[index] = expense;
        await cacheExpenses(cached, userId);
      }
    } catch (e) {
    }
  }

  static Future<void> removeExpenseFromCache(String expenseId, int userId) async {
    try {
      final cached = await getCachedExpenses(userId) ?? [];
      cached.removeWhere((e) => e.id == expenseId);
      await cacheExpenses(cached, userId);
    } catch (e) {
    }
  }

  static Future<void> cacheSettings(UserSettings settings) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        '${_settingsCacheKey}_${settings.userId}', 
        jsonEncode(settings.toSupabase()),
      );
    } catch (e) {
    }
  }

  static Future<UserSettings?> getCachedSettings(int userId) async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString('${_settingsCacheKey}_$userId');
      if (jsonString == null) return null;
      
      return UserSettings.fromSupabase(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await _preferences;
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isCacheStale({Duration maxAge = const Duration(minutes: 5)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  static Future<void> saveCurrentUserId(int userId) async {
    try {
      final prefs = await _preferences;
      await prefs.setInt(_userIdKey, userId);
    } catch (e) {
    }
  }

  static Future<int?> getSavedUserId() async {
    try {
      final prefs = await _preferences;
      return prefs.getInt(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearUserCache(int userId) async {
    try {
      final prefs = await _preferences;
      await prefs.remove('${_expensesCacheKey}_$userId');
      await prefs.remove('${_settingsCacheKey}_$userId');
    } catch (e) {
    }
  }

  static Future<void> clearAllCache() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_expensesCacheKey) || 
            key.startsWith(_settingsCacheKey)) {
          await prefs.remove(key);
        }
      }
      await prefs.remove(_lastSyncKey);
    } catch (e) {
    }
  }
}
