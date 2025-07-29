// lib/features/coach/screens/ai_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BilgeAI Çekirdeği'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Yapay Zeka Çekirdeği" görselleştirmesi
            GestureDetector(
              onTap: () {
                // Çekirdeğe dokunulduğunda birincil eylemi (Stratejik Koçluk) tetikle.
                context.go('/ai-hub/ai-coach');
              },
              child: Animate(
                onPlay: (controller) => controller.repeat(),
                effects: [
                  ShimmerEffect(
                    duration: 3000.ms,
                    color: Theme.of(context).colorScheme.secondary.withAlpha(80),
                  ),
                ],
                child: Animate(
                  effects: const [
                    ScaleEffect(
                      curve: Curves.easeInOut,
                      duration: Duration(seconds: 4),
                      begin: Offset(0.95, 0.95),
                      end: Offset(1, 1),
                    ),
                  ],
                  onPlay: (controller) => controller.repeat(reverse: true),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary.withAlpha(150),
                          Theme.of(context).colorScheme.primary.withAlpha(200),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Holografik Butonlar
            _buildAiToolButton(
              context,
              'Stratejik Koçluk',
              'Kişisel analiz, rapor ve haftalık eylem planın.',
                  () => context.go('/ai-hub/ai-coach'), // BİRLEŞTİRİLDİ
              Icons.insights_rounded,
              delay: 200.ms,
            ),
            _buildAiToolButton(
              context,
              'Zayıflık Avcısı',
              'En zayıf konundan anında özel sorular çöz.',
                  () => context.go('/ai-hub/weakness-hunter'), // YEPYENİ ÖZELLİK
              Icons.radar_rounded,
              delay: 300.ms,
            ),
            _buildAiToolButton(
              context,
              'Motivasyon Sohbeti',
              'Zorlandığında konuşabileceğin bir dost.',
                  () => context.go('/ai-hub/motivation-chat'),
              Icons.forum_rounded,
              delay: 400.ms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiToolButton(
      BuildContext context,
      String title,
      String subtitle,
      VoidCallback onTap,
      IconData icon, {
        required Duration delay,
      }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Animate(
      delay: delay,
      effects: [
        const FadeEffect(duration: Duration(milliseconds: 500)),
        const SlideEffect(begin: Offset(0, 0.2))
      ],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}