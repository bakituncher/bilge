// lib/features/home/screens/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_header.dart';
import 'package:bilge_ai/features/home/widgets/todays_mission_card.dart';
import 'package:bilge_ai/features/home/widgets/todays_plan.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_widgets/motivational_quote_card.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_widgets/dashboard_stats_row.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_widgets/action_center.dart';

// Motivasyon sözleri listesi aynı kalabilir.
const List<String> motivationalQuotes = [
  "Başarının sırrı, başlamaktır.",
  "Bugünün emeği, yarının zaferidir.",
  "En büyük zafer, kendine karşı kazandığın zaferdir.",
  "Hayal edebiliyorsan, yapabilirsin.",
  "Küçük adımlar, büyük başarılara götürür.",
  "Disiplin, hedefler ve başarı arasındaki köprüdür.",
  "Vazgeçenler asla kazanamaz, kazananlar asla vazgeçmez."
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'Tünaydın';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Kullanıcı verisi yüklenemedi."));

            final tests = testsAsync.valueOrNull ?? [];
            final randomQuote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];

            final testCount = tests.length;
            final avgNet = testCount > 0 ? (user.totalNetSum / testCount) : 0.0;
            final bestNet = tests.isEmpty ? 0.0 : tests.map((t) => t.totalNet).reduce(max);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. BÖLÜM: KARŞILAMA VE GENEL DURUM
                // Kullanıcıyı selamlar ve en kritik 3 metriği anında sunar.
                DashboardHeader(greeting: _getGreeting(), name: user.name ?? ''),
                const SizedBox(height: 16),
                DashboardStatsRow(avgNet: avgNet, bestNet: bestNet, streak: user.streak),
                const SizedBox(height: 24),

                // 2. BÖLÜM: GÜNLÜK HAREKAT MERKEZİ
                // "Günün Görevi" ve "Günlük Plan" birleştirilerek tek ve odaklanmış bir bileşen haline getirildi.
                // Bu, kullanıcının "Bugün ne yapmalıyım?" sorusuna net bir cevap verir.
                Text("Günlük Harekat Merkezi", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const TodaysMissionCard(), // Bu kart artık ana görevi belirtiyor.
                const SizedBox(height: 12),
                const TodaysPlan(), // Bu ise o görevi destekleyen adımları listeliyor.
                const SizedBox(height: 24),

                // 3. BÖLÜM: HIZLI EYLEMLER
                // En sık kullanılan iki eylem (Deneme Ekle, Odaklan) artık daha erişilebilir bir konumda.
                Text("Hızlı Eylemler", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const ActionCenter(),
                const SizedBox(height: 24),

                // 4. BÖLÜM: MOTİVASYON
                // Motivasyon kartı, ana eylemlerden sonra gelerek ekranı tamamlar.
                MotivationalQuoteCard(quote: randomQuote),
                const SizedBox(height: 16),

              ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (e, s) => Center(child: Text("Bir hata oluştu: $e")),
        ),
      ),
    );
  }
}