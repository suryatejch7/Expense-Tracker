import 'package:flutter/material.dart';

class CustomCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;

  CustomCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value, // Using .value for serialization - this is still the correct approach
      'isDefault': isDefault,
    };
  }

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id'],
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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
  static List<CustomCategory> get defaultCategories => [
    CustomCategory(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
      isDefault: true,
    ),
    CustomCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: Colors.blue,
      isDefault: true,
    ),
    CustomCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.purple,
      isDefault: true,
    ),
    CustomCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.pink,
      isDefault: true,
    ),
    CustomCategory(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt_long,
      color: Colors.red,
      isDefault: true,
    ),
    CustomCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.local_hospital,
      color: Colors.green,
      isDefault: true,
    ),
    CustomCategory(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: Colors.indigo,
      isDefault: true,
    ),
    CustomCategory(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight,
      color: Colors.teal,
      isDefault: true,
    ),
    CustomCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.category,
      color: Colors.grey,
      isDefault: true,
    ),
  ];
}
