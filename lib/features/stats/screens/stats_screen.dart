// lib/features/stats/screens/stats_screen.dart
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsyncValue = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performans Analizi'),
      ),
      body: testsAsyncValue.when(
        data: (tests) {
          if (tests.length < 2) {
            return _buildEmptyState(context);
          }
          final analysis = PerformanceAnalysis(tests);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Genel Bakış', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              _buildOverallNetChart(context, analysis).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 24),
              _buildKeyStats(context, analysis).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              Text('BilgeAI Analizi', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 8),
              _buildAiInsightCard(context, analysis).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
              const SizedBox(height: 24),
              Text('Ders Bazında Performans', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 16),
              _buildSubjectBarChart(context, analysis).animate().fadeIn(delay: 800.ms),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Grafik yüklenirken bir hata oluştu: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [colorScheme.primary.withAlpha(200), colorScheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 80, color: colorScheme.secondary),
            const SizedBox(height: 24),
            Text(
              'Analiz için Hazır!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Performans analizini ve kişisel tavsiyeleri görmek için en az 2 deneme sonucu eklemelisin.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildOverallNetChart(BuildContext context, PerformanceAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 250,
      child: Card(
        elevation: 0.5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withAlpha(50), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
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
                  getTooltipColor: (spot) => colorScheme.primary,
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
                  color: colorScheme.secondary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: colorScheme.secondary,
                        strokeColor: Theme.of(context).cardColor,
                        strokeWidth: 2
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [colorScheme.secondary.withAlpha(100), colorScheme.secondary.withAlpha(0)],
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
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildStatCard('Ortalama Net', analysis.averageNet.toStringAsFixed(2), Icons.track_changes_rounded, Colors.blue, context),
        _buildStatCard('En İyi Net', analysis.bestNet.toStringAsFixed(2), Icons.emoji_events_rounded, Colors.amber, context),
        _buildStatCard('En Kötü Net', analysis.worstNet.toStringAsFixed(2), Icons.trending_down_rounded, Colors.redAccent, context),
        _buildStatCard('Tutarlılık', '%${analysis.consistency.toStringAsFixed(1)}', Icons.sync_alt_rounded, Colors.green, context),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                Icon(icon, color: color),
              ],
            ),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard(BuildContext context, PerformanceAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primary.withAlpha(200),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: colorScheme.secondary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                analysis.aiInsight,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBarChart(BuildContext context, PerformanceAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final subjects = analysis.subjectAverages.keys.toList();
    return SizedBox(
      height: subjects.length * 50.0,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 120,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  // HATA DÜZELTİLDİ: Çökmemesi için güvenlik kontrolü eklendi.
                  if (index < 0 || index >= subjects.length) {
                    return const Text('');
                  }
                  return Text(
                    subjects[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: analysis.subjectAverages.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final subjectData = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: subjectData.value,
                  gradient: LinearGradient(colors: [colorScheme.secondary, colorScheme.secondary.withAlpha(150)]),
                  width: 20,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PerformanceAnalysis {
  final List<TestModel> tests;
  late List<TestModel> sortedTests;
  late List<FlSpot> netSpots;
  late double averageNet;
  late double bestNet;
  late double worstNet;
  late double consistency;
  late Map<String, double> subjectAverages;
  late String aiInsight;

  PerformanceAnalysis(this.tests) {
    sortedTests = tests.reversed.toList();
    netSpots = List.generate(sortedTests.length, (i) => FlSpot(i.toDouble(), sortedTests[i].totalNet));

    final allNets = tests.map((t) => t.totalNet).toList();
    averageNet = allNets.reduce((a, b) => a + b) / allNets.length;
    bestNet = allNets.reduce(max);
    worstNet = allNets.reduce(min);

    final double stdDev = sqrt(allNets.map((n) => pow(n - averageNet, 2)).reduce((a, b) => a + b) / allNets.length);
    consistency = (1 - (stdDev / averageNet)) * 100;
    if (consistency.isNegative || consistency.isNaN) consistency = 0;

    final subjectNets = <String, List<double>>{};
    for (var test in tests) {
      test.scores.forEach((subject, scores) {
        final net = scores['dogru']! - (scores['yanlis']! * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }
    subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));

    final weakestSubject = subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    final strongestSubject = subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    aiInsight = "Harika gidiyorsun! En güçlü olduğun alan '$strongestSubject' gibi görünüyor. Netlerini daha da artırmak için '$weakestSubject' dersine biraz daha odaklanabilirsin.";
  }
}