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
import 'package:bilge_ai/features/coach/widgets/mastery_topic_bubble.dart';

// Bu provider, hangi sekmede olduğumuzun bilgisini uygulama genelinde tutar.
final coachScreenTabProvider = StateProvider<int>((ref) => 0);

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  Map<String, List<SubjectTopic>> _getRelevantSubjects(
      UserModel user, Exam exam) {
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

  void _setupTabController(int length) {
    final initialIndex = ref.read(coachScreenTabProvider);
    _tabController = TabController(
      initialIndex: initialIndex < length ? initialIndex : 0,
      length: length,
      vsync: this,
    );
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        ref.read(coachScreenTabProvider.notifier).state = _tabController!.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    return userProfileAsync.when(
      data: (user) {
        if (user == null || user.selectedExam == null) {
          return Scaffold(
              appBar: AppBar(title: const Text('Bilgi Galaksisi')),
              body: const Center(
                  child: Text('Lütfen önce profilden bir sınav seçin.')));
        }

        final examType = ExamType.values.byName(user.selectedExam!);

        return FutureBuilder<Exam>(
          future: ExamData.getExamByType(examType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Bilgi Galaksisi')),
                  body: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.secondaryColor)));
            }
            if (snapshot.hasError) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Bilgi Galaksisi')),
                  body: Center(
                      child:
                      Text('Sınav verileri yüklenemedi: ${snapshot.error}')));
            }
            if (!snapshot.hasData) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Bilgi Galaksisi')),
                  body: const Center(child: Text('Sınav verisi bulunamadı.')));
            }

            final exam = snapshot.data!;
            final subjects = _getRelevantSubjects(user, exam);

            if (subjects.isEmpty) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Bilgi Galaksisi')),
                  body:
                  const Center(child: Text('Bu sınav için konu bulunamadı.')));
            }

            if (_tabController == null || _tabController!.length != subjects.length) {
              _setupTabController(subjects.length);
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Bilgi Galaksisi'),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: subjects.keys
                      .map((subjectName) => Tab(text: subjectName))
                      .toList(),
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: subjects.entries.map((entry) {
                  final subjectName = entry.key;
                  final topics = entry.value;
                  return _SubjectGalaxyView(
                    key: ValueKey(subjectName),
                    user: user,
                    subjectName: subjectName,
                    topics: topics,
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      loading: () => Scaffold(
          appBar: AppBar(title: const Text('Bilgi Galaksisi')),
          body: const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor))),
      error: (e, s) => Scaffold(
          appBar: AppBar(title: const Text('Bilgi Galaksisi')),
          body: Center(child: Text('Veriler yüklenirken bir hata oluştu: $e'))),
    );
  }
}

class _SubjectGalaxyView extends ConsumerWidget {
  final UserModel user;
  final String subjectName;
  final List<SubjectTopic> topics;

  const _SubjectGalaxyView({
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
    final double overallMastery =
    totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;

    final auraColor = Color.lerp(
        AppTheme.accentColor, AppTheme.successColor, overallMastery)!
        .withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [auraColor, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        // SORUNUN ÇÖZÜLDÜĞÜ YER BURASI:
        // Alt boşluğu artırarak içeriğin navigasyon barının üzerinde
        // rahatça kaydırılabilmesini sağlıyoruz.
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMasteryHeader(context, overallMastery, subjectName),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16.0,
              runSpacing: 20.0,
              alignment: WrapAlignment.center,
              children: topics.map((topic) {
                final performance =
                    performances[topic.name] ?? TopicPerformanceModel();
                return MasteryTopicBubble(
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
                );
              }).toList(),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryHeader(
      BuildContext context, double overallMastery, String subjectName) {
    final textTheme = Theme.of(context).textTheme;
    final masteryPercent = (overallMastery * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$subjectName Sistemi',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu sistemdeki gezegenlerin %$masteryPercent oranında kontrolü sende.',
            style: textTheme.titleMedium
                ?.copyWith(color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: overallMastery),
            builder: (context, value, child) => Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.lightSurfaceColor.withOpacity(0.5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color.lerp(
                        AppTheme.accentColor, AppTheme.successColor, value),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(AppTheme.accentColor,
                            AppTheme.successColor, value)!
                            .withOpacity(0.5),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }
}