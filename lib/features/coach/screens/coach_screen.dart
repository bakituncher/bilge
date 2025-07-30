// lib/features/coach/screens/coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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

          final examType = ExamType.values.byName(user.selectedExam!);
          final exam = ExamData.getExamByType(examType);
          final List<ExamSection> relevantSections = _getRelevantSectionsForUser(user, exam);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Konu Hakimiyetin', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Her konu için çözdüğün soru sayılarını girerek yapay zekanın hakimiyet seviyeni ölçmesini ve sana özel tavsiyeler vermesini sağla.',
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 20),
              ...relevantSections.expand((section) {
                return [
                  if (relevantSections.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text(
                        section.name,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                      ),
                    ),
                  ...section.subjects.entries.map((subjectEntry) {
                    final subjectName = subjectEntry.key;
                    final subjectDetails = subjectEntry.value;
                    return _buildSubjectExpansionTile(context, ref, user, subjectName, subjectDetails.topics)
                        .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
                  })
                ];
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text('Veriler yüklenirken bir hata oluştu: $e')),
      ),
    );
  }

  Widget _buildSubjectExpansionTile(BuildContext context, WidgetRef ref, UserModel user, String subjectName, List<SubjectTopic> topics) {
    final performances = user.topicPerformances[subjectName] ?? {};
    int totalQuestions = 0;
    int totalCorrect = 0;
    performances.forEach((key, value) {
      totalQuestions += value.questionCount;
      totalCorrect += value.correctCount;
    });
    final double overallMastery = totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0, end: overallMastery),
                    builder: (context, value, child) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                      color: Color.lerp(AppTheme.accentColor, AppTheme.successColor, value),
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hakimiyet: %${(overallMastery * 100).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondaryTextColor),
                ),
              ],
            ),
          ],
        ),
        children: topics.map((topic) {
          final performance = performances[topic.name] ?? TopicPerformanceModel();
          final mastery = performance.questionCount == 0 ? 0.0 : (performance.correctCount / performance.questionCount);

          return ListTile(
            title: Text(topic.name, style: const TextStyle(color: AppTheme.textColor)),
            subtitle: _buildMasteryBar(mastery, performance),
            onTap: () {
              _showPerformanceInputDialog(context, ref, user.id, subjectName, topic.name, performance);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMasteryBar(double mastery, TopicPerformanceModel performance) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: mastery,
              backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.3),
              color: Color.lerp(AppTheme.accentColor, AppTheme.successColor, mastery),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          // BİLGEAI DEVRİMİ: İstatistikler artık daha detaylı gösteriliyor.
          Expanded(
            flex: 4,
            child: Text(
              'D:${performance.correctCount} Y:${performance.wrongCount} B:${performance.blankCount}',
              style: const TextStyle(fontSize: 12, color: AppTheme.secondaryTextColor),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  void _showPerformanceInputDialog(BuildContext context, WidgetRef ref, String userId, String subject, String topic, TopicPerformanceModel currentPerformance) {
    final correctController = TextEditingController();
    final wrongController = TextEditingController();
    final blankController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // BİLGEAI DEVRİMİ: Dialog içindeki state yönetimi için (örn: toggle butonu)
    showDialog(
      context: context,
      builder: (context) {
        // true: Üzerine Ekle, false: Değiştir
        bool isAddingMode = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(topic, style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToggleButtons(
                      isSelected: [isAddingMode, !isAddingMode],
                      onPressed: (index) {
                        setState(() { isAddingMode = index == 0; });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: AppTheme.primaryColor,
                      color: Colors.white,
                      fillColor: AppTheme.secondaryColor,
                      selectedBorderColor: AppTheme.secondaryColor,
                      borderColor: AppTheme.lightSurfaceColor,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Üzerine Ekle')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Değiştir')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: correctController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Doğru Sayısı', hintText: isAddingMode ? 'Eklenecek doğru' : 'Toplam doğru'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: wrongController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Yanlış Sayısı', hintText: isAddingMode ? 'Eklenecek yanlış' : 'Toplam yanlış'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: blankController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Boş Sayısı', hintText: isAddingMode ? 'Eklenecek boş' : 'Toplam boş'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Boş bırakılamaz' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal', style: TextStyle(color: AppTheme.secondaryTextColor)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final correct = int.tryParse(correctController.text) ?? 0;
                      final wrong = int.tryParse(wrongController.text) ?? 0;
                      final blank = int.tryParse(blankController.text) ?? 0;

                      TopicPerformanceModel newPerformance;
                      if (isAddingMode) {
                        newPerformance = TopicPerformanceModel(
                          correctCount: currentPerformance.correctCount + correct,
                          wrongCount: currentPerformance.wrongCount + wrong,
                          blankCount: currentPerformance.blankCount + blank,
                          questionCount: currentPerformance.questionCount + correct + wrong + blank,
                        );
                      } else {
                        newPerformance = TopicPerformanceModel(
                          correctCount: correct,
                          wrongCount: wrong,
                          blankCount: blank,
                          questionCount: correct + wrong + blank,
                        );
                      }

                      ref.read(firestoreServiceProvider).updateTopicPerformance(
                        userId: userId,
                        subject: subject,
                        topic: topic,
                        performance: newPerformance,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}