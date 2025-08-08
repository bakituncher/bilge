// lib/features/coach/widgets/mastery_topic_bubble.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';

class MasteryTopicBubble extends StatefulWidget {
  final SubjectTopic topic;
  final TopicPerformanceModel performance;
  final VoidCallback onTap;

  const MasteryTopicBubble({
    super.key,
    required this.topic,
    required this.performance,
    required this.onTap,
  });

  @override
  State<MasteryTopicBubble> createState() => _MasteryTopicBubbleState();
}

class _MasteryTopicBubbleState extends State<MasteryTopicBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Animasyon kontrolcüsünü başlat
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + Random().nextInt(1000)),
    )..repeat(reverse: true); // Sürekli tekrarla (ileri-geri)

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hakimiyet seviyesini hesapla
    // 5'ten az soru çözülmüşse, veri yetersiz kabul edelim (-1)
    final double mastery = widget.performance.questionCount < 5
        ? -1
        : widget.performance.questionCount == 0
        ? 0
        : (widget.performance.correctCount / widget.performance.questionCount);

    // Hakimiyet seviyesine göre rengi belirle
    final Color color = switch (mastery) {
      < 0 => AppTheme.lightSurfaceColor, // Veri Yetersiz
      >= 0 && < 0.4 => AppTheme.accentColor, // Zayıf
      >= 0.4 && < 0.7 => AppTheme.secondaryColor, // Orta
      _ => AppTheme.successColor, // Güçlü
    };

    // Tooltip mesajını oluştur
    final String tooltipMessage = mastery < 0
        ? "${widget.topic.name}\n(Analiz için en az 5 soru çözülmeli)"
        : "${widget.topic.name}\nHakimiyet: %${(mastery * 100).toStringAsFixed(0)}\nD:${widget.performance.correctCount} Y:${widget.performance.wrongCount}";

    return Tooltip(
      message: tooltipMessage,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_isHovered ? 0.7 : 0.4),
                    blurRadius: _isHovered ? 15.0 : 8.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Text(
                widget.topic.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}