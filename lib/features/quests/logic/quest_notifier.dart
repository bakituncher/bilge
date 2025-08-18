// lib/features/quests/logic/quest_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/pomodoro/logic/pomodoro_notifier.dart'; // <-- HATA GİDERİLDİ: Import eklendi
import 'quest_completion_notifier.dart';

final _sessionCompletedQuestsProvider = StateProvider<Set<String>>((ref) => {});

final questNotifierProvider = StateNotifierProvider.autoDispose<QuestNotifier, bool>((ref) {
  return QuestNotifier(ref);
});

class QuestNotifier extends StateNotifier<bool> {
  final Ref _ref;
  QuestNotifier(this._ref) : super(false) {
    _listenToUserActions();
  }

  void _listenToUserActions() {
    _ref.listen<PomodoroModel>(pomodoroProvider, (previous, next) { // <-- HATA GİDERİLDİ: pomodoroNotifierProvider -> pomodoroProvider
      if (previous?.sessionState != PomodoroSessionState.completed && next.sessionState == PomodoroSessionState.completed) {
        updateQuestProgress(QuestCategory.engagement, amount: 1);
        if (next.lastResult != null) {
          updateQuestProgress(QuestCategory.focus, amount: (next.lastResult!.totalFocusSeconds ~/ 60));
        }
      }
    });
  }

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
          if (quest.id == 'consistency_01') {
            newProgress = user.dailyVisits.length;
          } else {
            newProgress = user.streak;
          }
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

      } else if (newProgress > quest.currentProgress) {
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