// lib/features/quests/logic/quest_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'quest_completion_notifier.dart';

// YENİ: Bu, mevcut uygulama oturumunda tamamlanan görevlerin ID'lerini geçici olarak saklar.
// Bu sayede, veritabanı güncellenmeden önce aynı görevin tekrar tamamlanmasını engeller.
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

    // Oturum içinde daha önce tamamlanmış görevlerin ID'lerini al
    final sessionCompletedIds = _ref.read(_sessionCompletedQuestsProvider);
    bool questUpdated = false;
    final activeQuestsCopy = List<Quest>.from(user.activeDailyQuests);

    for (var i = 0; i < activeQuestsCopy.length; i++) {
      var quest = activeQuestsCopy[i];

      // GÜNCELLENEN KONTROL:
      // 1. Kategori eşleşiyor mu?
      // 2. Veritabanında tamamlanmış olarak işaretlenmiş mi?
      // 3. Bu oturumda zaten tamamlandı olarak işaretlendi mi?
      // Bu üç kontrolden herhangi biri doğruysa, bu görevi atla.
      if (quest.category != category || quest.isCompleted || sessionCompletedIds.contains(quest.id)) {
        continue;
      }

      int newProgress = quest.currentProgress;

      switch (quest.progressType) {
        case QuestProgressType.increment:
          newProgress += amount;
          break;
        case QuestProgressType.set_to_value:
        // Bu örnekte 'userStreak' yerine doğrudan 'user.streak' kullanılıyor
        // Bu, modelin güncel veriye sahip olduğunu varsayar
          newProgress = user.streak;
          break;
      }

      if (newProgress >= quest.goalValue) {
        final completedQuest = quest.copyWith(
          currentProgress: quest.goalValue,
          isCompleted: true,
          completionDate: Timestamp.now(),
        );

        // Bu görevi, bu oturumda tamamlananlar listesine ekle
        _ref.read(_sessionCompletedQuestsProvider.notifier).update((state) => {...state, quest.id});

        // Zafer Habercisine sinyal gönder
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