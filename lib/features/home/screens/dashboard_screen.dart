// lib/features/home/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/core/constants/app_constants.dart';
import 'package:bilge_ai/features/coach/screens/ai_coach_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'Tünaydın';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            userAsync.when(
              data: (user) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, ${user?.name?.split(' ').first ?? ''}!',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('Bugün hedeflerine bir adım daha yaklaş.', style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Başarı Günlüğüm',
                    onPressed: () => context.go('/home/journal'),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (e,s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _buildTodaysPlanCard(context, ref),
            const SizedBox(height: 24),
            testsAsync.when(
              data: (tests) {
                double avgNet = tests.isNotEmpty ? tests.map((t) => t.totalNet).reduce((a, b) => a + b) / tests.length : 0;
                double bestNet = tests.isNotEmpty ? tests.map((t) => t.totalNet).reduce((a, b) => a > b ? a : b) : 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatSnapshotCard('Ortalama Net', avgNet.toStringAsFixed(2), Icons.track_changes_rounded, context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatSnapshotCard('En Yüksek Net', bestNet.toStringAsFixed(2), Icons.emoji_events_rounded, context)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Son Denemeler', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // ✅ UX GELİŞTİRMESİ: Kullanıcıya yol gösteren "Boş Durum" tasarımı eklendi.
                    if (tests.isEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1)
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.add_chart_rounded, size: 40, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(height: 12),
                              Text(
                                'İlk Denemeni Ekle',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Performansını takip etmeye ve yapay zekadan tavsiye almaya başlamak için ilk deneme sonucunu gir.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/home/add-test'),
                                child: const Text('Hadi Başlayalım!'),
                              )
                            ],
                          ),
                        ),
                      )
                    else
                      ...tests.take(3).map((test) =>
                          Animate(
                            effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
                            child: _buildTestCard(context, test),
                          )
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
            )
          ],
        ).animate().fadeIn(duration: kMediumAnimationDuration),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => context.go('/home/add-test'),
        label: const Text('Deneme Ekle'),
        icon: const Icon(Icons.add),
      ).animate().slide(begin: const Offset(0, 2)).fadeIn(),
    );
  }

  Widget _buildTodaysPlanCard(BuildContext context, WidgetRef ref) {
    final weeklyPlan = ref.watch(weeklyPlanProvider);
    final dayOfWeek = DateFormat('EEEE', 'tr_TR').format(DateTime.now());

    DailyPlan? todaysPlan;
    if (weeklyPlan != null) {
      todaysPlan = weeklyPlan.plan.firstWhere((p) => p.day == dayOfWeek, orElse: () => DailyPlan(day: dayOfWeek, tasks: []));
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünün Planı ($dayOfWeek)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (todaysPlan != null && todaysPlan.tasks.isNotEmpty)
              ...todaysPlan.tasks.map((task) => _buildPlanItem(context, task, false))
            else
              Text(
                "Yapay zeka koçundan henüz bir plan oluşturmadın. Koç sekmesinden haftalık planını oluşturarak görevlerini burada görebilirsin.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, String text, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSnapshotCard(String label, String value, IconData icon, BuildContext context){
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.secondary),
            const SizedBox(height: 8),
            Text(label, style: textTheme.bodyMedium),
            Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        onTap: () => context.go('/home/test-detail', extra: test),
        title: Text(test.testName),
        subtitle: Text('${test.examType.displayName} - ${DateFormat.yMMMMd('tr').format(test.date)}'),
        trailing: Text(
          test.totalNet.toStringAsFixed(2),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
    );
  }
}