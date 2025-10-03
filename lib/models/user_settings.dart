import '../models/expense_models.dart';

/// Model for user settings stored in Supabase
class UserSettings {
  final String userId;
  final String userName;
  final double monthlyBudget;
  final String currency;
  final Map<String, double> categoryBudgets;
  final List<ExpenseCategory> customCategories;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    required this.userName,
    required this.monthlyBudget,
    required this.currency,
    required this.categoryBudgets,
    required this.customCategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create UserSettings from Supabase data
  factory UserSettings.fromSupabase(Map<String, dynamic> data) {
    // Parse category budgets from JSONB
    final categoryBudgetsJson = data['category_budgets'] as Map<String, dynamic>? ?? {};
    final categoryBudgets = <String, double>{};
    categoryBudgetsJson.forEach((key, value) {
      categoryBudgets[key] = (value as num).toDouble();
    });

    // Parse custom categories from JSONB
    final customCategoriesJson = data['custom_categories'] as List<dynamic>? ?? [];
    final customCategories = customCategoriesJson
        .map((item) => ExpenseCategory.fromSupabase(item as Map<String, dynamic>))
        .toList();

    return UserSettings(
      userId: data['user_id'] ?? 'default_user',
      userName: data['user_name'] ?? 'User',
      monthlyBudget: (data['monthly_budget'] as num?)?.toDouble() ?? 25000.0,
      currency: data['currency'] ?? '₹',
      categoryBudgets: categoryBudgets,
      customCategories: customCategories,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert UserSettings to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'user_name': userName,
      'monthly_budget': monthlyBudget,
      'currency': currency,
      'category_budgets': categoryBudgets,
      'custom_categories': customCategories.map((cat) => cat.toSupabase()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserSettings copyWith({
    String? userId,
    String? userName,
    double? monthlyBudget,
    String? currency,
    Map<String, double>? categoryBudgets,
    List<ExpenseCategory>? customCategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
      categoryBudgets: categoryBudgets ?? Map.from(this.categoryBudgets),
      customCategories: customCategories ?? List.from(this.customCategories),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
