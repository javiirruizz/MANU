import 'package:flutter/material.dart';

/// Una opción del registro de estado de ánimo.
class MoodOption {
  const MoodOption({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final IconData icon;
}
