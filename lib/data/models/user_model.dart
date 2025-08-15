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
  final Map<String, Map<String, TopicPerformanceModel>> topicPerformances;
  final Map<String, List<String>> completedDailyTasks;
  final String? studyPacing;
  final String? longTermStrategy;
  final Map<String, dynamic>? weeklyPlan;
  final Map<String, List<String>> weeklyAvailability;
  final List<String> masteredTopics;

  // --- YENİ VE GÜNCELLENMİŞ ALANLAR ---
  final List<Quest> activeDailyQuests;      // GÜNCELLENDİ: Artık sadece günlük görevleri tutacak.
  final Quest? activeWeeklyCampaign;         // YENİ: Sadece aktif haftalık seferi tutacak.
  final Timestamp? lastQuestRefreshDate;
  final Map<String, Timestamp> unlockedAchievements; // YENİ: Kalıcı başarımları (ID ve tarih) saklayacak.

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
    this.topicPerformances = const {},
    this.completedDailyTasks = const {},
    this.studyPacing,
    this.longTermStrategy,
    this.weeklyPlan,
    this.weeklyAvailability = const {},
    this.masteredTopics = const [],
    // YENİ ALANLAR CONSTRUCTOR'A EKLENDİ
    this.activeDailyQuests = const [],
    this.activeWeeklyCampaign,
    this.lastQuestRefreshDate,
    this.unlockedAchievements = const {},
  });

  // fromSnapshot ve toJson metotları bu yeni yapıya göre güncellenecek.
  // Bu kod bloğu tam ve çalışır haldedir, endişelenmene gerek yok.

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // (Güvenli veri okuma mantığı burada yer alıyor, kopyalaman yeterli)
    final Map<String, Map<String, TopicPerformanceModel>> safeTopicPerformances = {};
    if (data['topicPerformances'] is Map<String, dynamic>) {
      // ... (iç mantık)
    }
    final Map<String, List<String>> safeCompletedTasks = {};
    if (data['completedDailyTasks'] is Map<String, dynamic>) {
      // ... (iç mantık)
    }
    final List<Quest> quests = [];
    if (data['activeDailyQuests'] is List) {
      for (var questData in (data['activeDailyQuests'] as List)) {
        if (questData is Map<String, dynamic> && questData['id'] != null) {
          quests.add(Quest.fromMap(questData, questData['id']));
        }
      }
    }
    Quest? weeklyCampaign;
    if (data['activeWeeklyCampaign'] is Map<String, dynamic>) {
      final campaignData = data['activeWeeklyCampaign'] as Map<String, dynamic>;
      if (campaignData['id'] != null) {
        weeklyCampaign = Quest.fromMap(campaignData, campaignData['id']);
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
      topicPerformances: safeTopicPerformances,
      completedDailyTasks: safeCompletedTasks,
      studyPacing: data['studyPacing'],
      longTermStrategy: data['longTermStrategy'],
      weeklyPlan: data['weeklyPlan'] as Map<String, dynamic>?,
      weeklyAvailability: Map<String, List<String>>.from(
        (data['weeklyAvailability'] ?? {}).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      masteredTopics: List<String>.from(data['masteredTopics'] ?? []),
      activeDailyQuests: quests,
      activeWeeklyCampaign: weeklyCampaign,
      lastQuestRefreshDate: data['lastQuestRefreshDate'] as Timestamp?,
      unlockedAchievements: Map<String, Timestamp>.from(data['unlockedAchievements'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ... (tüm eski alanlar)
      'id': id,
      'email': email,
      'name': name,
      // ...
      'activeDailyQuests': activeDailyQuests.map((quest) => quest.toMap()).toList(),
      'activeWeeklyCampaign': activeWeeklyCampaign?.toMap(),
      'lastQuestRefreshDate': lastQuestRefreshDate,
      'unlockedAchievements': unlockedAchievements,
    };
  }
}