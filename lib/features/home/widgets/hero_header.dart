// lib/features/home/widgets/hero_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/profile/logic/rank_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class HeroHeader extends ConsumerWidget {
  const HeroHeader({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Gece Vardiyası';
    if (hour < 11) return 'Günaydın';
    if (hour < 17) return 'Odak Zamanı';
    if (hour < 22) return 'Akşam Gücü';
    return 'Gece Derinliği';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final info = RankService.getRankInfo(user.engagementScore);
        final current = info.current;
        final next = info.next;
        final progress = info.progress; // 0..1

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [AppTheme.cardColor, AppTheme.lightSurfaceColor.withValues(alpha: .35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.lightSurfaceColor.withValues(alpha: .4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()}, ${user.name ?? 'Bilge'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(current.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryColor, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppTheme.lightSurfaceColor.withValues(alpha: .25),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.secondaryColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('BP ${user.engagementScore}  •  %${(progress * 100).toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Arşiv',
                onPressed: () => context.go('/library'),
                icon: const Icon(Icons.history_edu_rounded, color: AppTheme.secondaryTextColor),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
