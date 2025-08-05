// lib/features/stats/screens/stats_screen.dart
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsyncValue = ref.watch(testsProvider);
    final userAsyncValue = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performans Analizi'),
        backgroundColor: AppTheme.primaryColor.withOpacity(0.85),
      ),
      body: userAsyncValue.when(
        data: (user) => testsAsyncValue.when(
          data: (tests) {
            if (tests.length < 2 || user == null) {
              return _buildEmptyState(context);
            }
            final analysis = PerformanceAnalysis(tests, user);

            // TERTEMİZ YAPI: ListView ile sonsuz kaydırma, sıfır piksel hatası.
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildOverallNetChart(context, analysis),
                const SizedBox(height: 24),
                _buildKeyStats(context, analysis),
                const SizedBox(height: 24),
                Text('BilgeAI Analizi', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildAiInsightCard(context, analysis),
                const SizedBox(height: 24),
                Text('Ders Bazında Performans', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // O çirkin bar grafiği yok edildi. Yerine bu şaheser geldi.
                ...analysis.sortedSubjects.map((subjectEntry) {
                  return _SubjectStatCard(
                    subjectName: subjectEntry.key,
                    averageNet: subjectEntry.value,
                    questionCount: analysis.getQuestionCountForSubject(subjectEntry.key),
                  ).animate().fadeIn(delay: (100 * analysis.sortedSubjects.indexOf(subjectEntry)).ms).slideX(begin: -0.2);
                }).toList(),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (err, stack) => Center(child: Text('Grafik yüklenirken bir hata oluştu: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (err, stack) => Center(child: Text('Kullanıcı verisi yüklenirken bir hata oluştu: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insights_rounded, size: 80, color: AppTheme.secondaryTextColor),
          const SizedBox(height: 16),
          Text('Analiz için Veri Bekleniyor', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Performans analizini ve kişisel tavsiyeleri görmek için en az 2 deneme sonucu eklemelisin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildOverallNetChart(BuildContext context, PerformanceAnalysis analysis) {
    return SizedBox(
      height: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.lightSurfaceColor.withOpacity(0.3), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text('${value.toInt() + 1}.D'),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => AppTheme.primaryColor,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final test = analysis.sortedTests[spot.spotIndex];
                    final text = '${test.testName}\n${DateFormat.yMd('tr').format(test.date)}\n${test.totalNet.toStringAsFixed(2)} Net';
                    return LineTooltipItem(text, const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: analysis.netSpots,
                  isCurved: true,
                  color: AppTheme.secondaryColor,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: AppTheme.secondaryColor, strokeColor: AppTheme.cardColor, strokeWidth: 2),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppTheme.secondaryColor.withOpacity(0.3), AppTheme.secondaryColor.withOpacity(0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyStats(BuildContext context, PerformanceAnalysis analysis) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(context, 'Ortalama Net', analysis.averageNet.toStringAsFixed(2), Icons.track_changes_rounded, Colors.blueAccent),
        _buildStatCard(context, 'En İyi Net', analysis.bestNet.toStringAsFixed(2), Icons.emoji_events_rounded, Colors.amber),
        _buildStatCard(context, 'En Kötü Net', analysis.worstNet.toStringAsFixed(2), Icons.trending_down_rounded, Colors.redAccent),
        _buildStatCard(context, 'Tutarlılık', '%${analysis.consistency.toStringAsFixed(1)}', Icons.sync_alt_rounded, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(color: AppTheme.secondaryTextColor)),
                    Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard(BuildContext context, PerformanceAnalysis analysis) {
    return Card(
      color: AppTheme.secondaryColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.secondaryColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                analysis.aiInsight,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textColor, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ders performansını gösteren şık kart
class _SubjectStatCard extends StatelessWidget {
  final String subjectName;
  final double averageNet;
  final int questionCount;

  const _SubjectStatCard({
    required this.subjectName,
    required this.averageNet,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = questionCount > 0 ? (averageNet.clamp(0, questionCount) / questionCount) : 0.0;
    final Color progressColor = Color.lerp(AppTheme.accentColor, AppTheme.successColor, progress)!;

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
                  child: Text(
                    subjectName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  averageNet.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Analiz sınıfı
class PerformanceAnalysis {
  final List<TestModel> tests;
  final UserModel user;
  late List<TestModel> sortedTests;
  late List<FlSpot> netSpots;
  late double averageNet;
  late double bestNet;
  late double worstNet;
  late double consistency;
  late Map<String, double> subjectAverages;
  late List<MapEntry<String, double>> sortedSubjects;
  late String aiInsight;
  late Exam _examData;

  PerformanceAnalysis(this.tests, this.user) {
    if (tests.isEmpty || user.selectedExam == null) {
      _initializeEmpty();
      return;
    }

    _examData = ExamData.getExamByType(ExamType.values.byName(user.selectedExam!));
    sortedTests = List.from(tests)..sort((a, b) => a.date.compareTo(b.date));
    netSpots = List.generate(sortedTests.length, (i) => FlSpot(i.toDouble(), sortedTests[i].totalNet));
    final allNets = sortedTests.map((t) => t.totalNet).toList();
    averageNet = allNets.reduce((a, b) => a + b) / allNets.length;
    bestNet = allNets.reduce(max);
    worstNet = allNets.reduce(min);

    if (averageNet.abs() > 0.001) {
      final double stdDev = sqrt(allNets.map((n) => pow(n - averageNet, 2)).reduce((a, b) => a + b) / allNets.length);
      consistency = (1 - (stdDev / averageNet.abs())) * 100;
      if (consistency.isNegative || consistency.isNaN) consistency = 0;
    } else {
      consistency = 0.0;
    }

    final subjectNets = <String, List<double>>{};
    for (var test in sortedTests) {
      test.scores.forEach((subject, scores) {
        final net = (scores['dogru'] ?? 0) - ((scores['yanlis'] ?? 0) * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    if (subjectNets.isNotEmpty) {
      subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));
      sortedSubjects = subjectAverages.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final weakestSubject = sortedSubjects.last.key;
      final strongestSubject = sortedSubjects.first.key;
      aiInsight = "Harika gidiyorsun! En güçlü olduğun alan '$strongestSubject' gibi görünüyor. Netlerini daha da artırmak için '$weakestSubject' dersine biraz daha odaklanabilirsin.";
    } else {
      _initializeEmpty();
    }
  }

  void _initializeEmpty() {
    sortedTests = [];
    netSpots = [];
    averageNet = 0.0;
    bestNet = 0.0;
    worstNet = 0.0;
    consistency = 0.0;
    subjectAverages = {};
    sortedSubjects = [];
    aiInsight = "Analiz için yeterli veri bulunmuyor.";
  }

  int getQuestionCountForSubject(String subjectName) {
    for (var section in _examData.sections) {
      if (section.subjects.containsKey(subjectName)) {
        return section.subjects[subjectName]!.questionCount;
      }
    }
    return 40;
  }
}