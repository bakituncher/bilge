// lib/features/pomodoro/pomodoro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'logic/pomodoro_notifier.dart';
import 'widgets/pomodoro_stats_view.dart';
import 'widgets/pomodoro_timer_view.dart'; // YENİ WIDGET

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroProvider);
    final showTimerView = pomodoro.sessionState != PomodoroSessionState.idle || !pomodoro.isPaused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zihinsel Gözlemevi'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedContainer(
        duration: 800.ms,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              _getBackgroundColor(pomodoro.sessionState).withOpacity(0.3),
              AppTheme.primaryColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: 800.ms,
            transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child)),
            // IDLE durumunda istatistikleri, diğer durumlarda zamanlayıcıyı göster
            child: showTimerView
                ? const PomodoroTimerView(key: ValueKey('timer'))
                : const PomodoroStatsView(key: ValueKey('stats')),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(PomodoroSessionState currentState) {
    switch (currentState) {
      case PomodoroSessionState.work:
        return AppTheme.secondaryColor;
      case PomodoroSessionState.shortBreak:
      case PomodoroSessionState.longBreak:
        return AppTheme.successColor;
      case PomodoroSessionState.idle:
        return AppTheme.lightSurfaceColor;
    }
  }
}