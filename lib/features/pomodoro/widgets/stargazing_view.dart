// lib/features/pomodoro/widgets/stargazing_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import '../logic/pomodoro_notifier.dart';

class StargazingView extends ConsumerWidget {
  const StargazingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeRemaining = ref.watch(pomodoroProvider.select((p) => p.timeRemaining));

    return Column(
      key: const ValueKey('stargazing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bedtime_rounded, size: 80, color: AppTheme.successColor),
        const SizedBox(height: 24),
        Text("Yıldız Gözlemi", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text('${(timeRemaining / 60).floor().toString().padLeft(2, '0')}:${(timeRemaining % 60).toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.secondaryTextColor)),
        const SizedBox(height: 32),
        Text("Zihnin, yeni keşiflere hazırlanmak için dinleniyor.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic)),
      ],
    );
  }
}