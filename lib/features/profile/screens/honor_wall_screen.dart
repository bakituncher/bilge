// lib/features/profile/screens/honor_wall_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/profile/models/badge_model.dart' as app_badge;
import '../widgets/badge_card.dart';

class HonorWallScreen extends StatelessWidget {
  final List<app_badge.Badge> allBadges;

  const HonorWallScreen({super.key, required this.allBadges});

  @override
  Widget build(BuildContext context) {
    final unlockedBadges = allBadges.where((b) => b.isUnlocked).toList();
    final lockedBadges = allBadges.where((b) => !b.isUnlocked).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Şeref Duvarı"),
          bottom: const TabBar(
            indicatorColor: AppTheme.secondaryColor,
            tabs: [
              Tab(text: "KAZANILAN ZAFERLER"),
              Tab(text: "GELECEK HEDEFLER"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBadgeGrid(context, unlockedBadges, true),
            _buildBadgeGrid(context, lockedBadges, false),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(BuildContext context, List<app_badge.Badge> badges, bool isUnlocked) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.shield_moon_rounded : Icons.flag_rounded,
              size: 80,
              color: AppTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked ? 'Henüz Madalya Kazanılmadı' : 'Tüm Hedefler Fethedildi!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                isUnlocked ? 'Savaşmaya devam et, bu duvarı zaferlerinle doldur!' : 'Ulaşılacak yeni bir hedef kalmadı Komutan!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return BadgeCard(badge: badges[index])
            .animate()
            .fadeIn(delay: (100 * (index % 9)).ms)
            .slideY(begin: 0.5, curve: Curves.easeOutCubic);
      },
    );
  }
}