// lib/features/home/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgelik Kütüphanesi'),
      ),
      body: testsAsync.when(
        data: (tests) {
          if (tests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_edu_rounded, size: 80, color: AppTheme.secondaryTextColor),
                  const SizedBox(height: 16),
                  Text('Kütüphanen henüz boş.', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Eklediğin her deneme, burada bir bilgelik parşömenine dönüşecek.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return _TestMemoryCard(test: test)
                  .animate()
                  .fadeIn(delay: (100 * (index % 10)).ms, duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Hata: ${e.toString()}')),
      ),
    );
  }
}

class _TestMemoryCard extends StatelessWidget {
  final TestModel test;
  const _TestMemoryCard({required this.test});

  double _calculateWisdomScore() {
    if (test.totalQuestions == 0) return 0;
    double netContribution = (test.totalNet / test.totalQuestions) * 60;
    final attemptedQuestions = test.totalCorrect + test.totalWrong;
    double accuracyContribution = attemptedQuestions > 0 ? (test.totalCorrect / attemptedQuestions) * 25 : 0;
    double effortContribution = (attemptedQuestions / test.totalQuestions) * 15;
    double totalScore = netContribution + accuracyContribution + effortContribution;
    return totalScore.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final wisdomScore = _calculateWisdomScore();
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/home/test-result-summary', extra: test),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: wisdomScore / 100,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.lightSurfaceColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(AppTheme.accentColor, AppTheme.successColor, wisdomScore / 100)!,
                      ),
                    ),
                    Center(
                      child: Text(
                        wisdomScore.toInt().toString(),
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.testName,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMMd('tr').format(test.date),
                      style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}