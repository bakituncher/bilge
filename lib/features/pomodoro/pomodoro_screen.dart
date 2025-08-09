// lib/features/pomodoro/pomodoro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'logic/pomodoro_notifier.dart';
import 'widgets/pomodoro_stats_view.dart';
import 'widgets/starcharting_view.dart';
import 'widgets/calibration_view.dart';
import 'widgets/voyage_view.dart';
import 'widgets/discovery_view.dart';
import 'widgets/stargazing_view.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);

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
              _getBackgroundColor(pomodoroState.currentState).withOpacity(0.3),
              AppTheme.primaryColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: 800.ms,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
            child: _buildCurrentView(pomodoroState.currentState),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(PomodoroState currentState) {
    switch (currentState) {
      case PomodoroState.voyage:
        return AppTheme.secondaryColor;
      case PomodoroState.stargazing:
        return AppTheme.successColor;
      case PomodoroState.calibration:
        return Colors.blueAccent;
      case PomodoroState.stats:
      case PomodoroState.starcharting:
        return AppTheme.lightSurfaceColor;
      case PomodoroState.discovery:
        return AppTheme.lightSurfaceColor;
    }
  }

  Widget _buildCurrentView(PomodoroState currentState) {
    switch (currentState) {
      case PomodoroState.stats:
        return const PomodoroStatsView();
      case PomodoroState.starcharting:
        return const StarchartingView();
      case PomodoroState.calibration:
        return const CalibrationView();
      case PomodoroState.voyage:
        return const VoyageView();
      case PomodoroState.discovery:
        return const DiscoveryView();
      case PomodoroState.stargazing:
        return const StargazingView();
    }
  }
}