// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? goal;
  final List<String>? challenges;
  final double? weeklyStudyGoal;
  final bool onboardingCompleted;
  final bool tutorialCompleted;
  final int streak;
  final DateTime? lastStreakUpdate;
  final String? selectedExam;
  final String? selectedExamSection;
  final int testCount;
  final double totalNetSum;
  final int engagementScore;
  // ARTIK KULLANILMIYOR: final Map<String, Map<String, TopicPerformanceModel>> topicPerformances;
  final Map<String, List<String>> completedDailyTasks;
  // ARTIK KULLANILMIYOR: final String? studyPacing;
  // ARTIK KULLANILMIYOR: final String? longTermStrategy;
  // ARTIK KULLANILMIYOR: final Map<String, dynamic>? weeklyPlan;
  final Map<String, List<String>> weeklyAvailability;
  // ARTIK KULLANILMIYOR: final List<String> masteredTopics;
  final List<Quest> activeDailyQuests;
  final Quest? activeWeeklyCampaign;
  final Timestamp? lastQuestRefreshDate;
  final Map<String, Timestamp> unlockedAchievements;
  // YENİ ALAN: Savaşçı Yemini görevi için gün içi ziyaretleri takip eder.
  final List<Timestamp> dailyVisits;
  final String? avatarStyle;
  final String? avatarSeed;
  final String? dailyQuestPlanSignature; // YENİ: bugünkü plan imzası
  final double? lastScheduleCompletionRatio; // YENİ: dünkü program tamamlama oranı
  final Map<String, List<int>> dailyPlanBonuses; // YENİ: tarih -> verilen bonus eşikleri
  final int dailyScheduleStreak; // YENİ: art arda tamamlanan plan görevi sayısı (bugün)
  final Map<String,dynamic>? lastWeeklyReport; // YENİ: geçen hafta raporu
  final double? dynamicDifficultyFactorToday; // YENİ: bugünkü dinamik zorluk çarpanı
  final Timestamp? weeklyPlanCompletedAt; // YENİ: haftalık plan tamamlanma anı
  final int workshopStreak; // YENİ: art arda günlerde Cevher Atölyesi seansı
  final Timestamp? lastWorkshopDate; // YENİ: son Cevher seansı tarihi (UTC gün)
  final Map<String,int> recentPracticeVolumes; // YENİ: son günlere ait practice soru adetleri

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.goal,
    this.challenges,
    this.weeklyStudyGoal,
    this.onboardingCompleted = false,
    this.tutorialCompleted = false,
    this.streak = 0,
    this.lastStreakUpdate,
    this.selectedExam,
    this.selectedExamSection,
    this.testCount = 0,
    this.totalNetSum = 0.0,
    this.engagementScore = 0,
    // this.topicPerformances = const {},
    this.completedDailyTasks = const {},
    // this.studyPacing,
    // this.longTermStrategy,
    // this.weeklyPlan,
    this.weeklyAvailability = const {},
    // this.masteredTopics = const [],
    this.activeDailyQuests = const [],
    this.activeWeeklyCampaign,
    this.lastQuestRefreshDate,
    this.unlockedAchievements = const {},
    this.dailyVisits = const [], // YENİ
    this.avatarStyle, // YENİ
    this.avatarSeed, // YENİ
    this.dailyQuestPlanSignature,
    this.lastScheduleCompletionRatio,
    this.dailyPlanBonuses = const {},
    this.dailyScheduleStreak = 0,
    this.lastWeeklyReport,
    this.dynamicDifficultyFactorToday,
    this.weeklyPlanCompletedAt,
    this.workshopStreak = 0, // yeni
    this.lastWorkshopDate, // yeni
    this.recentPracticeVolumes = const {}, // yeni
  });

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Bu alanlar artık alt koleksiyonlardan okunacak, bu yüzden burada parse etmeye gerek yok.
    // final Map<String, Map<String, TopicPerformanceModel>> safeTopicPerformances = {};

    final Map<String, List<String>> safeCompletedTasks = {};
    if (data['completedDailyTasks'] is Map<String, dynamic>) {
      (data['completedDailyTasks'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          safeCompletedTasks[key] = List<String>.from(value);
        }
      });
    }

    final List<Quest> quests = [];
    if (data['activeDailyQuests'] is List) {
      for (var questData in (data['activeDailyQuests'] as List)) {
        if (questData is Map<String, dynamic>) {
          final dynamic rawId = questData['qid'] ?? questData['id'];
          if (rawId != null) {
            quests.add(Quest.fromMap(questData, rawId.toString()));
          }
        }
      }
    }
    Quest? weeklyCampaign;
    if (data['activeWeeklyCampaign'] is Map<String, dynamic>) {
      final campaignData = data['activeWeeklyCampaign'] as Map<String, dynamic>;
      final dynamic rawId = campaignData['qid'] ?? campaignData['id'];
      if (rawId != null) {
        weeklyCampaign = Quest.fromMap(campaignData, rawId.toString());
      }
    }

    return UserModel(
      id: doc.id,
      email: data['email'],
      name: data['name'],
      goal: data['goal'],
      challenges: List<String>.from(data['challenges'] ?? []),
      weeklyStudyGoal: (data['weeklyStudyGoal'] as num?)?.toDouble(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      tutorialCompleted: data['tutorialCompleted'] ?? false,
      streak: data['streak'] ?? 0,
      lastStreakUpdate: (data['lastStreakUpdate'] as Timestamp?)?.toDate(),
      selectedExam: data['selectedExam'],
      selectedExamSection: data['selectedExamSection'],
      testCount: data['testCount'] ?? 0,
      totalNetSum: (data['totalNetSum'] as num?)?.toDouble() ?? 0.0,
      engagementScore: data['engagementScore'] ?? 0,
      // topicPerformances: safeTopicPerformances,
      completedDailyTasks: safeCompletedTasks,
      // studyPacing: data['studyPacing'],
      // longTermStrategy: data['longTermStrategy'],
      // weeklyPlan: data['weeklyPlan'] as Map<String, dynamic>?,
      weeklyAvailability: Map<String, List<String>>.from(
        (data['weeklyAvailability'] ?? {}).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      // masteredTopics: List<String>.from(data['masteredTopics'] ?? []),
      activeDailyQuests: quests,
      activeWeeklyCampaign: weeklyCampaign,
      lastQuestRefreshDate: data['lastQuestRefreshDate'] as Timestamp?,
      unlockedAchievements: Map<String, Timestamp>.from(data['unlockedAchievements'] ?? {}),
      dailyVisits: List<Timestamp>.from(data['dailyVisits'] ?? []), // YENİ
      avatarStyle: data['avatarStyle'],
      avatarSeed: data['avatarSeed'],
      dailyQuestPlanSignature: data['dailyQuestPlanSignature'],
      lastScheduleCompletionRatio: (data['lastScheduleCompletionRatio'] as num?)?.toDouble(),
      dailyPlanBonuses: Map<String, List<int>>.from(
        (data['dailyPlanBonuses'] ?? {}).map((k, v) => MapEntry(k, List<int>.from(v))),
      ),
      dailyScheduleStreak: data['dailyScheduleStreak'] ?? 0,
      lastWeeklyReport: data['lastWeeklyReport'] as Map<String,dynamic>?,
      dynamicDifficultyFactorToday: (data['dynamicDifficultyFactorToday'] as num?)?.toDouble(),
      weeklyPlanCompletedAt: data['weeklyPlanCompletedAt'] as Timestamp?,
      workshopStreak: data['workshopStreak'] ?? 0, // yeni
      lastWorkshopDate: data['lastWorkshopDate'] as Timestamp?, // yeni
      recentPracticeVolumes: Map<String,int>.from(data['recentPracticeVolumes'] ?? {}), // yeni
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'goal': goal,
      'challenges': challenges,
      'weeklyStudyGoal': weeklyStudyGoal,
      'onboardingCompleted': onboardingCompleted,
      'tutorialCompleted': tutorialCompleted,
      'streak': streak,
      'lastStreakUpdate': lastStreakUpdate != null ? Timestamp.fromDate(lastStreakUpdate!) : null,
      'selectedExam': selectedExam,
      'selectedExamSection': selectedExamSection,
      'testCount': testCount,
      'totalNetSum': totalNetSum,
      'engagementScore': engagementScore,
      // 'topicPerformances': topicPerformances.map((key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v.toMap())))),
      'completedDailyTasks': completedDailyTasks,
      // 'studyPacing': studyPacing,
      // 'longTermStrategy': longTermStrategy,
      // 'weeklyPlan': weeklyPlan,
      'weeklyAvailability': weeklyAvailability,
      // 'masteredTopics': masteredTopics,
      'activeDailyQuests': activeDailyQuests.map((quest) => quest.toMap()).toList(),
      'activeWeeklyCampaign': activeWeeklyCampaign?.toMap(),
      'lastQuestRefreshDate': lastQuestRefreshDate,
      'unlockedAchievements': unlockedAchievements,
      'dailyVisits': dailyVisits, // YENİ
      'avatarStyle': avatarStyle,
      'avatarSeed': avatarSeed,
      'dailyQuestPlanSignature': dailyQuestPlanSignature,
      'lastScheduleCompletionRatio': lastScheduleCompletionRatio,
      'dailyPlanBonuses': dailyPlanBonuses,
      'dailyScheduleStreak': dailyScheduleStreak,
      'lastWeeklyReport': lastWeeklyReport,
      'dynamicDifficultyFactorToday': dynamicDifficultyFactorToday,
      'weeklyPlanCompletedAt': weeklyPlanCompletedAt,
      'workshopStreak': workshopStreak,
      'lastWorkshopDate': lastWorkshopDate,
      'recentPracticeVolumes': recentPracticeVolumes, // yeni
    };
  }
}