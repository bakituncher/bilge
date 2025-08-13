// lib/features/strategic_planning/screens/strategic_planning_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

// 🚀 2500'LERİN TEKNOLOJİSİ: GELİŞMİŞ PLANLAMA AŞAMALARI
enum Pacing { relaxed, moderate, intense, quantum, singularity }
enum PlanningStep { 
  dataCheck, 
  confirmation, 
  pacing, 
  loading, 
  aiAnalysis, 
  quantumOptimization,
  singularityMode 
}

// 🧠 QUANTUM AI ANALİZ DURUMU
enum AnalysisPhase { 
  historicalData, 
  patternRecognition, 
  predictiveModeling, 
  quantumOptimization,
  singularityActivation 
}

final selectedPacingProvider = StateProvider<Pacing>((ref) => Pacing.moderate);
final planningStepProvider = StateProvider<PlanningStep>((ref) => PlanningStep.dataCheck);
final analysisPhaseProvider = StateProvider<AnalysisPhase>((ref) => AnalysisPhase.historicalData);

// 🎯 QUANTUM STRATEJİ ÜRETİCİSİ - 2500'LERİN TEKNOLOJİSİ
class QuantumStrategyGenerator extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  QuantumStrategyGenerator(this._ref) : super(const AsyncValue.data(null));

  Future<void> _generateQuantumStrategy(BuildContext context, {String? revisionRequest}) async {
    state = const AsyncValue.loading();
    _ref.read(planningStepProvider.notifier).state = PlanningStep.aiAnalysis;
    
    // 🧠 QUANTUM AI ANALİZ BAŞLAT
    await _performQuantumAnalysis();
    
    final pacing = _ref.read(selectedPacingProvider);
    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;

    if (user == null || tests == null) {
      state = AsyncValue.error("Kullanıcı veya test verisi bulunamadı.", StackTrace.current);
      return;
    }

    try {
      // 🚀 QUANTUM AI STRATEJİ ÜRETİMİ
      final resultJson = await _ref.read(aiServiceProvider).generateQuantumStrategy(
        user: user,
        tests: tests,
        pacing: pacing.name,
        revisionRequest: revisionRequest,
        analysisPhase: _ref.read(analysisPhaseProvider).name,
      );

      final decodedData = jsonDecode(resultJson);

      if (decodedData.containsKey('error')) {
        throw Exception(decodedData['error']);
      }

      final result = {
        'longTermStrategy': decodedData['longTermStrategy'],
        'weeklyPlan': decodedData['weeklyPlan'],
        'pacing': pacing.name,
        'quantumAnalysis': decodedData['quantumAnalysis'],
        'predictiveInsights': decodedData['predictiveInsights'],
      };

      if (context.mounted) {
        context.push('/ai-hub/strategic-planning/${AppRoutes.strategyReview}', extra: result);
      }

      _ref.read(planningStepProvider.notifier).state = PlanningStep.dataCheck;
      state = const AsyncValue.data(null);
    } catch (e, s) {
      _ref.read(planningStepProvider.notifier).state = PlanningStep.pacing;
      state = AsyncValue.error(e, s);
    }
  }

  // 🧠 QUANTUM AI ANALİZ SÜRECİ
  Future<void> _performQuantumAnalysis() async {
    final phases = AnalysisPhase.values;
    
    for (int i = 0; i < phases.length; i++) {
      _ref.read(analysisPhaseProvider.notifier).state = phases[i];
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
    }
  }

  Future<void> generateQuantumPlan(BuildContext context) async {
    await _generateQuantumStrategy(context);
  }

  Future<void> regenerateQuantumPlanWithFeedback(BuildContext context, String feedback) async {
    await _generateQuantumStrategy(context, revisionRequest: feedback);
  }
}

final quantumStrategyProvider = StateNotifierProvider.autoDispose<QuantumStrategyGenerator, AsyncValue<void>>((ref) {
  return QuantumStrategyGenerator(ref);
});

// 🚀 QUANTUM STRATEJİ EKRANI - 2500'LERİN TEKNOLOJİSİ
class StrategicPlanningScreen extends ConsumerWidget {
  const StrategicPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final tests = ref.watch(testsProvider).valueOrNull;
    final step = ref.watch(planningStepProvider);
    final analysisPhase = ref.watch(analysisPhaseProvider);

    ref.listen<AsyncValue<void>>(quantumStrategyProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentColor,
            content: Text('Quantum strateji oluşturulurken bir hata oluştu: ${state.error}'),
          ),
        );
      }
    });

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text("Kullanıcı verisi bulunamadı.")));
        }

        if (user.longTermStrategy != null && user.weeklyPlan != null) {
          if(step != PlanningStep.confirmation && step != PlanningStep.pacing && 
             step != PlanningStep.loading && step != PlanningStep.aiAnalysis) {
            return _buildQuantumStrategyDisplay(context, ref, user);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.psychology, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                const Text('QUANTUM STRATEJİ MERKEZİ'),
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
            child: _buildQuantumStep(context, ref, step, tests?.isNotEmpty ?? false, analysisPhase),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))),
      error: (e, s) => Scaffold(body: Center(child: Text("Hata: $e"))),
    );
  }

  Widget _buildQuantumStep(BuildContext context, WidgetRef ref, PlanningStep step, bool hasTests, AnalysisPhase analysisPhase) {
    if (!hasTests) {
      return _buildQuantumDataMissingView(context);
    }

    if (step == PlanningStep.dataCheck && hasTests) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(planningStepProvider.notifier).state = PlanningStep.confirmation;
      });
      return const SizedBox.shrink();
    }

    switch (step) {
      case PlanningStep.confirmation:
        return _buildQuantumConfirmationView(context, ref);
      case PlanningStep.pacing:
        return _buildQuantumPacingView(context, ref);
      case PlanningStep.aiAnalysis:
        return _buildQuantumAnalysisView(context, ref, analysisPhase);
      case PlanningStep.loading:
        return _buildQuantumLoadingView(context, ref);
      default:
        return const SizedBox.shrink();
    }
  }

  // 🚀 QUANTUM STRATEJİ GÖRÜNÜMÜ
  Widget _buildQuantumStrategyDisplay(BuildContext context, WidgetRef ref, UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QUANTUM STRATEJİ AKTİF"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
                // 🧠 QUANTUM AI ANİMASYONU
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
                  .shimmer(duration: 2.seconds, color: AppTheme.accentColor.withOpacity(0.3)),
                
                const SizedBox(height: 32),
                
                Text(
                  "QUANTUM STRATEJİ AKTİF",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  "AI'nin quantum analizi tamamlandı. Stratejik planın optimize edildi ve gelecek haftalar için predictive modeling aktif.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: () => context.push('${AppRoutes.aiHub}/${AppRoutes.commandCenter}', extra: user),
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text("QUANTUM KOMUTA MERKEZİ"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    ref.read(planningStepProvider.notifier).state = PlanningStep.confirmation;
                  },
                  child: const Text("YENİ QUANTUM STRATEJİ"),
                )
              ],
            ),
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
                  Icons.psychology_off,
                  color: Colors.amber,
                  size: 50,
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
                "Quantum AI'nin seni analiz edebilmesi için önce düşmanı tanıması gerekiyor. En az bir deneme sonucu ekle ve quantum stratejiyi başlat.",
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
        ).animate().fadeIn(),
      ),
    );
  }

  // 🚀 QUANTUM ONAY GÖRÜNÜMÜ
  Widget _buildQuantumConfirmationView(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider).valueOrNull ?? [];
    final lastTestDate = tests.isNotEmpty ? DateFormat.yMMMMd('tr').format(tests.first.date) : "N/A";

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
                "QUANTUM STRATEJİ ÖNCESİ KONTROL",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          _QuantumConfirmationItem(
            icon: Icons.edit_calendar_rounded,
            question: "Zaman haritan quantum optimize edildi mi?",
            description: "Quantum AI, senin zaman dilimlerini analiz ederek optimal strateji oluşturacak.",
            buttonText: "HARİTAYI QUANTUM OPTİMİZE ET",
            onTap: () => context.push(AppRoutes.availability),
            isQuantum: true,
          ),
          
          _QuantumConfirmationItem(
            icon: Icons.auto_awesome,
            question: "Bilgi galaksin quantum analiz edildi mi?",
            description: "AI'nin konu hakimiyet verilerini quantum seviyede analiz etmesi gerekiyor.",
            buttonText: "GALAKSİYİ QUANTUM ZİYARET ET",
            onTap: () => context.push('/ai-hub/${AppRoutes.coachPushed}'),
            isQuantum: true,
          ),
          
          _QuantumConfirmationItem(
            icon: Icons.history_edu_rounded,
            question: "Deneme sonuçların quantum analiz için hazır mı?",
            description: "Son denemen $lastTestDate tarihinde eklendi. Quantum AI için daha fazla veri = daha iyi strateji.",
            buttonText: "QUANTUM VERİ EKLE",
            onTap: () => context.push('/home/add-test'),
            isQuantum: true,
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: () {
              ref.read(planningStepProvider.notifier).state = PlanningStep.pacing;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("QUANTUM STRATEJİYİ BAŞLAT"),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  // 🚀 QUANTUM TEMPO SEÇİMİ
  Widget _buildQuantumPacingView(BuildContext context, WidgetRef ref) {
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
              Icon(Icons.speed_rounded, size: 80, color: AppTheme.accentColor),
              
              const SizedBox(height: 24),
              
              Text(
                "QUANTUM TEMPO SEÇİMİ",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "AI'nin quantum analizi için tempo seç. Her tempo farklı quantum algoritma kullanır.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // 🚀 QUANTUM TEMPO SEÇENEKLERİ
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: Pacing.values.map((pacing) {
                  final isSelected = pacing == ref.watch(selectedPacingProvider);
                  final pacingInfo = _getPacingInfo(pacing);
                  
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedPacingProvider.notifier).state = pacing;
                    },
                    child: AnimatedContainer(
                      duration: 300.ms,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentColor : AppTheme.lightSurfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentColor : AppTheme.secondaryColor,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pacingInfo.icon,
                            color: isSelected ? Colors.white : AppTheme.secondaryColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pacingInfo.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pacingInfo.description,
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : AppTheme.secondaryTextColor,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton.icon(
                onPressed: () => ref.read(quantumStrategyProvider.notifier).generateQuantumPlan(context),
                icon: const Icon(Icons.rocket_launch),
                label: const Text("QUANTUM STRATEJİYİ BAŞLAT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  ref.read(planningStepProvider.notifier).state = PlanningStep.confirmation;
                },
                child: const Text("GERİ DÖN"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM AI ANALİZ GÖRÜNÜMÜ
  Widget _buildQuantumAnalysisView(BuildContext context, WidgetRef ref, AnalysisPhase phase) {
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
              // 🧠 QUANTUM AI ANİMASYONU
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
                value: (phase.index + 1) / AnalysisPhase.values.length,
                backgroundColor: AppTheme.lightSurfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "${phase.index + 1}/${AnalysisPhase.values.length}",
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 QUANTUM YÜKLEME GÖRÜNÜMÜ
  Widget _buildQuantumLoadingView(BuildContext context, WidgetRef ref) {
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
        key: const ValueKey('quantum-loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              "QUANTUM STRATEJİ OLUŞTURULUYOR",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              "AI quantum analizi tamamlıyor...\nBekleyin komutanım...",
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

  // 🚀 TEMPO BİLGİLERİ
  _PacingInfo _getPacingInfo(Pacing pacing) {
    switch (pacing) {
      case Pacing.relaxed:
        return _PacingInfo(
          name: "RAHAT",
          description: "Quantum AI hafif tempo",
          icon: Icons.sentiment_satisfied,
        );
      case Pacing.moderate:
        return _PacingInfo(
          name: "DENGELİ",
          description: "Quantum AI orta tempo",
          icon: Icons.balance,
        );
      case Pacing.intense:
        return _PacingInfo(
          name: "YOĞUN",
          description: "Quantum AI yoğun tempo",
          icon: Icons.flash_on,
        );
      case Pacing.quantum:
        return _PacingInfo(
          name: "QUANTUM",
          description: "Quantum AI maksimum",
          icon: Icons.psychology,
        );
      case Pacing.singularity:
        return _PacingInfo(
          name: "SINGULARITY",
          description: "AI tekilliği seviyesi",
          icon: Icons.rocket_launch,
        );
    }
  }

  // 🚀 ANALİZ AŞAMA METİNLERİ
  String _getAnalysisPhaseText(AnalysisPhase phase) {
    switch (phase) {
      case AnalysisPhase.historicalData:
        return "TARİHSEL VERİ ANALİZİ";
      case AnalysisPhase.patternRecognition:
        return "PATTERN TANIMA";
      case AnalysisPhase.predictiveModeling:
        return "PREDICTIVE MODELING";
      case AnalysisPhase.quantumOptimization:
        return "QUANTUM OPTİMİZASYON";
      case AnalysisPhase.singularityActivation:
        return "SINGULARITY AKTİVASYONU";
    }
  }

  String _getAnalysisPhaseDescription(AnalysisPhase phase) {
    switch (phase) {
      case AnalysisPhase.historicalData:
        return "Geçen haftaların verileri quantum seviyede analiz ediliyor...";
      case AnalysisPhase.patternRecognition:
        return "AI pattern'ları tanıyor ve öğreniyor...";
      case AnalysisPhase.predictiveModeling:
        return "Gelecek haftalar için predictive model oluşturuluyor...";
      case AnalysisPhase.quantumOptimization:
        return "Strateji quantum algoritmalarla optimize ediliyor...";
      case AnalysisPhase.singularityActivation:
        return "AI tekilliği aktif, maksimum performans...";
    }
  }
}

// 🚀 QUANTUM ONAY ÖĞESİ
class _QuantumConfirmationItem extends StatelessWidget {
  final IconData icon;
  final String question;
  final String description;
  final String buttonText;
  final VoidCallback onTap;
  final bool isQuantum;

  const _QuantumConfirmationItem({
    required this.icon,
    required this.question,
    required this.description,
    required this.buttonText,
    required this.onTap,
    this.isQuantum = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightSurfaceColor,
            AppTheme.lightSurfaceColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isQuantum ? AppTheme.accentColor : AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isQuantum ? AppTheme.accentColor : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isQuantum ? AppTheme.accentColor : AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 TEMPO BİLGİ SINIFI
class _PacingInfo {
  final String name;
  final String description;
  final IconData icon;

  _PacingInfo({
    required this.name,
    required this.description,
    required this.icon,
  });
}