// lib/shared/widgets/scaffold_with_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab', // HATA DÜZELTİLDİ: Benzersiz bir tag eklendi.
        onPressed: () => _onTap(2), // 3. sekme olan AI Hub'a git
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
        elevation: 2.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, icon: Icons.home_filled, label: 'Panel', index: 0),
            _buildNavItem(context, icon: Icons.insights, label: 'Koç', index: 1),
            const SizedBox(width: 48), // Ortadaki boşluk
            _buildNavItem(context, icon: Icons.military_tech, label: 'Arena', index: 3),
            _buildNavItem(context, icon: Icons.person, label: 'Profil', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey;
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _onTap(index),
      tooltip: label,
    );
  }
}