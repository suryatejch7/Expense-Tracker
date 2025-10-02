import 'package:flutter/material.dart';

/// Model for quick action items on the dashboard
class QuickActionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  QuickActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  QuickActionItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
    bool? isEnabled,
  }) {
    return QuickActionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      onTap: onTap ?? this.onTap,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Factory class for creating default quick actions
class QuickActions {
  static List<QuickActionItem> getDefaultActions(BuildContext context) {
    return [
      QuickActionItem(
        id: 'add_expense',
        title: 'Add Expense',
        subtitle: 'Manual entry',
        icon: Icons.add_circle_outline,
        color: Colors.blue,
        onTap: () {
          Navigator.pushNamed(context, '/add-expense');
        },
      ),
      QuickActionItem(
        id: 'scan_receipt',
        title: 'Scan Receipt',
        subtitle: 'OCR extraction',
        icon: Icons.camera_alt,
        color: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, '/scan-receipt');
        },
      ),
      QuickActionItem(
        id: 'view_analytics',
        title: 'Analytics',
        subtitle: 'View reports',
        icon: Icons.analytics,
        color: Colors.purple,
        onTap: () {
          Navigator.pushNamed(context, '/analytics');
        },
      ),
      QuickActionItem(
        id: 'categories',
        title: 'Categories',
        subtitle: 'Manage categories',
        icon: Icons.category,
        color: Colors.orange,
        onTap: () {
          Navigator.pushNamed(context, '/categories');
        },
      ),
    ];
  }
}
