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

  /// Görev ilerlemesini güncelleyen merkezi komuta fonksiyonu.
  /// Bu fonksiyon, tüm görev tiplerini ve senaryoları yönetecek şekilde tasarlandı.
  /// [category]: Hangi tür eylemin gerçekleştiğini belirtir (örn: practice, engagement).
  /// [amount]: Eylemin miktarını belirtir (örn: çözülen 50 soru için 50). Varsayılan 1'dir.
  Future<void> updateQuestProgress(QuestCategory category, {int amount = 1}) async {
    // Anlık kullanıcı verisini al, kullanıcı yoksa veya aktif görevi yoksa işlemi sonlandır.
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.activeQuests.isEmpty) return;

    bool questUpdated = false;
    // Veritabanındaki listeyi değiştirmemek için bir kopya oluştur.
    final activeQuestsCopy = List<Quest>.from(user.activeQuests);

    // Yalnızca ilgili kategorideki tamamlanmamış görevleri hedef al.
    final targetQuests = activeQuestsCopy.where((q) =>
    q.category == category && !q.isCompleted
    ).toList();

    // Eğer bu kategoride aktif görev yoksa, kaynakları boşa harcama.
    if (targetQuests.isEmpty) return;

    // Hedefteki her bir görev için ilerlemeyi hesapla.
    for (var quest in targetQuests) {
      int newProgress = quest.currentProgress;

      // GÖREV TÜRÜNE GÖRE AKILLI İLERLEME MANTIĞI
      switch (quest.progressType) {
      // 'increment' tipli görevler için: Gelen miktarı mevcut ilerlemeye ekle.
      // Örn: Pomodoro yapmak (amount=1), 50 soru çözmek (amount=50).
        case QuestProgressType.increment:
          newProgress += amount;
          break;
      // 'userStreak' tipli görevler için: İlerlemeyi doğrudan kullanıcının serisine eşitle.
      // Bu, en güncel ve doğru seri bilgisini garantiler.
        case QuestProgressType.userStreak:
          newProgress = user.streak;
          break;
      }

      // Güncellenecek görevin kopyalanan listedeki index'ini bul.
      final questIndex = activeQuestsCopy.indexWhere((q) => q.id == quest.id);
      if (questIndex == -1) continue; // Güvenlik kontrolü: Görev listede yoksa atla.

      // Görev tamamlandı mı kontrol et.
      if (newProgress >= quest.goalValue && !quest.isCompleted) {
        // Görev YENİ tamamlandıysa:
        // 1. Ödülü kullanıcıya ver.
        await _ref.read(firestoreServiceProvider).updateEngagementScore(user.id, quest.reward);

        // 2. Görevi "tamamlandı" olarak işaretle ve ilerlemesini hedefe sabitle.
        activeQuestsCopy[questIndex] = quest.copyWith(
          currentProgress: quest.goalValue,
          isCompleted: true,
        );
        questUpdated = true;
      } else if (!quest.isCompleted) {
        // Görev henüz tamamlanmadıysa, sadece ilerlemesini güncelle.
        activeQuestsCopy[questIndex] = quest.copyWith(
          currentProgress: newProgress,
        );
        questUpdated = true;
      }
    }

    // Eğer en az bir görevde değişiklik yapıldıysa, veritabanını güncelle.
    if (questUpdated) {
      await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
        'activeQuests': activeQuestsCopy.map((q) => q.toMap()..['id'] = q.id).toList(),
      });
      // Görev listesi ekranının anında güncellenmesi için provider'ı yenile.
      _ref.invalidate(dailyQuestsProvider);
    }
  }
}