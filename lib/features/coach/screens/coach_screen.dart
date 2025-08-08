// lib/features/coach/screens/coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  Map<String, List<SubjectTopic>> _getRelevantSubjects(UserModel user, Exam exam) {
    final subjects = <String, List<SubjectTopic>>{};
    final relevantSections = _getRelevantSectionsForUser(user, exam);

    for (var section in relevantSections) {
      section.subjects.forEach((subjectName, subjectDetails) {
        subjects[subjectName] = subjectDetails.topics;
      });
    }
    return subjects;
  }

  List<ExamSection> _getRelevantSectionsForUser(UserModel user, Exam exam) {
    if (user.selectedExam == ExamType.lgs.name) {
      return exam.sections;
    } else if (user.selectedExam == ExamType.yks.name) {
      final tytSection = exam.sections.firstWhere((s) => s.name == 'TYT');
      final userAytSection = exam.sections.firstWhere(
            (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      if (tytSection.name == userAytSection.name) return [tytSection];
      return [tytSection, userAytSection];
    } else {
      final relevantSection = exam.sections.firstWhere(
            (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      return [relevantSection];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    return userProfileAsync.when(
      data: (user) {
        if (user == null || user.selectedExam == null) {
          return Scaffold(
              appBar: AppBar(title: const Text('Hakimiyet Haritası')),
              body: const Center(child: Text('Lütfen önce profilden bir sınav seçin.'))
          );
        }

        final examType = ExamType.values.byName(user.selectedExam!);

        return FutureBuilder<Exam>(
          future: ExamData.getExamByType(examType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Hakimiyet Haritası')),
                  body: const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Hakimiyet Haritası')),
                  body: Center(child: Text('Sınav verileri yüklenemedi: ${snapshot.error}'))
              );
            }
            if (!snapshot.hasData) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Hakimiyet Haritası')),
                  body: const Center(child: Text('Sınav verisi bulunamadı.'))
              );
            }

            final exam = snapshot.data!;
            final subjects = _getRelevantSubjects(user, exam);

            if (subjects.isEmpty) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Hakimiyet Haritası')),
                  body: const Center(child: Text('Bu sınav için konu bulunamadı.'))
              );
            }

            return DefaultTabController(
              length: subjects.length,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Hakimiyet Haritası'),
                  bottom: TabBar(
                    isScrollable: true,
                    tabs: subjects.keys.map((subjectName) => Tab(text: subjectName)).toList(),
                  ),
                ),
                body: TabBarView(
                  children: subjects.entries.map((entry) {
                    final subjectName = entry.key;
                    final topics = entry.value;
                    return _SubjectMapView(
                      key: ValueKey(subjectName),
                      user: user,
                      subjectName: subjectName,
                      topics: topics,
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
      loading: () => Scaffold(
          appBar: AppBar(title: const Text('Hakimiyet Haritası')),
          body: const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
      ),
      error: (e, s) => Scaffold(
          appBar: AppBar(title: const Text('Hakimiyet Haritası')),
          body: Center(child: Text('Veriler yüklenirken bir hata oluştu: $e'))
      ),
    );
  }
}

// ... (dosyanın geri kalan _SubjectMapView ve _TopicBubble sınıfları aynı kalıyor)
class _SubjectMapView extends ConsumerWidget {
  final UserModel user;
  final String subjectName;
  final List<SubjectTopic> topics;

  const _SubjectMapView({
    super.key,
    required this.user,
    required this.subjectName,
    required this.topics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performances = user.topicPerformances[subjectName] ?? {};
    int totalQuestions = 0;
    int totalCorrect = 0;
    performances.forEach((key, value) {
      totalQuestions += value.questionCount;
      totalCorrect += value.correctCount;
    });
    final double overallMastery = totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMasteryHeader(context, overallMastery),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: topics.map((topic) {
              final performance = performances[topic.name] ?? TopicPerformanceModel();
              return _TopicBubble(
                topic: topic,
                performance: performance,
                onTap: () => context.go(
                  '/coach/update-topic-performance',
                  extra: {
                    'subject': subjectName,
                    'topic': topic.name,
                    'performance': performance,
                  },
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryHeader(BuildContext context, double overallMastery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genel Hakimiyet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: overallMastery),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                  color: Color.lerp(AppTheme.accentColor, AppTheme.successColor, value),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '%${(overallMastery * 100).toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopicBubble extends StatelessWidget {
  final SubjectTopic topic;
  final TopicPerformanceModel performance;
  final VoidCallback onTap;

  const _TopicBubble({
    required this.topic,
    required this.performance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double mastery = performance.questionCount < 5 ? -1 : (performance.correctCount / performance.questionCount);

    final Color color = switch(mastery) {
      < 0 => AppTheme.lightSurfaceColor, // Veri Yetersiz
      >= 0 && < 0.4 => AppTheme.accentColor,  // Zayıf
      >= 0.4 && < 0.7 => AppTheme.secondaryColor, // Orta
      _ => AppTheme.successColor, // Güçlü
    };

    final String tooltipMessage = mastery < 0
        ? "${topic.name}\n(Analiz için daha fazla veri gir)"
        : "${topic.name}\nHakimiyet: %${(mastery * 100).toStringAsFixed(0)}\nD:${performance.correctCount} Y:${performance.wrongCount} B:${performance.blankCount}";

    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1.5)
          ),
          child: Text(
            topic.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}