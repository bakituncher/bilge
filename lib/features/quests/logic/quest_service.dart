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

  Future<List<Quest>> refreshDailyQuestsForUser(UserModel user) async {
    final today = DateTime.now();
    final lastRefresh = user.lastQuestRefreshDate?.toDate();

    if (lastRefresh != null &&
        lastRefresh.year == today.year &&
        lastRefresh.month == today.month &&
        lastRefresh.day == today.day) {
      return user.activeDailyQuests;
    }

    final newQuests = await _generateQuestsForUser(user);

    await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
      'activeDailyQuests': newQuests.map((q) => q.toMap()).toList(),
      'lastQuestRefreshDate': Timestamp.now(),
    });

    return newQuests;
  }

  Future<List<Quest>> _generateQuestsForUser(UserModel user) async {
    final List<Quest> generatedQuests = [];
    final random = Random();
    final templatesToUse = List<Map<String, dynamic>>.from(questTemplates);
    templatesToUse.shuffle();

    final tests = await _ref.read(testsProvider.future);
    final examData = user.selectedExam != null
        ? await ExamData.getExamByType(ExamType.values.byName(user.selectedExam!))
        : null;

    StatsAnalysis? analysis;
    if (tests.isNotEmpty && examData != null) {
      analysis = StatsAnalysis(tests, user.topicPerformances, examData, user: user);
    }

    // Strateji 1: Tutarlılık görevi ata (Artık her zaman değil)
    if (random.nextDouble() < 0.7) { // %70 ihtimalle Savaşçı Yemini
      final consistencyQuest = templatesToUse.firstWhere((q) => q['id'] == 'consistency_01', orElse: () => {});
      if (consistencyQuest.isNotEmpty) {
        generatedQuests.add(_createQuestFromTemplate(consistencyQuest));
      }
    } else { // %30 ihtimalle Demir İrade
      final consistencyQuest = templatesToUse.firstWhere((q) => q['id'] == 'consistency_02', orElse: () => {});
      if (consistencyQuest.isNotEmpty) {
        generatedQuests.add(_createQuestFromTemplate(consistencyQuest));
      }
    }

    final addTestQuest = templatesToUse.firstWhere((q) => q['id'] == 'practice_03', orElse: () => {});
    if (addTestQuest.isNotEmpty) {
      generatedQuests.add(_createQuestFromTemplate(addTestQuest));
    }

    if (analysis?.weakestSubjectByNet != null && analysis!.weakestSubjectByNet != "Belirlenemedi") {
      final practiceQuest = templatesToUse.firstWhere((q) => q['id'] == 'practice_01', orElse: () => {});
      if (practiceQuest.isNotEmpty) {
        generatedQuests.add(_createQuestFromTemplate(
            practiceQuest,
            variables: {'{subject}': analysis.weakestSubjectByNet}
        ));
      }
    } else {
      final randomPractice = templatesToUse.firstWhere((q) => q['category'] == 'practice' && q['variables'] == null, orElse: () => {});
      if (randomPractice.isNotEmpty) {
        generatedQuests.add(_createQuestFromTemplate(randomPractice));
      }
    }

    final studyQuestTemplate = templatesToUse.firstWhere((q) => q['id'] == 'study_01', orElse: () => {});
    if (studyQuestTemplate.isNotEmpty && examData != null) {
      final relevantSections = _getRelevantSectionsForUser(user, examData);
      final allSubjects = relevantSections.expand((s) => s.subjects.keys).toSet().toList();
      final weakestSubject = analysis?.weakestSubjectByNet;

      if (weakestSubject != null && allSubjects.length > 1) {
        allSubjects.remove(weakestSubject);
      }

      if (allSubjects.isNotEmpty) {
        final randomSubject = allSubjects[random.nextInt(allSubjects.length)];
        generatedQuests.add(_createQuestFromTemplate(
            studyQuestTemplate,
            variables: {'{subject}': randomSubject}
        ));
      }
    }

    final engagementQuests = templatesToUse.where((q) => q['category'] == 'engagement').toList();
    final studyQuests = templatesToUse.where((q) => q['category'] == 'study').toList();
    final remainingPool = [...engagementQuests, ...studyQuests]..shuffle();

    while (generatedQuests.length < 5 && remainingPool.isNotEmpty) {
      final template = remainingPool.removeAt(0);
      if (!generatedQuests.any((q) => q.title == template['title'])) {
        generatedQuests.add(_createQuestFromTemplate(template));
      }
    }

    return generatedQuests.toSet().toList();
  }

  /// Şablondan, tüm alanları doldurulmuş, hatasız bir Quest nesnesi oluşturur.
  Quest _createQuestFromTemplate(Map<String, dynamic> template, {Map<String, String>? variables}) {
    // --- KALICI ÇÖZÜM: Null değerlere karşı zırh eklendi. ---
    // Bu, 'title', 'description' gibi alanlar şablonda eksik olsa bile uygulamanın çökmesini engeller.
    String title = template['title'] ?? 'İsimsiz Görev';
    String description = template['description'] ?? 'Açıklama bulunamadı.';
    String actionRoute = template['actionRoute'] ?? '/home';
    // --- BİTTİ ---

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
      type: QuestType.values.byName(template['type'] ?? 'daily'),
      category: QuestCategory.values.byName(template['category'] ?? 'engagement'),
      progressType: QuestProgressType.values.byName(template['progressType'] ?? 'increment'),
      reward: template['reward'] ?? 10,
      goalValue: template['goalValue'] ?? 1,
      actionRoute: actionRoute, // Güvenli değişken kullanılıyor.
    );
  }

  List<ExamSection> _getRelevantSectionsForUser(UserModel user, Exam exam) {
    if (user.selectedExam == ExamType.lgs.name) {
      return exam.sections;
    } else if (user.selectedExam == ExamType.yks.name) {
      final tytSection = exam.sections.firstWhere((s) => s.name == 'TYT');
      final userAytSection = exam.sections.firstWhere(
            (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      if (tytSection.name == userAytSection.name) return [tytSection];
      return [tytSection, userAytSection];
    } else {
      final relevantSection = exam.sections.firstWhere(
            (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      return [relevantSection];
    }
  }
}

final dailyQuestsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return [];
  }
  final questService = ref.read(questServiceProvider);
  return await questService.refreshDailyQuestsForUser(user);
});
