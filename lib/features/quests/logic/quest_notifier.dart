// lib/features/quests/logic/quest_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/pomodoro/logic/pomodoro_notifier.dart'; // <-- HATA GİDERİLDİ: Import eklendi
import 'quest_completion_notifier.dart';
import 'package:bilge_ai/features/quests/quest_armory.dart';
import 'package:flutter/services.dart'; // haptic

// ZİNCİR HARİTASI (Odak + Cevher)
const Map<String,String> _chainNextMap = {
  'chain_focus_1': 'chain_focus_2',
  'chain_focus_2': 'chain_focus_3',
  'chain_workshop_1': 'chain_workshop_2',
  'chain_workshop_2': 'chain_workshop_3',
};

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
    bool chainAdded = false;
    bool hiddenBonusAwarded = false;
    int extraEngagementDelta = 0;
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

      bool willComplete = newProgress >= quest.goalValue;

      if (willComplete) {
        final completedQuest = quest.copyWith(
          currentProgress: quest.goalValue,
          isCompleted: true,
          completionDate: Timestamp.now(),
        );

        _ref.read(_sessionCompletedQuestsProvider.notifier).update((state) => {...state, quest.id});
        _ref.read(questCompletionProvider.notifier).show(completedQuest);
        HapticFeedback.mediumImpact(); // haptic başarı
        extraEngagementDelta += quest.reward;
        activeQuestsCopy[i] = completedQuest;
        questUpdated = true;

        // 1) Adaptif ikinci kademe bonus: adaptive_practice_01 (>=30), adaptive_focus_01 (>=40)
        if (quest.id == 'adaptive_practice_01' && amount >= 30) {
          extraEngagementDelta += 30; hiddenBonusAwarded = true;
        } else if (quest.id == 'adaptive_focus_01' && amount >= 40) {
          extraEngagementDelta += 25; hiddenBonusAwarded = true;
        }

        // 3) Zincir görev otomatik ekleme
        // Odak + Cevher zincirleri tek haritadan yönetilir
        if (_chainNextMap.containsKey(quest.id)) {
          final nextId = _chainNextMap[quest.id]!;
          final alreadyHasNext = activeQuestsCopy.any((q) => q.id == nextId);
          if (!alreadyHasNext) {
            final template = questArmory.firstWhere((t) => t['id'] == nextId, orElse: () => {});
            if (template.isNotEmpty) {
              final newQuest = Quest(
                id: template['id'],
                title: template['title'],
                description: template['description'],
                type: QuestType.values.byName((template['type'] ?? 'daily')), // default daily
                category: QuestCategory.values.byName(template['category']),
                progressType: QuestProgressType.values.byName((template['progressType'] ?? 'increment')),
                reward: template['reward'] ?? 10,
                goalValue: template['goalValue'] ?? 1,
                actionRoute: template['actionRoute'] ?? '/home',
              );
              activeQuestsCopy.add(newQuest);
              chainAdded = true;
              HapticFeedback.selectionClick();
            }
          }
        }
      } else if (newProgress > quest.currentProgress) {
        activeQuestsCopy[i] = quest.copyWith(currentProgress: newProgress);
        questUpdated = true;
      }
    }

    // 2) Gizli Sandık otomatik tamamlama (celebration_01) – 4 farklı kategori tamamlandıysa
    final celebrationIndex = activeQuestsCopy.indexWhere((q) => q.id == 'celebration_01' && !q.isCompleted);
    if (celebrationIndex != -1) {
      final completedCategories = activeQuestsCopy.where((q) => q.isCompleted).map((q) => q.category).toSet();
      if (completedCategories.length >= 4) {
        final sandik = activeQuestsCopy[celebrationIndex];
        final completedSandik = sandik.copyWith(
          currentProgress: sandik.goalValue,
          isCompleted: true,
          completionDate: Timestamp.now(),
        );
        activeQuestsCopy[celebrationIndex] = completedSandik;
        extraEngagementDelta += sandik.reward;
        _ref.read(questCompletionProvider.notifier).show(completedSandik);
        HapticFeedback.mediumImpact();
        questUpdated = true;
      }
    }

    if (questUpdated) {
      await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
        'activeDailyQuests': activeQuestsCopy.map((q) => q.toMap()).toList(),
        if (extraEngagementDelta != 0) 'engagementScore': FieldValue.increment(extraEngagementDelta),
      });
      _ref.invalidate(dailyQuestsProvider);
    }

    // Bonus bildirimi için (UI snackbar tetikleyebilir) – burada sadece state’i koruyoruz.
    if (hiddenBonusAwarded || chainAdded) {
      // Bu aşamada sadece log bırakabiliriz (debug) – UI tarafında isteğe göre toast eklenebilir.
    }
  }

  Future<void> updateQuestProgressById(String questId, {int amount = 1}) async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.activeDailyQuests.isEmpty) return;

    final activeQuestsCopy = List<Quest>.from(user.activeDailyQuests);
    final idx = activeQuestsCopy.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    var quest = activeQuestsCopy[idx];
    if (quest.isCompleted) return;

    int newProgress = quest.currentProgress + amount;
    if (newProgress >= quest.goalValue) {
      final completedQuest = quest.copyWith(
        currentProgress: quest.goalValue,
        isCompleted: true,
        completionDate: Timestamp.now(),
      );
      activeQuestsCopy[idx] = completedQuest;
      _ref.read(questCompletionProvider.notifier).show(completedQuest);
      HapticFeedback.mediumImpact();
      await _ref.read(firestoreServiceProvider).updateEngagementScore(user.id, quest.reward);

      // Zincir devamı gerekiyorsa ekle
      if (_chainNextMap.containsKey(quest.id)) {
        final nextId = _chainNextMap[quest.id]!;
        final alreadyHasNext = activeQuestsCopy.any((q) => q.id == nextId);
        if (!alreadyHasNext) {
          final template = questArmory.firstWhere((t) => t['id'] == nextId, orElse: () => {});
          if (template.isNotEmpty) {
            final newQuest = Quest(
              id: template['id'],
              title: template['title'],
              description: template['description'],
              type: QuestType.values.byName((template['type'] ?? 'daily')), // default daily
              category: QuestCategory.values.byName(template['category']),
              progressType: QuestProgressType.values.byName((template['progressType'] ?? 'increment')),
              reward: template['reward'] ?? 10,
              goalValue: template['goalValue'] ?? 1,
              actionRoute: template['actionRoute'] ?? '/home',
            );
            activeQuestsCopy.add(newQuest);
          }
        }
      }
    } else {
      activeQuestsCopy[idx] = quest.copyWith(currentProgress: newProgress);
    }

    await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
      'activeDailyQuests': activeQuestsCopy.map((q) => q.toMap()).toList(),
    });
    _ref.invalidate(dailyQuestsProvider);
  }
}