// lib/features/stats/widgets/analysis_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:bilge_ai/features/stats/screens/subject_stats_screen.dart';
import 'package:bilge_ai/features/stats/widgets/title_widget.dart';
import 'package:bilge_ai/features/stats/widgets/net_evolution_chart.dart';
import 'package:bilge_ai/features/stats/widgets/key_stats_grid.dart';
import 'package:bilge_ai/features/stats/widgets/ai_insight_card.dart';
import 'package:bilge_ai/features/stats/widgets/subject_stat_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/data/models/performance_summary.dart';

class AnalysisView extends ConsumerWidget {
  final List<TestModel> tests;
  final UserModel user;
  final Exam exam;

  const AnalysisView({required this.tests, required this.user, required this.exam, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = ref.watch(performanceProvider).value ?? const PerformanceSummary();
    final firestoreService = ref.watch(firestoreServiceProvider);
    // DÜZELTME: firestoreService eklendi
    final analysis = StatsAnalysis(tests, performance, exam, firestoreService, user: user);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const TitleWidget(title: 'Kader Tayfı', subtitle: 'Netlerinin ve doğruluğunun zamansal analizi'),
        NetEvolutionChart(analysis: analysis),
        const SizedBox(height: 24),
        const TitleWidget(title: 'Zafer Anıtları', subtitle: 'Genel performans metriklerin'),
        KeyStatsGrid(analysis: analysis),
        const SizedBox(height: 24),
        const TitleWidget(title: 'Komutan Emirleri', subtitle: 'Bilge Göz\'ün taktiksel raporu'),
        AiInsightCard(analysis: analysis),
        const SizedBox(height: 24),
        const TitleWidget(title: 'Fetih Haritası', subtitle: 'Ders kalelerine tıklayarak detaylı istihbarat al'),
        ...analysis.sortedSubjects.map((subjectEntry) {
          final subjectAnalysis = analysis.getAnalysisForSubject(subjectEntry.key);
          return SubjectStatCard(
            subjectName: subjectEntry.key,
            analysis: subjectAnalysis,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectStatsScreen(
                    subjectName: subjectEntry.key,
                    analysis: subjectAnalysis,
                  ),
                ),
              );
            },
          ).animate().fadeIn(delay: (100 * analysis.sortedSubjects.indexOf(subjectEntry)).ms).slideX(begin: -0.2);
        }).toList(),
      ].animate(interval: 100.ms).fadeIn(duration: 400.ms),
    );
  }
}