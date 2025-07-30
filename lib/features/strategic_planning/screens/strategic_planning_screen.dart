// lib/features/strategic_planning/screens/strategic_planning_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/features/coach/screens/ai_coach_screen.dart'; // aiAnalysisProvider'ı güncellemek için
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';

enum Pacing { relaxed, moderate, intense }

final selectedPacingProvider = StateProvider<Pacing>((ref) => Pacing.moderate);

class StrategyGenerationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  StrategyGenerationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generatePlan() async {
    state = const AsyncValue.loading();

    final pacing = _ref.read(selectedPacingProvider);
    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;

    if (user == null || tests == null) {
      state = AsyncValue.error("Kullanıcı veya test verisi bulunamadı.", StackTrace.current);
      return;
    }

    try {
      final resultJson = await _ref.read(aiServiceProvider).generateGrandStrategy(
        user: user,
        tests: tests,
        pacing: pacing.name,
      );

      final decodedData = jsonDecode(resultJson);

      if (decodedData.containsKey('error')) {
        throw Exception(decodedData['error']);
      }

      final longTermStrategy = decodedData['longTermStrategy'];
      final weeklyPlan = decodedData['weeklyPlan'];

      await _ref.read(firestoreServiceProvider).updateStrategicPlan(
        userId: user.id,
        pacing: pacing.name,
        longTermStrategy: longTermStrategy,
      );

      final newSignature = "${user.id}_${tests.length}_${user.topicPerformances.hashCode}";
      _ref.read(aiAnalysisProvider.notifier).state = (signature: newSignature, data: {"weeklyPlan": weeklyPlan, "longTermStrategy": longTermStrategy});

      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final strategyGenerationProvider = StateNotifierProvider.autoDispose<StrategyGenerationNotifier, AsyncValue<void>>((ref) {
  return StrategyGenerationNotifier(ref);
});

class StrategicPlanningScreen extends ConsumerWidget {
  const StrategicPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final generationState = ref.watch(strategyGenerationProvider);
    final analysis = ref.watch(aiAnalysisProvider);

    if (user?.longTermStrategy != null && !generationState.isLoading) {
      return _buildStrategyDisplay(context, user!.longTermStrategy!, analysis?.data['weeklyPlan']);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stratejik Planlama Atölyesi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.architecture_rounded, size: 64, color: AppTheme.secondaryColor),
              const SizedBox(height: 24),
              Text(
                "Zafer Stratejini Oluştur",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                "Sınav gününe kadar seni başarıya götürecek yol haritanı çizelim. Lütfen çalışma temponu seç.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildPacingSelector(context, ref),
              const SizedBox(height: 48),
              generationState.when(
                data: (_) => ElevatedButton.icon(
                  onPressed: () => ref.read(strategyGenerationProvider.notifier).generatePlan(),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("Stratejiyi Oluştur"),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
                loading: () => const CircularProgressIndicator(color: AppTheme.secondaryColor),
                error: (e,s) => Column(
                  children: [
                    Text("Hata: $e", style: const TextStyle(color: AppTheme.accentColor)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(strategyGenerationProvider.notifier).generatePlan(),
                      child: const Text("Tekrar Dene"),
                    ),
                  ],
                ),
              )
            ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildPacingSelector(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPacingProvider);
    return ToggleButtons(
      isSelected: Pacing.values.map((p) => p == selected).toList(),
      onPressed: (index) {
        ref.read(selectedPacingProvider.notifier).state = Pacing.values[index];
      },
      borderRadius: BorderRadius.circular(16),
      selectedColor: AppTheme.primaryColor,
      color: Colors.white,
      fillColor: AppTheme.secondaryColor,
      selectedBorderColor: AppTheme.secondaryColor,
      borderColor: AppTheme.lightSurfaceColor,
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Rahat')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Dengeli')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Yoğun')),
      ],
    );
  }

  Widget _buildStrategyDisplay(BuildContext context, String longTermStrategy, Map<String, dynamic>? weeklyPlanData) {
    final plan = weeklyPlanData != null ? WeeklyPlan.fromJson(weeklyPlanData) : null;
    return Scaffold(
      appBar: AppBar(title: const Text("Stratejik Koçluk")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Büyük Strateji", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                  data: longTermStrategy,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16),
                      h2: const TextStyle(color: AppTheme.secondaryColor, fontSize: 22)
                  )
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text("Bu Haftanın Harekat Planı", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (plan != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.strategyFocus, style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.secondaryTextColor)),
                    const Divider(height: 24, color: AppTheme.lightSurfaceColor),
                    ...plan.plan.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                          ...d.tasks.map((t) => Text("- $t", style: const TextStyle(color: AppTheme.textColor, height: 1.5)))
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            )
          else
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Haftalık plan yüklenemedi."))),
        ],
      ).animate().fadeIn(),
    );
  }
}