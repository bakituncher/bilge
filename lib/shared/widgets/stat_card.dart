// lib/shared/widgets/stat_card.dart
import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: AppTheme.lightSurfaceColor.withOpacity(0.5),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color ?? AppTheme.secondaryColor,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const ProfileStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppTheme.secondaryTextColor),
              const SizedBox(height: 8),
              Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}