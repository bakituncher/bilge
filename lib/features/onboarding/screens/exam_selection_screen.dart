// lib/features/onboarding/screens/exam_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Bu provider, seçilen sınavı uygulama genelinde tutar.
// Gerçek bir uygulamada bu, bir veritabanına veya SharedPreferences'e kaydedilir.
final selectedExamProvider = StateProvider<ExamType?>((ref) => null);

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});

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
              ...ExamType.values.map((examType) =>
                  Animate(
                      effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.2))],
                      child: _buildExamCard(context, examType, ref)
                  )
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamType examType, WidgetRef ref){
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: (){
          ref.read(selectedExamProvider.notifier).state = examType;
          // Onboarding'in bir sonraki adımı olan ana ekrana yönlendir
          context.go('/home');
        },
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