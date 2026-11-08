import 'package:flutter/material.dart';

/// Un plato del menú escolar.
class MealItem {
  const MealItem({
    required this.label,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label; // "1º PLATO"
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}
