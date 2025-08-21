// lib/features/quests/logic/optimized_quests_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

/// Aktif görev listesini user stream değiştikçe günceller.
/// Equatable destekli Quest modeli ile gereksiz manuel diff kaldırıldı.
class OptimizedQuestsNotifier extends StateNotifier<List<Quest>> {
  final Ref _ref;
  OptimizedQuestsNotifier(this._ref) : super(const []) {
    // Başlangıç
    final user = _ref.read(userProfileProvider).value;
    if (user != null) {
      state = List<Quest>.from(user.activeDailyQuests);
    }
    // Stream dinle ve direkt ata
    _ref.listen(userProfileProvider, (previous, next) {
      final newUser = next.value;
      if (newUser == null) {
        if (state.isNotEmpty) state = const [];
        return;
      }
      // Equatable sayesinde aynı Quest nesneleri değişmedikçe widget'lar gereksiz yere yeniden build edilmez.
      state = List<Quest>.from(newUser.activeDailyQuests);
    });
  }
}

final optimizedDailyQuestsProvider = StateNotifierProvider<OptimizedQuestsNotifier, List<Quest>>((ref) {
  return OptimizedQuestsNotifier(ref);
});
