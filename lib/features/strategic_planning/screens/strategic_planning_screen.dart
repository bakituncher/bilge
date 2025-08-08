// lib/features/strategic_planning/screens/strategic_planning_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
import 'package:intl/intl.dart';

enum Pacing { relaxed, moderate, intense }
enum PlanningStep { dataCheck, confirmation, pacing, loading }

final selectedPacingProvider = StateProvider<Pacing>((ref) => Pacing.moderate);
final planningStepProvider = StateProvider<PlanningStep>((ref) => PlanningStep.dataCheck);

// Plan oluşturma Notifier'ı
class StrategyGenerationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  StrategyGenerationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generatePlan(BuildContext context) async {
    state = const AsyncValue.loading();
    _ref.read(planningStepProvider.notifier).state = PlanningStep.loading;

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

      final result = {
        'longTermStrategy': decodedData['longTermStrategy'],
        'weeklyPlan': decodedData['weeklyPlan'],
        'pacing': pacing.name,
      };

      if (context.mounted) {
        context.go('/ai-hub/strategic-planning/${AppRoutes.strategyReview}', extra: result);
      }

      _ref.read(planningStepProvider.notifier).state = PlanningStep.dataCheck;
      state = const AsyncValue.data(null);
    } catch (e, s) {
      _ref.read(planningStepProvider.notifier).state = PlanningStep.pacing;
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
    final userAsync = ref.watch(userProfileProvider);
    final tests = ref.watch(testsProvider).valueOrNull;
    final step = ref.watch(planningStepProvider);

    ref.listen<AsyncValue<void>>(strategyGenerationProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentColor,
            content: Text('Strateji oluşturulurken bir hata oluştu: ${state.error}'),
          ),
        );
      }
    });

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text("Kullanıcı verisi bulunamadı.")));
        }

        if (user.longTermStrategy != null && user.weeklyPlan != null) {
          if(step != PlanningStep.confirmation && step != PlanningStep.pacing && step != PlanningStep.loading) {
            return _buildStrategyDisplay(context, ref, user);
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Strateji Oturumu')),
          body: AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildStep(context, ref, step, tests?.isNotEmpty ?? false),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))),
      error: (e, s) => Scaffold(body: Center(child: Text("Hata: $e"))),
    );
  }

  Widget _buildStep(BuildContext context, WidgetRef ref, PlanningStep step, bool hasTests) {
    if (!hasTests) {
      return _buildDataMissingView(context);
    }

    if (step == PlanningStep.dataCheck && hasTests) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(planningStepProvider.notifier).state = PlanningStep.confirmation;
      });
      return const SizedBox.shrink();
    }

    switch (step) {
      case PlanningStep.confirmation:
        return _buildConfirmationView(context, ref);
      case PlanningStep.pacing:
        return _buildPacingView(context, ref);
      case PlanningStep.loading:
        return const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor));
      default:
        return const SizedBox.shrink();
    }
  }

  // *******************************************************************
  // * HATANIN ÇÖZÜLDÜĞÜ YER *
  // *******************************************************************
  Widget _buildStrategyDisplay(BuildContext context, WidgetRef ref, UserModel user) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stratejik Planın Hazır")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_moon_rounded, size: 80, color: AppTheme.successColor),
              const SizedBox(height: 24),
              Text(
                "Mevcut Bir Stratejin Var",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Uzun vadeli zafer planın ve bu haftaki görevlerin zaten belirlenmiş. Komuta merkezinden planını takip edebilirsin.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                // Yönlendirme komutu, tam yolu içerecek şekilde düzeltildi.
                onPressed: () => context.push('${AppRoutes.aiHub}/${AppRoutes.commandCenter}', extra: user),
                icon: const Icon(Icons.map_rounded),
                label: const Text("Komuta Merkezine Git"),
              ),
              TextButton(
                  onPressed: () {
                    ref.read(planningStepProvider.notifier).state = PlanningStep.confirmation;
                  },
                  child: const Text("Yeni Strateji Oluştur"))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataMissingView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.report_problem_outlined, color: Colors.amber, size: 64),
            const SizedBox(height: 24),
            Text(
              "Strateji İçin Veri Gerekli",
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
              onPressed: () => context.push('/home/add-test'),
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text("İlk Denemeni Ekle"),
            )
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildConfirmationView(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider).valueOrNull ?? [];
    final lastTestDate = tests.isNotEmpty ? DateFormat.yMMMMd('tr').format(tests.first.date) : "N/A";

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          "Stratejiyi oluşturmadan önce, her şeyin güncel olduğundan emin olalım:",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),
        _ConfirmationItem(
          icon: Icons.edit_calendar_rounded,
          question: "Zaman haritan güncel mi?",
          description: "Planın, sadece belirlediğin müsait zamanlara göre oluşturulacak.",
          buttonText: "Haritayı Gözden Geçir",
          onTap: () => context.push(AppRoutes.availability),
        ),
        _ConfirmationItem(
          icon: Icons.auto_awesome,
          question: "Bilgi Galaksin güncel mi?",
          description: "Konu hakimiyet verilerin, bu hafta hangi konulara odaklanacağımızı belirleyecek.",
          buttonText: "Galaksiyi Ziyaret Et",
          onTap: () => context.push('/ai-hub/${AppRoutes.coachPushed}'),
        ),
        _ConfirmationItem(
          icon: Icons.history_edu_rounded,
          question: "Deneme sonuçların güncel mi?",
          description: "Son denemen $lastTestDate tarihinde eklendi. Yeni bir deneme eklemek, planı daha isabetli yapar.",
          buttonText: "Yeni Deneme Ekle",
          onTap: () => context.push('/home/add-test'),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            ref.read(planningStepProvider.notifier).state = PlanningStep.pacing;
          },
          child: const Text("Her Şey Güncel, İlerle"),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPacingView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed_rounded, size: 64, color: AppTheme.secondaryColor),
            const SizedBox(height: 24),
            Text(
              "Bu Haftanın Temposu Ne Olsun?",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ToggleButtons(
              isSelected: Pacing.values.map((p) => p == ref.watch(selectedPacingProvider)).toList(),
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
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => ref.read(strategyGenerationProvider.notifier).generatePlan(context),
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Stratejiyi Oluştur"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
            TextButton(
                onPressed: () {
                  ref.read(planningStepProvider.notifier).state = PlanningStep.confirmation;
                },
                child: const Text("Geri Dön"))
          ],
        ),
      ),
    );
  }
}

class _ConfirmationItem extends StatelessWidget {
  final IconData icon;
  final String question;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  const _ConfirmationItem({
    required this.icon,
    required this.question,
    required this.description,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(icon, color: AppTheme.secondaryTextColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(question, style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36.0),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}