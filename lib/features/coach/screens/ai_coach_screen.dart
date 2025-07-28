// lib/features/coach/screens/ai_coach_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Model Sınıfları
class WeeklyPlan {
  final List<DailyPlan> plan;
  WeeklyPlan({required this.plan});

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    var list = json['plan'] as List;
    List<DailyPlan> dailyPlans = list.map((i) => DailyPlan.fromJson(i)).toList();
    return WeeklyPlan(plan: dailyPlans);
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
final recommendationProvider = StateProvider<String?>((ref) => null);
final weeklyPlanProvider = StateProvider<WeeklyPlan?>((ref) => null); // Artık model tutacak
final isLoadingProvider = StateProvider<bool>((ref) => false);


// Bu ekranın state'ini yöneten Notifier.
class AiCoachNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AiCoachNotifier(this._ref) : super(false);

  Future<void> getRecommendations() async {
    // Önbellekte varsa tekrar isteme
    if (_ref.read(recommendationProvider) != null) return;

    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;
    if (user == null || tests == null || tests.isEmpty) return;

    state = true;
    final result = await _ref.read(aiServiceProvider).getAIRecommendations(user, tests);
    _ref.read(recommendationProvider.notifier).state = result;
    state = false;
  }

  Future<void> getWeeklyPlan() async {
    // Önbellekte varsa tekrar isteme
    if (_ref.read(weeklyPlanProvider) != null) return;

    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;
    if (user == null || tests == null) return;

    state = true;
    final resultJson = await _ref.read(aiServiceProvider).generateWeeklyPlan(user, tests);
    try {
      final cleanJson = resultJson.replaceAll("```json", "").replaceAll("```", "").trim();
      final parsedPlan = WeeklyPlan.fromJson(jsonDecode(cleanJson));
      _ref.read(weeklyPlanProvider.notifier).state = parsedPlan;
    } catch (e) {
      print("JSON Parse Hatası: $e");
      _ref.read(weeklyPlanProvider.notifier).state = WeeklyPlan.fromJson({"plan": [{"day": "Hata", "tasks": ["Plan oluşturulamadı."]}]});
    }
    state = false;
  }
}

final aiCoachNotifierProvider = StateNotifierProvider<AiCoachNotifier, bool>((ref) {
  return AiCoachNotifier(ref);
});


class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(recommendationProvider);
    final plan = ref.watch(weeklyPlanProvider);
    final isLoading = ref.watch(aiCoachNotifierProvider); // isLoadingProvider yerine aiCoachNotifierProvider kullanılıyor
    final user = ref.watch(userProfileProvider).value;
    final tests = ref.watch(testsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Yapay Zeka Koçu')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Kişisel Analiz ve Tavsiyeler', Icons.insights_rounded),
          const SizedBox(height: 16),
          if (recommendation == null)
            _buildActionButton(
              context: context,
              isLoading: isLoading,
              isDisabled: user == null || tests == null || tests.isEmpty,
              onPressed: () => ref.read(aiCoachNotifierProvider.notifier).getRecommendations(),
              icon: Icons.auto_awesome,
              label: 'Analiz Oluştur',
            )
          else
            _buildMarkdownCard(recommendation),

          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Haftalık Çalışma Planın', Icons.calendar_today_rounded),
          const SizedBox(height: 16),
          if (plan == null)
            _buildActionButton(
              context: context,
              isLoading: isLoading,
              isDisabled: user == null || tests == null,
              onPressed: () => ref.read(aiCoachNotifierProvider.notifier).getWeeklyPlan(),
              icon: Icons.schema_rounded,
              label: 'Planımı Oluştur',
            )
          else
            _buildWeeklyPlanWidget(plan),

          if(isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  // YENİ WIDGET: Haftalık planı gösterir.
  Widget _buildWeeklyPlanWidget(WeeklyPlan plan) {
    return Column(
      children: plan.plan.map((dailyPlan) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dailyPlan.day,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(height: 20),
                ...dailyPlan.tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outline_blank, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(child: Text(task, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn();
  }

  // Diğer widget'lar aynı
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

  Widget _buildMarkdownCard(String? content) {
    return Card(
      elevation: 0,
      color: Colors.blueGrey.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MarkdownBody(
          data: content ?? "Veri yükleniyor...",
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 15, height: 1.5),
            h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}