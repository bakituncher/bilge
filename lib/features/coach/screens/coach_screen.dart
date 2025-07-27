// lib/features/coach/screens/coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:go_router/go_router.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  // Geliştirilmesi gereken alanları hesaplayan fonksiyon
  Map<String, double> _calculateDevelopmentAreas(WidgetRef ref) {
    final tests = ref.watch(testsProvider).asData?.value ?? [];
    if (tests.isEmpty) return {};

    final subjectNets = <String, List<double>>{};

    for (var test in tests) {
      test.scores.forEach((subject, scores) {
        final net = scores['dogru']! - (scores['yanlis']! * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    final subjectAverages = subjectNets.map((subject, nets) {
      return MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length);
    });

    // Ortalamaya göre sırala
    final sortedSubjects = subjectAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Map.fromEntries(sortedSubjects);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devAreas = _calculateDevelopmentAreas(ref);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akıllı Koç'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Gelişim Alanların',
            style: textTheme.headlineSmall,
          ),
          Text(
            'En düşük net ortalamasına sahip derslerden başlayarak ilerlemen en doğrusu olacaktır.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          if (devAreas.isEmpty)
            const Center(
              child: Text('Analiz için henüz yeterli deneme verisi yok.'),
            )
          else
            ...devAreas.entries.map((entry) {
              return Animate(
                effects: const [FadeEffect(), SlideEffect(begin: Offset(-0.1, 0))],
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => context.go('/coach/subject-detail', extra: entry.key),
                    leading: const Icon(Icons.show_chart),
                    title: Text(entry.key),
                    trailing: Text(
                      'Ort: ${entry.value.toStringAsFixed(2)} Net',
                      style: textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary
                      ),
                    ),
                  ),
                ),
              );
            }).toList()
        ],
      ).animate().fadeIn(),
    );
  }
}