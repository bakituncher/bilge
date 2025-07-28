// lib/features/onboarding/screens/exam_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

final selectedExamProvider = StateProvider<ExamType?>((ref) => null);

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});

  void _onExamTypeSelected(BuildContext context, WidgetRef ref, ExamType examType) async {
    final exam = ExamData.getExamByType(examType);
    final userId = ref.read(authControllerProvider).value!.uid;

    if (examType == ExamType.lgs || exam.sections.length == 1) {
      await ref.read(firestoreServiceProvider).saveExamSelection(
        userId: userId,
        examType: examType,
        sectionName: exam.sections.first.name,
      );

      // ✅ GÜVENLİK DÜZELTMESİ: İşlem bittikten sonra widget'ın hala "canlı" olup olmadığını kontrol et.
      // Bu, "Cannot use 'ref' after the widget was disposed" hatasını çözer.
      if (context.mounted) {
        // ignore: unused_result
        ref.refresh(userProfileProvider);
      }
      return;
    }

    final bool? selectionMade = await showModalBottomSheet<bool>(
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
                ...exam.sections.map(
                      (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(firestoreServiceProvider).saveExamSelection(
                          userId: userId,
                          examType: examType,
                          sectionName: section.name,
                        );
                        Navigator.of(ctx).pop(true);
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

    // ✅ GÜVENLİK DÜZELTMESİ: Aynı kontrol burada da geçerli.
    if (selectionMade == true && context.mounted) {
      // ignore: unused_result
      ref.refresh(userProfileProvider);
    }
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