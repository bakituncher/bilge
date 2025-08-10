// lib/features/pomodoro/widgets/pomodoro_completed_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import '../logic/pomodoro_notifier.dart';

class PomodoroCompletedView extends ConsumerWidget {
  final FocusSessionResult result;
  const PomodoroCompletedView({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pomodoroProvider.notifier);
    final pomodoro = ref.watch(pomodoroProvider);

    final isLongBreakTime = result.roundsCompleted % pomodoro.longBreakInterval == 0;
    final breakDuration = isLongBreakTime ? pomodoro.longBreakDuration : pomodoro.shortBreakDuration;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.check_circle_outline_rounded, size: 80, color: AppTheme.successColor)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(delay: 2.seconds, duration: 1.seconds, color: Colors.white.withOpacity(0.5))
              .animate() // Tekrar animate çağırarak ilk animasyonu sıfırla
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            "Yaratım Tamamlandı!",
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
          Text(
            "'${result.task}' görevine ${(result.totalFocusSeconds/60).round()} dakika odaklandın.",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
          const Spacer(),
          ElevatedButton.icon(
            icon: Icon(isLongBreakTime ? Icons.bedtime_rounded : Icons.coffee_rounded),
            label: Text("${(breakDuration/60).round()} Dakika Mola Ver"),
            onPressed: notifier.startNextSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
          TextButton(
            onPressed: notifier.reset,
            child: const Text("Mabedi Terk Et"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}