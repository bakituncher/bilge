// lib/features/coach/screens/motivation_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

final chatHistoryProvider = StateProvider<List<ChatMessage>>((ref) => [
  ChatMessage("Selam! Başarıya giden bu yolda sana nasıl destek olabilirim?", isUser: false),
]);

class MotivationChatScreen extends ConsumerStatefulWidget {
  const MotivationChatScreen({super.key});

  @override
  ConsumerState<MotivationChatScreen> createState() => _MotivationChatScreenState();
}

class _MotivationChatScreenState extends ConsumerState<MotivationChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(chatHistoryProvider.notifier).update((state) => [...state, ChatMessage(text, isUser: true)]);
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isTyping = true);
    _scrollToBottom(isNewMessage: true);


    final aiService = ref.read(aiServiceProvider);
    final history = ref.read(chatHistoryProvider);
    final aiResponse = await aiService.getMotivationalResponse(history);

    ref.read(chatHistoryProvider.notifier).update((state) => [...state, ChatMessage(aiResponse, isUser: false)]);
    setState(() => _isTyping = false);
    _scrollToBottom(isNewMessage: true);
  }

  void _scrollToBottom({bool isNewMessage = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: isNewMessage ? 300.ms : 100.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Motivasyon Sohbeti')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
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
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Bir mesaj yaz...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              elevation: 1,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Animate(
        effects: [
          const ScaleEffect(
              begin: Offset(0.5, 0.5),
              end: Offset(1, 1),
              duration: Duration(milliseconds: 400),
              curve: Curves.elasticOut),
          const FadeEffect(duration: Duration(milliseconds: 300)),
        ],
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
              color: isUser ? colorScheme.secondary : colorScheme.primary.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser ? colorScheme.secondary.withOpacity(0.4) : colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                )
              ]
          ),
          child: Text(
            message.text,
            style: TextStyle(color: isUser ? colorScheme.primary : Colors.white, fontSize: 15, height: 1.4),
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Animate(
              delay: (index * 200).ms,
              onPlay: (c) => c.repeat(reverse: true),
              // ✅ HATA GİDERİLDİ: 'const' kaldırıldı.
              effects: const [
                ScaleEffect(
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    begin: Offset(0.8, 0.8),
                    end: Offset(1.2, 1.2))
              ],
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}