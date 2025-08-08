// lib/features/strategic_planning/screens/strategic_planning_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/plan_model.dart'; // DÜZELTİLDİ: Yeni model yolu
import 'package:bilge_ai/data/models/user_model.dart';

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
        weeklyPlan: weeklyPlan,
      );

      // ignore: unused_result
      _ref.refresh(userProfileProvider);

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
    final tests = ref.watch(testsProvider).valueOrNull;
    final generationState = ref.watch(strategyGenerationProvider);

    ref.listen<AsyncValue<void>>(strategyGenerationProvider, (_, state) {
      if (state.isLoading) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryColor),
          ),
        );
      } else if (state.hasError) {
        if(Navigator.of(context).canPop()) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${state.error.toString()}')),
        );
      } else if (state.hasValue) {
        if(Navigator.of(context).canPop()) Navigator.pop(context);
      }
    });

    if (tests == null || tests.isEmpty) {
      return _buildDataMissingView(context);
    }

    if (user?.longTermStrategy != null && !generationState.isLoading) {
      return _buildStrategyDisplay(context, ref);
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
              ElevatedButton.icon(
                onPressed: () => ref.read(strategyGenerationProvider.notifier).generatePlan(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("Stratejiyi Oluştur"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              ),
            ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildDataMissingView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stratejik Planlama Atölyesi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.report_problem_outlined, color: Colors.amber, size: 64),
              const SizedBox(height: 24),
              Text(
                "Yetersiz İstihbarat",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Sana özel bir strateji oluşturabilmem için önce düşmanı tanımam gerek. Lütfen en az bir deneme sonucu ekle.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/home/add-test'),
                icon: const Icon(Icons.add_chart_rounded),
                label: const Text("Deneme Ekle"),
              )
            ],
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

  Widget _buildStrategyDisplay(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text("Kullanıcı verisi bulunamadı.")));

    final plan = user.weeklyPlan != null ? WeeklyPlan.fromJson(user.weeklyPlan!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Stratejik Koçluk")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(strategyGenerationProvider.notifier).generatePlan();
        },
        label: const Text("Yeniden Oluştur"),
        icon: const Icon(Icons.refresh_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shadowColor: AppTheme.secondaryColor.withOpacity(0.2),
            child: InkWell(
              onTap: () => context.push('/ai-hub/command-center', extra: user),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, size: 40, color: AppTheme.secondaryColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Komuta Merkezi", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Uzun vadeli zafer stratejini ve harekât aşamalarını görüntüle.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(plan?.planTitle ?? "Bu Haftanın Harekat Planı", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (plan != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.strategyFocus, style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.secondaryTextColor, fontSize: 16)),
                    const Divider(height: 24, color: AppTheme.lightSurfaceColor),
                    ...plan.plan.map((dailyPlan) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dailyPlan.day,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            if (dailyPlan.schedule.isNotEmpty)
                              ...dailyPlan.schedule.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item.time}:",
                                        style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.activity,
                                          style: const TextStyle(color: AppTheme.secondaryTextColor, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList()
                            else
                              Text(
                                dailyPlan.rawScheduleString ?? "Bu gün için özel bir görev belirtilmemiş.",
                                style: const TextStyle(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            )
          else
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Haftalık plan yüklenemedi."))),

          const SizedBox(height: 80),
        ],
      ).animate().fadeIn(),
    );
  }
}