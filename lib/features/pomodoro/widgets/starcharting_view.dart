// lib/features/pomodoro/widgets/starcharting_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import '../logic/pomodoro_notifier.dart';
import 'package:bilge_ai/shared/widgets/score_slider.dart';

final _workDurationProvider = StateProvider.autoDispose<double>((ref) => 25);
final _breakDurationProvider = StateProvider.autoDispose<double>((ref) => 5);

class StarchartingView extends ConsumerWidget {
  const StarchartingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workDuration = ref.watch(_workDurationProvider);
    final breakDuration = ref.watch(_breakDurationProvider);
    final pomodoroNotifier = ref.read(pomodoroProvider.notifier);
    final user = ref.watch(userProfileProvider).value;

    final List<({String task, String? identifier})> tasks = [
      (task: "Genel Çalışma", identifier: null),
      (task: "Konu Tekrarı", identifier: null),
      (task: "Soru Çözümü", identifier: null),
    ];

    if (user?.weeklyPlan != null) {
      final plan = WeeklyPlan.fromJson(user!.weeklyPlan!);
      final today = DateTime.now();
      final todayName = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][today.weekday - 1];
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayPlan = plan.plan.firstWhere(
            (day) => day.day == todayName,
        orElse: () => DailyPlan(day: todayName, schedule: []),
      );

      for (var item in todayPlan.schedule) {
        final identifier = '$dateKey-${item.time}-${item.activity}';
        final isCompleted = user.completedDailyTasks[dateKey]?.contains(identifier) ?? false;
        if(!isCompleted) {
          tasks.add((task: item.activity, identifier: identifier));
        }
      }
    }


    Future<void> showTaskSelectionSheet(BuildContext context) async {
      final selectedTask = await showModalBottomSheet<({String task, String? identifier})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _TaskSelectionSheet(tasks: tasks),
      );

      if (selectedTask != null) {
        pomodoroNotifier.startVoyage(
          task: selectedTask.task,
          taskIdentifier: selectedTask.identifier,
          workDuration: (workDuration * 60).toInt(),
          breakDuration: (breakDuration * 60).toInt(),
        );
      }
    }

    return ListView(
      key: const ValueKey('starcharting'),
      padding: const EdgeInsets.all(24.0),
      children: [
        const Icon(Icons.explore_rounded, size: 80, color: AppTheme.secondaryColor).animate().fadeIn().scale(duration: 800.ms),
        const SizedBox(height: 24),
        Text("Yeni Bir Keşfe Başla", style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text("Odaklanma ve mola sürelerini belirle, ne üzerinde çalışacağını seçerek yolculuğa başla.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor)),
        const SizedBox(height: 48),
        ScoreSlider(
          label: "Odaklanma Süresi (dk)",
          value: workDuration,
          max: 60,
          color: AppTheme.secondaryColor,
          onChanged: (value) => ref.read(_workDurationProvider.notifier).state = value,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
        const SizedBox(height: 16),
        ScoreSlider(
          label: "Mola Süresi (dk)",
          value: breakDuration,
          max: 30,
          color: AppTheme.successColor,
          onChanged: (value) => ref.read(_breakDurationProvider.notifier).state = value,
        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: () => showTaskSelectionSheet(context),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text("Yolculuğa Başla"),
        ).animate().fadeIn(delay: 500.ms),
        TextButton(
          onPressed: () => pomodoroNotifier.reset(),
          child: const Text("Geri Dön"),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

class _TaskSelectionSheet extends StatelessWidget {
  final List<({String task, String? identifier})> tasks;
  const _TaskSelectionSheet({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text("Hangi Takımyıldızını Keşfedeceksin?", style: Theme.of(context).textTheme.headlineSmall)),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task.task, maxLines: 2, overflow: TextOverflow.ellipsis,),
                    onTap: () => Navigator.of(context).pop(task),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}