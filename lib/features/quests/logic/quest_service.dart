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

final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService(ref);
});

class QuestService {
  final Ref _ref;
  QuestService(this._ref);

  // Kullanıcı için görevleri yenileyen ana fonksiyon
  Future<List<Quest>> refreshQuestsForUser(UserModel user) async {
    final today = DateTime.now();
    final lastRefresh = user.lastQuestRefreshDate?.toDate();

    if (lastRefresh != null &&
        lastRefresh.year == today.year &&
        lastRefresh.month == today.month &&
        lastRefresh.day == today.day) {
      return user.activeQuests;
    }

    final newQuests = await _generateQuestsForUser(user);

    await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
      'activeQuests': newQuests.map((q) => q.toMap()..['id'] = q.id).toList(),
      'lastQuestRefreshDate': Timestamp.now(),
    });

    return newQuests;
  }

  // "KADERİN KALEMİ" MOTORU
  Future<List<Quest>> _generateQuestsForUser(UserModel user) async {
    final List<Quest> generatedQuests = [];
    final random = Random();

    final tests = await _ref.read(testsProvider.future);
    final examData = user.selectedExam != null
        ? await ExamData.getExamByType(ExamType.values.byName(user.selectedExam!))
        : null;

    StatsAnalysis? analysis;
    if(tests.isNotEmpty && examData != null) {
      analysis = StatsAnalysis(tests, user.topicPerformances, examData, user: user);
    }

    // --- Görev Atama Mantığı ---
    final templatesToUse = questTemplates.toList(); // Şablonların kopyasını oluştur

    // 1. Her zaman bir tutarlılık görevi ver.
    final consistencyQuestTemplate = templatesToUse.firstWhere((q) => q['id'] == 'consistency_01');
    generatedQuests.add(_createQuestFromTemplate(consistencyQuestTemplate));

    // 2. Bir etkileşim görevi ver (Pomodoro, Strateji vb.)
    final engagementQuests = templatesToUse.where((q) => q['category'] == 'engagement').toList();
    generatedQuests.add(_createQuestFromTemplate(engagementQuests[random.nextInt(engagementQuests.length)]));

    // 3. Kullanıcının en zayıf dersine göre bir pratik görevi ata.
    if (analysis?.weakestSubjectByNet != null && analysis!.weakestSubjectByNet != "Belirlenemedi") {
      final practiceTemplate = templatesToUse.firstWhere((q) => q['id'] == 'practice_01');
      generatedQuests.add(_createQuestFromTemplate(
          practiceTemplate,
          variables: {'{subject}': analysis.weakestSubjectByNet}
      ));
    }

    // 4. Bir deneme ekleme görevi ekle (her zaman)
    final addTestTemplate = templatesToUse.firstWhere((q) => q['id'] == 'practice_03');
    generatedQuests.add(_createQuestFromTemplate(addTestTemplate));

    return generatedQuests.toSet().toList(); // Olası çift görevleri engelle
  }

  // --- HATA BURADAYDI VE DÜZELTİLDİ ---
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
      id: const Uuid().v4(),
      title: title,
      description: description,
      category: QuestCategory.values.byName(template['category']),
      // EKSİK OLAN PARAMETRE BURAYA EKLENDİ
      progressType: QuestProgressType.values.byName(template['progressType'] ?? 'increment'),
      reward: template['reward'],
      goalValue: template['goalValue'] ?? 1,
      currentProgress: 0,
      isCompleted: false,
      expiryDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      actionRoute: template['actionRoute'],
    );
  }
}

// Görevleri getiren ve güncelleyen ana provider
final dailyQuestsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return [];
  }

  final questService = ref.read(questServiceProvider);
  return await questService.refreshQuestsForUser(user);
});