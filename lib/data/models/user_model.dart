// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? goal;
  final List<String>? challenges;
  final double? dailyStudyGoal;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.email,
    this.goal,
    this.challenges,
    this.dailyStudyGoal,
    this.onboardingCompleted = false,
  });

  // Firestore'dan veri okurken Map'i objeye çevirir.
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'],
      goal: data['goal'],
      challenges: List<String>.from(data['challenges'] ?? []),
      dailyStudyGoal: (data['dailyStudyGoal'] as num?)?.toDouble(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }

  // Firestore'a veri yazarken objeyi Map'e çevirir.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'goal': goal,
      'challenges': challenges,
      'dailyStudyGoal': dailyStudyGoal,
      'onboardingCompleted': onboardingCompleted,
    };
  }
}