// lib/features/strategic_planning/screens/strategy_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/features/strategic_planning/screens/strategic_planning_screen.dart';

class StrategyReviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> generationResult;
  const StrategyReviewScreen({super.key, required this.generationResult});

  @override
  ConsumerState<StrategyReviewScreen> createState() =>
      _StrategyReviewScreenState();
}

class _StrategyReviewScreenState extends ConsumerState<StrategyReviewScreen> {
  late WeeklyPlan weeklyPlan;
  late String longTermStrategy;
  late String pacing;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _initializePlan();
  }

  void _initializePlan() {
    weeklyPlan = WeeklyPlan.fromJson(widget.generationResult['weeklyPlan']);
    longTermStrategy = widget.generationResult['longTermStrategy'];
    pacing = widget.generationResult['pacing'];
  }

  void _approvePlan() {
    final userId = ref.read(authControllerProvider).value!.uid;
    ref.read(firestoreServiceProvider).updateStrategicPlan(
      userId: userId,
      pacing: pacing,
      longTermStrategy: longTermStrategy,
      weeklyPlan: widget.generationResult['weeklyPlan'],
    );
    // ignore: unused_result
    ref.refresh(userProfileProvider);
    context.go('/home');
  }

  void _requestRevision() {
    // TODO: Bu kısım, AI'a revizyon isteği gönderecek olan daha gelişmiş
    // bir diyalog penceresi veya ekran ile değiştirilebilir.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Revizyon özelliği yakında aktif olacak!"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Zafer Yolu Çizildi!",
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      "İşte sana özel hazırlanan haftalık harekat planın. İncele ve onayla.",
                      style: textTheme.titleMedium
                          ?.copyWith(color: AppTheme.secondaryTextColor)),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
            SizedBox(
              height: 400, // Önizleme alanının yüksekliği
              child: PageView.builder(
                controller: _pageController,
                itemCount: weeklyPlan.plan.length,
                itemBuilder: (context, index) {
                  final dailyPlan = weeklyPlan.plan[index];
                  return _DailyPlanCard(dailyPlan: dailyPlan)
                      .animate()
                      .fadeIn(delay: (100 * index).ms)
                      .slideX(begin: 0.5);
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _requestRevision,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.secondaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Revizyon İste"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _approvePlan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Onayla ve Başla"),
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

class _DailyPlanCard extends StatelessWidget {
  final DailyPlan dailyPlan;
  const _DailyPlanCard({required this.dailyPlan});

  IconData _getIconForTaskType(String type) {
    switch (type.toLowerCase()) {
      case 'study': return Icons.book_rounded;
      case 'practice': case 'routine': return Icons.edit_note_rounded;
      case 'test': return Icons.quiz_rounded;
      case 'review': return Icons.history_edu_rounded;
      case 'break': return Icons.self_improvement_rounded;
      default: return Icons.shield_moon_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dailyPlan.day,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppTheme.secondaryColor),
            ),
            const Divider(height: 24),
            Expanded(
              child: dailyPlan.schedule.isEmpty
                  ? Center(
                child: Text(
                  "Bugün dinlenme ve strateji gözden geçirme günü. Zihnini dinlendir, yarınki fethe hazırlan!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.secondaryTextColor),
                ),
              )
                  : ListView.builder(
                itemCount: dailyPlan.schedule.length,
                itemBuilder: (context, index) {
                  final item = dailyPlan.schedule[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(_getIconForTaskType(item.type),
                              size: 20, color: AppTheme.secondaryTextColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.activity, style: Theme.of(context).textTheme.bodyLarge),
                              Text(item.time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
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