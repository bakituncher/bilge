// lib/features/home/screens/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_header.dart';
import 'package:bilge_ai/features/home/widgets/todays_mission_card.dart';
// DEĞİŞİKLİK: Eski widget'ı silip yenisini ekliyoruz
import 'package:bilge_ai/features/home/widgets/todays_plan.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_widgets/motivational_quote_card.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_widgets/dashboard_stats_row.dart';
import 'package:bilge_ai/features/home/widgets/dashboard_widgets/action_center.dart';

const List<String> motivationalQuotes = [
  "Başarının sırrı, başlamaktır.",
  "Bugünün emeği, yarının zaferidir.",
  "En büyük zafer, kendine karşı kazandığın zaferdir.",
  "Hayal edebiliyorsan, yapabilirsin.",
  "Küçük adımlar, büyük başarılara götürür.",
  "Disiplin, hedefler ve başarı arasındaki köprüdür.",
  "Vazgeçenler asla kazanamaz, kazananlar asla vazgeçmez.",
  "Her zorlukla beraber bir kolaylık vardır.",
  "Başarı, hazırlığın fırsatla buluştuğu yerdir.",
  "Zamanı iyi kullan, çünkü o senin en değerli varlığındır",
  "Başarı, cesaretin ve azmin birleşimidir.",
  "Hayatta en büyük risk, hiç risk almamaktır.",
  "Başarı, düşmek değil, her düştüğünde kalkmaktır.",
  "Kendine inan, çünkü senin potansiyelin sınırsız.",
  "Zamanı iyi Cullan, çünkü o senin en değerli varlığındır",
  "Başarı, cesaretin ve azmin birleşimidir.",
  "Hayatta en büyük risk, hiç risk almamaktır.",
  "Başarı, düşmek değil, her düştüğünde kalkmaktır.",
  "Kendine inan, çünkü senin potansiyelin sınırsız.",
  "Her yeni gün, yeni bir başlangıçtır.",
  "Zorluklar, seni daha güçlü yapar.",
  "Başarı, hedeflerine ulaşmak için attığın adımlardır.",
  "Hayallerini gerçekleştirmenin ilk adımı, onlara inanmandır.",
  "Başarı, azim ve kararlılıkla elde edilir.",
  "Her başarısızlık, başarıya giden yolda bir adımdır.",
  "Kendini geliştir, çünkü senin potansiyelin sınırsız.",
  "Başarı, cesaretin ve azmin birleşimidir.",
  "Hayatta en büyük risk, hiç risk almamaktır.",
  "Başarı, düşmek değil, her düştüğünde kalkmaktır.",
  "Kendine inan, çünkü senin potansiyelin sınırsız.",
  "Her yeni gün, yeni bir başlangıçtır.",
  "Zorluklar, seni daha güçlü yapar.",
  "Başarı, hedeflerine ulaşmak için attığın adımlardır.",
  "Hayallerini gerçekleştirmenin ilk adımı, onlara inanmandır.",

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
                DashboardHeader(greeting: _getGreeting(), name: user.name ?? ''),
                const SizedBox(height: 16),
                MotivationalQuoteCard(quote: randomQuote),
                const SizedBox(height: 24),
                DashboardStatsRow(avgNet: avgNet, bestNet: bestNet, streak: user.streak),
                const SizedBox(height: 24),
                const TodaysMissionCard(),
                const SizedBox(height: 24),
                const ActionCenter(),
                const SizedBox(height: 24),
                // DEĞİŞİKLİK: Eski widget'ı silip yenisini ekliyoruz
                const TodaysPlan(),
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