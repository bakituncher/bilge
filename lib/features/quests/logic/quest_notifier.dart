// lib/features/quests/logic/quest_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

final questNotifierProvider = Provider.autoDispose<QuestNotifier>((ref) {
  return QuestNotifier(ref);
});

class QuestNotifier {
  final Ref _ref;
  QuestNotifier(this._ref);

  Future<void> updateQuestProgress(QuestCategory category, {int amount = 1}) async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.activeQuests.isEmpty) return;

    bool questUpdated = false;
    final activeQuestsCopy = List<Quest>.from(user.activeQuests);

    final targetQuests = activeQuestsCopy.where((q) =>
    q.category == category && !q.isCompleted
    ).toList();

    if (targetQuests.isEmpty) return;

    for (var quest in targetQuests) {
      int newProgress = quest.currentProgress;

      // --- ZEKİ GÜNCELLEME MANTIĞI ---
      switch (quest.progressType) {
        case QuestProgressType.increment:
          newProgress += amount;
          break;
        case QuestProgressType.userStreak:
          newProgress = user.streak; // İlerlemeyi doğrudan kullanıcının serisine eşitle!
          break;
      }

      final questIndex = activeQuestsCopy.indexWhere((q) => q.id == quest.id);
      if (questIndex == -1) continue;

      if (newProgress >= quest.goalValue && !quest.isCompleted) {
        await _ref.read(firestoreServiceProvider).updateEngagementScore(user.id, quest.reward);

        activeQuestsCopy[questIndex] = quest.copyWith(
          currentProgress: quest.goalValue,
          isCompleted: true,
        );
        questUpdated = true;
      } else if (!quest.isCompleted) {
        activeQuestsCopy[questIndex] = quest.copyWith(
          currentProgress: newProgress,
        );
        questUpdated = true;
      }
    }

    if (questUpdated) {
      await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
        'activeQuests': activeQuestsCopy.map((q) => q.toMap()..['id'] = q.id).toList(),
      });
      _ref.invalidate(dailyQuestsProvider);
    }
  }
}