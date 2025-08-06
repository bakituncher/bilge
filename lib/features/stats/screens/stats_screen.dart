// lib/features/stats/screens/stats_screen.dart
import 'dart:math';
import 'package:collection/collection.dart';
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
import 'package:bilge_ai/features/stats/screens/subject_stats_screen.dart';

// --- DEVRİM GÜNCELLEMESİ: Özel ve animasyonlu sekme yönetimi için StateProvider ---
final _selectedTabIndexProvider = StateProvider<int>((ref) => 0);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsyncValue = ref.watch(testsProvider);
    final userAsyncValue = ref.watch(userProfileProvider);

    return userAsyncValue.when(
      data: (user) => testsAsyncValue.when(
        data: (tests) {
          if (user == null || tests.isEmpty) {
            return _buildEmptyState(context, isCompletelyEmpty: true);
          }

          final groupedTests = <String, List<TestModel>>{};
          for (final test in tests) {
            (groupedTests[test.sectionName] ??= []).add(test);
          }

          final sortedGroups = groupedTests.entries.toList()
            ..sort((a, b) {
              if (a.key == 'TYT') return -1;
              if (b.key == 'TYT') return 1;
              if (a.key.contains('Sayısal')) return -1;
              if (b.key.contains('Sayısal')) return 1;
              return a.key.compareTo(b.key);
            });

          if (sortedGroups.isEmpty) {
            return _buildEmptyState(context, isCompletelyEmpty: true);
          }

          // Sekme sıfırlama mantığı
          final selectedIndex = ref.watch(_selectedTabIndexProvider);
          if (selectedIndex >= sortedGroups.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(_selectedTabIndexProvider.notifier).state = 0;
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Performans Kalesi'),
            ),
            body: Column(
              children: [
                // --- DEVRİM GÜNCELLEMESİ: Eski TabBar yerine özel "Strateji Plakaları" ---
                _FortressTabSelector(
                  tabs: sortedGroups.map((e) => e.key).toList(),
                ),
                Expanded(
                  // --- DEVRİM GÜNCELLEMESİ: TabBarView yerine IndexedStack ---
                  child: IndexedStack(
                    index: ref.watch(_selectedTabIndexProvider),
                    children: sortedGroups.map((entry) {
                      return _AnalysisView(
                        key: ValueKey(entry.key),
                        tests: entry.value,
                        user: user,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState('Test verileri yüklenemedi: $err'),
      ),
      loading: () => _buildLoadingState(),
      error: (err, stack) => _buildErrorState('Kullanıcı verisi yüklenemedi: $err'),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Performans Kalesi')),
      body: const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performans Kalesi')),
      body: Center(child: Text(error)),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isCompletelyEmpty = false, String sectionName = ''}) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performans Kalesi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insights_rounded, size: 80, color: AppTheme.secondaryTextColor),
              const SizedBox(height: 16),
              Text(
                'Kale Henüz İnşa Edilmedi',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isCompletelyEmpty
                    ? 'Stratejik analizleri ve fetih haritalarını görmek için deneme sonuçları ekleyerek kalenin temellerini atmalısın.'
                    : 'Bu cephede anlamlı bir strateji oluşturmak için en az 2 adet "$sectionName" denemesi eklemelisin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor, height: 1.5),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
        ),
      ),
    );
  }
}

// --- YENİ WIDGET: Özel Tasarım, Animasyonlu Sekme Sistemi ---
class _FortressTabSelector extends ConsumerWidget {
  final List<String> tabs;
  const _FortressTabSelector({required this.tabs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(_selectedTabIndexProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.lightSurfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(_selectedTabIndexProvider.notifier).state = index,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}


class _AnalysisView extends StatelessWidget {
  final List<TestModel> tests;
  final UserModel user;

  const _AnalysisView({required this.tests, required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    if (tests.length < 2) {
      return StatsScreen()._buildEmptyState(context, sectionName: tests.firstOrNull?.sectionName ?? '');
    }

    final analysis = PerformanceAnalysis(tests, user);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _TitleWidget(title: 'Kader Tayfı', subtitle: 'Netlerinin ve doğruluğunun zamansal analizi'),
        _NetEvolutionChart(analysis: analysis),
        const SizedBox(height: 24),
        _TitleWidget(title: 'Zafer Anıtları', subtitle: 'Genel performans metriklerin'),
        _KeyStatsGrid(analysis: analysis),
        const SizedBox(height: 24),
        _TitleWidget(title: 'Komutan Emirleri', subtitle: 'Bilge Göz\'ün taktiksel raporu'),
        _AiInsightCard(analysis: analysis),
        const SizedBox(height: 24),
        _TitleWidget(title: 'Fetih Haritası', subtitle: 'Ders kalelerine tıklayarak detaylı istihbarat al'),
        ...analysis.sortedSubjects.map((subjectEntry) {
          final subjectAnalysis = analysis.getAnalysisForSubject(subjectEntry.key);
          return _SubjectStatCard(
            subjectName: subjectEntry.key,
            analysis: subjectAnalysis,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectStatsScreen(
                    subjectName: subjectEntry.key,
                    analysis: subjectAnalysis,
                  ),
                ),
              );
            },
          ).animate().fadeIn(delay: (100 * analysis.sortedSubjects.indexOf(subjectEntry)).ms).slideX(begin: -0.2);
        }).toList(),
      ].animate(interval: 100.ms).fadeIn(duration: 400.ms),
    );
  }
}
class _TitleWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  const _TitleWidget({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }
}

class _NetEvolutionChart extends StatelessWidget {
  final PerformanceAnalysis analysis;
  const _NetEvolutionChart({required this.analysis});

  @override
  Widget build(BuildContext context) {
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
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => AppTheme.primaryColor.withOpacity(0.9),
                  getTooltipItems: (spots) => spots.map((spot) {
                    final test = analysis.sortedTests[spot.spotIndex];
                    final accuracy = (test.totalCorrect / (test.totalCorrect + test.totalWrong)).isNaN ? 0.0 : (test.totalCorrect / (test.totalCorrect + test.totalWrong));
                    final text = '${test.testName}\n${DateFormat.yMd('tr').format(test.date)}\n${test.totalNet.toStringAsFixed(2)} Net (%${(accuracy * 100).toStringAsFixed(0)} isabet)';
                    return LineTooltipItem(text, const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: analysis.netSpots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [AppTheme.successColor, AppTheme.secondaryColor]),
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final accuracy = (analysis.sortedTests[index].totalCorrect / (analysis.sortedTests[index].totalCorrect + analysis.sortedTests[index].totalWrong)).isNaN ? 0.0 : (analysis.sortedTests[index].totalCorrect / (analysis.sortedTests[index].totalCorrect + analysis.sortedTests[index].totalWrong));
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Color.lerp(AppTheme.accentColor, AppTheme.successColor, accuracy)!,
                        strokeColor: AppTheme.cardColor,
                        strokeWidth: 2,
                      );
                    },
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
}

class _KeyStatsGrid extends StatelessWidget {
  final PerformanceAnalysis analysis;
  const _KeyStatsGrid({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _StatCard(label: 'Savaşçı Skoru', value: analysis.warriorScore.toStringAsFixed(1), icon: Icons.shield_rounded, color: AppTheme.secondaryColor, tooltip: "Genel net, doğruluk ve istikrarı birleştiren özel puanın."),
        _StatCard(label: 'İsabet Oranı', value: '%${analysis.accuracy.toStringAsFixed(1)}', icon: Icons.gps_fixed_rounded, color: Colors.green, tooltip: "Cevapladığın soruların yüzde kaçı doğru?"),
        _StatCard(label: 'Tutarlılık Mührü', value: '%${analysis.consistency.toStringAsFixed(1)}', icon: Icons.sync_alt_rounded, color: Colors.blueAccent, tooltip: "Netlerin ne kadar istikrarlı? %100, tüm netlerin aynı demek."),
        _StatCard(label: 'Yükseliş Hızı', value: analysis.trend.toStringAsFixed(2), icon: analysis.trend > 0.1 ? Icons.trending_up_rounded : (analysis.trend < -0.1 ? Icons.trending_down_rounded : Icons.trending_flat_rounded), color: analysis.trend > 0.1 ? Colors.teal : (analysis.trend < -0.1 ? Colors.redAccent : Colors.grey), tooltip: "Deneme başına net artış/azalış hızın."),
      ],
    );
  }
}
class _StatCard extends StatelessWidget {
  final String label, value, tooltip;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.bold)),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final PerformanceAnalysis analysis;
  const _AiInsightCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.lightSurfaceColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: analysis.tacticalAdvice.map((advice) {
            final isLast = advice == analysis.tacticalAdvice.last;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(advice.icon, color: advice.color, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      advice.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textColor, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SubjectStatCard extends StatelessWidget {
  final String subjectName;
  final SubjectAnalysis analysis;
  final VoidCallback onTap;

  const _SubjectStatCard({required this.subjectName, required this.analysis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double progress = analysis.questionCount > 0 ? (analysis.averageNet.clamp(-analysis.questionCount.toDouble(), analysis.questionCount.toDouble()) + analysis.questionCount) / (analysis.questionCount * 2) : 0.0;
    final Color progressColor = Color.lerp(AppTheme.accentColor, AppTheme.successColor, progress)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  Row(
                    children: [
                      Text(
                        'Ort: ${analysis.averageNet.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.secondaryTextColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: "Hakimiyet: %${(progress * 100).toStringAsFixed(0)}",
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================================
// ||                    ACIMASIZ ANALİZ MOTORU KODU BAŞLANGICI                   ||
// =================================================================================

class TacticalAdvice {
  final String text;
  final IconData icon;
  final Color color;
  TacticalAdvice(this.text, {required this.icon, required this.color});
}

class SubjectAnalysis {
  final String subjectName;
  final double averageNet;
  final double bestNet;
  final double worstNet;
  final double trend;
  final int questionCount;
  final List<TestModel> subjectTests;
  final List<FlSpot> netSpots;

  SubjectAnalysis({
    required this.subjectName,
    required this.averageNet,
    required this.bestNet,
    required this.worstNet,
    required this.trend,
    required this.questionCount,
    required this.subjectTests,
    required this.netSpots,
  });
}

class PerformanceAnalysis {
  final List<TestModel> tests;
  final UserModel user;
  late List<TestModel> sortedTests;
  late List<FlSpot> netSpots;
  late double warriorScore;
  late double accuracy;
  late double consistency;
  late double trend;
  late Map<String, double> subjectAverages;
  late List<MapEntry<String, double>> sortedSubjects;
  late List<TacticalAdvice> tacticalAdvice;
  late Exam _examData;

  PerformanceAnalysis(this.tests, this.user) {
    if (tests.isEmpty || user.selectedExam == null) {
      _initializeEmpty();
      return;
    }

    _examData = ExamData.getExamByType(ExamType.values.byName(user.selectedExam!));
    sortedTests = List.from(tests)..sort((a, b) => a.date.compareTo(b.date));

    final allNets = sortedTests.map((t) => t.totalNet).toList();
    final totalQuestionsAttempted = sortedTests.map((t) => t.totalCorrect + t.totalWrong).sum;
    final totalCorrectAnswers = sortedTests.map((t) => t.totalCorrect).sum;
    if (totalQuestionsAttempted == 0 && totalCorrectAnswers > 0) throw Exception("Mantıksız veri: Cevaplanan soru 0 olamazken doğru sayısı 0'dan büyük.");

    final averageNet = allNets.average;

    if (averageNet.abs() > 0.001) {
      final double stdDev = sqrt(allNets.map((n) => pow(n - averageNet, 2)).sum / allNets.length);
      consistency = max(0, (1 - (stdDev / averageNet.abs())) * 100);
    } else {
      consistency = 0.0;
    }

    accuracy = totalQuestionsAttempted > 0 ? (totalCorrectAnswers / totalQuestionsAttempted) * 100 : 0.0;
    trend = _calculateTrend(allNets);
    netSpots = List.generate(sortedTests.length, (i) => FlSpot(i.toDouble(), sortedTests[i].totalNet));

    final netComponent = (averageNet / (sortedTests.first.totalQuestions * 1.0)) * 50;
    final accuracyComponent = (accuracy / 100) * 25;
    final consistencyComponent = (consistency / 100) * 15;
    final trendComponent = (atan(trend) / (pi / 2)) * 10;
    warriorScore = (netComponent + accuracyComponent + consistencyComponent + trendComponent).clamp(0, 100);

    final subjectNets = <String, List<double>>{};
    for (var test in sortedTests) {
      test.scores.forEach((subject, scores) {
        final net = (scores['dogru'] ?? 0) - ((scores['yanlis'] ?? 0) * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    if (subjectNets.isNotEmpty) {
      subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.average));
      sortedSubjects = subjectAverages.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    } else {
      subjectAverages = {};
      sortedSubjects = [];
    }
    tacticalAdvice = _generateTacticalAdvice();
  }

  double _calculateTrend(List<double> data) {
    if (data.length < 2) return 0.0;
    final n = data.length;
    final sumX = (n * (n - 1)) / 2;
    final sumY = data.sum;
    final sumXY = List.generate(n, (i) => i * data[i]).sum;
    final sumX2 = List.generate(n, (i) => i * i).sum;
    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = (n * sumX2) - (sumX * sumX);
    return denominator == 0 ? 0.0 : numerator / denominator;
  }

  SubjectAnalysis getAnalysisForSubject(String subjectName) {
    final subjectTests = sortedTests.where((t) => t.scores.containsKey(subjectName)).toList();
    if (subjectTests.isEmpty) {
      return SubjectAnalysis(subjectName: subjectName, averageNet: 0, bestNet: 0, worstNet: 0, trend: 0, questionCount: 0, subjectTests: [], netSpots: []);
    }

    final subjectNets = subjectTests.map((t) {
      final scores = t.scores[subjectName]!;
      return (scores['dogru'] ?? 0) - ((scores['yanlis'] ?? 0) * t.penaltyCoefficient);
    }).toList();

    final netSpots = List.generate(subjectNets.length, (i) => FlSpot(i.toDouble(), subjectNets[i]));

    return SubjectAnalysis(
      subjectName: subjectName,
      averageNet: subjectNets.average,
      bestNet: subjectNets.reduce(max),
      worstNet: subjectNets.reduce(min),
      trend: _calculateTrend(subjectNets),
      questionCount: getQuestionCountForSubject(subjectName),
      subjectTests: subjectTests,
      netSpots: netSpots,
    );
  }

  List<TacticalAdvice> _generateTacticalAdvice() {
    final adviceList = <TacticalAdvice>[];
    if (sortedSubjects.isEmpty) return adviceList;

    final strongestSubject = sortedSubjects.first.key;
    final weakestSubject = sortedSubjects.last.key;

    if (warriorScore > 75) {
      adviceList.add(TacticalAdvice("MUHAREBE DURUMU: MÜKEMMEL. Kalen sarsılmaz, stratejin kusursuz. Zirveyi koru.", icon: Icons.workspace_premium, color: Colors.amber));
    } else {
      adviceList.add(TacticalAdvice("MUHAREBE DURUMU: İYİ. Güçlüsün ama zafiyetlerin var. Zayıf cepheleri güçlendirerek hakimiyetini pekiştir.", icon: Icons.shield_rounded, color: AppTheme.successColor));
    }

    adviceList.add(TacticalAdvice("TAARRUZ EMRİ: '$weakestSubject' cephesi en zayıf halkan. Tüm gücünle bu hedefe yüklen. Bu kaleyi fethetmek, zaferi getirecek.", icon: Icons.radar_rounded, color: AppTheme.accentColor));

    return adviceList;
  }

  void _initializeEmpty() {
    sortedTests = [];
    netSpots = [];
    warriorScore = 0.0;
    accuracy = 0.0;
    consistency = 0.0;
    trend = 0.0;
    subjectAverages = {};
    sortedSubjects = [];
    tacticalAdvice = [];
  }

  int getQuestionCountForSubject(String subjectName) {
    final sectionName = tests.first.sectionName;
    final section = _examData.sections.firstWhere((s) => s.name == sectionName, orElse: () => _examData.sections.first);
    return section.subjects[subjectName]?.questionCount ?? 40;
  }
}