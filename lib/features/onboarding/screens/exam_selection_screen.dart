// lib/features/onboarding/screens/exam_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});

  // GÖREV 1: KPSS için alt seçim menüsü gösteren fonksiyon.
  void _showKpssSubTypeSelection(BuildContext context, WidgetRef ref) {
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
                  'Hangi KPSS türüne hazırlanıyorsun?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _onExamTypeSelected(context, ref, ExamType.kpssLisans);
                    },
                    child: const Text("Lisans"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _onExamTypeSelected(context, ref, ExamType.kpssOnlisans);
                    },
                    child: const Text("Önlisans"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _onExamTypeSelected(context, ref, ExamType.kpssOrtaogretim);
                    },
                    child: const Text("Ortaöğretim"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // GÖREV 2: LGS için bölüm seçtirme sorununu çözen güncellenmiş mantık.
  void _onExamTypeSelected(BuildContext context, WidgetRef ref, ExamType examType) async {
    final exam = await ExamData.getExamByType(examType);
    final userId = ref.read(authControllerProvider).value!.uid;

    // LGS DÜZELTMESİ: LGS seçildiğinde, bölüm sormadan doğrudan kaydet ve ilerle.
    if (examType == ExamType.lgs) {
      await ref.read(firestoreServiceProvider).saveExamSelection(
        userId: userId,
        examType: examType,
        sectionName: "LGS", // LGS için genel bir bölüm adı kullanılıyor.
      );
      if (context.mounted) context.go(AppRoutes.availability);
      return;
    }

    // YKS ve KPSS (tek bölümlü olduğu için) bu mantıkla doğru çalışır.
    if (exam.sections.length == 1) {
      await ref.read(firestoreServiceProvider).saveExamSelection(
        userId: userId,
        examType: examType,
        sectionName: exam.sections.first.name,
      );
      if (context.mounted) context.go(AppRoutes.availability);
      return;
    }

    // Bu kısım artık sadece YKS için çalışacak.
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
                    .where((section) => section.name != 'TYT')
                    .map(
                      (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(firestoreServiceProvider).saveExamSelection(
                          userId: userId,
                          examType: examType,
                          sectionName: section.name,
                        );
                        if (context.mounted) context.go(AppRoutes.availability);
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
              // GÜNCELLENMİŞ YAPI: Sınavlar artık manuel olarak listeleniyor.
              Animate(
                effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.2))],
                child: _buildExamCard(context, "YKS", () => _onExamTypeSelected(context, ref, ExamType.yks)),
              ),
              Animate(
                effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.2))],
                child: _buildExamCard(context, "LGS", () => _onExamTypeSelected(context, ref, ExamType.lgs)),
              ),
              Animate(
                effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.2))],
                child: _buildExamCard(context, "KPSS", () => _showKpssSubTypeSelection(context, ref)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // GÜNCELLENMİŞ YAPI: Bu widget artık ExamType yerine doğrudan bir metin alıyor.
  Widget _buildExamCard(BuildContext context, String displayName, VoidCallback onTap) {
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
                displayName,
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