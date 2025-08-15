// lib/shared/widgets/quest_completion_toast.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/quests/logic/quest_completion_notifier.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

class QuestCompletionToast extends ConsumerStatefulWidget {
  final Quest completedQuest;
  const QuestCompletionToast({super.key, required this.completedQuest});

  @override
  ConsumerState<QuestCompletionToast> createState() => _QuestCompletionToastState();
}

class _QuestCompletionToastState extends ConsumerState<QuestCompletionToast> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // 4 saniye sonra bildirimi otomatik olarak kapatmak için bir zamanlayıcı başlat.
    _dismissTimer = Timer(4.seconds, () {
      if (mounted) {
        ref.read(questCompletionProvider.notifier).clear();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    ref.read(questCompletionProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss, // Kullanıcı dokunursa hemen kapat.
      child: Animate(
        // Bildirim ekrandan kaldırıldığında (state null olduğunda) çıkış animasyonunu oynat.
        target: ref.watch(questCompletionProvider) == null ? 0 : 1,
        // HATA GİDERİLDİ: 'effects' listesindeki 'const' anahtar kelimesi kaldırıldı.
        effects: [
          SlideEffect(begin: const Offset(0, 0.5), end: Offset.zero, duration: 400.ms, curve: Curves.easeOutCubic),
          FadeEffect(begin: 0.0, end: 1.0, duration: 400.ms),
        ],
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.5), width: 1.5),
            color: const Color(0xFF2A374E), // Daha canlı bir kart rengi
            boxShadow: [
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.military_tech_rounded, color: AppTheme.successColor, size: 40)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white)
                  .animate() // İkinci animasyon için
                  .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.completedQuest.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "+${widget.completedQuest.reward} Bilgelik Puanı",
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}