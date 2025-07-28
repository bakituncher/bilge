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
        title: const Text('BilgeAI Merkezi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAiToolCard(
              context: context,
              title: 'Yapay Zeka Koçu',
              subtitle: 'Kişisel analiz, tavsiye ve program',
              icon: Icons.auto_awesome,
              onTap: () => context.go('/ai-hub/ai-coach'),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

            _buildAiToolCard(
              context: context,
              title: 'Motivasyon Sohbeti',
              subtitle: 'Zorlandığında konuşabileceğin bir dost',
              icon: Icons.forum_rounded,
              onTap: () => context.go('/ai-hub/motivation-chat'),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildAiToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }
}