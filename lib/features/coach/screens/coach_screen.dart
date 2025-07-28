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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konu Takip Merkezi'),
      ),
      body: userProfileAsync.when(
        data: (user) {
          if (user?.selectedExam == null) {
            return const Center(child: Text('Lütfen önce profilden bir sınav seçin.'));
          }

          final examType = ExamType.values.byName(user!.selectedExam!);
          final exam = ExamData.getExamByType(examType);

          // ✅ DÜZELTME: LGS ise tüm dersleri, YKS/KPSS ise sadece ilgili bölümün derslerini al.
          Map<String, SubjectDetails> subjectsToShow = {};
          if (examType == ExamType.lgs) {
            // LGS için tüm bölümlerdeki dersleri birleştir.
            for (var section in exam.sections) {
              subjectsToShow.addAll(section.subjects);
            }
          } else {
            // YKS ve KPSS için sadece kullanıcının seçtiği bölümün derslerini al.
            final relevantSection = exam.sections.firstWhere(
                  (s) => s.name == user.selectedExamSection,
              orElse: () => exam.sections.first,
            );
            subjectsToShow = relevantSection.subjects;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Konu İlerlemen', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Bitirdiğin konuları işaretleyerek yapay zekanın sana daha isabetli önerilerde bulunmasını sağla.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ...subjectsToShow.entries.map((subjectEntry) {
                final subjectName = subjectEntry.key;
                final subjectDetails = subjectEntry.value;
                int index = subjectsToShow.keys.toList().indexOf(subjectName);
                return _buildSubjectExpansionTile(
                  context,
                  ref,
                  user,
                  subjectName,
                  subjectDetails.topics,
                ).animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
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
      List<SubjectTopic> topics,
      ) {
    final completedTopicsForSubject = user.completedTopics[subjectName] ?? [];
    final progress = topics.isEmpty ? 0.0 : completedTopicsForSubject.length / topics.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '%${(progress * 100).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        children: topics.map((topic) {
          final isCompleted = completedTopicsForSubject.contains(topic.name);
          return CheckboxListTile(
            title: Text(topic.name),
            value: isCompleted,
            onChanged: (bool? value) {
              // Butona basıldığında anlık olarak UI'da değişiklik olmasını sağla
              // ve ardından Firestore'a yaz.
              ref.read(firestoreServiceProvider).updateCompletedTopic(
                userId: user.id,
                subject: subjectName,
                topic: topic.name,
                isCompleted: value ?? false,
              );
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Theme.of(context).colorScheme.primary,
          );
        }).toList(),
      ),
    );
  }
}