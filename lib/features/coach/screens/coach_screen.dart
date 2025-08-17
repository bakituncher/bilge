// lib/features/coach/screens/coach_screen.dart
import 'dart:ui';
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
import 'package:bilge_ai/features/coach/widgets/topic_stats_dialog.dart';

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

  // Anahtarları güvenli hale getiren merkezi fonksiyon
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[.\s\(\)]'), '_');
  }

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
        ref.read(coachScreenTabProvider.notifier).state =
            _tabController!.index;
      }
    });
  }

  // YENİ: Rehber diyalogunu gösteren fonksiyon
  void _showGalaxyGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _GalaxyGuideDialog(),
    );
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
                      child: Text(
                          'Sınav verileri yüklenemedi: ${snapshot.error}')));
            }
            if (!snapshot.hasData) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Bilgi Galaksisi')),
                  body:
                  const Center(child: Text('Sınav verisi bulunamadı.')));
            }

            final exam = snapshot.data!;
            final subjects = _getRelevantSubjects(user, exam);

            if (subjects.isEmpty) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Bilgi Galaksisi')),
                  body: const Center(
                      child: Text('Bu sınav için konu bulunamadı.')));
            }

            if (_tabController == null ||
                _tabController!.length != subjects.length) {
              _setupTabController(subjects.length);
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Bilgi Galaksisi'),
                // YENİ: Rehber butonu eklendi
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    tooltip: "Rehber",
                    onPressed: () => _showGalaxyGuide(context),
                  ),
                ],
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
                    exam: exam,
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
              child:
              CircularProgressIndicator(color: AppTheme.secondaryColor))),
      error: (e, s) => Scaffold(
          appBar: AppBar(title: const Text('Bilgi Galaksisi')),
          body:
          Center(child: Text('Veriler yüklenirken bir hata oluştu: $e'))),
    );
  }
}

class _SubjectGalaxyView extends ConsumerWidget {
  final UserModel user;
  final Exam exam;
  final String subjectName;
  final List<SubjectTopic> topics;

  const _SubjectGalaxyView({
    super.key,
    required this.user,
    required this.exam,
    required this.subjectName,
    required this.topics,
  });

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[.\s\(\)]'), '_');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performances =
        user.topicPerformances[_sanitizeKey(subjectName)] ?? {};
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalWrong = 0;

    final relevantSection = exam.sections.firstWhere(
          (s) => s.subjects.containsKey(subjectName),
      orElse: () => exam.sections.first,
    );
    final penaltyCoefficient = relevantSection.penaltyCoefficient;

    performances.forEach((key, value) {
      totalQuestions += value.questionCount;
      totalCorrect += value.correctCount;
      totalWrong += value.wrongCount;
    });

    final double overallNet =
        totalCorrect - (totalWrong * penaltyCoefficient);
    final double overallMastery = totalQuestions == 0
        ? 0.0
        : (overallNet / totalQuestions).clamp(0.0, 1.0);

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
                final performance = performances[_sanitizeKey(topic.name)] ??
                    TopicPerformanceModel();

                final double netCorrect = performance.correctCount -
                    (performance.wrongCount * penaltyCoefficient);
                final double mastery = performance.questionCount < 5
                    ? -1
                    : performance.questionCount == 0
                    ? 0
                    : (netCorrect / performance.questionCount)
                    .clamp(0.0, 1.0);

                return MasteryTopicBubble(
                  topic: topic,
                  performance: performance,
                  penaltyCoefficient: penaltyCoefficient,
                  onTap: () => context.go(
                    '/coach/update-topic-performance',
                    extra: {
                      'subject': subjectName,
                      'topic': topic.name,
                      'performance': performance,
                    },
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => TopicStatsDialog(
                        topicName: topic.name,
                        performance: performance,
                        mastery: mastery,
                      ),
                    );
                  },
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
            style:
            textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu sistemdeki gezegenlerin %$masteryPercent oranında net hakimiyeti sende.',
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


// YENİ: Bilgi Galaksisi Rehber Diyalog Widget'ı
class _GalaxyGuideDialog extends StatelessWidget {
  const _GalaxyGuideDialog();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: AppTheme.cardColor.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        // *** HATA ÇÖZÜMÜ: Başlık (Text) widget'ı Expanded ile sarmalandı ***
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.secondaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Text("Bilgi Galaksisi Rehberi"),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _GuideDetailRow(
                icon: Icons.explore_rounded,
                title: "Galaksiyi Keşfet",
                subtitle: "Burası, her bir dersin bir sistem, her bir konunun ise bir gezegen olduğu senin kişisel bilgi evrenin.",
              ),
              _GuideDetailRow(
                icon: Icons.palette_rounded,
                title: "Gezegen Renkleri",
                subtitle: "Gezegenlerin rengi, o konudaki hakimiyetini gösterir. Kırmızı zayıf, sarı orta, yeşil ise güçlü olduğun anlamına gelir.",
              ),
              _GuideDetailRow(
                icon: Icons.touch_app_rounded,
                title: "Hızlı Dokunuş: Veri Girişi",
                subtitle: "Bir gezegene kısa dokunarak o konuyla ilgili çözdüğün son testin doğru/yanlış sayılarını girebilir ve hakimiyetini güncelleyebilirsin.",
              ),
              _GuideDetailRow(
                icon: Icons.integration_instructions_rounded,
                title: "Uzun Dokunuş: Analiz",
                subtitle: "Bir gezegene uzun basarak o konunun detaylı istatistiklerini ve BilgeAI'nin özel yorumunu içeren 'Konu Künyesi'ni açabilirsin.",
              ),
            ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideX(begin: 0.5),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Anladım, Kapat"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}

// YENİ: Rehber satırları için özel widget
class _GuideDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuideDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondaryTextColor, size: 28),
          const SizedBox(width: 16),
          Expanded( // PIXEL HATASI ÇÖZÜMÜ: Metnin taşmasını engellemek için Expanded eklendi.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}