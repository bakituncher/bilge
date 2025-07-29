// lib/features/coach/screens/ai_coach_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart'; // Model için import

// State Provider'ları
final coachingSessionProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class AiCoachNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AiCoachNotifier(this._ref) : super(false);

  Future<void> getCoachingSession() async {
    // Veri zaten yüklüyse tekrar çekme
    if (_ref.read(coachingSessionProvider) != null) return;

    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;
    if (user == null || tests == null || tests.isEmpty) return;

    state = true;
    try {
      // ✅ HATA GİDERİLDİ: Artık birleşik metot çağrılıyor.
      final resultJson = await _ref.read(aiServiceProvider).getCoachingSession(user, tests);
      if (mounted) {
        _ref.read(coachingSessionProvider.notifier).state = jsonDecode(resultJson);
      }
    } catch (e) {
      if (mounted) {
        // Hata durumunda state'i de güncelle
        _ref.read(coachingSessionProvider.notifier).state = {
          "error": "Analiz oluşturulurken bir hata oluştu: ${e.toString()}"
        };
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }
}

final aiCoachNotifierProvider = StateNotifierProvider<AiCoachNotifier, bool>((ref) {
  return AiCoachNotifier(ref);
});


class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionData = ref.watch(coachingSessionProvider);
    final isLoading = ref.watch(aiCoachNotifierProvider);
    final user = ref.watch(userProfileProvider).value;
    final tests = ref.watch(testsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Stratejik Koçluk')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (sessionData == null)
            _buildActionButton(
              context: context,
              isLoading: isLoading,
              isDisabled: user == null || tests == null || tests.isEmpty,
              onPressed: () => ref.read(aiCoachNotifierProvider.notifier).getCoachingSession(),
              icon: Icons.auto_awesome,
              label: 'Analiz ve Plan Oluştur',
            )
          else if (sessionData.containsKey("error"))
            _buildErrorCard(sessionData["error"])
          else
            _buildSessionContent(context, sessionData),


          if(isLoading && sessionData == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
        color: Colors.red.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Hata: $error"),
        )
    );
  }

  Widget _buildSessionContent(BuildContext context, Map<String, dynamic> sessionData) {
    final analysisReport = sessionData['analysisReport'] as String?;
    final weeklyPlanData = sessionData['weeklyPlan'] as Map<String, dynamic>?;
    final plan = weeklyPlanData != null ? WeeklyPlan.fromJson(weeklyPlanData) : null;

    return Column(
      children: [
        _buildSectionHeader(context, 'Kişisel Analiz ve Tavsiyeler', Icons.insights_rounded),
        const SizedBox(height: 16),
        if (analysisReport != null)
          _buildMarkdownCard(analysisReport),

        const SizedBox(height: 32),

        _buildSectionHeader(context, 'Haftalık Çalışma Planın', Icons.calendar_today_rounded),
        const SizedBox(height: 16),
        if (plan != null)
          _buildWeeklyPlanWidget(context, plan)
        else
          const Text("Haftalık plan oluşturulamadı."),
      ],
    );
  }

  Widget _buildWeeklyPlanWidget(BuildContext context, WeeklyPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.flag_circle_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(plan.strategyFocus, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...plan.plan.map((dailyPlan) {
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(Icons.check_box_outline_blank, size: 20, color: Colors.grey[600]),
                        ),
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
      ],
    ).animate().fadeIn();
  }

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