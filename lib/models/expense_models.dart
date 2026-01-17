import 'package:flutter/material.dart';

/// Model for expense transactions stored in Supabase
class Expense {
  final String? id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String? payee;
  final String? paymentApp;
  final String? transactionId;
  final String? notes;
  final String? accountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.payee,
    this.paymentApp,
    this.transactionId,
    this.notes,
    this.accountId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Expense from Supabase row
  factory Expense.fromSupabase(Map<String, dynamic> data) {
    return Expense(
      id: data['id']?.toString(),
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      date: DateTime.parse(data['date']),
      payee: data['payee'],
      paymentApp: data['payment_app'],
      transactionId: data['transaction_id'],
      notes: data['notes'],
      accountId: data['account_id'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  /// Convert Expense to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'payee': payee,
      'payment_app': paymentApp,
      'transaction_id': transactionId,
      'notes': notes,
      'account_id': accountId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    String? payee,
    String? paymentApp,
    String? transactionId,
    String? notes,
    String? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      payee: payee ?? this.payee,
      paymentApp: paymentApp ?? this.paymentApp,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for expense categories
class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final bool isDefault;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    Color? color,
    this.isDefault = false,
    String? colorHex, // Add support for colorHex parameter
  }) : color = colorHex != null ? _parseColorFromHex(colorHex) : (color ?? Colors.grey);

  /// Parse color from hex string
  static Color _parseColorFromHex(String hexColor) {
    String cleanHex = hexColor.replaceAll('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex'; // Add alpha if not present
    }
    return Color(int.parse(cleanHex, radix: 16));
  }

  /// Get display name (alias for name)
  String get displayName => name;

  /// Create ExpenseCategory from Supabase data
  factory ExpenseCategory.fromSupabase(Map<String, dynamic> data) {
    return ExpenseCategory(
      id: data['id'],
      name: data['name'],
      icon: data['icon'],
      color: Color(data['color']),
      isDefault: data['is_default'] ?? false,
    );
  }

  /// Convert ExpenseCategory to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.toARGB32(),
      'is_default': isDefault,
    };
  }

  /// Create default categories
  static List<ExpenseCategory> getDefaultCategories() {
    return [
      ExpenseCategory(
        id: 'food',
        name: 'Food',
        icon: '🍕',
        color: Colors.orange,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'transport',
        name: 'Transport',
        icon: '🚗',
        color: Colors.blue,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'shopping',
        name: 'Shopping',
        icon: '🛍️',
        color: Colors.purple,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'entertainment',
        name: 'Entertainment',
        icon: '🎬',
        color: Colors.red,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'health',
        name: 'Health',
        icon: '🏥',
        color: Colors.green,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'bills',
        name: 'Bills',
        icon: '📄',
        color: Colors.amber,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'education',
        name: 'Education',
        icon: '📚',
        color: Colors.indigo,
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'other',
        name: 'Other',
        icon: '📦',
        color: Colors.grey,
        isDefault: true,
      ),
    ];
  }
}

/// Model for bank accounts
class BankAccount {
  final String id;
  final String name;
  final bool isDefault;

  BankAccount({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  /// Create BankAccount from Supabase data
  factory BankAccount.fromSupabase(Map<String, dynamic> data) {
    return BankAccount(
      id: data['id'] as String,
      name: data['name'] as String,
      isDefault: data['is_default'] as bool? ?? false,
    );
  }

  /// Convert BankAccount to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'is_default': isDefault,
    };
  }

  /// Create a copy with updated fields
  BankAccount copyWith({
    String? id,
    String? name,
    bool? isDefault,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
