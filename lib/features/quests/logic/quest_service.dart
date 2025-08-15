// lib/features/quests/logic/quest_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/quests/quest_templates.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:uuid/uuid.dart';
import 'package:bilge_ai/data/models/exam_model.dart';

// Bu servis, görev oluşturma ve yenileme mantığının beynidir.
final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService(ref);
});

class QuestService {
  final Ref _ref;
  QuestService(this._ref);

  /// Kullanıcı için günlük görevleri yenileyen ana fonksiyon.
  /// Her gün sadece bir kez çalışır.
  Future<List<Quest>> refreshDailyQuestsForUser(UserModel user) async {
    final today = DateTime.now();
    final lastRefresh = user.lastQuestRefreshDate?.toDate();

    // Eğer bugün zaten görevler yenilendiyse, mevcut görevleri döndür.
    if (lastRefresh != null &&
        lastRefresh.year == today.year &&
        lastRefresh.month == today.month &&
        lastRefresh.day == today.day) {
      return user.activeDailyQuests;
    }

    // Bugün için yeni görevler oluştur.
    final newQuests = await _generateQuestsForUser(user);

    // Yeni görevleri ve yenilenme tarihini veritabanına kaydet.
    await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
      'activeDailyQuests': newQuests.map((q) => q.toMap()).toList(),
      'lastQuestRefreshDate': Timestamp.now(),
    });

    return newQuests;
  }

  /// "KADERİN KALEMİ" MOTORU: Kullanıcıya özel görevleri akıllıca seçer.
  Future<List<Quest>> _generateQuestsForUser(UserModel user) async {
    final List<Quest> generatedQuests = [];
    final random = Random();
    final templatesToUse = List<Map<String, dynamic>>.from(questTemplates);
    templatesToUse.shuffle(); // Görevlerin her gün farklı sırada gelmesi için karıştır.

    // Kullanıcının performans analizi için verileri hazırla.
    final tests = await _ref.read(testsProvider.future);
    final examData = user.selectedExam != null
        ? await ExamData.getExamByType(ExamType.values.byName(user.selectedExam!))
        : null;

    StatsAnalysis? analysis;
    if (tests.isNotEmpty && examData != null) {
      analysis = StatsAnalysis(tests, user.topicPerformances, examData, user: user);
    }

    // --- GÖREV ATAMA STRATEJİSİ ---

    // Strateji 1: Her zaman bir tutarlılık görevi ver.
    final consistencyQuest = templatesToUse.firstWhere((q) => q['category'] == 'consistency', orElse: () => {});
    if (consistencyQuest.isNotEmpty) {
      generatedQuests.add(_createQuestFromTemplate(consistencyQuest));
    }

    // Strateji 2: Her zaman bir deneme ekleme görevi ver.
    final addTestQuest = templatesToUse.firstWhere((q) => q['id'] == 'practice_03', orElse: () => {});
    if (addTestQuest.isNotEmpty) {
      generatedQuests.add(_createQuestFromTemplate(addTestQuest));
    }

    // Strateji 3: Zayıf noktaya saldır! En zayıf derse özel bir pratik görevi ata.
    if (analysis?.weakestSubjectByNet != null && analysis!.weakestSubjectByNet != "Belirlenemedi") {
      final practiceQuest = templatesToUse.firstWhere((q) => q['id'] == 'practice_01', orElse: () => {});
      if (practiceQuest.isNotEmpty) {
        generatedQuests.add(_createQuestFromTemplate(
            practiceQuest,
            variables: {'{subject}': analysis.weakestSubjectByNet}
        ));
      }
    } else {
      // Eğer zayıf ders bulunamazsa, rastgele bir pratik görevi ver.
      final randomPractice = templatesToUse.firstWhere((q) => q['category'] == 'practice' && q['variables'] == null, orElse: () => {});
      if (randomPractice.isNotEmpty) {
        generatedQuests.add(_createQuestFromTemplate(randomPractice));
      }
    }

    // Strateji 4: Geri kalan slotları doldur. Hedef: Toplam 4-5 görev.
    final engagementQuests = templatesToUse.where((q) => q['category'] == 'engagement').toList();
    final studyQuests = templatesToUse.where((q) => q['category'] == 'study').toList();
    final remainingPool = [...engagementQuests, ...studyQuests]..shuffle();

    while (generatedQuests.length < 5 && remainingPool.isNotEmpty) {
      final template = remainingPool.removeAt(0);
      // Aynı ID'li görevin tekrar eklenmesini engelle.
      if (!generatedQuests.any((q) => q.title == template['title'])) {
        generatedQuests.add(_createQuestFromTemplate(template));
      }
    }

    return generatedQuests.toSet().toList();
  }

  /// Şablondan, tüm alanları doldurulmuş, hatasız bir Quest nesnesi oluşturur.
  Quest _createQuestFromTemplate(Map<String, dynamic> template, {Map<String, String>? variables}) {
    String title = template['title'];
    String description = template['description'];

    if (variables != null) {
      variables.forEach((key, value) {
        title = title.replaceAll(key, value);
        description = description.replaceAll(key, value);
      });
    }

    return Quest(
      id: template['id'] ?? const Uuid().v4(),
      title: title,
      description: description,
      type: QuestType.daily,
      category: QuestCategory.values.byName(template['category']),
      progressType: QuestProgressType.values.byName(template['progressType'] ?? 'increment'),
      reward: template['reward'],
      goalValue: template['goalValue'] ?? 1,
      actionRoute: template['actionRoute'],
    );
  }
}

/// Bu provider, UI'ın o anki günlük görevleri anlık olarak dinlemesini sağlar.
final dailyQuestsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return [];
  }
  final questService = ref.read(questServiceProvider);
  return await questService.refreshDailyQuestsForUser(user);
});