// lib/features/coach/screens/ai_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

// Öğretici için GlobalKey'ler
final GlobalKey strategicPlanningKey = GlobalKey();
final GlobalKey weaknessWorkshopKey = GlobalKey();
final GlobalKey motivationChatKey = GlobalKey();

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.go('/ai-hub/strategic-planning');
                },
                child: Animate(
                  onPlay: (controller) => controller.repeat(),
                  effects: [
                    ShimmerEffect(
                      duration: 3000.ms,
                      color: AppTheme.secondaryColor.withAlpha(80),
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
                            AppTheme.secondaryColor.withAlpha(100),
                            AppTheme.primaryColor.withAlpha(150),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryColor.withOpacity(0.3),
                            blurRadius: 40,
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
              const Spacer(),
              _buildAiToolButton(
                context,
                'Stratejik Planlama',
                'Uzun vadeli zafer stratejini ve haftalık planını oluştur.',
                    () => context.go('/ai-hub/strategic-planning'),
                Icons.insights_rounded,
                delay: 200.ms,
                key: strategicPlanningKey,
              ),
              _buildAiToolButton(
                context,
                'Cevher Atölyesi',
                'En zayıf konunu, kişisel çalışma kartı ve özel test ile işle.',
                    () => context.go('/ai-hub/weakness-workshop'),
                Icons.construction_rounded,
                delay: 300.ms,
                key: weaknessWorkshopKey,
              ),
              _buildAiToolButton(
                context,
                'Motivasyon Sohbeti',
                'Zorlandığında konuşabileceğin bir dost.',
                    () => context.go('/ai-hub/motivation-chat'),
                Icons.forum_rounded,
                delay: 400.ms,
                key: motivationChatKey,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiToolButton(BuildContext context, String title, String subtitle, VoidCallback onTap, IconData icon, {required Duration delay, required GlobalKey key}) {
    return Animate(
      delay: delay,
      effects: [const FadeEffect(duration: Duration(milliseconds: 500)), const SlideEffect(begin: Offset(0, 0.2))],
      child: Card(
        key: key,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(icon, size: 32, color: AppTheme.secondaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}