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
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  /// Create Expense from extracted transaction data
  factory Expense.fromExtractedTransaction({
    required String extractedAmount,
    required String category,
    String? payee,
    String? paymentApp,
    String? transactionId,
    DateTime? transactionDate,
  }) {
    final now = DateTime.now();
    final amount = double.tryParse(extractedAmount.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

    return Expense(
      amount: amount,
      description: payee != null ? 'Payment to $payee' : 'Transaction',
      category: category,
      date: transactionDate ?? now,
      payee: payee,
      paymentApp: paymentApp,
      transactionId: transactionId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to Supabase row data
  Map<String, dynamic> toSupabase() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'payee': payee,
      'payment_app': paymentApp,
      'transaction_id': transactionId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: ₹$amount, description: $description, category: $category)';
  }
}

/// Model for expense categories
class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.isDefault = false,
    required this.createdAt,
  });

  // Helper getters for UI
  String get displayName => name;

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF747D8C); // Default color
    }
  }

  // For compatibility with existing code
  Map<String, dynamic> get values => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': colorHex,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ExpenseCategory.fromSupabase(Map<String, dynamic> data) {
    return ExpenseCategory(
      id: data['id']?.toString() ?? '',
      name: data['name'],
      icon: data['icon'],
      colorHex: data['color'],
      isDefault: data['is_default'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'icon': icon,
      'color': colorHex,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Model for analytics data
class ExpenseAnalytics {
  final double totalExpenses;
  final double monthlyAverage;
  final Map<String, double> categoryTotals;
  final Map<String, int> categoryCount;
  final List<Expense> recentTransactions;
  final DateTime periodStart;
  final DateTime periodEnd;

  ExpenseAnalytics({
    required this.totalExpenses,
    required this.monthlyAverage,
    required this.categoryTotals,
    required this.categoryCount,
    required this.recentTransactions,
    required this.periodStart,
    required this.periodEnd,
  });
}
