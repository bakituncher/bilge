// lib/features/quests/screens/quests_screen.dart
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(dailyQuestsProvider);

    // Bir görev tamamlandığında konfeti efektini tetiklemek için dinleyici
    ref.listen<AsyncValue<List<Quest>>>(dailyQuestsProvider, (previous, next) {
      final prevQuests = previous?.valueOrNull ?? [];
      final nextQuests = next.valueOrNull ?? [];

      if (prevQuests.isNotEmpty && nextQuests.isNotEmpty) {
        final prevCompleted = prevQuests.where((q) => q.isCompleted).length;
        final nextCompleted = nextQuests.where((q) => q.isCompleted).length;
        if (nextCompleted > prevCompleted) {
          _confettiController.play();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fetih Kütüğü"),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          questsAsync.when(
            data: (quests) {
              if (quests.isEmpty) {
                return _buildEmptyState(context);
              }
              // Görevleri mantıksal gruplara ayır
              final weeklyCampaigns = quests.where((q) => q.type == QuestType.weekly).toList();
              final completedQuests = quests.where((q) => q.isCompleted && q.type == QuestType.daily).toList();
              final activeQuests = quests.where((q) => !q.isCompleted && q.type == QuestType.daily).toList();

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Haftalık Seferler (varsa)
                  if (weeklyCampaigns.isNotEmpty) ...[
                    _SectionHeader(title: "Haftalık Sefer"),
                    ...weeklyCampaigns.map((quest) => QuestCard(quest: quest)),
                    const SizedBox(height: 16),
                  ],

                  // Aktif Günlük Emirler (varsa)
                  if (activeQuests.isNotEmpty) ...[
                    _SectionHeader(title: "Günlük Emirler"),
                    ...activeQuests.map((quest) => QuestCard(quest: quest)),
                  ],

                  // Tamamlanmış Görevler (varsa)
                  if (completedQuests.isNotEmpty) ...[
                    _SectionHeader(title: "Fethedilenler (${completedQuests.length})"),
                    ...completedQuests.map((quest) => QuestCard(quest: quest)),
                  ]
                ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
            error: (err, stack) {
              // Kullanıcı dostu hata mesajı
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.accentColor, size: 64),
                      const SizedBox(height: 16),
                      Text("Görevler Yüklenemedi", style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        "Komutanım, görev parşömenlerini getirirken bir sorunla karşılaştık. Lütfen daha sonra tekrar deneyin.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppTheme.secondaryColor, AppTheme.successColor, Colors.white],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_moon_rounded, size: 80, color: AppTheme.secondaryTextColor),
          const SizedBox(height: 16),
          Text('Bugünün Fetihleri Tamamlandı!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Yarın yeni hedeflerle görüşmek üzere, komutanım.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class QuestCard extends StatelessWidget {
  final Quest quest;
  const QuestCard({super.key, required this.quest});

  IconData _getIconForCategory(QuestCategory category) {
    switch (category) {
      case QuestCategory.study: return Icons.book_rounded;
      case QuestCategory.practice: return Icons.edit_note_rounded;
      case QuestCategory.engagement: return Icons.auto_awesome;
      case QuestCategory.consistency: return Icons.event_repeat_rounded;
      case QuestCategory.test_submission: return Icons.add_chart_rounded;
      default: return Icons.shield_moon_rounded; // Beklenmedik durumlara karşı
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final progress = quest.goalValue > 0 ? (quest.currentProgress / quest.goalValue).clamp(0.0, 1.0) : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      color: isCompleted ? AppTheme.cardColor.withOpacity(0.5) : AppTheme.cardColor,
      child: InkWell(
        // Kullanıcıyı görevi tamamlayabileceği ekrana yönlendir.
        onTap: isCompleted ? null : () => context.go(quest.actionRoute),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        Text(quest.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: isCompleted ? AppTheme.secondaryTextColor : Colors.white)),
                        const SizedBox(height: 4),
                        Text(quest.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isCompleted)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("${quest.currentProgress} / ${quest.goalValue}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    label: Text("+${quest.reward} BP", style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (isCompleted)
                    Row(
                      children: [
                        const Text("Fethedildi!", style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 20)
                      ],
                    ).animate().fadeIn().shake(delay: 200.ms, duration: 300.ms),
                  if (!isCompleted)
                    const Row(
                      children: [
                        Text("Yola Koyul", style: TextStyle(color: AppTheme.secondaryTextColor)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: AppTheme.secondaryTextColor, size: 16),
                      ],
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.lightSurfaceColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(title, style: const TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.bold)),
          ),
          const Expanded(child: Divider(color: AppTheme.lightSurfaceColor)),
        ],
      ),
    );
  }
}