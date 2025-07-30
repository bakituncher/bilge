// lib/features/weakness_workshop/screens/weakness_workshop_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/weakness_workshop/models/study_guide_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:go_router/go_router.dart';

enum WorkshopState { idle, loading, guide, quiz, results }

final workshopProvider = StateNotifierProvider.autoDispose<WorkshopNotifier, AsyncValue<StudyGuideAndQuiz>>((ref) {
  return WorkshopNotifier(ref);
});

class WorkshopNotifier extends StateNotifier<AsyncValue<StudyGuideAndQuiz>> {
  final Ref _ref;
  WorkshopNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> generateMaterial() async {
    state = const AsyncValue.loading();
    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;

    if (user == null || tests == null || tests.isEmpty) {
      state = AsyncValue.error("Analiz için yeterli veri bulunmuyor.", StackTrace.current);
      return;
    }

    try {
      final jsonString = await _ref.read(aiServiceProvider).generateStudyGuideAndQuiz(user, tests);
      final decodedJson = jsonDecode(jsonString);
      if (decodedJson.containsKey('error')) {
        throw Exception(decodedJson['error']);
      }
      final material = StudyGuideAndQuiz.fromJson(decodedJson);
      state = AsyncValue.data(material);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

class WeaknessWorkshopScreen extends ConsumerStatefulWidget {
  const WeaknessWorkshopScreen({super.key});

  @override
  ConsumerState<WeaknessWorkshopScreen> createState() => _WeaknessWorkshopScreenState();
}

class _WeaknessWorkshopScreenState extends ConsumerState<WeaknessWorkshopScreen> {
  WorkshopState _currentState = WorkshopState.idle;
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {}; // {questionIndex: selectedOptionIndex}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workshopProvider.notifier).generateMaterial();
    });
  }

  void _startQuiz() {
    setState(() {
      _currentState = WorkshopState.quiz;
      _currentQuestionIndex = 0;
      _selectedAnswers = {};
    });
  }

  void _submitQuiz(StudyGuideAndQuiz material) {
    int correct = 0;
    int wrong = 0;
    for (int i = 0; i < material.quiz.length; i++) {
      if (_selectedAnswers.containsKey(i)) {
        if (_selectedAnswers[i] == material.quiz[i].correctOptionIndex) {
          correct++;
        } else {
          wrong++;
        }
      }
    }
    int blank = material.quiz.length - correct - wrong;

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

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

    setState(() => _currentState = WorkshopState.results);
  }

  @override
  Widget build(BuildContext context) {
    final workshopAsync = ref.watch(workshopProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cevher Atölyesi')),
      body: workshopAsync.when(
        data: (material) {
          // İlk yükleme tamamlandığında durumu 'guide' olarak ayarla
          if (_currentState == WorkshopState.idle || _currentState == WorkshopState.loading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _currentState = WorkshopState.guide);
              }
            });
          }
          switch (_currentState) {
            case WorkshopState.idle:
            case WorkshopState.loading:
              return _buildLoadingView(material.topic);
            case WorkshopState.guide:
              return _buildStudyGuideView(material);
            case WorkshopState.quiz:
              return _buildQuizView(material);
            case WorkshopState.results:
              return _buildResultsView(material);
          }
        },
        loading: () => _buildLoadingView("Zayıf konu belirleniyor..."),
        error: (e, s) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: _buildFab(workshopAsync.valueOrNull),
    );
  }

  Widget? _buildFab(StudyGuideAndQuiz? material) {
    if (material == null || _currentState == WorkshopState.loading || _currentState == WorkshopState.idle) return null;

    String text = "";
    IconData icon = Icons.play_arrow_rounded;
    VoidCallback? onPressed;

    switch (_currentState) {
      case WorkshopState.guide:
        text = "Teste Başla";
        icon = Icons.quiz_rounded;
        onPressed = _startQuiz;
        break;
      case WorkshopState.quiz:
        text = "Testi Bitir";
        icon = Icons.check_circle_rounded;
        onPressed = _selectedAnswers.length == material.quiz.length ? () => _submitQuiz(material) : null;
        break;
      case WorkshopState.results:
        text = "Atölyeden Çık";
        icon = Icons.exit_to_app_rounded;
        onPressed = () => context.pop();
        break;
      default:
        return null;
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(text),
      icon: Icon(icon),
    ).animate().slide(begin: const Offset(0, 2)).fadeIn();
  }

  Widget _buildLoadingView(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.secondaryColor),
          const SizedBox(height: 20),
          Text(text, style: const TextStyle(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildStudyGuideView(StudyGuideAndQuiz material) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: material.studyGuide,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textColor),
          h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
          h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.underline, decorationColor: AppTheme.successColor),
          listBullet: const TextStyle(fontSize: 16, color: AppTheme.textColor),
        ),
      ),
    );
  }

  Widget _buildQuizView(StudyGuideAndQuiz material) {
    final question = material.quiz[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Soru ${_currentQuestionIndex + 1} / ${material.quiz.length}", style: const TextStyle(color: AppTheme.secondaryTextColor)),
          const SizedBox(height: 8),
          Text(question.question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          ...List.generate(question.options.length, (index) {
            final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
            return Card(
              color: isSelected ? AppTheme.secondaryColor.withOpacity(0.3) : AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? AppTheme.secondaryColor : AppTheme.lightSurfaceColor, width: 1.5)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentQuestionIndex] = index;
                    if (_currentQuestionIndex < material.quiz.length - 1) {
                      _currentQuestionIndex++;
                    }
                  });
                },
                title: Text(question.options[index]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultsView(StudyGuideAndQuiz material) {
    int correct = 0;
    material.quiz.asMap().forEach((index, q) {
      if (_selectedAnswers[index] == q.correctOptionIndex) correct++;
    });
    final score = (correct / material.quiz.length) * 100;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Test Tamamlandı!", style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          Text("Başarı Oranın", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.secondaryTextColor)),
          Text("%${score.toStringAsFixed(0)}", style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text(
            "Sonuçların konu hakimiyet verilerine eklendi.\nBilgeAI, bir sonraki analizinde bu sonucu dikkate alacak.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}