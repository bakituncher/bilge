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

  Future<void> _generateAndNavigate(BuildContext context, {String? revisionRequest}) async {
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
        revisionRequest: revisionRequest,
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
        context.push('/ai-hub/strategic-planning/${AppRoutes.strategyReview}', extra: result);
      }

      _ref.read(planningStepProvider.notifier).state = PlanningStep.dataCheck;
      state = const AsyncValue.data(null);
    } catch (e, s) {
      _ref.read(planningStepProvider.notifier).state = PlanningStep.pacing;
      state = AsyncValue.error(e, s);
    }
  }


  Future<void> generatePlan(BuildContext context) async {
    await _generateAndNavigate(context);
  }

  Future<void> regeneratePlanWithFeedback(BuildContext context, String feedback) async {
    await _generateAndNavigate(context, revisionRequest: feedback);
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
        return Center(
            key: const ValueKey('loading'),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppTheme.secondaryColor),
                  const SizedBox(height: 24),
                  Text("Strateji güncelleniyor,\nbekleyin komutanım...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16)
                  )
                ]
            )
        );
      default:
        return const SizedBox.shrink();
    }
  }

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
    final user = ref.watch(userProfileProvider).value;
    final tests = ref.watch(testsProvider).valueOrNull ?? [];
    if(user == null) return const Center(child: CircularProgressIndicator());

    final totalHours = user.weeklyAvailability.values.expand((slots) => slots).length * 2;
    final analyzedTopicsCount = user.topicPerformances.values.expand((subject) => subject.values).where((topic) => topic.questionCount > 3).length;
    final isTimeMapOk = totalHours >= 10;
    final isGalaxyOk = analyzedTopicsCount >= 5;

    final lastTestDate = tests.isNotEmpty ? tests.first.date : null;
    String testStatusText;
    bool isTestsOk;

    if (lastTestDate == null) {
      testStatusText = "Hiç deneme eklenmemiş";
      isTestsOk = false;
    } else {
      final daysSinceLastTest = DateTime.now().difference(lastTestDate).inDays;
      if (daysSinceLastTest == 0) {
        testStatusText = "Bugün eklendi";
      } else if (daysSinceLastTest == 1) {
        testStatusText = "Dün eklendi";
      } else {
        testStatusText = "$daysSinceLastTest gün önce";
      }
      isTestsOk = daysSinceLastTest <= 7;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Harekat Öncesi Son Kontrol",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "En isabetli strateji için tüm verilerinin güncel olduğundan emin olalım.",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor),
                ),
                const SizedBox(height: 32),

                _ChecklistItemCard(
                  icon: Icons.map_rounded,
                  title: "Zaman Haritası",
                  description: "Stratejin, haftalık olarak ayırdığın zamana göre şekillenecek.",
                  statusText: "$totalHours Saat",
                  statusDescription: "Haftalık Plan",
                  statusColor: isTimeMapOk ? AppTheme.successColor : Colors.amber,
                  buttonText: "Güncelle",
                  onTap: () => context.push(AppRoutes.availability),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                _ChecklistItemCard(
                  icon: Icons.insights_rounded,
                  title: "Bilgi Galaksisi",
                  description: "Konu hakimiyetin, bu hafta hangi konulara odaklanacağımızı belirleyecek.",
                  statusText: "$analyzedTopicsCount",
                  statusDescription: "Konu Analiz Edildi",
                  statusColor: isGalaxyOk ? AppTheme.successColor : Colors.amber,
                  buttonText: "Ziyaret Et",
                  onTap: () => context.push('/ai-hub/${AppRoutes.coachPushed}'),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                _ChecklistItemCard(
                  icon: Icons.history_edu_rounded,
                  title: "Deneme Arşivi",
                  description: "Güncel deneme sonuçların, planın isabet oranını doğrudan etkiler.",
                  statusText: "Son Deneme",
                  statusDescription: testStatusText,
                  statusColor: isTestsOk ? AppTheme.successColor : Colors.amber,
                  buttonText: "Yeni Ekle",
                  onTap: () => context.push('/home/add-test'),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),

              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              ref.read(planningStepProvider.notifier).state = PlanningStep.pacing;
            },
            child: const Text("Tüm Verilerim Güncel, İlerle"),
          ),
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


// =======================================================================
// YENİDEN TASARLANMIŞ, "NİRVANA" KART WIDGET'I
// =======================================================================
class _ChecklistItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusText;
  final String statusDescription;
  final Color statusColor;
  final String buttonText;
  final VoidCallback onTap;

  const _ChecklistItemCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusText,
    required this.statusDescription,
    required this.statusColor,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: Başlık ve Açıklama
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppTheme.secondaryTextColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Alt Kısım: Durum ve Eylem
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.lightSurfaceColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Durum Göstergesi
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: textTheme.headlineSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          statusDescription,
                          style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Eylem Butonu
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}