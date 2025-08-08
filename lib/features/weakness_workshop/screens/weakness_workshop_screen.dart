// lib/features/weakness_workshop/screens/weakness_workshop_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/weakness_workshop/models/study_guide_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';

// Atölyenin hangi aşamada olduğunu yöneten durum
enum WorkshopStep { briefing, study, quiz, results }

// Seçilen konuyu ve zorluk seviyesini tutan provider'lar
final _selectedTopicProvider = StateProvider<Map<String, String>?>((ref) => null);
final _difficultyProvider = StateProvider<String>((ref) => 'normal');

// AI'dan gelen çalışma materyalini yöneten ana provider
final workshopSessionProvider = FutureProvider.autoDispose<StudyGuideAndQuiz>((ref) async {
  final selectedTopic = ref.watch(_selectedTopicProvider);
  final difficulty = ref.watch(_difficultyProvider);

  if (selectedTopic == null) {
    return Future.error("Konu seçilmedi.");
  }

  final user = ref.read(userProfileProvider).value;
  final tests = ref.read(testsProvider).value;

  if (user == null || tests == null) {
    return Future.error("Analiz için kullanıcı veya test verisi bulunamadı.");
  }

  final jsonString = await ref.read(aiServiceProvider).generateStudyGuideAndQuiz(
    user,
    tests,
    topicOverride: selectedTopic,
    difficulty: difficulty,
  );

  final decodedJson = jsonDecode(jsonString);
  if (decodedJson.containsKey('error')) {
    throw Exception(decodedJson['error']);
  }
  return StudyGuideAndQuiz.fromJson(decodedJson);
});


class WeaknessWorkshopScreen extends ConsumerStatefulWidget {
  const WeaknessWorkshopScreen({super.key});
  @override
  ConsumerState<WeaknessWorkshopScreen> createState() => _WeaknessWorkshopScreenState();
}

class _WeaknessWorkshopScreenState extends ConsumerState<WeaknessWorkshopScreen> {
  WorkshopStep _currentStep = WorkshopStep.briefing;
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};

  void _startWorkshop(Map<String, String> topic) {
    ref.read(_selectedTopicProvider.notifier).state = topic;
    ref.read(_difficultyProvider.notifier).state = 'normal';
    _currentQuestionIndex = 0;
    _selectedAnswers = {};
    setState(() => _currentStep = WorkshopStep.study);
  }

  void _submitQuiz(StudyGuideAndQuiz material) {
    final user = ref.read(userProfileProvider).value;
    if(user == null) return;

    int correct = 0;
    int wrong = 0;
    material.quiz.asMap().forEach((index, q) {
      if (_selectedAnswers.containsKey(index)) {
        if (_selectedAnswers[index] == q.correctOptionIndex) {
          correct++;
        } else {
          wrong++;
        }
      }
    });
    int blank = material.quiz.length - correct - wrong;

    final currentPerformance = user.topicPerformances[material.subject]?[material.topic] ?? TopicPerformanceModel();
    final newPerformance = TopicPerformanceModel(
      correctCount: currentPerformance.correctCount + correct,
      wrongCount: currentPerformance.wrongCount + wrong,
      blankCount: currentPerformance.blankCount + blank,
      questionCount: currentPerformance.questionCount + material.quiz.length,
    );

    ref.read(firestoreServiceProvider).updateTopicPerformance(
      userId: user.id,
      subject: material.subject,
      topic: material.topic,
      performance: newPerformance,
    );
    setState(() => _currentStep = WorkshopStep.results);
  }

  void _resetToBriefing(){
    ref.read(_selectedTopicProvider.notifier).state = null;
    setState(() => _currentStep = WorkshopStep.briefing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cevher Atölyesi'),
        leading: _currentStep != WorkshopStep.briefing ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: (){
            if(_currentStep == WorkshopStep.results){ _resetToBriefing(); }
            else if(_currentStep == WorkshopStep.quiz){ setState(() => _currentStep = WorkshopStep.study); }
            else { _resetToBriefing(); }
          },
        ) : null,
      ),
      body: AnimatedSwitcher(
        duration: 300.ms,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: _buildCurrentStepView(),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    if (_currentStep == WorkshopStep.briefing) {
      return _BriefingView(key: const ValueKey('briefing'), onTopicSelected: _startWorkshop);
    }

    final sessionAsync = ref.watch(workshopSessionProvider);
    return sessionAsync.when(
      loading: () => Center(key: const ValueKey('loading'), child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text("Cevher işleniyor...", style: TextStyle(color: AppTheme.secondaryTextColor))])),
      error: (e, s) {
        if (e.toString().contains("Konu seçilmedi")) {
          return const Center(key: ValueKey('waiting'), child: CircularProgressIndicator());
        }
        return Center(key: const ValueKey('error'), child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Bir hata oluştu: ${e.toString()}", textAlign: TextAlign.center,)));
      },
      data: (material) {
        switch (_currentStep) {
          case WorkshopStep.study:
            return _StudyView(key: ValueKey('study_${material.topic}'), material: material, onStartQuiz: () => setState(() => _currentStep = WorkshopStep.quiz));
          case WorkshopStep.quiz:
            return _QuizView(key: ValueKey('quiz_${material.topic}'), material: material, onSubmit: _submitQuiz, selectedAnswers: _selectedAnswers, onAnswered: (q, a) => setState(() {
              _selectedAnswers[q] = a;
              if(_currentQuestionIndex < material.quiz.length - 1){ _currentQuestionIndex++; }
            }), questionIndex: _currentQuestionIndex);
          case WorkshopStep.results:
            return _ResultsView(key: ValueKey('results_${material.topic}'), material: material, selectedAnswers: _selectedAnswers, onNextTopic: _resetToBriefing,
                onRetryHarder: () {
                  ref.read(_difficultyProvider.notifier).state = 'hard';
                  _currentQuestionIndex = 0;
                  _selectedAnswers = {};
                  ref.invalidate(workshopSessionProvider);
                  setState(() => _currentStep = WorkshopStep.study);
                });
          default: return const SizedBox.shrink();
        }
      },
    );
  }
}

class _BriefingView extends ConsumerWidget {
  final Function(Map<String, String>) onTopicSelected;
  const _BriefingView({super.key, required this.onTopicSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final tests = ref.watch(testsProvider).value;

    if (user == null || tests == null || user.selectedExam == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Exam>(
        future: ExamData.getExamByType(ExamType.values.byName(user.selectedExam!)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final analysis = StatsAnalysis(tests, user.topicPerformances, snapshot.data!, user: user);
          final suggestions = analysis.getWorkshopSuggestions(count: 3);

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text("Stratejik Mola", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                suggestions.any((s) => s['isSuggestion'] == true)
                    ? "Henüz yeterli verin olmadığı için BilgeAI, yolculuğa başlaman için bazı kilit konuları belirledi. Bunlar 'Keşif Noktaları'dır."
                    : "BilgeAI, performansını analiz etti ve gelişim için en parlak fırsatları belirledi. Aşağıdaki cevherlerden birini seçerek işlemeye başla.",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 24),
              if(suggestions.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Harika! Önerilecek bir zayıf nokta veya fethedilmemiş konu kalmadı.", textAlign: TextAlign.center)))
              else
                ...suggestions.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var topicData = entry.value;
                  final topicForSelection = {'subject': topicData['subject'].toString(),'topic': topicData['topic'].toString(),};
                  return _TopicCard(
                    topic: topicData,
                    isRecommended: idx == 0,
                    onTap: () => onTopicSelected(topicForSelection),
                  ).animate().fadeIn(delay: (200 * idx).ms).slideX(begin: 0.2);
                })
            ],
          );
        });
  }
}

class _TopicCard extends StatelessWidget {
  final Map<String, dynamic> topic;
  final bool isRecommended;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.isRecommended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final masteryValue = topic['mastery'] as double?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended ? const BorderSide(color: AppTheme.secondaryColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text("BİLGEAI ÖNERİSİ", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              if (isRecommended) const SizedBox(height: 8),
              Text(topic['topic']!, style: Theme.of(context).textTheme.titleLarge),
              Text(topic['subject']!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text("Hakimiyet: ", style: Theme.of(context).textTheme.bodySmall),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: masteryValue == null || masteryValue < 0 ? null : masteryValue,
                      backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.3),
                      color: masteryValue == null || masteryValue < 0 ? AppTheme.secondaryTextColor : Color.lerp(AppTheme.accentColor, AppTheme.successColor, masteryValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(masteryValue == null || masteryValue < 0 ? "Keşfet!" : "%${(masteryValue * 100).toStringAsFixed(0)}", style: Theme.of(context).textTheme.bodySmall)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyView extends StatelessWidget {
  final StudyGuideAndQuiz material;
  final VoidCallback onStartQuiz;
  const _StudyView({super.key, required this.material, required this.onStartQuiz});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: MarkdownBody(
                data: material.studyGuide,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textColor),
                  h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                  h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                )
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.quiz_rounded),
            label: const Text("Ustalık Sınavına Başla"),
            onPressed: onStartQuiz,
          ),
        )
      ],
    );
  }
}

class _QuizView extends StatelessWidget {
  final StudyGuideAndQuiz material;
  final Function(StudyGuideAndQuiz) onSubmit;
  final int questionIndex;
  final Map<int,int> selectedAnswers;
  final Function(int, int) onAnswered;

  const _QuizView({super.key, required this.material, required this.onSubmit, required this.questionIndex, required this.selectedAnswers, required this.onAnswered});

  @override
  Widget build(BuildContext context) {
    final question = material.quiz[questionIndex];
    final isAllAnswered = selectedAnswers.length == material.quiz.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Soru ${questionIndex + 1} / ${material.quiz.length}", style: const TextStyle(color: AppTheme.secondaryTextColor)),
                const SizedBox(height: 8),
                Text(question.question, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                ...List.generate(question.options.length, (index) {
                  final isSelected = selectedAnswers[questionIndex] == index;
                  return Card(
                    color: isSelected ? AppTheme.secondaryColor.withOpacity(0.3) : AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? AppTheme.secondaryColor : AppTheme.lightSurfaceColor, width: 1.5)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => onAnswered(questionIndex, index),
                      title: Text(question.options[index]),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: isAllAnswered ? () => onSubmit(material) : null,
            child: const Text("Testi Bitir"),
          ),
        )
      ],
    );
  }
}

class _ResultsView extends ConsumerWidget {
  final StudyGuideAndQuiz material;
  final VoidCallback onNextTopic;
  final VoidCallback onRetryHarder;
  final Map<int, int> selectedAnswers;

  const _ResultsView({super.key, required this.material, required this.onNextTopic, required this.onRetryHarder, required this.selectedAnswers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int correct = 0;
    material.quiz.asMap().forEach((index, q) {
      if (selectedAnswers[index] == q.correctOptionIndex) correct++;
    });
    final score = material.quiz.isEmpty ? 0.0 : (correct / material.quiz.length) * 100;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Ustalık Sınavı Tamamlandı!", style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center,),
          const SizedBox(height: 16),
          Text("%${score.toStringAsFixed(0)}", style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.successColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
          Text("Başarı Oranı", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor), textAlign: TextAlign.center,),
          const SizedBox(height: 24),
          if(score > 79)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text("Bu Konuyu Fethettim"),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                    side: const BorderSide(color: AppTheme.successColor)
                ),
                onPressed: () {
                  final userId = ref.read(authControllerProvider).value!.uid;
                  ref.read(firestoreServiceProvider).markTopicAsMastered(
                      userId: userId,
                      subject: material.subject,
                      topic: material.topic
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${material.topic} fethedildi! Artık önerilmeyecek.")));
                  onNextTopic();
                },
              ),
            ),
          const Spacer(),
          _ResultActionCard(title: "Derinleşmek İstiyorum", subtitle: "Bu konuyla ilgili daha zor sorularla kendini sına.", icon: Icons.auto_awesome, onTap: onRetryHarder),
          const SizedBox(height: 16),
          _ResultActionCard(title: "Sıradaki Cevhere Geç", subtitle: "Başka bir zayıf halkanı güçlendir.", icon: Icons.arrow_forward_rounded, onTap: onNextTopic),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Atölyeden Ayrıl"),
          )
        ],
      ),
    );
  }
}

class _ResultActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ResultActionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.secondaryColor, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }
}