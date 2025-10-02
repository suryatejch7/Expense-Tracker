import 'package:flutter/material.dart';

class QuickActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
