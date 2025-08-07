// lib/features/profile/widgets/honor_wall.dart
import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/profile/models/badge_model.dart' as app_badge; // DÜZELTİLDİ

class HonorWall extends StatelessWidget {
  final List<app_badge.Badge> unlockedBadges; // DÜZELTİLDİ
  const HonorWall({super.key, required this.unlockedBadges});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Şeref Duvarı", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (unlockedBadges.isEmpty)
          const Center(child: Text("Henüz madalya kazanılmadı. Savaşmaya devam et!", style: TextStyle(color: AppTheme.secondaryTextColor))),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: unlockedBadges.map((badge) {
            return Tooltip(
              message: "${badge.name}\n${badge.description}",
              child: Chip(
                avatar: Icon(badge.icon, color: badge.color, size: 18),
                label: Text(badge.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: badge.color.withOpacity(0.2),
                side: BorderSide(color: badge.color),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}