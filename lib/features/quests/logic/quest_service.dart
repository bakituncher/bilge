// lib/features/quests/logic/quest_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/quests/quest_armory.dart'; // YENİ CEPHANELİK
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:uuid/uuid.dart';
import 'package:bilge_ai/data/models/exam_model.dart';

final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService(ref);
});

// "Strateji Masası" - Görev Atama Motoru
class QuestService {
  final Ref _ref;
  QuestService(this._ref);

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

    // "Strateji Masası"nı çalıştır ve yeni görevleri üret.
    final newQuests = await _generateQuestsForUser(user);

    await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
      'activeDailyQuests': newQuests.map((q) => q.toMap()).toList(),
      'lastQuestRefreshDate': Timestamp.now(),
    });

    return newQuests;
  }

  // === MİLYON DOLARLIK OTOMASYONUN KALBİ: GÖREV ÜRETİM MOTORU ===
  Future<List<Quest>> _generateQuestsForUser(UserModel user) async {
    final List<Quest> generatedQuests = [];
    final random = Random();

    // 1. VERİ TOPLAMA: Savaş alanının tam bir resmini çek.
    final tests = await _ref.read(testsProvider.future);
    final examData = user.selectedExam != null
        ? await ExamData.getExamByType(ExamType.values.byName(user.selectedExam!))
        : null;

    StatsAnalysis? analysis;
    if (tests.isNotEmpty && examData != null) {
      analysis = StatsAnalysis(tests, user.topicPerformances, examData, user: user);
    }

    // 2. FİLTRELEME: Cephanelikteki tüm görevleri masaya yatır ve uygun olmayanları ele.
    List<Map<String, dynamic>> availableQuestTemplates = List.from(questArmory);
    availableQuestTemplates.shuffle();

    // Zaten aktif olan veya bu oturumda tamamlanan görevleri tekrar atama.
    availableQuestTemplates.removeWhere((template) => user.activeDailyQuests.any((q) => q.id == template['id']));

    // 3. PUANLAMA VE ÖNCELİKLENDİRME: Her bir göreve, kullanıcının durumuna göre stratejik bir puan ver.
    final List<({Map<String, dynamic> template, int score, Map<String, String> variables})> scoredQuests = [];

    for (var template in availableQuestTemplates) {
      int score = 100; // Temel puan
      Map<String, String> variables = {};

      // Tetikleme koşullarını kontrol et
      if (template['triggerConditions'] is Map) {
        final conditions = template['triggerConditions'] as Map<String, dynamic>;

        // Zayıf ders koşulu
        if (conditions['hasWeakSubject'] == true) {
          if (analysis?.weakestSubjectByNet != null && analysis!.weakestSubjectByNet != "Belirlenemedi") {
            score += 250; // En yüksek öncelik!
            variables['{subject}'] = analysis.weakestSubjectByNet;
          } else {
            score = 0; // Atanamaz
          }
        }

        // Güçlü ders koşulu
        if (conditions['hasStrongSubject'] == true) {
          if (analysis?.strongestSubjectByNet != null && analysis!.strongestSubjectByNet != "Belirlenemedi") {
            score += 100;
            variables['{subject}'] = analysis.strongestSubjectByNet;
          } else {
            score = 0; // Atanamaz
          }
        }

        // Son zamanlarda test eklememe koşulu
        if (conditions['noRecentTest'] == true) {
          final lastTestDate = tests.isNotEmpty ? tests.first.date : null;
          if (lastTestDate == null || DateTime.now().difference(lastTestDate).inDays > 3) {
            score += 200; // Yüksek öncelik
          } else {
            score = 0; // Son 3 günde test eklediyse bu görevi atama
          }
        }
      }

      if(score > 0) {
        scoredQuests.add((template: template, score: score, variables: variables));
      }
    }

    // Görevleri puanlarına göre büyükten küçüğe sırala
    scoredQuests.sort((a, b) => b.score.compareTo(a.score));

    // 4. STRATEJİK SEÇİM: En yüksek puanlı ve en çeşitli görevleri seç.
    final Set<QuestCategory> selectedCategories = {};

    while(generatedQuests.length < 5 && scoredQuests.isNotEmpty) {
      final candidate = scoredQuests.removeAt(0);

      // Aynı kategoriden çok fazla görev atamamak için kontrol
      if(selectedCategories.contains(QuestCategory.values.byName(candidate.template['category']))) {
        if(random.nextDouble() > 0.6) continue; // %60 ihtimalle atla
      }

      generatedQuests.add(_createQuestFromTemplate(candidate.template, variables: candidate.variables));
      selectedCategories.add(QuestCategory.values.byName(candidate.template['category']));
    }

    return generatedQuests;
  }

  Quest _createQuestFromTemplate(Map<String, dynamic> template, {Map<String, String>? variables}) {
    String title = template['title'] ?? 'İsimsiz Görev';
    String description = template['description'] ?? 'Açıklama bulunamadı.';
    String actionRoute = template['actionRoute'] ?? '/home';

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
      actionRoute: actionRoute,
    );
  }

  // ... (ExamSection helper fonksiyonu burada kalabilir)
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