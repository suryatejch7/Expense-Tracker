import 'package:flutter/material.dart';
import '../models/expense_models.dart';

/// Model for custom expense categories created by users
class CustomCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final double budget;
  final bool isActive;
  final DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  String get displayName => name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color':
          color.r.toInt() << 24 |
          color.g.toInt() << 16 |
          color.b.toInt() << 8 |
          color.a.toInt(),
      'budget': budget,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '📦',
      color: Color(map['color'] ?? 0xFF747D8C),
      budget: (map['budget'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  CustomCategory copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    double? budget,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budget: budget ?? this.budget,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Predefined icon options for category creation
class CategoryIcons {
  static const List<IconData> availableIcons = [
    // Food & Dining
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_pizza,
    Icons.local_cafe,
    Icons.wine_bar,

    // Transportation
    Icons.directions_car,
    Icons.directions_bus,
    Icons.train,
    Icons.flight,
    Icons.local_gas_station,
    Icons.motorcycle,
    Icons.pedal_bike,

    // Entertainment
    Icons.movie,
    Icons.theater_comedy,
    Icons.music_note,
    Icons.sports_esports,
    Icons.sports_soccer,
    Icons.camera_alt,

    // Shopping
    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.store,
    Icons.local_mall,
    Icons.checkroom,

    // Bills & Finance
    Icons.receipt_long,
    Icons.payment,
    Icons.credit_card,
    Icons.account_balance,
    Icons.phone,
    Icons.wifi,
    Icons.electrical_services,

    // Health & Fitness
    Icons.local_hospital,
    Icons.medical_services,
    Icons.fitness_center,
    Icons.spa,
    Icons.psychology,

    // Education & Work
    Icons.school,
    Icons.work,
    Icons.laptop,
    Icons.book,
    Icons.library_books,

    // Travel & Vacation
    Icons.luggage,
    Icons.hotel,
    Icons.beach_access,
    Icons.hiking,
    Icons.map,

    // Home & Family
    Icons.home,
    Icons.family_restroom,
    Icons.pets,
    Icons.child_care,
    Icons.elderly,

    // Miscellaneous
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.card_giftcard,
    Icons.celebration,
    Icons.savings,
    Icons.trending_up,
    Icons.trending_down,
  ];

  static const List<Color> availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
}

// Default categories that come with the app
class DefaultCategories {
  static List<ExpenseCategory> get defaultCategories =>
      ExpenseCategory.getDefaultCategories();
}
