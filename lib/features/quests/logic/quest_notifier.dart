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
import 'package:bilge_ai/core/analytics/analytics_logger.dart';
import 'package:bilge_ai/features/quests/logic/quest_progress_controller.dart';

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
  final QuestProgressController _controller = const QuestProgressController();
  QuestNotifier(this._ref) : super(false) {
    _listenToUserActions();
  }

  void _listenToUserActions() {
    _ref.listen<PomodoroModel>(pomodoroProvider, (previous, next) {
      if (previous?.sessionState != PomodoroSessionState.completed && next.sessionState == PomodoroSessionState.completed) {
        _controller.updateQuestProgress(_ref, QuestCategory.engagement, amount: 1);
        if (next.lastResult != null) {
          _controller.updateQuestProgress(_ref, QuestCategory.focus, amount: (next.lastResult!.totalFocusSeconds ~/ 60));
        }
      }
    });
  }

  Future<void> updateQuestProgress(QuestCategory category, {int amount = 1}) async => _controller.updateQuestProgress(_ref, category, amount: amount);
  Future<void> updateQuestProgressById(String questId, {int amount = 1}) async => _controller.updateQuestProgressById(_ref, questId, amount: amount);
}
