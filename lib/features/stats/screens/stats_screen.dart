// lib/features/stats/screens/stats_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsyncValue = ref.watch(testsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: Center(
        child: testsAsyncValue.when(
          data: (tests) {
            if (tests.length < 2) {
              return const Text(
                'Net grafiğini görmek için en az 2 deneme sınavı eklemelisin.',
                textAlign: TextAlign.center,
              );
            }
            // Grafiği göstermek için yeni bir widget çağırıyoruz
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: _NetLineChart(tests: tests),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Grafik yüklenirken bir hata oluştu: $err'),
        ),
      ),
    );
  }
}

// Grafik widget'ını ayrı bir component olarak oluşturmak kod temizliği için iyidir.
class _NetLineChart extends StatelessWidget {
  final List<TestModel> tests;
  const _NetLineChart({required this.tests});

  @override
  Widget build(BuildContext context) {
    // Grafik için veriyi hazırlıyoruz. fl_chart, FlSpot listesi bekler.
    // Grafiğin soldan sağa doğru zamanla ilerlemesi için listeyi ters çeviriyoruz (çünkü en yeni en üstte geliyor).
    final sortedTests = tests.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedTests.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedTests[i].totalNet));
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return LineChart(
      LineChartData(
        // 1. Izgara (Grid) Ayarları
        gridData: const FlGridData(show: false),

        // 2. Kenarlık Ayarları
        borderData: FlBorderData(show: false),

        // 3. Başlık (Eksen Etiketleri) Ayarları
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Alttaki etiketler (1. Deneme, 2. Deneme vb.)
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('${value.toInt() + 1}.D'),
                );
              },
            ),
          ),
        ),

        // 4. Dokunma (Tooltip) Ayarları - HATANIN DÜZELTİLDİĞİ YER
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) {
              return primaryColor; // Koyu mavi arka plan
            },
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final testIndex = spot.spotIndex;
                final selectedTest = sortedTests[testIndex];
                final date = DateFormat.yMd('tr').format(selectedTest.date);
                final text =
                    '${selectedTest.testName}\n$date\n${selectedTest.totalNet.toStringAsFixed(2)} Net';

                return LineTooltipItem(
                  text,
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),

        // 5. Çizgi Verisi
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: secondaryColor, // Turuncu renk
            barWidth: 2.5, // Kalınlık
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // Noktaları gizle
            belowBarData: BarAreaData(show: false), // Çizgi altını doldurma
          ),
        ],
      ),
    );
  }
}