// lib/features/quests/screens/quests_screen.dart

import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(dailyQuestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Günlük Fetihler"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.cardColor.withOpacity(0.1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.cardColor.withOpacity(0.8)],
          ),
        ),
        child: questsAsync.when(
          data: (quests) {
            if (quests.isEmpty) {
              return const Center(child: Text("Bugün için yeni fetihler bulunamadı."));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: quests.length,
              itemBuilder: (context, index) {
                return QuestCard(quest: quests[index])
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideY(begin: 0.3, curve: Curves.easeOutCubic);
              },
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.secondaryColor),
                SizedBox(height: 20),
                Text(
                  "Fetih Haritası Yükleniyor...",
                  style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16),
                ),
              ],
            ),
          ),
          error: (err, stack) => Center(child: Text("Hata: $err")),
        ),
      ),
    );
  }
}

class QuestCard extends StatelessWidget {
  final Quest quest;
  const QuestCard({super.key, required this.quest});

  IconData _getIconForCategory(QuestCategory category) {
    switch (category) {
      case QuestCategory.study:
        return Icons.book_rounded;
      case QuestCategory.practice:
        return Icons.edit_note_rounded;
      case QuestCategory.engagement:
        return Icons.auto_awesome;
      case QuestCategory.consistency:
        return Icons.event_repeat_rounded;
      default:
        return Icons.shield_moon_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.currentProgress >= quest.goalValue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(quest.actionRoute),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isCompleted ? AppTheme.successColor.withOpacity(0.2) : AppTheme.secondaryColor.withOpacity(0.2),
                    child: Icon(
                      _getIconForCategory(quest.category),
                      color: isCompleted ? AppTheme.successColor : AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quest.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    label: Text("+${quest.reward} BP", style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  if (!isCompleted)
                    Text(
                      "${quest.currentProgress} / ${quest.goalValue}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    )
                  else
                    const Row(
                      children: [
                        Text("Fethedildi!", style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 20)
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}