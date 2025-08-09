// lib/features/pomodoro/widgets/pomodoro_timer_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/shared/widgets/score_slider.dart'; // DÜZELTME: Eksik import eklendi
import 'package:intl/intl.dart'; // DÜZELTME: Eksik import eklendi
import '../logic/pomodoro_notifier.dart';

class PomodoroTimerView extends ConsumerWidget {
  const PomodoroTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final totalDuration = _getTotalDuration(pomodoro);

    final String sessionTitle;
    final Color progressColor;

    switch (pomodoro.sessionState) {
      case PomodoroSessionState.work:
        sessionTitle = "Odaklan";
        progressColor = AppTheme.secondaryColor;
        break;
      case PomodoroSessionState.shortBreak:
        sessionTitle = "Kısa Mola";
        progressColor = AppTheme.successColor;
        break;
      case PomodoroSessionState.longBreak:
        sessionTitle = "Uzun Mola";
        progressColor = AppTheme.successColor;
        break;
      default:
        sessionTitle = "Hazır";
        progressColor = AppTheme.lightSurfaceColor;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeader(context, sessionTitle, pomodoro, notifier, ref), // DÜZELTME: ref eklendi
          _buildTimerDial(context, pomodoro, totalDuration, progressColor),
          _buildControls(context, pomodoro, notifier, ref), // DÜZELTME: ref eklendi
        ],
      ),
    );
  }

  int _getTotalDuration(PomodoroModel pomodoro) {
    switch (pomodoro.sessionState) {
      case PomodoroSessionState.work:
        return pomodoro.workDuration;
      case PomodoroSessionState.shortBreak:
        return pomodoro.shortBreakDuration;
      case PomodoroSessionState.longBreak:
        return pomodoro.longBreakDuration;
      default:
        return pomodoro.workDuration;
    }
  }

  Widget _buildHeader(BuildContext context, String title, PomodoroModel pomodoro, PomodoroNotifier notifier, WidgetRef ref) { // DÜZELTME: ref eklendi
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        ActionChip(
          avatar: const Icon(Icons.assignment_outlined, size: 18),
          label: Text(pomodoro.currentTask, overflow: TextOverflow.ellipsis),
          onPressed: () => _showTaskSelectionSheet(context, ref),
        ),
        const SizedBox(height: 8),
        Text("Tur: ${pomodoro.currentRound} / ${pomodoro.longBreakInterval}",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }

  Widget _buildTimerDial(BuildContext context, PomodoroModel pomodoro, int totalDuration, Color progressColor) {
    final time = Duration(seconds: pomodoro.timeRemaining);
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');

    return AspectRatio(
      aspectRatio: 1,
      child: Animate(
        target: pomodoro.isPaused ? 1 : 0,
        effects: [
          ScaleEffect(duration: 300.ms, curve: Curves.easeOut, begin: const Offset(1,1), end: const Offset(0.95, 0.95))
        ],
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: totalDuration > 0 ? pomodoro.timeRemaining / totalDuration : 1,
              strokeWidth: 12,
              backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Text(
                '$minutes:$seconds',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PomodoroModel pomodoro, PomodoroNotifier notifier, WidgetRef ref) { // DÜZELTME: ref eklendi
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: () => _showSettingsSheet(context, ref),
              icon: const Icon(Icons.settings),
              style: IconButton.styleFrom(backgroundColor: AppTheme.lightSurfaceColor),
            ),
            const SizedBox(width: 20),
            IconButton.filled(
              iconSize: 56,
              onPressed: pomodoro.isPaused ? notifier.start : notifier.pause,
              icon: Icon(pomodoro.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
            const SizedBox(width: 20),
            IconButton.filled(
              onPressed: notifier.reset,
              icon: const Icon(Icons.replay_rounded),
              style: IconButton.styleFrom(backgroundColor: AppTheme.lightSurfaceColor),
            ),
          ],
        ),
        if(pomodoro.sessionState == PomodoroSessionState.work && pomodoro.currentTaskIdentifier != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextButton.icon(
                onPressed: (){
                  notifier.markTaskAsCompleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'${pomodoro.currentTask}' tamamlandı!"), backgroundColor: AppTheme.successColor),
                  );
                },
                icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
                label: Text("'${pomodoro.currentTask}' görevini tamamla", style: const TextStyle(color: AppTheme.successColor))
            ),
          )
      ],
    );
  }

  Future<void> _showTaskSelectionSheet(BuildContext context, WidgetRef ref) async { // DÜZELTME: ref eklendi
    final user = ref.read(userProfileProvider).value;
    final List<({String task, String? identifier})> tasks = [
      (task: "Genel Çalışma", identifier: null),
    ];

    if (user?.weeklyPlan != null) {
      final plan = WeeklyPlan.fromJson(user!.weeklyPlan!);
      final today = DateTime.now();
      final todayName = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][today.weekday - 1];
      final dateKey = DateFormat('yyyy-MM-dd').format(today);

      final todayPlan = plan.plan.firstWhere((day) => day.day == todayName, orElse: () => DailyPlan(day: todayName, schedule: []));

      for (var item in todayPlan.schedule) {
        final identifier = '${item.time}-${item.activity}';
        final isCompleted = user.completedDailyTasks[dateKey]?.contains(identifier) ?? false;
        if (!isCompleted) {
          tasks.add((task: item.activity, identifier: identifier));
        }
      }
    }

    final selectedTask = await showModalBottomSheet<({String task, String? identifier})>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tasks.map((task) => ListTile(
              title: Text(task.task, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).pop(task),
            )).toList(),
          ),
        ),
      ),
    );

    if (selectedTask != null) {
      ref.read(pomodoroProvider.notifier).setTask(task: selectedTask.task, identifier: selectedTask.identifier);
    }
  }

  Future<void> _showSettingsSheet(BuildContext context, WidgetRef ref) async { // DÜZELTME: ref eklendi
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => const PomodoroSettingsSheet()
    );
  }
}

class PomodoroSettingsSheet extends ConsumerStatefulWidget {
  const PomodoroSettingsSheet({super.key});

  @override
  ConsumerState<PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends ConsumerState<PomodoroSettingsSheet> {
  late double _work, _short, _long, _interval;

  @override
  void initState() {
    super.initState();
    final pomodoro = ref.read(pomodoroProvider);
    _work = (pomodoro.workDuration / 60).roundToDouble();
    _short = (pomodoro.shortBreakDuration / 60).roundToDouble();
    _long = (pomodoro.longBreakDuration / 60).roundToDouble();
    _interval = pomodoro.longBreakInterval.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Zaman Ayarları", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ScoreSlider(label: "Odaklanma (dk)", value: _work, max: 60, color: AppTheme.secondaryColor, onChanged: (v) => setState(() => _work = v.roundToDouble())),
            ScoreSlider(label: "Kısa Mola (dk)", value: _short, max: 15, color: AppTheme.successColor, onChanged: (v) => setState(() => _short = v.roundToDouble())),
            ScoreSlider(label: "Uzun Mola (dk)", value: _long, max: 30, color: AppTheme.successColor, onChanged: (v) => setState(() => _long = v.roundToDouble())),
            ScoreSlider(label: "Uzun Mola Aralığı (Tur)", value: _interval, max: 8, color: AppTheme.lightSurfaceColor, onChanged: (v) => setState(() => _interval = v.roundToDouble())),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: (){
                  ref.read(pomodoroProvider.notifier).updateSettings(
                    work: _work.toInt(),
                    short: _short.toInt(),
                    long: _long.toInt(),
                    interval: _interval.toInt(),
                  );
                  Navigator.pop(context);
                },
                child: const Text("Kaydet")
            )
          ],
        ),
      ),
    );
  }
}