// lib/shared/widgets/scaffold_with_nav_bar.dart
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true, // BİLGEAI DEVRİMİ: Body'nin navbar'ın altına uzanmasını sağlar.
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab',
        onPressed: () => _onTap(2),
        backgroundColor: AppTheme.secondaryColor,
        child: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 28),
        elevation: 4.0,
        shape: const CircleBorder(),
      ).animate().scale(delay: 500.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        padding: EdgeInsets.zero,
        height: 70,
        color: AppTheme.cardColor.withOpacity(0.95), // Hafif transparanlık
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, icon: Icons.dashboard_rounded, label: 'Panel', index: 0),
            _buildNavItem(context, icon: Icons.school_rounded, label: 'Koç', index: 1),
            const SizedBox(width: 56), // Merkezdeki boşluk
            _buildNavItem(context, icon: Icons.military_tech_rounded, label: 'Arena', index: 3),
            _buildNavItem(context, icon: Icons.person_rounded, label: 'Profil', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final isSelected = navigationShell.currentIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? AppTheme.secondaryColor : AppTheme.secondaryTextColor, size: 28),
      onPressed: () => _onTap(index),
      tooltip: label,
      splashColor: AppTheme.secondaryColor.withOpacity(0.2),
      highlightColor: AppTheme.secondaryColor.withOpacity(0.1),
    );
  }
}