// lib/features/home/screens/test_result_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/home/widgets/summary_widgets/verdict_card.dart';
import 'package:bilge_ai/features/home/widgets/summary_widgets/key_stats_row.dart';
import 'package:bilge_ai/features/home/widgets/summary_widgets/subject_highlights.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';

class TestResultSummaryScreen extends StatelessWidget {
  final TestModel test;

  const TestResultSummaryScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final wisdomScore = test.wisdomScore;
    final verdict = test.expertVerdict;
    final keySubjects = test.findKeySubjects();
    final isGoodResult = wisdomScore > 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Savaş Raporu"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          VerdictCard(verdict: verdict, wisdomScore: wisdomScore),
          const SizedBox(height: 24),
          KeyStatsRow(test: test),
          const SizedBox(height: 24),
          if (keySubjects.isNotEmpty)
            SubjectHighlights(keySubjects: keySubjects),
          const SizedBox(height: 24),
          // YENİ EKLENEN BUTONLAR
          OutlinedButton.icon(
              icon: const Icon(Icons.forum_rounded),
              label: Text(isGoodResult ? "Zaferi Kutla!" : "Durumu Değerlendir"),
              style: OutlinedButton.styleFrom(
                foregroundColor: isGoodResult ? AppTheme.successColor : AppTheme.secondaryColor,
                side: BorderSide(color: isGoodResult ? AppTheme.successColor : AppTheme.secondaryColor),
              ),
              onPressed: () {
                final prompt = isGoodResult ? 'new_test_good' : 'new_test_bad';
                context.push('${AppRoutes.aiHub}/${AppRoutes.motivationChat}', extra: prompt);
              }
          )
        ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.dashboard_customize_rounded),
          label: const Text("Ana Panele Dön"),
          onPressed: () => context.go('/home'),
        ),
      ),
    );
  }
}