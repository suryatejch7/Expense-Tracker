import 'package:flutter/material.dart';
import '../models/expense_models.dart';

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

class CategoryIcons {
  static const List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_pizza,
    Icons.local_cafe,
    Icons.wine_bar,

    Icons.directions_car,
    Icons.directions_bus,
    Icons.train,
    Icons.flight,
    Icons.local_gas_station,
    Icons.motorcycle,
    Icons.pedal_bike,

    Icons.movie,
    Icons.theater_comedy,
    Icons.music_note,
    Icons.sports_esports,
    Icons.sports_soccer,
    Icons.camera_alt,

    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.store,
    Icons.local_mall,
    Icons.checkroom,

    Icons.receipt_long,
    Icons.payment,
    Icons.credit_card,
    Icons.account_balance,
    Icons.phone,
    Icons.wifi,
    Icons.electrical_services,

    Icons.local_hospital,
    Icons.medical_services,
    Icons.fitness_center,
    Icons.spa,
    Icons.psychology,

    Icons.school,
    Icons.work,
    Icons.laptop,
    Icons.book,
    Icons.library_books,

    Icons.luggage,
    Icons.hotel,
    Icons.beach_access,
    Icons.hiking,
    Icons.map,

    Icons.home,
    Icons.family_restroom,
    Icons.pets,
    Icons.child_care,
    Icons.elderly,

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

class DefaultCategories {
  static List<ExpenseCategory> get defaultCategories =>
      ExpenseCategory.getDefaultCategories();
}
