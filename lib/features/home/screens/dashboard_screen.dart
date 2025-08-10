import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_header.dart';
import 'package:bilge_ai/features/home/widgets/todays_plan.dart';
import 'package:bilge_ai/shared/widgets/stat_card.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
// KALDIRIN: Artık burada tutorial provider'a ihtiyaç yok.
// import 'packagepackage:bilge_ai/features/onboarding/providers/tutorial_provider.dart';

// Widget'ları vurgulamak için GlobalKey'ler
final GlobalKey todaysPlanKey = GlobalKey();
final GlobalKey addTestKey = GlobalKey();
final GlobalKey coachKey = GlobalKey();
final GlobalKey arenaKey = GlobalKey();
final GlobalKey profileKey = GlobalKey();
final GlobalKey aiHubFabKey = GlobalKey();

// DEĞİŞİKLİK 4: Daha basit bir ConsumerWidget'a geri dönün.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getWarriorTitle(int testCount, double avgNet) {
    if (testCount < 5) return "Acemi Kâşif";
    if (avgNet > 90 && testCount > 20) return "Efsanevi Komutan";
    if (avgNet > 70) return "Usta Stratejist";
    if (testCount > 15) return "Kıdemli Savaşçı";
    return "Azimli Savaşçı";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Kullanıcı verisi yüklenemedi.'));
        }
        final tests = testsAsync.valueOrNull ?? [];
        final testCount = tests.length;
        final avgNet = testCount > 0 ? (user.totalNetSum / testCount) : 0.0;
        final warriorTitle = _getWarriorTitle(testCount, avgNet);

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DashboardHeader(
                name: user.name ?? 'Savaşçı',
                title: warriorTitle,
              ),
            ),
            const SizedBox(height: 24),
            Container(key: todaysPlanKey, child: const TodaysPlan()),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _QuickStats(tests: tests, user: user),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(key: addTestKey, child: _ActionCenter()),
            ),
          ]
              .animate(interval: 80.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
      error: (e, s) => Center(child: Text('Bir hata oluştu: $e')),
    );
  }
}


class _QuickStats extends StatelessWidget {
  final List<TestModel> tests;
  final UserModel user;

  const _QuickStats({required this.tests, required this.user});

  @override
  Widget build(BuildContext context) {
    final avgNet = tests.isNotEmpty ? (user.totalNetSum / tests.length) : 0.0;
    final bestNet = tests.isEmpty ? 0.0 : tests.map((t) => t.totalNet).reduce(max);
    final streak = user.streak;

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: StatCard(icon: Icons.track_changes_rounded, value: avgNet.toStringAsFixed(1), label: 'Ortalama Net', color: Colors.blueAccent, onTap: () => context.push('/home/stats'))),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.emoji_events_rounded, value: bestNet.toStringAsFixed(1), label: 'En Yüksek Net', color: Colors.amber, onTap: () => context.push('/home/stats'))),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.local_fire_department_rounded, value: streak.toString(), label: 'Günlük Seri', color: Colors.orangeAccent, onTap: () => context.push('/profile'))),
        ],
      ),
    );
  }
}

class _ActionCenter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onTap: () => context.go('/home/add-test'),
            icon: Icons.add_chart_outlined,
            label: "Deneme Ekle",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            onTap: () => context.go('/home/pomodoro'),
            icon: Icons.timer_outlined,
            label: "Odaklan",
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _ActionButton({required this.onTap, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.lightSurfaceColor.withOpacity(0.5))
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}