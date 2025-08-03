// lib/features/home/screens/test_result_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/test_model.dart';

class TestResultSummaryScreen extends StatelessWidget {
  final TestModel test;

  const TestResultSummaryScreen({super.key, required this.test});

  // Kullanıcının performansına göre bir "Bilgelik Puanı" hesaplar.
  // Bu puan sadece nete değil, doğruluğa ve çabaya da önem verir.
  double _calculateWisdomScore() {
    if (test.totalQuestions == 0) return 0;

    // Netin katkısı (%60)
    double netContribution = (test.totalNet / test.totalQuestions) * 60;

    // Doğruluk oranının katkısı (%25) - Boş bırakmak yerine yanlış yapmayı cezalandırır.
    final attemptedQuestions = test.totalCorrect + test.totalWrong;
    double accuracyContribution = attemptedQuestions > 0
        ? (test.totalCorrect / attemptedQuestions) * 25
        : 0;

    // Çaba/Katılım oranının katkısı (%15) - Boş bırakmamayı ödüllendirir.
    double effortContribution = (attemptedQuestions / test.totalQuestions) * 15;

    double totalScore = netContribution + accuracyContribution + effortContribution;
    if (totalScore < 0) return 0;
    if (totalScore > 100) return 100;
    return totalScore;
  }

  // Puan aralığına göre uzman yorumu ve unvanı döndürür.
  Map<String, String> _getExpertVerdict(double score) {
    if (score > 85) {
      return {
        "title": "Efsanevi Savaşçı",
        "verdict": "Zirvedeki yerin sarsılmaz. Bilgin bir kılıç gibi keskin, iraden ise bir zırh kadar sağlam. Bu yolda devam et, zafer seni bekliyor."
      };
    } else if (score > 70) {
      return {
        "title": "Usta Stratejist",
        "verdict": "Savaş meydanını okuyorsun. Güçlü ve zayıf yönlerini biliyorsun. Küçük gedikleri kapatarak yenilmez olacaksın. Potansiyelin parlıyor."
      };
    } else if (score > 50) {
      return {
        "title": "Yetenekli Savaşçı",
        "verdict": "Gücün ve cesaretin takdire şayan. Temellerin sağlam, ancak bazı hamlelerinde tereddüt var. Pratik ve odaklanma ile bu savaşı kazanacaksın."
      };
    } else if (score > 30) {
      return {
        "title": "Azimli Acemi",
        "verdict": "Her büyük savaşçı bu yoldan geçti. Kaybettiğin her mevzi, öğrendiğin yeni bir derstir. Azmin en büyük silahın, pes etme."
      };
    } else {
      return {
        "title": "Yolun Başındaki Kâşif",
        "verdict": "Unutma, en uzun yolculuklar tek bir adımla başlar. Bu ilk adımı attın. Şimdi hatalarından öğrenme ve güçlenme zamanı. Yanındayım."
      };
    }
  }

  // En güçlü ve en zayıf dersleri bulan fonksiyon
  Map<String, MapEntry<String, double>> _findKeySubjects() {
    if (test.scores.isEmpty) {
      return {};
    }

    MapEntry<String, double>? strongest;
    MapEntry<String, double>? weakest;

    test.scores.forEach((subject, scoresMap) {
      final net = scoresMap['dogru']! - (scoresMap['yanlis']! * test.penaltyCoefficient);
      if (strongest == null || net > strongest!.value) {
        strongest = MapEntry(subject, net);
      }
      if (weakest == null || net < weakest!.value) {
        weakest = MapEntry(subject, net);
      }
    });

    return {
      'strongest': strongest!,
      'weakest': weakest!,
    };
  }


  @override
  Widget build(BuildContext context) {
    final wisdomScore = _calculateWisdomScore();
    final verdict = _getExpertVerdict(wisdomScore);
    final keySubjects = _findKeySubjects();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Savaş Raporu"),
        automaticallyImplyLeading: false, // Geri tuşunu kaldır
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Bilgelik Puanı ve Uzman Yorumu
          _buildVerdictCard(textTheme, verdict, wisdomScore),
          const SizedBox(height: 24),

          // Temel İstatistikler
          _buildKeyStats(textTheme),
          const SizedBox(height: 24),

          // En Güçlü ve En Zayıf Alanlar
          if (keySubjects.isNotEmpty)
            _buildSubjectHighlights(textTheme, keySubjects),

        ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.dashboard_customize_rounded),
          label: const Text("Ana Panele Dön"),
          onPressed: () {
            // Rapor ekranını kapatıp ana panele yönlendir
            context.go('/home');
          },
        ),
      ),
    );
  }

  Card _buildVerdictCard(TextTheme textTheme, Map<String, String> verdict, double wisdomScore) {
    return Card(
      elevation: 4,
      shadowColor: AppTheme.secondaryColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(verdict['title']!, style: textTheme.headlineSmall?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              "Bilgelik Puanın: ${wisdomScore.toStringAsFixed(1)}",
              style: textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: wisdomScore / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: AppTheme.lightSurfaceColor,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "\"${verdict['verdict']}\"",
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildKeyStats(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(label: "Toplam Net", value: test.totalNet.toStringAsFixed(2)),
            _StatColumn(label: "Doğru", value: test.totalCorrect.toString(), color: AppTheme.successColor),
            _StatColumn(label: "Yanlış", value: test.totalWrong.toString(), color: AppTheme.accentColor),
            _StatColumn(label: "Boş", value: test.totalBlank.toString(), color: AppTheme.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectHighlights(TextTheme textTheme, Map<String, MapEntry<String, double>> keySubjects) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HighlightCard(
                icon: Icons.shield_rounded,
                iconColor: AppTheme.successColor,
                title: "Kal'en (En Güçlü Alan)",
                subject: keySubjects['strongest']!.key,
                net: keySubjects['strongest']!.value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _HighlightCard(
                icon: Icons.construction_rounded,
                iconColor: AppTheme.secondaryColor,
                title: "Cevher (Gelişim Fırsatı)",
                subject: keySubjects['weakest']!.key,
                net: keySubjects['weakest']!.value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "En zayıf alanına odaklanmak, netlerini en hızlı artıracak stratejidir.",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
        )
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatColumn({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color ?? Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subject;
  final double net;

  const _HighlightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subject,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
            const SizedBox(height: 8),
            Text(subject, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("${net.toStringAsFixed(2)} Net", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: iconColor)),
          ],
        ),
      ),
    );
  }
}