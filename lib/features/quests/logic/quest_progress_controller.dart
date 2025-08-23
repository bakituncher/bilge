import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/quests/quest_armory.dart';
import 'package:bilge_ai/features/quests/logic/quest_completion_notifier.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/core/analytics/analytics_logger.dart';
import 'dart:async';

// Oturum içinde tamamlanan görevleri tekrarlı progressten korur
final sessionCompletedQuestsProvider = StateProvider<Set<String>>((ref) => {});

class QuestProgressController {
  const QuestProgressController();

  Future<void> updateQuestProgress(Ref ref, QuestCategory category, {int amount = 1}) async {
    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    // Güncel görevleri alt koleksiyondan çek
    final firestoreSvc = ref.read(firestoreServiceProvider);
    final activeQuests = await firestoreSvc.getDailyQuestsOnce(user.id);
    if (activeQuests.isEmpty) return;

    final sessionCompletedIds = ref.read(sessionCompletedQuestsProvider);
    bool chainAdded = false;
    bool hiddenBonusAwarded = false;
    int engagementDelta = 0;

    final Map<String, Map<String, dynamic>> updates = {};

    for (final quest in activeQuests) {
      if (quest.category != category || quest.isCompleted || sessionCompletedIds.contains(quest.id)) continue;

      int newProgress = quest.currentProgress;
      switch (quest.progressType) {
        case QuestProgressType.increment:
          newProgress += amount; break;
        case QuestProgressType.set_to_value:
          if (quest.id == 'consistency_01') newProgress = user.dailyVisits.length; else newProgress = user.streak; break;
      }
      final willComplete = newProgress >= quest.goalValue;
      if (willComplete) {
        updates[quest.id] = {
          'currentProgress': quest.goalValue,
          'isCompleted': true,
          'completionDate': Timestamp.now(),
        };
        ref.read(sessionCompletedQuestsProvider.notifier).update((s)=>{...s, quest.id});
        ref.read(questCompletionProvider.notifier).show(quest.copyWith(currentProgress: quest.goalValue, isCompleted: true, completionDate: Timestamp.now()));
        HapticFeedback.mediumImpact();
        engagementDelta += quest.reward;
        ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_completed', data: {
          'questId': quest.id,'category': quest.category.name,'reward': quest.reward,'difficulty': quest.difficulty.name,
        });
        // Bonuslar
        if (quest.id == 'adaptive_practice_01' && amount >= 30) { engagementDelta += 30; hiddenBonusAwarded = true; }
        if (quest.id == 'adaptive_focus_01' && amount >= 40) { engagementDelta += 25; hiddenBonusAwarded = true; }
        // Zincir
        await _maybeAddNextChainQuest(ref, quest, user.id, onAdded: ()=> chainAdded = true);
      } else if (newProgress > quest.currentProgress) {
        updates[quest.id] = {
          'currentProgress': newProgress,
        };
        ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_progress', data: {
          'questId': quest.id,'progress': newProgress,'goal': quest.goalValue,
        });
      }
    }

    // Gizli Sandık: mevcut ve tamamlanmamışsa ve 4+ farklı kategori tamamlandıysa
    Quest? celebration;
    for (final q in activeQuests) {
      if (q.id == 'celebration_01' && !q.isCompleted) { celebration = q; break; }
    }
    if (celebration != null) {
      final completedCategories = <QuestCategory>{};
      for (final q in activeQuests) {
        final updated = updates.containsKey(q.id) ? (updates[q.id]!['isCompleted'] == true || q.isCompleted) : q.isCompleted;
        if (updated) completedCategories.add(q.category);
      }
      if (completedCategories.length >= 4) {
        updates[celebration!.id] = {
          'currentProgress': celebration!.goalValue,
          'isCompleted': true,
          'completionDate': Timestamp.now(),
        };
        engagementDelta += celebration!.reward;
        ref.read(questCompletionProvider.notifier).show(celebration!.copyWith(currentProgress: celebration!.goalValue, isCompleted: true, completionDate: Timestamp.now()));
        HapticFeedback.mediumImpact();
      }
    }

    if (updates.isNotEmpty || engagementDelta != 0) {
      await firestoreSvc.batchUpdateQuestFields(user.id, updates, engagementDelta: engagementDelta);
      ref.invalidate(dailyQuestsProvider);
    }
    if (hiddenBonusAwarded || chainAdded) {
      // Sessiz log – UI tarafında ileride kullanılabilir.
    }
  }

  Future<void> updateQuestProgressById(Ref ref, String questId, {int amount = 1}) async {
    final user = ref.read(userProfileProvider).value;
    if (user == null) return;
    final firestoreSvc = ref.read(firestoreServiceProvider);
    final activeQuests = await firestoreSvc.getDailyQuestsOnce(user.id);
    Quest? quest;
    for (final q in activeQuests) { if (q.id == questId) { quest = q; break; } }
    if (quest == null) return;
    if (quest!.isCompleted) return;

    int newProgress = quest!.currentProgress + amount;
    int engagementDelta = 0;
    final Map<String, Map<String,dynamic>> updates = {};

    if (newProgress >= quest!.goalValue) {
      updates[quest!.id] = {
        'currentProgress': quest!.goalValue,
        'isCompleted': true,
        'completionDate': Timestamp.now(),
      };
      ref.read(questCompletionProvider.notifier).show(quest!.copyWith(currentProgress: quest!.goalValue, isCompleted: true, completionDate: Timestamp.now()));
      HapticFeedback.mediumImpact();
      engagementDelta += quest!.reward;
      ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_completed', data: {
        'questId': quest!.id,'category': quest!.category.name,'reward': quest!.reward,'difficulty': quest!.difficulty.name,
      });
      await _maybeAddNextChainQuest(ref, quest!, user.id);
    } else {
      updates[quest!.id] = {
        'currentProgress': newProgress,
      };
      ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_progress', data: {
        'questId': quest!.id,'progress': newProgress,'goal': quest!.goalValue,
      });
    }

    await firestoreSvc.batchUpdateQuestFields(user.id, updates, engagementDelta: engagementDelta);
    ref.invalidate(dailyQuestsProvider);
  }

  Future<void> _maybeAddNextChainQuest(Ref ref, Quest quest, String userId, {VoidCallback? onAdded}) async {
    const Map<String,String> chainNextMap = {
      'chain_focus_1': 'chain_focus_2',
      'chain_focus_2': 'chain_focus_3',
      'chain_workshop_1': 'chain_workshop_2',
      'chain_workshop_2': 'chain_workshop_3',
    };
    if (!chainNextMap.containsKey(quest.id)) return;
    final nextId = chainNextMap[quest.id]!;

    // Zaten var mı kontrolü
    final existing = await ref.read(firestoreServiceProvider).getDailyQuestsOnce(userId);
    if (existing.any((q)=>q.id==nextId)) return;

    final template = questArmory.firstWhere((t)=>t['id']==nextId, orElse: ()=>{});
    if (template.isEmpty) return;
    final newQuest = Quest(
      id: template['id'],
      title: template['title'],
      description: template['description'],
      type: QuestType.values.byName((template['type'] ?? 'daily')),
      category: QuestCategory.values.byName(template['category']),
      progressType: QuestProgressType.values.byName((template['progressType'] ?? 'increment')),
      reward: template['reward'] ?? 10,
      goalValue: template['goalValue'] ?? 1,
      actionRoute: template['actionRoute'] ?? '/home',
      route: questRouteFromPath(template['actionRoute'] ?? '/home'),
      chainId: template['id'].toString().split('_').sublist(0, template['id'].toString().split('_').length -1).join('_'),
      chainStep: int.tryParse(template['id'].toString().split('_').last),
      chainLength: 3,
    );
    await ref.read(firestoreServiceProvider).upsertQuest(userId, newQuest);
    ref.read(analyticsLoggerProvider).logQuestEvent(userId: userId, event: 'quest_chain_next_added', data: {
      'fromQuestId': quest.id,'nextQuestId': newQuest.id,'chainId': newQuest.chainId,'chainStep': newQuest.chainStep,
    });
    onAdded?.call();
  }
}
