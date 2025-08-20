// lib/features/home/widgets/performance_cluster.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PerformanceCluster extends StatelessWidget {
  final List<TestModel> tests;
  final UserModel user;
  const PerformanceCluster({super.key, required this.tests, required this.user});

  @override
  Widget build(BuildContext context) {
    final avgNet = tests.isNotEmpty ? (user.totalNetSum / tests.length) : 0.0;
    final bestNet = tests.isEmpty ? 0.0 : tests.map((t) => t.totalNet).reduce(max);
    final streak = user.streak;
    final trend = _trend(tests);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _DoubleCircleStat(avg: avgNet, best: bestNet),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _MiniCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Seri',
                value: streak.toString(),
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              _MiniCard(
                icon: trend == 1
                    ? Icons.trending_up_rounded
                    : trend == -1
                        ? Icons.trending_down_rounded
                        : Icons.trending_flat_rounded,
                label: 'Trend',
                value: trend == 1
                    ? 'Yukarı'
                    : trend == -1
                        ? 'Aşağı'
                        : 'Düz',
                color: trend == 1
                    ? Colors.greenAccent
                    : trend == -1
                        ? AppTheme.accentColor
                        : AppTheme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ].animate(interval: 80.ms).fadeIn().slideY(begin: .1),
    );
  }

  int _trend(List<TestModel> tests) {
    if (tests.length < 3) return 0;
    final sorted = [...tests]..sort((a,b)=> a.date.compareTo(b.date));
    final last3 = sorted.takeLast(3).toList();
    final diff = last3.last.totalNet - last3.first.totalNet;
    if (diff > 0.1) return 1;
    if (diff < -0.1) return -1;
    return 0;
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length - n);
}

class _DoubleCircleStat extends StatelessWidget {
  final double avg;
  final double best;
  const _DoubleCircleStat({required this.avg, required this.best});

  @override
  Widget build(BuildContext context) {
    final pct = best == 0 ? 0.0 : (avg / best).clamp(0.0, 1.0).toDouble();
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              valueColor: AlwaysStoppedAnimation(AppTheme.lightSurfaceColor.withValues(alpha: .35)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 10,
              valueColor: const AlwaysStoppedAnimation(AppTheme.secondaryColor),
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(avg.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Ort', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.secondaryTextColor)),
              const SizedBox(height: 4),
              Text('En İyi ${best.toStringAsFixed(1)}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
            ],
          )
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.lightSurfaceColor.withValues(alpha: .5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }
}
