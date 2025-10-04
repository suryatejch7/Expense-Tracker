import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart' as models;
import '../services/supabase_service.dart';
import 'expense_provider.dart';

class UserProvider extends ChangeNotifier {
  models.User? _currentUser;
  models.UserSettings? _userSettings;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedFromStorage = false;

  models.User? get currentUser => _currentUser;
  models.UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  int get userId => _currentUser?.id ?? 0;
  String get userName => _currentUser?.userName ?? '';

  /// Load user from SharedPreferences on app start
  Future<void> loadUserFromStorage() async {
    // Only load from storage once during app startup
    if (_hasLoadedFromStorage) {
      return;
    }
    _hasLoadedFromStorage = true;
    
    // Set loading state without notifying listeners during build
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId != null && userId > 0) {
        // Load user from database
        final user = await ExpenseSupabaseService.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          // Load user settings
          _userSettings = await ExpenseSupabaseService.getUserSettings(userId: userId);
        } else {
          // User not found in database, clear storage
          await clearUser();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load user: $e';
      await clearUser();
    } finally {
      _isLoading = false;
      // Defer all notifyListeners calls to avoid calling during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Register a new user
  Future<bool> registerUser(String userName) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // Check if username already exists (case-sensitive)
      final exists = await ExpenseSupabaseService.isUsernameTaken(userName);
      if (exists) {
        _errorMessage = 'Username already exists';
        return false;
      }

      // Create new user
      final user = await ExpenseSupabaseService.createUser(userName);
      
      // Create default settings
      final settings = await ExpenseSupabaseService.createDefaultUserSettings(user.id);
      
      // Save to storage and state
      await _saveUserToStorage(user);
      _currentUser = user;
      _userSettings = settings;
      
      // Notify listeners that the user state has changed
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with username
  Future<bool> loginWithUsername(String userName) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final user = await ExpenseSupabaseService.getUserByUsername(userName);
      if (user == null) {
        _errorMessage = 'User not found';
        return false;
      }

      // Load user settings
      final settings = await ExpenseSupabaseService.getUserSettings(userId: user.id);
      
      // Save to storage and state
      await _saveUserToStorage(user);
      _currentUser = user;
      _userSettings = settings;
      
      // Notify listeners that the user state has changed
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with user ID
  Future<bool> loginWithUserId(int userId) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final user = await ExpenseSupabaseService.getUserById(userId);
      if (user == null) {
        _errorMessage = 'User not found';
        return false;
      }

      // Load user settings
      final settings = await ExpenseSupabaseService.getUserSettings(userId: user.id);
      
      // Save to storage and state
      await _saveUserToStorage(user);
      _currentUser = user;
      _userSettings = settings;
      
      // Notify listeners that the user state has changed
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user settings
  Future<void> updateUserSettings(models.UserSettings settings) async {
    try {
      await ExpenseSupabaseService.saveUserSettings(settings);
      _userSettings = settings;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update settings: $e';
      throw Exception(_errorMessage);
    }
  }

  /// Update user name
  Future<bool> updateUserName(String userName) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      return false;
    }
    
    try {
      
      await ExpenseSupabaseService.updateUserName(userName, userId: _currentUser!.id);
      _currentUser = models.User(
        id: _currentUser!.id,
        userName: userName,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update username: $e';
      return false;
    }
  }

  /// Update monthly budget
  Future<void> updateMonthlyBudget(double budget) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      return;
    }
    
    try {
      await ExpenseSupabaseService.updateMonthlyBudget(budget, userId: _currentUser!.id);
      if (_userSettings != null) {
        _userSettings = _userSettings!.copyWith(monthlyBudget: budget);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update budget: $e';
      throw Exception(_errorMessage);
    }
  }

  /// Clear user data and logout
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    
    _currentUser = null;
    _userSettings = null;
    _errorMessage = null;
    _hasLoadedFromStorage = false; // Reset flag to allow loading from storage again
    notifyListeners();
  }

  /// Initialize expense provider with current user data
  Future<void> initializeExpenseProvider(ExpenseProvider expenseProvider) async {
    if (_currentUser != null && _userSettings != null) {
      await expenseProvider.initializeWithUser(
        _currentUser!.id,
        _currentUser!.userName,
        _userSettings!,
      );
    }
  }

  /// Get all available users
  Future<List<models.User>> getAllUsers() async {
    try {
      final users = await ExpenseSupabaseService.getAllUsers();
      return users;
    } catch (e) {
      _errorMessage = 'Failed to fetch users: $e';
      return [];
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _saveUserToStorage(models.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id);
    await prefs.setString('userName', user.userName);
  }
}
