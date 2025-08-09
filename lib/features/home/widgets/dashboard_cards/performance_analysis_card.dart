// lib/features/home/widgets/dashboard_cards/performance_analysis_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';

class PerformanceAnalysisCard extends ConsumerWidget {
  final UserModel user;
  final List<TestModel> tests;
  const PerformanceAnalysisCard({super.key, required this.user, required this.tests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        elevation: 4,
        shadowColor: AppTheme.successColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<Exam?>(
            future: user.selectedExam != null ? ExamData.getExamByType(ExamType.values.byName(user.selectedExam!)) : null,
            builder: (context, examSnapshot) {
              if (!examSnapshot.hasData || tests.length < 2) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text("Performans trendini görebilmek için en az 2 deneme sonucu girmelisin.",
                          textAlign: TextAlign.center, style: TextStyle(color: AppTheme.secondaryTextColor, height: 1.5)),
                    ));
              }

              final analysis = StatsAnalysis(tests, user.topicPerformances, examSnapshot.data!, user: user);

              // YENİ GÖRSELLEŞTİRME MANTIĞI
              final midPoint = (tests.length / 2).ceil();
              final firstHalfNets = tests.sublist(midPoint).map((t) => t.totalNet);
              final secondHalfNets = tests.sublist(0, midPoint).map((t) => t.totalNet);

              final firstHalfAvg = firstHalfNets.isNotEmpty ? firstHalfNets.reduce((a, b) => a + b) / firstHalfNets.length : 0.0;
              final secondHalfAvg = secondHalfNets.isNotEmpty ? secondHalfNets.reduce((a, b) => a + b) / secondHalfNets.length : 0.0;

              final difference = secondHalfAvg - firstHalfAvg;

              String title;
              String subtitle;
              IconData icon;
              Color color;

              if (difference > 0.5) {
                title = "Yükseliştesin!";
                subtitle = "Son denemelerin, ilk denemelerine göre ortalama ${difference.toStringAsFixed(1)} net daha yüksek. Harika gidiyorsun!";
                icon = Icons.trending_up_rounded;
                color = AppTheme.successColor;
              } else if (difference < -0.5) {
                title = "Stratejiyi Gözden Geçir";
                subtitle = "Son denemelerinde ortalama ${(-difference).toStringAsFixed(1)} netlik bir düşüş gözleniyor. Moral bozmak yok, hemen analiz edelim.";
                icon = Icons.trending_down_rounded;
                color = AppTheme.accentColor;
              } else {
                title = "İstikrarını Koruyorsun";
                subtitle = "Netlerin stabil bir seyir izliyor. Şimdi bu platoyu aşıp yeni zirvelere ulaşma zamanı.";
                icon = Icons.trending_flat_rounded;
                color = AppTheme.secondaryColor;
              }

              return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 28, color: color),
                          const SizedBox(width: 12),
                          Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor, height: 1.4)),
                      const Spacer(),
                      // YENİ GÖRSEL RAPOR WIDGET'I
                      _PerformanceComparison(
                        firstHalfAvg: firstHalfAvg,
                        secondHalfAvg: secondHalfAvg,
                        color: color,
                      ),
                      const Spacer(),
                      Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                              onPressed: () => context.push('/home/stats'),
                              style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.8)),
                              child: const Text("Detaylı Analiz"))),
                    ],
                  ));
            }));
  }
}

// YENİ WIDGET: PERFORMANS KARŞILAŞTIRMA GÖRSELİ
class _PerformanceComparison extends StatelessWidget {
  final double firstHalfAvg;
  final double secondHalfAvg;
  final Color color;

  const _PerformanceComparison({
    required this.firstHalfAvg,
    required this.secondHalfAvg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatColumn(label: "Önceki Ort.", value: firstHalfAvg.toStringAsFixed(1), color: AppTheme.secondaryTextColor),
        Icon(Icons.arrow_forward_rounded, size: 32, color: color).animate(
          onPlay: (c) => c.repeat(reverse: true),
        ).shimmer(delay: 400.ms, duration: 1800.ms, color: color),
        _StatColumn(label: "Sonraki Ort.", value: secondHalfAvg.toStringAsFixed(1), color: color, isLarge: true),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: isLarge
              ? Theme.of(context).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
        ),
      ],
    );
  }
}