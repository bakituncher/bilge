// lib/features/profile/models/badge_model.dart
import 'package:flutter/material.dart';

class Badge {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  Badge({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
  });
}