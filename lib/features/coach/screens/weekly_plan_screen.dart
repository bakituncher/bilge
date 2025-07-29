// lib/features/coach/screens/weekly_plan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Model Sınıfları
class WeeklyPlan {
  final String planTitle;
  final String strategyFocus;
  final List<DailyPlan> plan;
  WeeklyPlan({required this.planTitle, required this.strategyFocus, required this.plan});

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    var list = json['plan'] as List;
    List<DailyPlan> dailyPlans = list.map((i) => DailyPlan.fromJson(i)).toList();
    return WeeklyPlan(
      planTitle: json['planTitle'] ?? "Haftalık Stratejik Plan",
      strategyFocus: json['strategyFocus'] ?? "Strateji belirlenemedi.",
      plan: dailyPlans,
    );
  }
}

class DailyPlan {
  final String day;
  final List<String> tasks;
  DailyPlan({required this.day, required this.tasks});

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    var tasksFromJson = json['tasks'] as List;
    List<String> taskList = tasksFromJson.cast<String>();
    return DailyPlan(day: json['day'], tasks: taskList);
  }
}

// State Provider'ları
final weeklyPlanProvider = StateProvider<WeeklyPlan?>((ref) => null);
final weeklyPlanNotifierProvider = StateNotifierProvider.autoDispose<WeeklyPlanNotifier, bool>((ref) {
  return WeeklyPlanNotifier(ref);
});

class WeeklyPlanNotifier extends StateNotifier<bool> {
  final Ref _ref;
  WeeklyPlanNotifier(this._ref) : super(false);

  Future<void> getWeeklyPlan() async {
    if (_ref.read(weeklyPlanProvider) != null) return;

    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;
    if (user == null) return;

    state = true;
    final resultJson = await _ref.read(aiServiceProvider).generateWeeklyPlan(user, tests ?? []);
    if (mounted) {
      try {
        final parsedPlan = WeeklyPlan.fromJson(jsonDecode(resultJson));
        _ref.read(weeklyPlanProvider.notifier).state = parsedPlan;
      } catch (e) {
        print("JSON Parse Hatası: $e");
        _ref.read(weeklyPlanProvider.notifier).state = WeeklyPlan.fromJson({"planTitle": "Hata", "strategyFocus": "Plan oluşturulurken bir sorun oluştu. Lütfen tekrar deneyin.", "plan": []});
      }
      state = false;
    }
  }
}

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(weeklyPlanProvider);
    final isLoading = ref.watch(weeklyPlanNotifierProvider);
    final user = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Haftalık Stratejik Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (plan == null)
            _buildActionButton(
              context: context,
              isLoading: isLoading,
              isDisabled: user == null,
              onPressed: () => ref.read(weeklyPlanNotifierProvider.notifier).getWeeklyPlan(),
              icon: Icons.schema_rounded,
              label: 'Stratejik Planımı Oluştur',
            )
          else
            _buildWeeklyPlanWidget(context, plan),

          if(isLoading && plan == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildWeeklyPlanWidget(BuildContext context, WeeklyPlan plan) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.planTitle, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.flag_circle_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(plan.strategyFocus, style: textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...plan.plan.map((dailyPlan) {
          int index = plan.plan.indexOf(dailyPlan);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: Theme.of(context).colorScheme.surface.withAlpha(150),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dailyPlan.day,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  ...dailyPlan.tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(Icons.check_box_outline_blank, size: 20, color: colorScheme.secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(task, style: const TextStyle(fontSize: 15, height: 1.4))),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (200 * (index + 1)).ms).slideY(begin: 0.2);
        }).toList(),
      ],
    ).animate().fadeIn();
  }

  // ✅ HATA DÜZELTİLDİ: Fonksiyonun sonuna 'return' ifadesi eklendi.
  Widget _buildActionButton({
    required BuildContext context,
    required bool isLoading,
    required bool isDisabled,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: isLoading || isDisabled ? null : onPressed,
      icon: isLoading ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
    );
  }
}