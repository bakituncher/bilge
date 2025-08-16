// lib/features/quests/logic/quest_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'quest_completion_notifier.dart';

final _sessionCompletedQuestsProvider = StateProvider<Set<String>>((ref) => {});

final questNotifierProvider = Provider.autoDispose<QuestNotifier>((ref) {
  return QuestNotifier(ref);
});

class QuestNotifier {
  final Ref _ref;
  QuestNotifier(this._ref);

  Future<void> updateQuestProgress(QuestCategory category, {int amount = 1}) async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.activeDailyQuests.isEmpty) return;

    final sessionCompletedIds = _ref.read(_sessionCompletedQuestsProvider);
    bool questUpdated = false;
    final activeQuestsCopy = List<Quest>.from(user.activeDailyQuests);

    for (var i = 0; i < activeQuestsCopy.length; i++) {
      var quest = activeQuestsCopy[i];

      if (quest.category != category || quest.isCompleted || sessionCompletedIds.contains(quest.id)) {
        continue;
      }

      int newProgress = quest.currentProgress;

      switch (quest.progressType) {
        case QuestProgressType.increment:
          newProgress += amount;
          break;
        case QuestProgressType.set_to_value:
        // --- YENİ MANTIK: Görev ID'sine göre özel değer ataması ---
          if (quest.id == 'consistency_01') {
            // "Savaşçı Yemini" için güncel ziyaret sayısını al
            newProgress = user.dailyVisits.length;
          } else {
            // Diğer 'set_to_value' görevleri için (örn: seri)
            newProgress = user.streak;
          }
          // --- BİTTİ ---
          break;
      }

      if (newProgress >= quest.goalValue) {
        final completedQuest = quest.copyWith(
          currentProgress: quest.goalValue,
          isCompleted: true,
          completionDate: Timestamp.now(),
        );

        _ref.read(_sessionCompletedQuestsProvider.notifier).update((state) => {...state, quest.id});

        _ref.read(questCompletionProvider.notifier).show(completedQuest);
        await _ref.read(firestoreServiceProvider).updateEngagementScore(user.id, quest.reward);

        activeQuestsCopy[i] = completedQuest;
        questUpdated = true;

      } else {
        activeQuestsCopy[i] = quest.copyWith(
          currentProgress: newProgress,
        );
        questUpdated = true;
      }
    }

    if (questUpdated) {
      await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
        'activeDailyQuests': activeQuestsCopy.map((q) => q.toMap()).toList(),
      });
      _ref.invalidate(dailyQuestsProvider);
    }
  }
}
