// lib/features/quests/logic/optimized_quests_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

/// Aktif görev listesini user stream değiştikçe minimal diff ile günceller.
/// Amaç: Her küçük Firestore alan değişiminde tüm görev kartlarının rebuild olmasını önlemek.
class OptimizedQuestsNotifier extends StateNotifier<List<Quest>> {
  final Ref _ref;
  OptimizedQuestsNotifier(this._ref) : super(const []) {
    // Başlangıç
    final user = _ref.read(userProfileProvider).value;
    if (user != null) {
      state = List<Quest>.from(user.activeDailyQuests);
    }
    // Stream dinle
    _ref.listen(userProfileProvider, (previous, next) {
      final newUser = next.value;
      if (newUser == null) {
        if (state.isNotEmpty) state = const [];
        return;
      }
      final newQuests = newUser.activeDailyQuests;
      // Hızlı referans karşılaştırması: aynı uzunluk ve id'ler + progress & completed değişmemişse atla
      if (_isSameList(state, newQuests)) return; // hiçbir fark yok
      // Diff uygula: eski referansları mümkün olduğunca koru
      final Map<String, Quest> oldMap = {for (final q in state) q.id: q};
      final List<Quest> updated = [];
      bool changed = false;
      for (final nq in newQuests) {
        final old = oldMap[nq.id];
        if (old == null) {
          updated.add(nq);
          changed = true;
        } else {
          if (_questDiffers(old, nq)) {
            updated.add(nq); // yeni sürüm
            changed = true;
          } else {
            updated.add(old); // referansı koru
          }
        }
      }
      if (changed || updated.length != state.length) {
        state = updated;
      }
    });
  }

  bool _questDiffers(Quest a, Quest b) {
    return a.currentProgress != b.currentProgress ||
        a.isCompleted != b.isCompleted ||
        a.reward != b.reward ||
        a.goalValue != b.goalValue ||
        a.title != b.title ||
        a.description != b.description;
  }

  bool _isSameList(List<Quest> oldList, List<Quest> newList) {
    if (identical(oldList, newList)) return true;
    if (oldList.length != newList.length) return false;
    for (int i = 0; i < oldList.length; i++) {
      final o = oldList[i];
      final n = newList[i];
      if (o.id != n.id) return false;
      if (_questDiffers(o, n)) return false;
    }
    return true;
  }
}

final optimizedDailyQuestsProvider = StateNotifierProvider<OptimizedQuestsNotifier, List<Quest>>((ref) {
  return OptimizedQuestsNotifier(ref);
});

