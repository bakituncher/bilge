// lib/features/coach/screens/update_topic_performance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/shared/widgets/score_slider.dart';

// State Management Provider'ları
final _updateModeProvider = StateProvider.autoDispose<bool>((ref) => true); // true: Ekle, false: Değiştir
final _correctCountProvider = StateProvider.autoDispose<int>((ref) => 0);
final _wrongCountProvider = StateProvider.autoDispose<int>((ref) => 0);

class UpdateTopicPerformanceScreen extends ConsumerWidget {
  final String subject;
  final String topic;
  final TopicPerformanceModel initialPerformance;

  const UpdateTopicPerformanceScreen({
    super.key,
    required this.subject,
    required this.topic,
    required this.initialPerformance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isAddingMode = ref.watch(_updateModeProvider);
    final correct = ref.watch(_correctCountProvider);
    final wrong = ref.watch(_wrongCountProvider);

    // HAKİMİYET HESAPLAMASI (DÜZELTİLDİ)
    final double mastery;
    if (isAddingMode) {
      final finalCorrect = initialPerformance.correctCount + correct;
      final finalTotalQuestions = initialPerformance.questionCount + correct + wrong;
      mastery = finalTotalQuestions == 0 ? 0.0 : (finalCorrect / finalTotalQuestions).clamp(0.0, 1.0);
    } else { // Değiştir Modu
      final finalTotalQuestions = correct + wrong;
      mastery = finalTotalQuestions == 0 ? 0.0 : (correct / finalTotalQuestions).clamp(0.0, 1.0);
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(topic),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Mod Seçimi
            _buildModeSelector(context, ref),
            const SizedBox(height: 32),

            // 2. Hakimiyet Mührü
            _buildMasteryGauge(context, mastery),
            const SizedBox(height: 32),

            // 3. Kaydırıcılar
            ScoreSlider(
              label: isAddingMode ? "Eklenecek Doğru" : "Toplam Doğru",
              value: correct.toDouble(),
              max: 200, // Yüksek bir limit
              color: AppTheme.successColor,
              onChanged: (value) => ref.read(_correctCountProvider.notifier).state = value.toInt(),
            ),
            ScoreSlider(
              label: isAddingMode ? "Eklenecek Yanlış" : "Toplam Yanlış",
              value: wrong.toDouble(),
              max: 200,
              color: AppTheme.accentColor,
              onChanged: (value) => ref.read(_wrongCountProvider.notifier).state = value.toInt(),
            ),
            const Spacer(),

            // 4. Kaydet Butonu
            ElevatedButton(
              onPressed: () {
                final userId = ref.read(authControllerProvider).value!.uid;

                // KAYDETME MANTIĞI (DÜZELTİLDİ)
                TopicPerformanceModel newPerformance;
                if (isAddingMode) {
                  newPerformance = TopicPerformanceModel(
                    correctCount: initialPerformance.correctCount + correct,
                    wrongCount: initialPerformance.wrongCount + wrong,
                    blankCount: initialPerformance.blankCount, // Eski boşlar korunur
                    questionCount: initialPerformance.questionCount + correct + wrong, // Toplam soru sayısı artar
                  );
                } else { // Değiştir Modu
                  newPerformance = TopicPerformanceModel(
                    correctCount: correct,
                    wrongCount: wrong,
                    blankCount: 0, // Bu modda boş soru olmadığı varsayılır
                    questionCount: correct + wrong,
                  );
                }

                ref.read(firestoreServiceProvider).updateTopicPerformance(
                  userId: userId,
                  subject: subject,
                  topic: topic,
                  performance: newPerformance,
                );
                context.pop();
              },
              child: const Text("Cevheri İşle ve Kaydet"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, WidgetRef ref) {
    final isAddingMode = ref.watch(_updateModeProvider);
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            title: "Üzerine Ekle",
            subtitle: "Mevcut istatistiklere ekleme yap.",
            icon: Icons.add_circle_outline_rounded,
            isSelected: isAddingMode,
            onTap: () {
              ref.read(_updateModeProvider.notifier).state = true;
              ref.invalidate(_correctCountProvider);
              ref.invalidate(_wrongCountProvider);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ModeCard(
            title: "Değiştir",
            subtitle: "Tüm istatistikleri sıfırdan gir.",
            icon: Icons.sync_rounded,
            isSelected: !isAddingMode,
            onTap: () {
              ref.read(_updateModeProvider.notifier).state = false;
              ref.invalidate(_correctCountProvider);
              ref.invalidate(_wrongCountProvider);
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMasteryGauge(BuildContext context, double mastery) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 180,
      height: 180,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: mastery),
        duration: 400.ms,
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(AppTheme.accentColor, AppTheme.successColor, value)!,
                ),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "%${(value * 100).toStringAsFixed(0)}",
                      style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      "Hakimiyet",
                      style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor.withOpacity(0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryColor : AppTheme.lightSurfaceColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.secondaryColor : AppTheme.secondaryTextColor, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
          ],
        ),
      ),
    );
  }
}