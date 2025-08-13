// lib/features/weakness_workshop/screens/workshop_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

class WorkshopStatsScreen extends ConsumerWidget {
  const WorkshopStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Atölye Raporu"),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Kullanıcı verisi bulunamadı."));
          final analysis = WorkshopAnalysis(user);

          if (analysis.totalQuestionsAnswered == 0) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildOverallStats(context, analysis),
              const SizedBox(height: 24),
              _buildPerformanceChart(context, analysis),
              const SizedBox(height: 24),
              _buildSubjectBreakdown(context, analysis),
            ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text("Hata: $e")),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_rounded, size: 80, color: AppTheme.secondaryTextColor),
              const SizedBox(height: 16),
              Text(
                'Atölye Henüz Sessiz',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cevher Atölyesi\'nde bir konu üzerinde çalıştığında, burası başarılarınla ve gelişim raporlarınla dolacak.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor, height: 1.5),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
        ));
    }

  Widget _buildOverallStats(BuildContext context, WorkshopAnalysis analysis) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.quiz_rounded,
          value: analysis.totalQuestionsAnswered.toString(),
          label: "Toplam Soru Çözüldü",
          color: AppTheme.secondaryColor,
        ),
        _StatCard(
          icon: Icons.diamond_rounded,
          value: analysis.uniqueTopicsWorkedOn.toString(),
          label: "Farklı Cevher İşlendi",
          color: AppTheme.successColor,
        ),
        _StatCard(
          icon: Icons.military_tech_rounded,
          value: "%${analysis.overallAccuracy.toStringAsFixed(1)}",
          label: "Genel Başarı Oranı",
          color: Colors.blueAccent,
        ),
        _StatCard(
          icon: Icons.school_rounded,
          value: analysis.mostWorkedSubject,
          label: "Favori Ders",
          color: Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(BuildContext context, WorkshopAnalysis analysis) {
    final chartData = analysis.subjectAccuracyList;
    if (chartData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Derslere Göre Başarı Dağılımı", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        SizedBox(
          height: chartData.length * 60.0,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: chartData.mapIndexed((index, data) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.accuracy,
                          gradient: const LinearGradient(
                            colors: [AppTheme.successColor, AppTheme.secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          width: 12,
                          borderRadius: BorderRadius.circular(6),
                        )
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < chartData.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                chartData[index].subject,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 120,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text("${value.toInt()}%"),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: false,
                    verticalInterval: 25,
                    getDrawingVerticalLine: (value) => FlLine(
                      color: AppTheme.lightSurfaceColor.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.primaryColor.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = chartData[group.x];
                        return BarTooltipItem(
                          '${data.subject}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          children: <TextSpan>[
                            TextSpan(
                              text: '%${data.accuracy.toStringAsFixed(1)} Başarı',
                              style: const TextStyle(color: AppTheme.successColor),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                swapAnimationDuration: 500.ms,
                swapAnimationCurve: Curves.easeInOut,
              ).animate().fadeIn(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectBreakdown(BuildContext context, WorkshopAnalysis analysis) {
    final topTopics = analysis.getTopTopicsByMastery(count: 5);
    if (topTopics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Konu Hakimiyet Raporu", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...topTopics.map((topic) {
          final mastery = topic['mastery'] as double;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic['topic'] as String, style: Theme.of(context).textTheme.titleLarge),
                            Text(topic['subject'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
                          ],
                        ),
                      ),
                      Text(
                        "%${(mastery * 100).toStringAsFixed(0)}",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Color.lerp(AppTheme.accentColor, AppTheme.successColor, mastery)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: mastery,
                      minHeight: 8,
                      backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.3),
                      color: Color.lerp(AppTheme.accentColor, AppTheme.successColor, mastery),
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Analiz Mantığı
class WorkshopAnalysis {
  final UserModel user;
  WorkshopAnalysis(this.user);

  String _deSanitizeKey(String key) {
    return key.replaceAll('_', ' ');
  }

  int get totalQuestionsAnswered => user.topicPerformances.values
      .expand((subject) => subject.values)
      .map((topic) => topic.questionCount)
      .sum;

  int get totalCorrectAnswers => user.topicPerformances.values
      .expand((subject) => subject.values)
      .map((topic) => topic.correctCount)
      .sum;

  int get uniqueTopicsWorkedOn => user.topicPerformances.values
      .expand((subject) => subject.keys)
      .toSet()
      .length;

  double get overallAccuracy => totalQuestionsAnswered > 0 ? (totalCorrectAnswers / totalQuestionsAnswered) * 100 : 0.0;

  String get mostWorkedSubject {
    if (user.topicPerformances.isEmpty) return "Yok";
    final subjectName = user.topicPerformances.entries
        .map((entry) => MapEntry(
        entry.key,
        entry.value.values.map((e) => e.questionCount).sum))
        .sortedBy<num>((e) => e.value)
        .last
        .key;
    return _deSanitizeKey(subjectName);
  }

  List<({String subject, double accuracy})> get subjectAccuracyList {
    return user.topicPerformances.entries.map((entry) {
      final totalQuestions = entry.value.values.map((e) => e.questionCount).sum;
      final totalCorrect = entry.value.values.map((e) => e.correctCount).sum;
      final accuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;
      return (subject: _deSanitizeKey(entry.key), accuracy: accuracy);
    }).where((d) => d.accuracy > 0).sortedBy<num>((d) => d.accuracy).reversed.toList();
  }

  List<Map<String, dynamic>> getTopTopicsByMastery({int count = 5}) {
    final allTopics = user.topicPerformances.entries.expand((subjectEntry) {
      return subjectEntry.value.entries.map((topicEntry) {
        final performance = topicEntry.value;
        final netCorrect = performance.correctCount - (performance.wrongCount * 0.25);
        final mastery = performance.questionCount > 0 ? (netCorrect / performance.questionCount) : 0.0;
        return {
          'subject': _deSanitizeKey(subjectEntry.key),
          'topic': _deSanitizeKey(topicEntry.key),
          'mastery': mastery.clamp(0.0, 1.0),
        };
      });
    }).toList();

    allTopics.sort((a, b) => (b['mastery'] as double).compareTo(a['mastery'] as double));
    return allTopics.take(count).toList();
  }
}