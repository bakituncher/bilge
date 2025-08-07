// lib/features/home/screens/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/shared/widgets/stat_card.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_header.dart';
import 'package:bilge_ai/features/home/widgets/todays_mission_card.dart';
import 'package:bilge_ai/features/home/widgets/weekly_parchment.dart';

const List<String> motivationalQuotes = [
  "Başarının sırrı, başlamaktır.",
  "Bugünün emeği, yarının zaferidir.",
  "En büyük zafer, kendine karşı kazandığın zaferdir.",
  "Hayal edebiliyorsan, yapabilirsin.",
  "Küçük adımlar, büyük başarılara götürür.",
  "Disiplin, hedefler ve başarı arasındaki köprüdür.",
  "Vazgeçenler asla kazanamaz, kazananlar asla vazgeçmez."
];

// GÖZLEMCİ WIDGET: Sadece yüklenme ve hata durumlarını kontrol eder.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Kullanıcı verisi yüklenemedi."));
            // Veri hazır olduğunda, asıl işi yapacak olan akıllı Komutan widget'ını çağır.
            return const _DashboardView();
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (e, s) => Center(child: Text("Bir hata oluştu: $e")),
        ),
      ),
    );
  }
}

// KOMUTAN WIDGET: Sadece önemli veriler değiştiğinde yeniden çizim yapar.
class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'Tünaydın';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DÜZELTİLDİ: Artık tüm 'user' objesini değil, SADECE bu ekranın ihtiyaç duyduğu
    // ve sık değişmeyen verileri '.select' ile dinliyoruz.
    // 'completedDailyTasks' haritasındaki değişiklikler bu widget'ı tetiklemeyecek.
    final dashboardUserData = ref.watch(userProfileProvider.select((user) => (
    name: user.value?.name ?? '',
    totalNetSum: user.value?.totalNetSum ?? 0.0,
    streak: user.value?.streak ?? 0
    )));

    final tests = ref.watch(testsProvider).valueOrNull ?? [];
    final randomQuote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];

    final testCount = tests.length;
    final avgNet = testCount > 0 ? dashboardUserData.totalNetSum / testCount : 0.0;
    final bestNet = tests.isEmpty ? 0.0 : tests.map((t) => t.totalNet).reduce(max);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        DashboardHeader(greeting: _getGreeting(), name: dashboardUserData.name),
        const SizedBox(height: 16),
        _buildMotivationalQuoteCard(randomQuote),
        const SizedBox(height: 24),
        _buildStatsRow(context, avgNet, bestNet, dashboardUserData.streak),
        const SizedBox(height: 24),
        const TodaysMissionCard(), // Bu widget kendi verisini kendi yönetir
        const SizedBox(height: 24),
        _buildActionCenter(context),
        const SizedBox(height: 24),
        const WeeklyParchment(), // Bu widget da kendi verisini kendi yönetir
      ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildMotivationalQuoteCard(String quote) {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.format_quote, color: AppTheme.secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quote,
                style: const TextStyle(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, double avgNet, double bestNet, int streak) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: StatCard(icon: Icons.track_changes_rounded, value: avgNet.toStringAsFixed(1), label: 'Ortalama Net', color: Colors.blueAccent, onTap: () => context.go('/home/stats'))),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.emoji_events_rounded, value: bestNet.toStringAsFixed(1), label: 'En Yüksek Net', color: Colors.amber, onTap: () => context.go('/home/stats'))),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.local_fire_department_rounded, value: streak.toString(), label: 'Günlük Seri', color: Colors.orangeAccent, onTap: () => context.go('/home/stats'))),
        ],
      ),
    );
  }

  Widget _buildActionCenter(BuildContext context) {
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