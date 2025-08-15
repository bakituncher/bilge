// lib/features/quests/logic/quest_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'quest_completion_notifier.dart'; // YENİ: Zafer Habercisi import edildi.

final questNotifierProvider = Provider.autoDispose<QuestNotifier>((ref) {
  return QuestNotifier(ref);
});

class QuestNotifier {
  final Ref _ref;
  QuestNotifier(this._ref);

  Future<void> updateQuestProgress(QuestCategory category, {int amount = 1}) async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.activeDailyQuests.isEmpty) return;

    bool questUpdated = false;
    final activeQuestsCopy = List<Quest>.from(user.activeDailyQuests);

    for (var quest in activeQuestsCopy) {
      // Sadece ilgili kategorideki tamamlanmamış görevleri hedef al
      if (quest.category != category || quest.isCompleted) continue;

      int newProgress = quest.currentProgress;

      switch (quest.progressType) {
        case QuestProgressType.increment:
          newProgress += amount;
          break;
        case QuestProgressType.set_to_value:
          newProgress = user.streak;
          break;
      }

      final questIndex = activeQuestsCopy.indexWhere((q) => q.id == quest.id);
      if (questIndex == -1) continue;

      if (newProgress >= quest.goalValue) {
        // --- ZAFER SİNYALİ ENTEGRASYONU ---
        // Görev YENİ tamamlandıysa, Zafer Habercisine sinyal gönder.
        final completedQuest = quest.copyWith(
          currentProgress: quest.goalValue,
          isCompleted: true,
          completionDate: Timestamp.now(),
        );
        _ref.read(questCompletionProvider.notifier).show(completedQuest);
        // ------------------------------------

        await _ref.read(firestoreServiceProvider).updateEngagementScore(user.id, quest.reward);
        activeQuestsCopy[questIndex] = completedQuest;
        questUpdated = true;

      } else {
        activeQuestsCopy[questIndex] = quest.copyWith(
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