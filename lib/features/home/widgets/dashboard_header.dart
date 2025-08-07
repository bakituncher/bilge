// lib/features/home/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.name,
  });

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300, color: AppTheme.secondaryTextColor)),
            Text(name.split(' ').first, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.history_edu_rounded, color: AppTheme.secondaryTextColor, size: 28),
          tooltip: 'Bilgelik Kütüphanesi',
          onPressed: () => context.go('/library'),
        ),
      ],
    );
  }
}