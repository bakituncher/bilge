// lib/features/stats/widgets/key_stats_grid.dart
import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';

class KeyStatsGrid extends StatelessWidget {
  final StatsAnalysis analysis;
  const KeyStatsGrid({required this.analysis, super.key});

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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
        content: Text(tooltip, style: const TextStyle(color: AppTheme.secondaryTextColor, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Anladım"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => _showInfoDialog(context),
                    child: const Icon(Icons.info_outline, color: AppTheme.secondaryTextColor, size: 20),
                  ),
                ],
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    Icon(icon, color: color, size: 24),
                  ]
              )
            ],
          ),
        ),
      ),
    );
  }
}