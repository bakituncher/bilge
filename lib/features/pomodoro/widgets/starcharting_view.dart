// lib/features/pomodoro/widgets/starcharting_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import '../logic/pomodoro_notifier.dart';

class StarchartingView extends ConsumerWidget {
  const StarchartingView({super.key});

  Future<void> _selectConstellationToExplore(BuildContext context, WidgetRef ref) async {
    final user = ref.read(userProfileProvider).value;
    List<String> tasks = ["Genel Çalışma", "Konu Tekrarı", "Soru Çözümü"];
    if (user?.weeklyPlan != null) {
      final plan = WeeklyPlan.fromJson(user!.weeklyPlan!);
      tasks.addAll(plan.plan.expand((day) => day.schedule.map((item) => item.activity)));
    }
    tasks = tasks.toSet().toList();

    final String? chosenTask = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskSelectionSheet(tasks: tasks),
    );

    if (chosenTask != null) {
      ref.read(pomodoroProvider.notifier).startVoyage(chosenTask);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('starcharting'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.explore_rounded, size: 80, color: AppTheme.secondaryColor),
        const SizedBox(height: 24),
        Text("Keşfe Hazır Ol", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text("Yıldız haritanı oluştur ve zihninin derinliklerine bir yolculuğa çık.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor)),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: () => _selectConstellationToExplore(context, ref),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text("Yolculuğa Başla"),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _TaskSelectionSheet extends StatelessWidget {
  final List<String> tasks;
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
                itemBuilder: (context, index) => ListTile(title: Text(tasks[index], maxLines: 2, overflow: TextOverflow.ellipsis,), onTap: () => Navigator.of(context).pop(tasks[index])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}