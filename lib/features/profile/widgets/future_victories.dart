// lib/features/profile/widgets/future_victories.dart
import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/profile/models/badge_model.dart' as app_badge; // DÜZELTİLDİ

class FutureVictories extends StatelessWidget {
  final List<app_badge.Badge> lockedBadges; // DÜZELTİLDİ
  const FutureVictories({super.key, required this.lockedBadges});

  @override
  Widget build(BuildContext context) {
    if (lockedBadges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Gelecek Zaferler", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: lockedBadges.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final badge = lockedBadges[index];
            return Tooltip(
              message: "${badge.name}\n${badge.description}",
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                      color: AppTheme.cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.lightSurfaceColor.withOpacity(0.3), width: 1.5)
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                          badge.icon,
                          color: AppTheme.secondaryTextColor.withOpacity(0.2),
                          size: 30
                      ),
                      Icon(
                          Icons.lock,
                          color: AppTheme.secondaryTextColor.withOpacity(0.8),
                          size: 20
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}