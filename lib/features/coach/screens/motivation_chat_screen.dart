// lib/features/coach/screens/motivation_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/data/models/test_model.dart';

// RUH HALİ SEÇENEKLERİ
enum Mood { focused, neutral, tired, stressed, badResult, goodResult }

// EKRANIN DURUMUNU YÖNETEN STATE
final chatScreenStateProvider = StateProvider<Mood?>((ref) => null);

final chatHistoryProvider = StateProvider<List<ChatMessage>>((ref) => []);

class MotivationChatScreen extends ConsumerStatefulWidget {
  final String? initialPromptType;
  const MotivationChatScreen({super.key, this.initialPromptType});

  @override
  ConsumerState<MotivationChatScreen> createState() => _MotivationChatScreenState();
}

class _MotivationChatScreenState extends ConsumerState<MotivationChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında geçmişi temizle ve başlangıç durumuna getir.
    Future.microtask(() async {
      ref.read(chatHistoryProvider.notifier).state = [];
      if (widget.initialPromptType != null) {
        // Eğer dışarıdan bir prompt tipiyle gelmişsek, direkt mesajı oluştur
        await _onMoodSelected(widget.initialPromptType!);
      } else {
        ref.read(chatScreenStateProvider.notifier).state = null;
      }
    });
  }

  // Hızlı yanıt seçenekleri
  final List<String> _quickReplies = [
    "Bugün çok yorgunum.",
    "Stresli hissediyorum.",
    "Konular yetişmeyecek gibi...",
    "Sadece biraz motivasyon istiyorum.",
  ];

  void _sendMessage({String? quickReply}) async {
    final text = quickReply ?? _controller.text.trim();
    if (text.isEmpty) return;

    // Kullanıcının mesajını geçmişe ekle
    ref.read(chatHistoryProvider.notifier).update((state) => [...state, ChatMessage(text, isUser: true)]);
    _controller.clear();
    FocusScope.of(context).unfocus();

    // AI'ın "yazıyor" animasyonunu başlat
    setState(() => _isTyping = true);
    _scrollToBottom(isNewMessage: true);

    // AI yanıtını al
    final aiService = ref.read(aiServiceProvider);
    final user = ref.read(userProfileProvider).value!;
    final tests = ref.read(testsProvider).value!;
    final aiResponse = await aiService.getPersonalizedMotivation(
      user: user,
      tests: tests,
      promptType: 'user_chat',
      emotion: text,
    );

    // AI'ın yanıtını ekle ve animasyonu durdur
    ref.read(chatHistoryProvider.notifier).update((state) => [...state, ChatMessage(aiResponse, isUser: false)]);
    setState(() => _isTyping = false);
    _scrollToBottom(isNewMessage: true);
  }

  Future<void> _onMoodSelected(String moodType) async {
    final user = ref.read(userProfileProvider).value!;
    final tests = ref.read(testsProvider).value!;

    String userMessage;
    Mood mood;
    if (moodType == 'welcome') {
      mood = Mood.neutral;
      userMessage = "Bugün nasıl hissediyorsun?";
    } else if (moodType == 'new_test_good') {
      mood = Mood.goodResult;
      userMessage = "Çok iyi bir net yaptım!";
    } else if (moodType == 'new_test_bad') {
      mood = Mood.badResult;
      userMessage = "Deneme çok kötü geçti...";
    } else {
      mood = Mood.neutral;
      userMessage = _getMoodMessageFromEnum(Mood.values.firstWhere((e) => e.name == moodType));
    }

    ref.read(chatScreenStateProvider.notifier).state = mood;

    setState(() => _isTyping = true);

    final aiService = ref.read(aiServiceProvider);
    final aiResponse = await aiService.getPersonalizedMotivation(
      user: user,
      tests: tests,
      promptType: moodType,
      emotion: userMessage,
    );

    ref.read(chatHistoryProvider.notifier).state = [
      ChatMessage(aiResponse, isUser: false),
    ];

    setState(() => _isTyping = false);
    _scrollToBottom(isNewMessage: true);
  }

  String _getMoodMessageFromEnum(Mood mood) {
    switch (mood) {
      case Mood.focused: return "Harika hissediyorum, tam odaklandım!";
      case Mood.neutral: return "Bugün normal bir gün.";
      case Mood.tired: return "Çok yorgun hissediyorum.";
      case Mood.stressed: return "Biraz stresliyim.";
      default: return "";
    }
  }

  void _scrollToBottom({bool isNewMessage = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: isNewMessage ? 400.ms : 100.ms,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatHistoryProvider);
    final selectedMood = ref.watch(chatScreenStateProvider);
    final showQuickReplies = history.isNotEmpty && history.length < 4;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Zihinsel Harbiye'),
        backgroundColor: AppTheme.primaryColor.withOpacity(0.5),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.cardColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: 500.ms,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: selectedMood == null
                    ? _MoodSelectionView(onMoodSelected: (mood) => _onMoodSelected(mood.name))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  itemCount: history.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == history.length) {
                      return const _TypingBubble();
                    }
                    final message = history[index];
                    return _MessageBubble(message: message);
                  },
                ),
              ),
            ),
            if (selectedMood != null && showQuickReplies) _buildQuickReplies(),
            if (selectedMood != null) _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _quickReplies.map((reply) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              label: Text(reply),
              onPressed: () => _sendMessage(quickReply: reply),
              backgroundColor: AppTheme.lightSurfaceColor,
              labelStyle: const TextStyle(color: AppTheme.textColor),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5);
  }

  Widget _buildChatInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'BilgeAI\'ye yaz...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.lightSurfaceColor.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.lightSurfaceColor.withOpacity(0.5)),
                  ),
                  filled: true,
                  fillColor: AppTheme.primaryColor.withOpacity(0.7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _sendMessage(),
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _MoodSelectionView extends StatelessWidget {
  final Function(Mood) onMoodSelected;
  const _MoodSelectionView({required this.onMoodSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          backgroundColor: AppTheme.secondaryColor,
          radius: 40,
          child: Icon(Icons.auto_awesome, size: 40, color: AppTheme.primaryColor),
        ).animate().fadeIn(delay: 200.ms).scale(),
        const SizedBox(height: 24),
        Text(
          "Bugün nasıl hissediyorsun?",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textColor),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
        _MoodButton(
          label: "Odaklanmış",
          icon: "🔥",
          onTap: () => onMoodSelected(Mood.focused),
          delay: 500.ms,
        ),
        _MoodButton(
          label: "Normal",
          icon: "😊",
          onTap: () => onMoodSelected(Mood.neutral),
          delay: 600.ms,
        ),
        _MoodButton(
          label: "Yorgun",
          icon: "😩",
          onTap: () => onMoodSelected(Mood.tired),
          delay: 700.ms,
        ),
        _MoodButton(
          label: "Stresli",
          icon: "😐",
          onTap: () => onMoodSelected(Mood.stressed),
          delay: 800.ms,
        ),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final Duration delay;

  const _MoodButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppTheme.lightSurfaceColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideY(begin: 0.5, curve: Curves.easeOutCubic);
  }
}


class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Animate(
      effects: [
        FadeEffect(duration: 500.ms, curve: Curves.easeIn),
        SlideEffect(begin: isUser ? const Offset(0.2, 0) : const Offset(-0.2, 0), curve: Curves.easeOutCubic),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser)
              const CircleAvatar(
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(Icons.auto_awesome, size: 20, color: AppTheme.primaryColor),
                radius: 16,
              ),
            if (!isUser) const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.secondaryColor : AppTheme.lightSurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(color: isUser ? AppTheme.primaryColor : Colors.white, fontSize: 16, height: 1.4, fontWeight: isUser ? FontWeight.w500 : FontWeight.normal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 0.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.secondaryColor,
              child: Icon(Icons.auto_awesome, size: 20, color: AppTheme.primaryColor),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightSurfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Animate(
                    delay: (index * 200).ms,
                    onPlay: (c) => c.repeat(reverse: true),
                    effects: const [
                      ScaleEffect(
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          begin: Offset(0.7, 0.7),
                          end: Offset(1.1, 1.1))
                    ],
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryTextColor.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}