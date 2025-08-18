import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/quests/quest_armory.dart';
import 'package:bilge_ai/features/quests/logic/quest_completion_notifier.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/core/analytics/analytics_logger.dart';

// Oturum içinde tamamlanan görevleri tekrarlı progressten korur
final sessionCompletedQuestsProvider = StateProvider<Set<String>>((ref) => {});

class QuestProgressController {
  const QuestProgressController();

  Future<void> updateQuestProgress(Ref ref, QuestCategory category, {int amount = 1}) async {
    final user = ref.read(userProfileProvider).value;
    if (user == null || user.activeDailyQuests.isEmpty) return;

    final sessionCompletedIds = ref.read(sessionCompletedQuestsProvider);
    bool questUpdated = false;
    bool chainAdded = false;
    bool hiddenBonusAwarded = false;
    int extraEngagementDelta = 0;
    final activeQuestsCopy = List<Quest>.from(user.activeDailyQuests);

    for (var i = 0; i < activeQuestsCopy.length; i++) {
      var quest = activeQuestsCopy[i];
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
        final completedQuest = quest.copyWith(currentProgress: quest.goalValue, isCompleted: true, completionDate: Timestamp.now());
        ref.read(sessionCompletedQuestsProvider.notifier).update((s)=>{...s, quest.id});
        ref.read(questCompletionProvider.notifier).show(completedQuest);
        HapticFeedback.mediumImpact();
        extraEngagementDelta += quest.reward;
        activeQuestsCopy[i] = completedQuest;
        questUpdated = true;
        ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_completed', data: {
          'questId': quest.id,'category': quest.category.name,'reward': quest.reward,'difficulty': quest.difficulty.name,
        });
        // Bonuslar
        if (quest.id == 'adaptive_practice_01' && amount >= 30) { extraEngagementDelta += 30; hiddenBonusAwarded = true; }
        if (quest.id == 'adaptive_focus_01' && amount >= 40) { extraEngagementDelta += 25; hiddenBonusAwarded = true; }
        // Zincir
        _maybeAddNextChainQuest(ref, quest, activeQuestsCopy, user.id, onAdded: ()=> chainAdded = true);
      } else if (newProgress > quest.currentProgress) {
        activeQuestsCopy[i] = quest.copyWith(currentProgress: newProgress);
        questUpdated = true;
        ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_progress', data: {
          'questId': quest.id,'progress': newProgress,'goal': quest.goalValue,
        });
      }
    }

    // Gizli Sandık
    final celebrationIndex = activeQuestsCopy.indexWhere((q) => q.id == 'celebration_01' && !q.isCompleted);
    if (celebrationIndex != -1) {
      final completedCategories = activeQuestsCopy.where((q) => q.isCompleted).map((q) => q.category).toSet();
      if (completedCategories.length >= 4) {
        final sandik = activeQuestsCopy[celebrationIndex];
        final completedSandik = sandik.copyWith(currentProgress: sandik.goalValue,isCompleted: true,completionDate: Timestamp.now());
        activeQuestsCopy[celebrationIndex] = completedSandik;
        extraEngagementDelta += sandik.reward;
        ref.read(questCompletionProvider.notifier).show(completedSandik);
        HapticFeedback.mediumImpact();
        questUpdated = true;
      }
    }

    if (questUpdated) {
      await ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
        'activeDailyQuests': activeQuestsCopy.map((q)=>q.toMap()).toList(),
        if (extraEngagementDelta!=0) 'engagementScore': FieldValue.increment(extraEngagementDelta),
      });
      ref.invalidate(dailyQuestsProvider);
    }
    if (hiddenBonusAwarded || chainAdded) {
      // Sessiz log – UI tarafında ileride kullanılabilir.
    }
  }

  Future<void> updateQuestProgressById(Ref ref, String questId, {int amount = 1}) async {
    final user = ref.read(userProfileProvider).value;
    if (user == null || user.activeDailyQuests.isEmpty) return;
    final activeQuestsCopy = List<Quest>.from(user.activeDailyQuests);
    final idx = activeQuestsCopy.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = activeQuestsCopy[idx];
    if (quest.isCompleted) return;
    int newProgress = quest.currentProgress + amount;
    if (newProgress >= quest.goalValue) {
      final completedQuest = quest.copyWith(currentProgress: quest.goalValue,isCompleted: true,completionDate: Timestamp.now());
      activeQuestsCopy[idx] = completedQuest;
      ref.read(questCompletionProvider.notifier).show(completedQuest);
      HapticFeedback.mediumImpact();
      await ref.read(firestoreServiceProvider).updateEngagementScore(user.id, quest.reward);
      ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_completed', data: {
        'questId': quest.id,'category': quest.category.name,'reward': quest.reward,'difficulty': quest.difficulty.name,
      });
      _maybeAddNextChainQuest(ref, quest, activeQuestsCopy, user.id);
    } else {
      activeQuestsCopy[idx] = quest.copyWith(currentProgress: newProgress);
      ref.read(analyticsLoggerProvider).logQuestEvent(userId: user.id, event: 'quest_progress', data: {
        'questId': quest.id,'progress': newProgress,'goal': quest.goalValue,
      });
    }
    await ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({'activeDailyQuests': activeQuestsCopy.map((q)=>q.toMap()).toList()});
    ref.invalidate(dailyQuestsProvider);
  }

  void _maybeAddNextChainQuest(Ref ref, Quest quest, List<Quest> list, String userId, {VoidCallback? onAdded}) {
    const Map<String,String> chainNextMap = {
      'chain_focus_1': 'chain_focus_2',
      'chain_focus_2': 'chain_focus_3',
      'chain_workshop_1': 'chain_workshop_2',
      'chain_workshop_2': 'chain_workshop_3',
    };
    if (!chainNextMap.containsKey(quest.id)) return;
    final nextId = chainNextMap[quest.id]!;
    if (list.any((q)=>q.id==nextId)) return;
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
    list.add(newQuest);
    ref.read(analyticsLoggerProvider).logQuestEvent(userId: userId, event: 'quest_chain_next_added', data: {
      'fromQuestId': quest.id,'nextQuestId': newQuest.id,'chainId': newQuest.chainId,'chainStep': newQuest.chainStep,
    });
    onAdded?.call();
  }
}
