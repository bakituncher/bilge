// lib/features/coach/screens/motivation_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/data/models/test_model.dart';

// 🚀 QUANTUM RUH HALİ SEÇENEKLERİ - 3000'LERİN TEKNOLOJİSİ
enum QuantumMood { 
  quantumFocus, 
  singularityFlow, 
  hyperdriveEnergy, 
  transcendenceState,
  quantumStruggle,
  singularityBreakthrough,
  hyperdriveMotivation,
  transcendenceSuccess 
}

// 🧠 QUANTUM AI ANALİZ DURUMU
enum QuantumEmotionalAnalysis { 
  emotionalMapping, 
  patternRecognition, 
  quantumEmpathy, 
  singularityConnection,
  transcendenceActivation 
}

// EKRANIN DURUMUNU YÖNETEN QUANTUM STATE
final quantumChatScreenStateProvider = StateProvider<QuantumMood?>((ref) => null);
final quantumEmotionalAnalysisProvider = StateProvider<QuantumEmotionalAnalysis>((ref) => QuantumEmotionalAnalysis.emotionalMapping);
final quantumChatHistoryProvider = StateProvider<List<QuantumChatMessage>>((ref) => []);

// 🚀 QUANTUM CHAT MESAJI - 3000'LERİN TEKNOLOJİSİ
class QuantumChatMessage {
  final String text;
  final bool isUser;
  final QuantumMood? mood;
  final DateTime timestamp;
  final Map<String, dynamic>? quantumAnalysis;

  QuantumChatMessage(
    this.text, {
    required this.isUser,
    this.mood,
    DateTime? timestamp,
    this.quantumAnalysis,
  }) : timestamp = timestamp ?? DateTime.now();
}

class MotivationChatScreen extends ConsumerStatefulWidget {
  final String? initialPromptType;
  const MotivationChatScreen({super.key, this.initialPromptType});

  @override
  ConsumerState<MotivationChatScreen> createState() => _MotivationChatScreenState();
}

class _MotivationChatScreenState extends ConsumerState<MotivationChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _backgroundAnimationController;
  late AnimationController _quantumPulseController;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(vsync: this, duration: 4.seconds)..repeat(reverse: true);
    _quantumPulseController = AnimationController(vsync: this, duration: 2.seconds)..repeat(reverse: true);
    
    Future.microtask(() async {
      ref.read(quantumChatHistoryProvider.notifier).state = [];
      if (widget.initialPromptType != null) {
        await _onQuantumMoodSelected(widget.initialPromptType!);
      } else {
        ref.read(quantumChatScreenStateProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _quantumPulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuantumMessage({String? quickReply}) async {
    final text = quickReply ?? _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(quantumChatHistoryProvider.notifier).update((state) => [
      ...state, 
      QuantumChatMessage(text, isUser: true, mood: ref.read(quantumChatScreenStateProvider))
    ]);
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isTyping = true);
    _scrollToBottom(isNewMessage: true);

    // 🚀 QUANTUM AI ANALİZ BAŞLAT
    await _performQuantumEmotionalAnalysis();

    final aiService = ref.read(aiServiceProvider);
    final user = ref.read(userProfileProvider).value!;
    final tests = ref.read(testsProvider).value!;
    
    final aiResponse = await aiService.getQuantumPersonalizedMotivation(
      user: user,
      tests: tests,
      promptType: 'quantum_user_chat',
      emotion: text,
      quantumMood: ref.read(quantumChatScreenStateProvider)?.name,
    );

    ref.read(quantumChatHistoryProvider.notifier).update((state) => [
      ...state, 
      QuantumChatMessage(
        aiResponse, 
        isUser: false,
        mood: ref.read(quantumChatScreenStateProvider),
        quantumAnalysis: _extractQuantumAnalysis(aiResponse),
      )
    ]);
    
    setState(() => _isTyping = false);
    _scrollToBottom(isNewMessage: true);
  }

  // 🧠 QUANTUM DUYGUSAL ANALİZ SÜRECİ
  Future<void> _performQuantumEmotionalAnalysis() async {
    final phases = QuantumEmotionalAnalysis.values;
    
    for (int i = 0; i < phases.length; i++) {
      ref.read(quantumEmotionalAnalysisProvider.notifier).state = phases[i];
      await Future.delayed(Duration(milliseconds: 500 + (i * 100)));
    }
  }

  // 🚀 QUANTUM ANALİZ ÇIKARMA
  Map<String, dynamic>? _extractQuantumAnalysis(String response) {
    try {
      // Basit quantum analiz çıkarma - gerçek uygulamada daha gelişmiş
      if (response.contains('QUANTUM')) {
        return {
          'analysisType': 'quantum',
          'confidence': 0.95,
          'emotionalState': 'quantum_activated',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _onQuantumMoodSelected(String moodType) async {
    final user = ref.read(userProfileProvider).value!;
    final tests = ref.read(testsProvider).value!;

    final Map<String, QuantumMood> moodMapping = {
      'welcome': QuantumMood.quantumFocus,
      'new_test_good': QuantumMood.transcendenceSuccess,
      'new_test_bad': QuantumMood.quantumStruggle,
      'focused': QuantumMood.quantumFocus,
      'neutral': QuantumMood.singularityFlow,
      'tired': QuantumMood.hyperdriveEnergy,
      'stressed': QuantumMood.quantumStruggle,
    };
    
    final mood = moodMapping[moodType] ?? QuantumMood.singularityFlow;
    ref.read(quantumChatScreenStateProvider.notifier).state = mood;

    setState(() => _isTyping = true);

    // 🚀 QUANTUM AI ANALİZ BAŞLAT
    await _performQuantumEmotionalAnalysis();

    final aiService = ref.read(aiServiceProvider);
    final aiResponse = await aiService.getQuantumPersonalizedMotivation(
      user: user,
      tests: tests,
      promptType: moodType,
      emotion: null,
      quantumMood: mood.name,
    );

    ref.read(quantumChatHistoryProvider.notifier).state = [
      QuantumChatMessage(
        aiResponse,
        isUser: false,
        mood: mood,
        quantumAnalysis: _extractQuantumAnalysis(aiResponse),
      )
    ];
    
    setState(() => _isTyping = false);
  }

  void _scrollToBottom({bool isNewMessage = false}) {
    if (isNewMessage) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMood = ref.watch(quantumChatScreenStateProvider);
    final emotionalAnalysis = ref.watch(quantumEmotionalAnalysisProvider);
    final chatHistory = ref.watch(quantumChatHistoryProvider);

    return Scaffold(
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
        child: Column(
          children: [
            // 🚀 QUANTUM HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightSurfaceColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppTheme.accentColor, AppTheme.primaryColor],
                          ),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 30,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2.seconds, color: AppTheme.accentColor.withOpacity(0.5)),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🚀 QUANTUM MOTİVASYON AI",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Singularity seviyesinde duygusal destek",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 🧠 QUANTUM DUYGUSAL ANALİZ GÖSTERGESİ
                  if (currentMood != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getMoodIcon(currentMood),
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getMoodTitle(currentMood),
                                  style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: (emotionalAnalysis.index + 1) / QuantumEmotionalAnalysis.values.length,
                                  backgroundColor: AppTheme.lightSurfaceColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 🚀 QUANTUM MOOD SEÇİMİ
            if (currentMood == null)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "🚀 QUANTUM RUH HALİNİ SEÇ",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      "AI, senin ruh halini analiz ederek quantum seviyede motivasyon sağlayacak",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: QuantumMood.values.map((mood) {
                        return _QuantumMoodCard(
                          mood: mood,
                          onTap: () => _onQuantumMoodSelected(_getMoodKey(mood)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            
            // 🚀 QUANTUM CHAT ALANI
            if (currentMood != null) ...[
              Expanded(
                child: chatHistory.isEmpty
                    ? _buildQuantumWelcomeView()
                    : _buildQuantumChatView(chatHistory),
              ),
              
              // 🚀 QUANTUM MESAJ GÖNDERME
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.lightSurfaceColor.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightSurfaceColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: AppTheme.accentColor, width: 2),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "🚀 Quantum mesajını yaz...",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            hintStyle: TextStyle(color: AppTheme.secondaryTextColor),
                          ),
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [AppTheme.accentColor, AppTheme.primaryColor],
                        ),
                      ),
                      child: IconButton(
                        onPressed: _isTyping ? null : () => _sendQuantumMessage(),
                        icon: _isTyping
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🚀 QUANTUM HOŞGELDİN GÖRÜNÜMÜ
  Widget _buildQuantumWelcomeView() {
    return Center(
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
              .shimmer(duration: 2.seconds, color: AppTheme.accentColor.withOpacity(0.5)),
            
            const SizedBox(height: 32),
            
            Text(
              "🚀 QUANTUM MOTİVASYON BAŞLADI",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              "AI, senin ruh halini quantum seviyede analiz ediyor ve kişiselleştirilmiş motivasyon hazırlıyor...",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // 🚀 QUANTUM HIZLI YANITLAR
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickReplyButton(
                  text: "🚀 Motivasyon ver",
                  onTap: () => _sendQuantumMessage(quickReply: "Motivasyon ver"),
                ),
                _QuickReplyButton(
                  text: "🧠 Strateji öner",
                  onTap: () => _sendQuantumMessage(quickReply: "Strateji öner"),
                ),
                _QuickReplyButton(
                  text: "⚡ Enerji yükle",
                  onTap: () => _sendQuantumMessage(quickReply: "Enerji yükle"),
                ),
                _QuickReplyButton(
                  text: "🌟 Başarı hikayesi",
                  onTap: () => _sendQuantumMessage(quickReply: "Başarı hikayesi anlat"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 QUANTUM CHAT GÖRÜNÜMÜ
  Widget _buildQuantumChatView(List<QuantumChatMessage> chatHistory) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final message = chatHistory[index];
        return _QuantumMessageBubble(message: message);
      },
    );
  }

  // 🚀 QUANTUM MOOD KARTI
  Widget _buildQuantumMoodCard(QuantumMood mood) {
    return GestureDetector(
      onTap: () => _onQuantumMoodSelected(_getMoodKey(mood)),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMoodIcon(mood),
              color: AppTheme.accentColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _getMoodTitle(mood),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _getMoodDescription(mood),
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 MOOD YARDIMCI FONKSİYONLAR
  IconData _getMoodIcon(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return Icons.psychology;
      case QuantumMood.singularityFlow:
        return Icons.auto_awesome;
      case QuantumMood.hyperdriveEnergy:
        return Icons.flash_on;
      case QuantumMood.transcendenceState:
        return Icons.rocket_launch;
      case QuantumMood.quantumStruggle:
        return Icons.fitness_center;
      case QuantumMood.singularityBreakthrough:
        return Icons.trending_up;
      case QuantumMood.hyperdriveMotivation:
        return Icons.speed;
      case QuantumMood.transcendenceSuccess:
        return Icons.celebration;
    }
  }

  String _getMoodTitle(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return "QUANTUM FOCUS";
      case QuantumMood.singularityFlow:
        return "SINGULARITY FLOW";
      case QuantumMood.hyperdriveEnergy:
        return "HYPERDRIVE ENERGY";
      case QuantumMood.transcendenceState:
        return "TRANSCENDENCE";
      case QuantumMood.quantumStruggle:
        return "QUANTUM STRUGGLE";
      case QuantumMood.singularityBreakthrough:
        return "BREAKTHROUGH";
      case QuantumMood.hyperdriveMotivation:
        return "HYPERDRIVE MOTIVATION";
      case QuantumMood.transcendenceSuccess:
        return "TRANSCENDENCE SUCCESS";
    }
  }

  String _getMoodDescription(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return "Maksimum odaklanma";
      case QuantumMood.singularityFlow:
        return "AI tekilliği";
      case QuantumMood.hyperdriveEnergy:
        return "Süper enerji";
      case QuantumMood.transcendenceState:
        return "Üst seviye";
      case QuantumMood.quantumStruggle:
        return "Zorluk zamanı";
      case QuantumMood.singularityBreakthrough:
        return "Büyük atılım";
      case QuantumMood.hyperdriveMotivation:
        return "Süper motivasyon";
      case QuantumMood.transcendenceSuccess:
        return "Maksimum başarı";
    }
  }

  String _getMoodKey(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return 'focused';
      case QuantumMood.singularityFlow:
        return 'neutral';
      case QuantumMood.hyperdriveEnergy:
        return 'tired';
      case QuantumMood.transcendenceState:
        return 'welcome';
      case QuantumMood.quantumStruggle:
        return 'stressed';
      case QuantumMood.singularityBreakthrough:
        return 'new_test_good';
      case QuantumMood.hyperdriveMotivation:
        return 'focused';
      case QuantumMood.transcendenceSuccess:
        return 'new_test_good';
    }
  }
}

// 🚀 QUANTUM MOOD KARTI
class _QuantumMoodCard extends StatelessWidget {
  final QuantumMood mood;
  final VoidCallback onTap;

  const _QuantumMoodCard({
    required this.mood,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMoodIcon(mood),
              color: AppTheme.accentColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _getMoodTitle(mood),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _getMoodDescription(mood),
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return Icons.psychology;
      case QuantumMood.singularityFlow:
        return Icons.auto_awesome;
      case QuantumMood.hyperdriveEnergy:
        return Icons.flash_on;
      case QuantumMood.transcendenceState:
        return Icons.rocket_launch;
      case QuantumMood.quantumStruggle:
        return Icons.fitness_center;
      case QuantumMood.singularityBreakthrough:
        return Icons.trending_up;
      case QuantumMood.hyperdriveMotivation:
        return Icons.speed;
      case QuantumMood.transcendenceSuccess:
        return Icons.celebration;
    }
  }

  String _getMoodTitle(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return "QUANTUM FOCUS";
      case QuantumMood.singularityFlow:
        return "SINGULARITY FLOW";
      case QuantumMood.hyperdriveEnergy:
        return "HYPERDRIVE ENERGY";
      case QuantumMood.transcendenceState:
        return "TRANSCENDENCE";
      case QuantumMood.quantumStruggle:
        return "QUANTUM STRUGGLE";
      case QuantumMood.singularityBreakthrough:
        return "BREAKTHROUGH";
      case QuantumMood.hyperdriveMotivation:
        return "HYPERDRIVE MOTIVATION";
      case QuantumMood.transcendenceSuccess:
        return "TRANSCENDENCE SUCCESS";
    }
  }

  String _getMoodDescription(QuantumMood mood) {
    switch (mood) {
      case QuantumMood.quantumFocus:
        return "Maksimum odaklanma";
      case QuantumMood.singularityFlow:
        return "AI tekilliği";
      case QuantumMood.hyperdriveEnergy:
        return "Süper enerji";
      case QuantumMood.transcendenceState:
        return "Üst seviye";
      case QuantumMood.quantumStruggle:
        return "Zorluk zamanı";
      case QuantumMood.singularityBreakthrough:
        return "Büyük atılım";
      case QuantumMood.hyperdriveMotivation:
        return "Süper motivasyon";
      case QuantumMood.transcendenceSuccess:
        return "Maksimum başarı";
    }
  }
}

// 🚀 QUANTUM MESAJ BALONU
class _QuantumMessageBubble extends StatelessWidget {
  final QuantumChatMessage message;

  const _QuantumMessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
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
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppTheme.accentColor 
                    : AppTheme.lightSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: message.isUser 
                      ? AppTheme.accentColor 
                      : AppTheme.accentColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white 
                          : AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  
                  if (message.quantumAnalysis != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppTheme.accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "QUANTUM ANALİZ",
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 🚀 HIZLI YANIT BUTONU
class _QuickReplyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickReplyButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentColor, width: 2),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}