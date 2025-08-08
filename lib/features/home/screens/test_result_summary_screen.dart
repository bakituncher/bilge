// lib/features/home/screens/test_result_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/home/logic/test_summary_logic.dart';
import 'package:bilge_ai/features/home/widgets/summary_widgets/verdict_card.dart';
import 'package:bilge_ai/features/home/widgets/summary_widgets/key_stats_row.dart';
import 'package:bilge_ai/features/home/widgets/summary_widgets/subject_highlights.dart';

class TestResultSummaryScreen extends StatelessWidget {
  final TestModel test;

  const TestResultSummaryScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final summaryLogic = TestSummaryLogic(test);
    final wisdomScore = summaryLogic.calculateWisdomScore();
    final verdict = summaryLogic.getExpertVerdict(wisdomScore);
    final keySubjects = summaryLogic.findKeySubjects();

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
        ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.dashboard_customize_rounded),
          label: const Text("Ana Panele Dön"),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
    );
  }
}