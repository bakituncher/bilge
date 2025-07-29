// lib/features/coach/screens/coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  Map<String, List<String>> _localCompletedTopics = {};

  List<ExamSection> _getRelevantSectionsForUser(UserModel user, Exam exam) {
    if (user.selectedExam == ExamType.lgs.name) {
      return exam.sections;
    } else if (user.selectedExam == ExamType.yks.name) {
      final tytSection = exam.sections.firstWhere((s) => s.name == 'TYT');
      final userAytSection = exam.sections.firstWhere(
            (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      if (tytSection.name == userAytSection.name) return [tytSection];
      return [tytSection, userAytSection];
    } else {
      final relevantSection = exam.sections.firstWhere(
            (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      return [relevantSection];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konu Takip Merkezi'),
      ),
      body: userProfileAsync.when(
        data: (user) {
          if (user == null || user.selectedExam == null) {
            return const Center(child: Text('Lütfen önce profilden bir sınav seçin.'));
          }

          if (_localCompletedTopics.isEmpty && user.completedTopics.isNotEmpty) {
            _localCompletedTopics = user.completedTopics.map((key, value) => MapEntry(key, List<String>.from(value)));
          }

          final examType = ExamType.values.byName(user.selectedExam!);
          final exam = ExamData.getExamByType(examType);
          final List<ExamSection> relevantSections = _getRelevantSectionsForUser(user, exam);

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

              ...relevantSections.expand((section) {
                int sectionIndex = relevantSections.indexOf(section);
                return [
                  if (relevantSections.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text(
                        section.name,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ...section.subjects.entries.map((subjectEntry) {
                    final subjectName = subjectEntry.key;
                    final subjectDetails = subjectEntry.value;
                    int subjectIndex = section.subjects.keys.toList().indexOf(subjectName);

                    return _buildSubjectExpansionTile(
                      context,
                      ref,
                      user,
                      subjectName,
                      subjectDetails.topics,
                    ).animate()
                        .fadeIn(delay: ((sectionIndex * 200) + (subjectIndex * 100)).ms)
                        .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
                  })
                ];
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
    final completedTopicsForSubject = _localCompletedTopics[subjectName] ?? [];
    final progress = topics.isEmpty ? 0.0 : completedTopicsForSubject.length / topics.length;
    final bool isCompleted = progress == 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ✅ HATA DÜZELTİLDİ: Uzun metinlerin taşmasını engellemek için Expanded kullanıldı.
                Expanded(
                  child: Text(
                    subjectName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis, // Çok uzunsa sonunu ... ile bitirir.
                  ),
                ),
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.green.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: progress,
                    ),
                    builder: (context, value, child) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade300,
                      color: isCompleted ? Colors.green.shade600 : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '%${(progress * 100).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        children: topics.map((topic) {
          final isTopicCompleted = completedTopicsForSubject.contains(topic.name);
          return CheckboxListTile(
            title: Text(
              topic.name,
              style: TextStyle(
                  decoration: isTopicCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  color: isTopicCompleted ? Colors.grey.shade600 : null
              ),
            ),
            value: isTopicCompleted,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _localCompletedTopics.putIfAbsent(subjectName, () => []).add(topic.name);
                } else {
                  _localCompletedTopics[subjectName]?.remove(topic.name);
                }
              });

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