// lib/features/home/widgets/todays_mission_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';

class TodaysMissionCard extends ConsumerWidget {
  const TodaysMissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider).valueOrNull;
    final user = ref.watch(userProfileProvider).valueOrNull;

    if (user == null || tests == null) {
      return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator())));
    }
    if (user.selectedExam == null) {
      return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Lütfen bir sınav seçin."))));
    }

    final examType = ExamType.values.byName(user.selectedExam!);

    return FutureBuilder<Exam>(
      future: ExamData.getExamByType(examType),
      builder: (context, examSnapshot) {
        if (examSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator())));
        }
        if (!examSnapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Sınav verisi yüklenemedi."))));
        }

        final exam = examSnapshot.data!;
        final textTheme = Theme.of(context).textTheme;

        IconData icon;
        String title;
        String subtitle;
        VoidCallback? onTap;
        String buttonText;

        if (tests.isEmpty) {
          title = "Yolculuğa Başla";
          subtitle = "Potansiyelini ortaya çıkarmak için ilk deneme sonucunu ekle.";
          onTap = () => context.go('${AppRoutes.home}/${AppRoutes.addTest}');
          buttonText = "İlk Denemeni Ekle";
          icon = Icons.add_chart_rounded;
        } else {
          final analysis = StatsAnalysis(tests, user.topicPerformances, exam, user: user);
          final weakestTopicInfo = analysis.getWeakestTopicWithDetails();
          title = "Günün Önceliği";
          subtitle = weakestTopicInfo != null
              ? "BilgeAI, en zayıf noktanın **'${weakestTopicInfo['subject']}'** dersindeki **'${weakestTopicInfo['topic']}'** konusu olduğunu tespit etti. Bu cevheri işlemeye hazır mısın?"
              : "Harika gidiyorsun! Şu an belirgin bir zayıf noktan tespit edilmedi. Yeni konu verileri girerek analizi derinleştirebilirsin.";
          // HATA DÜZELTİLDİ: .go() -> .push() olarak değiştirildi.
          onTap = weakestTopicInfo != null ? () => context.push('${AppRoutes.aiHub}/${AppRoutes.weaknessWorkshop}') : null;
          buttonText = "Cevher Atölyesine Git";
          icon = Icons.construction_rounded;
        }

        return Card(
          elevation: 4,
          shadowColor: AppTheme.secondaryColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [AppTheme.secondaryColor.withOpacity(0.9), AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 32, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 8),
                  _buildRichTextFromMarkdown(
                      subtitle,
                      baseStyle: textTheme.bodyLarge?.copyWith(color: AppTheme.primaryColor.withOpacity(0.9), height: 1.5),
                      boldStyle: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                        ),
                        child: Text(buttonText),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichTextFromMarkdown(String text, {TextStyle? baseStyle, TextStyle? boldStyle}) {
    List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r"\*\*(.*?)\*\*");
    text.splitMapJoin(regExp,
        onMatch: (m) {
          spans.add(TextSpan(text: m.group(1), style: boldStyle ?? baseStyle?.copyWith(fontWeight: FontWeight.bold)));
          return '';
        },
        onNonMatch: (n) {
          spans.add(TextSpan(text: n));
          return '';
        }
    );
    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}