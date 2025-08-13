// lib/features/weakness_workshop/screens/weakness_workshop_screen.dart
import 'dart:async';
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
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';

// 🚀 QUANTUM ATÖLYE AŞAMALARI - 2500'LERİN TEKNOLOJİSİ
enum WorkshopStep { 
  quantumBriefing, 
  quantumStudy, 
  quantumQuiz, 
  quantumResults,
  quantumAnalysis,
  quantumOptimization 
}

// 🧠 QUANTUM ZORLUK SEVİYELERİ
enum QuantumDifficulty { 
  quantum, 
  singularity, 
  hyperdrive, 
  transcendence 
}

// 🚀 QUANTUM AI ANALİZ DURUMU
enum QuantumAnalysisPhase { 
  patternRecognition, 
  weaknessMapping, 
  adaptiveLearning, 
  quantumOptimization,
  singularityActivation 
}

// Seçilen konuyu ve quantum zorluk seviyesini tutan provider'lar
final _selectedTopicProvider = StateProvider<Map<String, String>?>((ref) => null);
final _quantumDifficultyProvider = StateProvider<QuantumDifficulty>((ref) => QuantumDifficulty.quantum);
final _quantumAnalysisPhaseProvider = StateProvider<QuantumAnalysisPhase>((ref) => QuantumAnalysisPhase.patternRecognition);

// 🧠 QUANTUM AI'dan gelen çalışma materyalini yöneten ana provider
final quantumWorkshopSessionProvider = FutureProvider.autoDispose<StudyGuideAndQuiz>((ref) async {
  final selectedTopic = ref.watch(_selectedTopicProvider);
  final difficulty = ref.watch(_quantumDifficultyProvider);

  if (selectedTopic == null) {
    return Future.error("Konu seçilmedi.");
  }

  final user = ref.read(userProfileProvider).value;
  final tests = ref.read(testsProvider).value;

  if (user == null || tests == null) {
    return Future.error("Quantum analiz için kullanıcı veya test verisi bulunamadı.");
  }

  // 🚀 QUANTUM AI ANALİZ BAŞLAT
  await _performQuantumAnalysis(ref);
  
  // 🧠 QUANTUM AI MATERYAL ÜRETİMİ
  final jsonString = await ref.read(aiServiceProvider).generateQuantumStudyGuideAndQuiz(
    user,
    tests,
    topicOverride: selectedTopic,
    difficulty: difficulty.name,
  ).timeout(
    const Duration(seconds: 45),
    onTimeout: () => throw TimeoutException("Quantum AI çok uzun süredir yanıt vermiyor. Lütfen tekrar deneyin."),
  );

  final decodedJson = jsonDecode(jsonString);
  if (decodedJson.containsKey('error')) {
    throw Exception(decodedJson['error']);
  }
  return StudyGuideAndQuiz.fromJson(decodedJson);
});

// 🧠 QUANTUM AI ANALİZ SÜRECİ
Future<void> _performQuantumAnalysis(Ref ref) async {
  final phases = QuantumAnalysisPhase.values;
  
  for (int i = 0; i < phases.length; i++) {
    ref.read(_quantumAnalysisPhaseProvider.notifier).state = phases[i];
    await Future.delayed(Duration(milliseconds: 600 + (i * 150)));
  }
}

// 🚀 QUANTUM CEVHER ATÖLYESİ EKRANI - 2500'LERİN TEKNOLOJİSİ
class WeaknessWorkshopScreen extends ConsumerStatefulWidget {
  const WeaknessWorkshopScreen({super.key});
  @override
  ConsumerState<WeaknessWorkshopScreen> createState() => _WeaknessWorkshopScreenState();
}

class _WeaknessWorkshopScreenState extends ConsumerState<WeaknessWorkshopScreen> {
  WorkshopStep _currentStep = WorkshopStep.quantumBriefing;
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  QuantumAnalysisPhase _currentAnalysisPhase = QuantumAnalysisPhase.patternRecognition;

  void _startQuantumWorkshop(Map<String, String> topic) {
    ref.read(_selectedTopicProvider.notifier).state = topic;
    ref.read(_quantumDifficultyProvider.notifier).state = QuantumDifficulty.quantum;
    _currentQuestionIndex = 0;
    _selectedAnswers = {};
    setState(() => _currentStep = WorkshopStep.quantumStudy);
  }

  void _submitQuantumQuiz(StudyGuideAndQuiz material) {
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
      subject: material.subject,
      topic: material.topic,
      correctCount: currentPerformance.correctCount + correct,
      wrongCount: currentPerformance.wrongCount + wrong,
      blankCount: currentPerformance.blankCount + blank,
    );

    // 🚀 QUANTUM PERFORMANS GÜNCELLEMESİ
    ref.read(userProfileProvider.notifier).update((state) {
      if (state == null) return state;
      
      final updatedPerformances = Map<String, Map<String, TopicPerformanceModel>>.from(state.topicPerformances);
      updatedPerformances.putIfAbsent(material.subject, () => {});
      updatedPerformances[material.subject]![material.topic] = newPerformance;
      
      return state.copyWith(topicPerformances: updatedPerformances);
    });

    setState(() => _currentStep = WorkshopStep.quantumResults);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final tests = ref.watch(testsProvider);
    final analysisPhase = ref.watch(_quantumAnalysisPhaseProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text("Kullanıcı verisi bulunamadı.")));
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.psychology, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                const Text('QUANTUM CEVHER ATÖLYESİ'),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: AnimatedSwitcher(
            duration: 600.ms,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildQuantumStep(context, ref, user, tests.valueOrNull ?? [], analysisPhase),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))),
      error: (e, s) => Scaffold(body: Center(child: Text("Hata: $e"))),
    );
  }

  Widget _buildQuantumStep(BuildContext context, WidgetRef ref, UserModel user, List<TestModel> tests, QuantumAnalysisPhase analysisPhase) {
    switch (_currentStep) {
      case WorkshopStep.quantumBriefing:
        return _buildQuantumBriefingView(context, ref, user, tests);
      case WorkshopStep.quantumStudy:
        return _buildQuantumStudyView(context, ref, user, tests, analysisPhase);
      case WorkshopStep.quantumQuiz:
        return _buildQuantumQuizView(context, ref, user, tests);
      case WorkshopStep.quantumResults:
        return _buildQuantumResultsView(context, ref, user, tests);
      case WorkshopStep.quantumAnalysis:
        return _buildQuantumAnalysisView(context, ref, analysisPhase);
      case WorkshopStep.quantumOptimization:
        return _buildQuantumOptimizationView(context, ref, analysisPhase);
      default:
        return const SizedBox.shrink();
    }
  }

  // 🚀 QUANTUM BİLGİLENDİRME GÖRÜNÜMÜ
  Widget _buildQuantumBriefingView(BuildContext context, WidgetRef ref, UserModel user, List<TestModel> tests) {
    if (tests.isEmpty) {
      return _buildQuantumDataMissingView(context);
    }

    final topicPerformances = user.topicPerformances;
    final weakTopics = _identifyQuantumWeaknesses(topicPerformances, tests);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.accentColor, size: 32),
              const SizedBox(width: 12),
              Text(
                "QUANTUM CEVHER ATÖLYESİ",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            "Quantum AI, senin zayıf alanlarını analiz etti ve quantum optimize edilmiş çalışma materyali hazırladı.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            "🚀 QUANTUM ZAYIFLIK ANALİZİ",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...weakTopics.map((topic) => _QuantumWeaknessCard(
            topic: topic,
            onTap: () => _startQuantumWorkshop(topic),
          )),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () => _startQuantumWorkshop(weakTopics.first),
            icon: const Icon(Icons.rocket_launch),
            label: const Text("QUANTUM ATÖLYEYİ BAŞLAT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  // 🚀 QUANTUM ÇALIŞMA GÖRÜNÜMÜ
  Widget _buildQuantumStudyView(BuildContext context, WidgetRef ref, UserModel user, List<TestModel> tests, QuantumAnalysisPhase analysisPhase) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // 🧠 QUANTUM AI ANALİZ GÖSTERGESİ
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightSurfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentColor, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppTheme.accentColor, AppTheme.primaryColor],
                    ),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1.seconds, color: AppTheme.accentColor.withOpacity(0.5)),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAnalysisPhaseText(analysisPhase),
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (analysisPhase.index + 1) / QuantumAnalysisPhase.values.length,
                        backgroundColor: AppTheme.lightSurfaceColor,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ref.watch(quantumWorkshopSessionProvider).when(
              data: (material) => _buildQuantumStudyMaterial(context, material),
              loading: () => _buildQuantumLoadingView(context, analysisPhase),
              error: (e, s) => _buildQuantumErrorView(context, e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 QUANTUM ÇALIŞMA MATERYALİ
  Widget _buildQuantumStudyMaterial(BuildContext context, StudyGuideAndQuiz material) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.lightSurfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: AppTheme.accentColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "🚀 QUANTUM ÇALIŞMA REHBERİ",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "${material.subject} - ${material.topic}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              MarkdownBody(
                data: material.studyGuide,
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                  h2: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  h3: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                  p: TextStyle(color: AppTheme.secondaryTextColor),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton.icon(
          onPressed: () => setState(() => _currentStep = WorkshopStep.quantumQuiz),
          icon: const Icon(Icons.quiz),
          label: const Text("QUANTUM QUIZ'E BAŞLA"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  // 🚀 QUANTUM QUIZ GÖRÜNÜMÜ
  Widget _buildQuantumQuizView(BuildContext context, WidgetRef ref, UserModel user, List<TestModel> tests) {
    return ref.watch(quantumWorkshopSessionProvider).when(
      data: (material) => _buildQuantumQuizQuestions(context, material),
      loading: () => _buildQuantumLoadingView(context, QuantumAnalysisPhase.quantumOptimization),
      error: (e, s) => _buildQuantumErrorView(context, e.toString()),
    );
  }

  // 🚀 QUANTUM QUIZ SORULARI
  Widget _buildQuantumQuizQuestions(BuildContext context, StudyGuideAndQuiz material) {
    if (_currentQuestionIndex >= material.quiz.length) {
      _submitQuantumQuiz(material);
      return const SizedBox.shrink();
    }

    final question = material.quiz[_currentQuestionIndex];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚀 QUANTUM İLERLEME GÖSTERGESİ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz, color: AppTheme.accentColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "QUANTUM QUIZ",
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_currentQuestionIndex + 1}/${material.quiz.length}",
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              "🚀 SORU ${_currentQuestionIndex + 1}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              question.question,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 18,
              ),
            ),
            
            const SizedBox(height: 32),
            
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentQuestionIndex] = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentColor : AppTheme.lightSurfaceColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentColor : AppTheme.secondaryColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : AppTheme.secondaryColor,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: AppTheme.accentColor, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            const Spacer(),
            
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text("GERİ"),
                    ),
                  ),
                
                if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAnswers.containsKey(_currentQuestionIndex)
                        ? () {
                            setState(() {
                              _currentQuestionIndex++;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      _currentQuestionIndex < material.quiz.length - 1 ? "İLERİ" : "BİTİR",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 QUANTUM SONUÇLAR GÖRÜNÜMÜ
  Widget _buildQuantumResultsView(BuildContext context, WidgetRef ref, UserModel user, List<TestModel> tests) {
    return ref.watch(quantumWorkshopSessionProvider).when(
      data: (material) => _buildQuantumResults(context, material),
      loading: () => _buildQuantumLoadingView(context, QuantumAnalysisPhase.singularityActivation),
      error: (e, s) => _buildQuantumErrorView(context, e.toString()),
    );
  }

  // 🚀 QUANTUM SONUÇLAR
  Widget _buildQuantumResults(BuildContext context, StudyGuideAndQuiz material) {
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
    final percentage = (correct / material.quiz.length * 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🚀 QUANTUM SONUÇ ANİMASYONU
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppTheme.accentColor, AppTheme.primaryColor],
                  ),
                ),
                child: Icon(
                  percentage >= 80 ? Icons.celebration : Icons.psychology,
                  color: Colors.white,
                  size: 60,
                ),
              ).animate().scale(duration: 1.seconds).then().shimmer(duration: 2.seconds),
              
              const SizedBox(height: 32),
              
              Text(
                "🚀 QUANTUM QUIZ SONUÇLARI",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "${material.subject} - ${material.topic}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // 🚀 QUANTUM SONUÇ KARTLARI
              Row(
                children: [
                  Expanded(
                    child: _QuantumResultCard(
                      title: "DOĞRU",
                      value: correct.toString(),
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuantumResultCard(
                      title: "YANLIŞ",
                      value: wrong.toString(),
                      color: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuantumResultCard(
                      title: "BOŞ",
                      value: blank.toString(),
                      color: Colors.orange,
                      icon: Icons.radio_button_unchecked,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "BAŞARI ORANI: %$percentage",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: percentage >= 80 ? Colors.green : percentage >= 60 ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = WorkshopStep.quantumBriefing;
                    _currentQuestionIndex = 0;
                    _selectedAnswers.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("YENİ QUANTUM ATÖLYE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM ANALİZ GÖRÜNÜMÜ
  Widget _buildQuantumAnalysisView(BuildContext context, WidgetRef ref, QuantumAnalysisPhase phase) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppTheme.accentColor, AppTheme.primaryColor],
                  ),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 60,
                  color: Colors.white,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1.seconds, color: AppTheme.accentColor.withOpacity(0.5)),
              
              const SizedBox(height: 32),
              
              Text(
                _getAnalysisPhaseText(phase),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _getAnalysisPhaseDescription(phase),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              LinearProgressIndicator(
                value: (phase.index + 1) / QuantumAnalysisPhase.values.length,
                backgroundColor: AppTheme.lightSurfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM OPTİMİZASYON GÖRÜNÜMÜ
  Widget _buildQuantumOptimizationView(BuildContext context, WidgetRef ref, QuantumAnalysisPhase phase) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppTheme.accentColor, AppTheme.primaryColor],
                  ),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 60,
                  color: Colors.white,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1.seconds, color: AppTheme.accentColor.withOpacity(0.5)),
              
              const SizedBox(height: 32),
              
              Text(
                "QUANTUM OPTİMİZASYON",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "AI, senin öğrenme pattern'larını analiz ediyor ve materyali optimize ediyor...",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM YÜKLEME GÖRÜNÜMÜ
  Widget _buildQuantumLoadingView(BuildContext context, QuantumAnalysisPhase phase) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.accentColor, AppTheme.primaryColor],
                ),
              ),
              child: Icon(
                Icons.psychology,
                size: 50,
                color: Colors.white,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1.seconds, color: AppTheme.accentColor.withOpacity(0.5))
              .then()
              .scale(duration: 500.ms),
            
            const SizedBox(height: 32),
            
            Text(
              "QUANTUM AI ANALİZ YAPIYOR",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _getAnalysisPhaseDescription(phase),
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            CircularProgressIndicator(
              color: AppTheme.accentColor,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 QUANTUM HATA GÖRÜNÜMÜ
  Widget _buildQuantumErrorView(BuildContext context, String error) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
              ).animate().shake(),
              
              const SizedBox(height: 32),
              
              Text(
                "QUANTUM AI HATASI",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                error,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = WorkshopStep.quantumBriefing;
                  });
                },
                child: const Text("GERİ DÖN"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM VERİ EKSİK GÖRÜNÜMÜ
  Widget _buildQuantumDataMissingView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppTheme.accentColor,
                  size: 48,
                ),
              ).animate().scale(duration: 1.seconds).then().shake(),
              
              const SizedBox(height: 32),
              
              Text(
                "QUANTUM ANALİZ İÇİN VERİ GEREKLİ",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "Quantum AI'nin seni analiz edebilmesi için önce deneme sonuçları eklemen gerekiyor.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => context.push('/home/add-test'),
                icon: const Icon(Icons.add_chart_rounded),
                label: const Text("İLK QUANTUM VERİYİ EKLE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM ZAYIFLIK TESPİTİ
  List<Map<String, String>> _identifyQuantumWeaknesses(
    Map<String, Map<String, TopicPerformanceModel>> topicPerformances,
    List<TestModel> tests,
  ) {
    final weaknesses = <Map<String, String>>[];
    
    // Basit zayıflık tespiti - gerçek uygulamada daha gelişmiş algoritma kullanılır
    for (final subject in topicPerformances.keys) {
      for (final topic in topicPerformances[subject]!.keys) {
        final performance = topicPerformances[subject]![topic]!;
        final totalQuestions = performance.correctCount + performance.wrongCount + performance.blankCount;
        
        if (totalQuestions > 0) {
          final accuracy = performance.correctCount / totalQuestions;
          if (accuracy < 0.7) { // %70'den düşük doğruluk
            weaknesses.add({
              'subject': subject,
              'topic': topic,
            });
          }
        }
      }
    }
    
    // Eğer zayıflık bulunamazsa, varsayılan konular
    if (weaknesses.isEmpty) {
      weaknesses.addAll([
        {'subject': 'Matematik', 'topic': 'Temel Matematik'},
        {'subject': 'Türkçe', 'topic': 'Dil Bilgisi'},
        {'subject': 'Fen Bilimleri', 'topic': 'Fizik'},
      ]);
    }
    
    return weaknesses.take(5).toList(); // En fazla 5 zayıflık
  }

  // 🚀 ANALİZ AŞAMA METİNLERİ
  String _getAnalysisPhaseText(QuantumAnalysisPhase phase) {
    switch (phase) {
      case QuantumAnalysisPhase.patternRecognition:
        return "PATTERN TANIMA";
      case QuantumAnalysisPhase.weaknessMapping:
        return "ZAYIFLIK HARİTALAMA";
      case QuantumAnalysisPhase.adaptiveLearning:
        return "ADAPTİF ÖĞRENME";
      case QuantumAnalysisPhase.quantumOptimization:
        return "QUANTUM OPTİMİZASYON";
      case QuantumAnalysisPhase.singularityActivation:
        return "SINGULARITY AKTİVASYONU";
    }
  }

  String _getAnalysisPhaseDescription(QuantumAnalysisPhase phase) {
    switch (phase) {
      case QuantumAnalysisPhase.patternRecognition:
        return "AI, senin öğrenme pattern'larını tanıyor...";
      case QuantumAnalysisPhase.weaknessMapping:
        return "Zayıf alanlar quantum seviyede haritalanıyor...";
      case QuantumAnalysisPhase.adaptiveLearning:
        return "Materyal senin öğrenme stiline adapte ediliyor...";
      case QuantumAnalysisPhase.quantumOptimization:
        return "Çalışma materyali quantum optimize ediliyor...";
      case QuantumAnalysisPhase.singularityActivation:
        return "AI tekilliği aktif, maksimum performans...";
    }
  }
}

// 🚀 QUANTUM ZAYIFLIK KARTI
class _QuantumWeaknessCard extends StatelessWidget {
  final Map<String, String> topic;
  final VoidCallback onTap;

  const _QuantumWeaknessCard({
    required this.topic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lightSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic['subject']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic['topic']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 QUANTUM SONUÇ KARTI
class _QuantumResultCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _QuantumResultCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}