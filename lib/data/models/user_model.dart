// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // YENİ: Kullanıcının tamamladığı konuları saklamak için.
  // Map<"Ders Adı", List<"Konu Adı">> formatında olacak.
  final Map<String, List<String>> completedTopics;

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
    this.completedTopics = const {}, // Varsayılan değer boş bir harita.
  });

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final topicsData = data['completedTopics'] as Map<String, dynamic>? ?? {};
    final completedTopics = topicsData.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
    );

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
      completedTopics: completedTopics,
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
      'lastStreakUpdate': lastStreakUpdate,
      'selectedExam': selectedExam,
      'selectedExamSection': selectedExamSection,
      'testCount': testCount,
      'totalNetSum': totalNetSum,
      'completedTopics': completedTopics,
    };
  }
}