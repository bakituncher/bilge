// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? goal;
  final List<String>? challenges;
  final double? weeklyStudyGoal;
  final bool onboardingCompleted;
  final bool tutorialCompleted; // YENİ EKLENDİ
  final int streak;
  final DateTime? lastStreakUpdate;
  final String? selectedExam;
  final String? selectedExamSection;
  final String? selectedExamType; // YENİ EKLENDİ
  final int testCount;
  final double totalNetSum;
  final int engagementScore;
  final Map<String, Map<String, TopicPerformanceModel>> topicPerformances;
  final Map<String, List<String>> completedDailyTasks;
  final List<String> completedTasks; // YENİ EKLENDİ
  final String? studyPacing;
  final String? longTermStrategy;
  final Map<String, dynamic>? weeklyPlan;
  final Map<String, List<String>> weeklyAvailability;
  final Map<String, dynamic>? availability; // YENİ EKLENDİ
  final List<String> masteredTopics;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.goal,
    this.challenges,
    this.weeklyStudyGoal,
    this.onboardingCompleted = false,
    this.tutorialCompleted = false, // YENİ EKLENDİ
    this.streak = 0,
    this.lastStreakUpdate,
    this.selectedExam,
    this.selectedExamSection,
    this.selectedExamType, // YENİ EKLENDİ
    this.testCount = 0,
    this.totalNetSum = 0.0,
    this.engagementScore = 0,
    this.topicPerformances = const {},
    this.completedDailyTasks = const {},
    this.completedTasks = const [], // YENİ EKLENDİ
    this.studyPacing,
    this.longTermStrategy,
    this.weeklyPlan,
    this.weeklyAvailability = const {},
    this.availability, // YENİ EKLENDİ
    this.masteredTopics = const [],
  });

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final Map<String, Map<String, TopicPerformanceModel>> safeTopicPerformances = {};
    if (data['topicPerformances'] is Map<String, dynamic>) {
      final subjectMap = data['topicPerformances'] as Map<String, dynamic>;
      subjectMap.forEach((subjectKey, topicMap) {
        if (topicMap is Map<String, dynamic>) {
          final newTopicMap = <String, TopicPerformanceModel>{};
          topicMap.forEach((topicKey, performanceData) {
            if (performanceData is Map<String, dynamic>) {
              newTopicMap[topicKey] = TopicPerformanceModel.fromMap(performanceData);
            }
          });
          safeTopicPerformances[subjectKey] = newTopicMap;
        }
      });
    }

    final Map<String, List<String>> safeCompletedTasks = {};
    if (data['completedDailyTasks'] is Map<String, dynamic>) {
      final taskMap = data['completedDailyTasks'] as Map<String, dynamic>;
      taskMap.forEach((dateKey, taskList) {
        if (taskList is List) {
          safeCompletedTasks[dateKey] = taskList.cast<String>();
        }
      });
    }

    return UserModel(
      id: doc.id,
      email: data['email'],
      name: data['name'],
      goal: data['goal'],
      challenges: List<String>.from(data['challenges'] ?? []),
      weeklyStudyGoal: (data['weeklyStudyGoal'] as num?)?.toDouble(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      tutorialCompleted: data['tutorialCompleted'] ?? false, // YENİ EKLENDİ
      streak: data['streak'] ?? 0,
      lastStreakUpdate: (data['lastStreakUpdate'] as Timestamp?)?.toDate(),
      selectedExam: data['selectedExam'],
      selectedExamSection: data['selectedExamSection'],
      selectedExamType: data['selectedExamType'], // YENİ EKLENDİ
      testCount: data['testCount'] ?? 0,
      totalNetSum: (data['totalNetSum'] as num?)?.toDouble() ?? 0.0,
      engagementScore: data['engagementScore'] ?? 0,
      topicPerformances: safeTopicPerformances,
      completedDailyTasks: safeCompletedTasks,
      completedTasks: List<String>.from(data['completedTasks'] ?? []), // YENİ EKLENDİ
      studyPacing: data['studyPacing'],
      longTermStrategy: data['longTermStrategy'],
      weeklyPlan: data['weeklyPlan'] as Map<String, dynamic>?,
      weeklyAvailability: Map<String, List<String>>.from(
        (data['weeklyAvailability'] ?? {}).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      availability: data['availability'] as Map<String, dynamic>?, // YENİ EKLENDİ
      masteredTopics: List<String>.from(data['masteredTopics'] ?? []),
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
      'tutorialCompleted': tutorialCompleted, // YENİ EKLENDİ
      'streak': streak,
      'lastStreakUpdate': lastStreakUpdate != null ? Timestamp.fromDate(lastStreakUpdate!) : null,
      'selectedExam': selectedExam,
      'selectedExamSection': selectedExamSection,
      'selectedExamType': selectedExamType, // YENİ EKLENDİ
      'testCount': testCount,
      'totalNetSum': totalNetSum,
      'engagementScore': engagementScore,
      'topicPerformances': topicPerformances.map(
            (subjectKey, topicMap) => MapEntry(
          subjectKey,
          topicMap.map((topicKey, model) => MapEntry(topicKey, model.toMap())),
        ),
      ),
      'completedDailyTasks': completedDailyTasks,
      'completedTasks': completedTasks, // YENİ EKLENDİ
      'studyPacing': studyPacing,
      'longTermStrategy': longTermStrategy,
      'weeklyPlan': weeklyPlan,
      'weeklyAvailability': weeklyAvailability,
      'availability': availability, // YENİ EKLENDİ
      'masteredTopics': masteredTopics,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? goal,
    List<String>? challenges,
    double? weeklyStudyGoal,
    bool? onboardingCompleted,
    bool? tutorialCompleted,
    int? streak,
    DateTime? lastStreakUpdate,
    String? selectedExam,
    String? selectedExamSection,
    String? selectedExamType,
    int? testCount,
    double? totalNetSum,
    int? engagementScore,
    Map<String, Map<String, TopicPerformanceModel>>? topicPerformances,
    Map<String, List<String>>? completedDailyTasks,
    List<String>? completedTasks,
    String? studyPacing,
    String? longTermStrategy,
    Map<String, dynamic>? weeklyPlan,
    Map<String, List<String>>? weeklyAvailability,
    Map<String, dynamic>? availability,
    List<String>? masteredTopics,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      challenges: challenges ?? this.challenges,
      weeklyStudyGoal: weeklyStudyGoal ?? this.weeklyStudyGoal,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      streak: streak ?? this.streak,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
      selectedExam: selectedExam ?? this.selectedExam,
      selectedExamSection: selectedExamSection ?? this.selectedExamSection,
      selectedExamType: selectedExamType ?? this.selectedExamType,
      testCount: testCount ?? this.testCount,
      totalNetSum: totalNetSum ?? this.totalNetSum,
      engagementScore: engagementScore ?? this.engagementScore,
      topicPerformances: topicPerformances ?? this.topicPerformances,
      completedDailyTasks: completedDailyTasks ?? this.completedDailyTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      studyPacing: studyPacing ?? this.studyPacing,
      longTermStrategy: longTermStrategy ?? this.longTermStrategy,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      weeklyAvailability: weeklyAvailability ?? this.weeklyAvailability,
      availability: availability ?? this.availability,
      masteredTopics: masteredTopics ?? this.masteredTopics,
    );
  }
}