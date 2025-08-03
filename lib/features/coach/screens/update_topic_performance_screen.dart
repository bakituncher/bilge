// lib/features/coach/screens/update_topic_performance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    // Hakimiyet hesaplaması
    final finalCorrect = isAddingMode ? initialPerformance.correctCount + correct : correct;
    final finalWrong = isAddingMode ? initialPerformance.wrongCount + wrong : wrong;
    final finalBlank = isAddingMode ? initialPerformance.blankCount - correct - wrong : 0; // Değiştir modunda boş olmaz
    final finalTotal = finalCorrect + finalWrong + (isAddingMode ? finalBlank : 0);
    final double mastery = finalTotal == 0 ? 0.0 : (finalCorrect / finalTotal).clamp(0.0, 1.0);


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
            _ScoreSlider(
              label: isAddingMode ? "Eklenecek Doğru" : "Toplam Doğru",
              value: correct.toDouble(),
              max: 200, // Yüksek bir limit
              color: AppTheme.successColor,
              onChanged: (value) => ref.read(_correctCountProvider.notifier).state = value.toInt(),
            ),
            _ScoreSlider(
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
                final newPerformance = TopicPerformanceModel(
                  correctCount: finalCorrect,
                  wrongCount: finalWrong,
                  blankCount: finalBlank < 0 ? 0 : finalBlank, // Boş negatif olamaz
                  questionCount: finalCorrect + finalWrong + (finalBlank < 0 ? 0 : finalBlank),
                );
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

class _ScoreSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final Function(double) onChanged;

  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toInt()}", style: Theme.of(context).textTheme.titleLarge),
        Slider(
          value: value,
          max: max,
          divisions: max.toInt(),
          label: value.toInt().toString(),
          activeColor: color,
          inactiveColor: color.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }
}