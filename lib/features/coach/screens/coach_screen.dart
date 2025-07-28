// lib/features/coach/screens/coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konu Takip Merkezi'),
      ),
      body: userProfileAsync.when(
        data: (user) {
          if (user?.selectedExam == null) {
            return const Center(child: Text('Lütfen önce bir sınav seçin.'));
          }

          final examType = ExamType.values.byName(user!.selectedExam!);
          final exam = ExamData.getExamByType(examType);
          final relevantSection = exam.sections.firstWhere(
                (s) => s.name == user.selectedExamSection,
            orElse: () => exam.sections.first,
          );
          final subjects = relevantSection.subjects;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Konu İlerlemen', style: textTheme.headlineSmall),
              Text(
                'Bitirdiğin konuları işaretleyerek yapay zekanın sana daha isabetli önerilerde bulunmasını sağla.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...subjects.entries.map((subjectEntry) {
                final subjectName = subjectEntry.key;
                final subjectDetails = subjectEntry.value;
                return Animate(
                  effects: const [FadeEffect(), SlideEffect(begin: Offset(-0.1, 0))],
                  child: _buildSubjectExpansionTile(
                    context,
                    ref,
                    user,
                    subjectName,
                    subjectDetails.topics, // DÜZELTME: Doğru veri yapısı kullanıldı
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Veriler yüklenirken bir hata oluştu: $e')),
      ),
    );
  }

  Widget _buildSubjectExpansionTile(
      BuildContext context,
      WidgetRef ref,
      UserModel user,
      String subjectName,
      List<SubjectTopic> topics, // DÜZELTME: Doğru tip belirtildi
      ) {
    final completedTopicsForSubject = user.completedTopics[subjectName] ?? [];
    final progress = topics.isEmpty ? 0.0 : completedTopicsForSubject.length / topics.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '%${(progress * 100).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        children: topics.map((topic) {
          final isCompleted = completedTopicsForSubject.contains(topic.name);
          return CheckboxListTile(
            title: Text(topic.name), // DÜZELTME: Null safety sağlandı
            value: isCompleted,
            onChanged: (bool? value) {
              ref.read(firestoreServiceProvider).updateCompletedTopic(
                userId: user.id,
                subject: subjectName,
                topic: topic.name, // DÜZELTME: Null safety sağlandı
                isCompleted: value ?? false,
              );
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ),
    );
  }
}