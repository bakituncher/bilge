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
  final int streak;
  final DateTime? lastStreakUpdate;
  final String? selectedExam;
  final String? selectedExamSection;
  final int testCount;
  final double totalNetSum;
  // BİLGEAI DEVRİMİ: Basit tamamlanmış konu listesi, detaylı performans modeli ile değiştirildi.
  // Yapı: { "Fizik": { "Vektörler": TopicPerformanceModel(...), ... }, ... }
  final Map<String, Map<String, TopicPerformanceModel>> topicPerformances;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.goal,
    this.challenges,
    this.weeklyStudyGoal,
    this.onboardingCompleted = false,
    this.streak = 0,
    this.lastStreakUpdate,
    this.selectedExam,
    this.selectedExamSection,
    this.testCount = 0,
    this.totalNetSum = 0.0,
    this.topicPerformances = const {},
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

    return UserModel(
      id: doc.id,
      email: data['email'],
      name: data['name'],
      goal: data['goal'],
      challenges: List<String>.from(data['challenges'] ?? []),
      weeklyStudyGoal: (data['weeklyStudyGoal'] as num?)?.toDouble(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      streak: data['streak'] ?? 0,
      lastStreakUpdate: (data['lastStreakUpdate'] as Timestamp?)?.toDate(),
      selectedExam: data['selectedExam'],
      selectedExamSection: data['selectedExamSection'],
      testCount: data['testCount'] ?? 0,
      totalNetSum: (data['totalNetSum'] as num?)?.toDouble() ?? 0.0,
      topicPerformances: safeTopicPerformances,
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
      'streak': streak,
      'lastStreakUpdate': lastStreakUpdate != null ? Timestamp.fromDate(lastStreakUpdate!) : null,
      'selectedExam': selectedExam,
      'selectedExamSection': selectedExamSection,
      'testCount': testCount,
      'totalNetSum': totalNetSum,
      // BİLGEAI DEVRİMİ: Yeni model Firestore'a yazılacak şekilde güncellendi.
      'topicPerformances': topicPerformances.map(
            (subjectKey, topicMap) => MapEntry(
          subjectKey,
          topicMap.map((topicKey, model) => MapEntry(topicKey, model.toMap())),
        ),
      ),
    };
  }
}