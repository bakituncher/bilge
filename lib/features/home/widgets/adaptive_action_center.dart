// lib/features/home/widgets/adaptive_action_center.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdaptiveActionCenter extends StatelessWidget {
  const AdaptiveActionCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Deneme Ekle',
            icon: Icons.add_chart_outlined,
            onTap: () => context.go('/home/add-test'),
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            label: 'Odaklan',
            icon: Icons.timer_outlined,
            onTap: () => context.go('/home/pomodoro'),
            color: Colors.tealAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            label: 'Zayıflık',
            icon: Icons.auto_fix_high_rounded,
            onTap: () => context.go('/ai-hub/weakness-workshop'),
            color: Colors.purpleAccent,
          ),
        ),
      ].animate(interval: 120.ms).fadeIn(duration: 350.ms).slideY(begin: .15),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _ActionButton({required this.label, required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppTheme.cardColor,
          border: Border.all(color: AppTheme.lightSurfaceColor.withValues(alpha: .5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack);
  }
}
