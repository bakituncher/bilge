// lib/features/coach/screens/ai_coach_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

// BİLGEAI DEVRİMİ: Analiz sonucunu ve onu oluşturan veri imzasını tutan state.
final aiAnalysisProvider = StateProvider<({String signature, Map<String, dynamic> data})?>((ref) => null);

class AiCoachNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AiCoachNotifier(this._ref) : super(false);

  Future<void> getCoachingSession() async {
    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;
    if (user == null || tests == null || tests.isEmpty) return;

    // BİLGEAI DEVRİMİ: "Bilge Kasa" - Önbellek Kontrolü
    // Mevcut verilerden bir "imza" oluştur.
    final newSignature = "${user.id}_${tests.length}_${user.topicPerformances.hashCode}";
    final cachedAnalysis = _ref.read(aiAnalysisProvider);

    // Eğer kasada veri varsa ve imza aynıysa, API'yi çağırma.
    if (cachedAnalysis != null && cachedAnalysis.signature == newSignature) {
      debugPrint("Bilge Kasa'dan yüklendi!");
      return;
    }

    debugPrint("Bilge Kasa boş veya geçersiz. API çağrılıyor...");
    state = true;
    try {
      final resultJson = await _ref.read(aiServiceProvider).getCoachingSession(user, tests);
      final decodedData = jsonDecode(resultJson);

      if (decodedData.containsKey("error")) {
        // Hata durumunu da kasaya yaz ki tekrar tekrar aynı hatayı denemesin.
        _ref.read(aiAnalysisProvider.notifier).state = (signature: newSignature, data: decodedData);
      } else if (mounted) {
        // Başarılı sonucu imzasıyla birlikte kasaya kaydet.
        _ref.read(aiAnalysisProvider.notifier).state = (signature: newSignature, data: decodedData);
      }
    } catch (e) {
      if (mounted) {
        _ref.read(aiAnalysisProvider.notifier).state = (signature: newSignature, data: {
          "error": "Analiz oluşturulurken bir hata oluştu: ${e.toString()}"
        });
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }
}

final aiCoachNotifierProvider = StateNotifierProvider.autoDispose<AiCoachNotifier, bool>((ref) {
  return AiCoachNotifier(ref);
});


class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BİLGEAI DEVRİMİ: Artık doğrudan kasadaki veriyi izliyoruz.
    final analysisAsync = ref.watch(aiAnalysisProvider);
    final isLoading = ref.watch(aiCoachNotifierProvider);
    final user = ref.watch(userProfileProvider).value;
    final tests = ref.watch(testsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Stratejik Koçluk')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (analysisAsync == null)
            _buildActionButton(
              context: context,
              isLoading: isLoading,
              isDisabled: user == null || tests == null || tests.isEmpty,
              onPressed: () => ref.read(aiCoachNotifierProvider.notifier).getCoachingSession(),
              icon: Icons.auto_awesome,
              label: 'Analiz ve Plan Oluştur',
            )
          else if (analysisAsync.data.containsKey("error"))
            _buildErrorCard(analysisAsync.data["error"])
          else
            _buildSessionContent(context, analysisAsync.data),


          if(isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
            )
        ],
      ),
    );
  }

  // ... (Geri kalan widget'lar aynı, sadece veri kaynağı değişti)
  Widget _buildErrorCard(String error) {
    return Card(
        color: AppTheme.accentColor.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Hata: $error", style: const TextStyle(color: Colors.white)),
        )
    );
  }

  Widget _buildSessionContent(BuildContext context, Map<String, dynamic> sessionData) {
    final analysisReport = sessionData['analysisReport'] as String?;
    final weeklyPlanData = sessionData['weeklyPlan'] as Map<String, dynamic>?;
    final plan = weeklyPlanData != null ? WeeklyPlan.fromJson(weeklyPlanData) : null;

    return Column(
      children: [
        _buildSectionHeader(context, 'Kişisel Analiz ve Tavsiyeler', Icons.insights_rounded),
        const SizedBox(height: 16),
        if (analysisReport != null)
          _buildMarkdownCard(analysisReport),

        const SizedBox(height: 32),

        _buildSectionHeader(context, 'Haftalık Çalışma Planın', Icons.calendar_today_rounded),
        const SizedBox(height: 16),
        if (plan != null)
          _buildWeeklyPlanWidget(context, plan)
        else
          const Text("Haftalık plan oluşturulamadı."),
      ],
    );
  }
  Widget _buildWeeklyPlanWidget(BuildContext context, WeeklyPlan plan) {
    // ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppTheme.successColor),
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.flag_circle_rounded,
                    color: AppTheme.successColor),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(plan.strategyFocus,
                        style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...plan.plan.map((dailyPlan) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dailyPlan.day,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Divider(height: 20, color: AppTheme.lightSurfaceColor),
                  ...dailyPlan.tasks
                      .map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(Icons.check_box_outline_blank,
                              size: 20,
                              color: AppTheme.secondaryTextColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(task,
                                style: const TextStyle(fontSize: 15))),
                      ],
                    ),
                  ))
                      .toList(),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isLoading,
    required bool isDisabled,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    // ...
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: isLoading || isDisabled ? null : onPressed,
      icon: isLoading ? const SizedBox.shrink() : Icon(icon),
      label: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(label),
    );
  }

  Widget _buildMarkdownCard(String? content) {
    // ...
    return Card(
      elevation: 0,
      color: AppTheme.lightSurfaceColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MarkdownBody(
          data: content ?? "Veri yükleniyor...",
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.secondaryTextColor),
            h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    // ...
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}