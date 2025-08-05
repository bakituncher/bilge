// lib/features/onboarding/screens/exam_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});

  void _onExamTypeSelected(BuildContext context, WidgetRef ref, ExamType examType) async {
    final exam = ExamData.getExamByType(examType);
    final userId = ref.read(authControllerProvider).value!.uid;

    // Eğer sınav LGS veya KPSS gibi tek bölümlüyse, direkt kaydet.
    // GoRouter yönlendirmeyi otomatik olarak halledecek.
    if (exam.sections.length == 1) {
      await ref.read(firestoreServiceProvider).saveExamSelection(
        userId: userId,
        examType: examType,
        sectionName: exam.sections.first.name,
      );
      return;
    }

    // YKS gibi çok bölümlü sınavlar için seçim menüsünü göster.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hangi alana hazırlanıyorsun?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...exam.sections
                // TYT'yi listeden çıkarıyoruz çünkü o zaten seçili alanla birlikte geliyor.
                    .where((section) => section.name != 'TYT')
                    .map(
                      (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // **NİHAİ DÜZELTME: SADECE VERİTABANINI GÜNCELLE**
                        // Artık Navigator.pop() komutu KULLANMIYORUZ.
                        // Bu, GoRouter ile olan çakışmayı %100 engeller.
                        // GoRouter, yönlendirmeyi yaparken bu menüyü kendi kapatacak.
                        await ref.read(firestoreServiceProvider).saveExamSelection(
                          userId: userId,
                          examType: examType,
                          sectionName: section.name,
                        );

                        // Gerekirse menüyü yine de kapatmak için bu satır kullanılabilir,
                        // ama en güvenlisi GoRouter'a bırakmaktır. Test için bu satırı
                        // yorumdan çıkarabilirsiniz.
                        // if (ctx.mounted) {
                        //    Navigator.of(ctx).pop();
                        // }
                      },
                      child: Text(section.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Harika!',
                style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Şimdi hazırlanacağın sınavı seçerek yolculuğuna başla.',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 40),
              ...ExamType.values.map(
                    (examType) => Animate(
                  effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.2))],
                  child: _buildExamCard(context, examType, () => _onExamTypeSelected(context, ref, examType)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamType examType, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                examType.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}