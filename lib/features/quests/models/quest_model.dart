// lib/features/quests/models/quest_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestCategory {
  study,
  practice,
  engagement,
  consistency
}

// YENİ EKLENDİ: Görevin ilerlemesinin nasıl takip edileceğini belirler.
enum QuestProgressType {
  increment, // Her eylemde sayacı 1 artırır (örn: 1 pomodoro yap)
  userStreak // İlerlemeyi doğrudan kullanıcının serisine eşitler
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestProgressType progressType; // YENİ ALAN
  final int reward;
  final int goalValue;
  final int currentProgress;
  final bool isCompleted;
  final Timestamp expiryDate;
  final String actionRoute;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.progressType, // YENİ ALAN
    required this.reward,
    required this.goalValue,
    required this.currentProgress,
    required this.isCompleted,
    required this.expiryDate,
    required this.actionRoute,
  });

  factory Quest.fromMap(Map<String, dynamic> map, String id) {
    return Quest(
      id: id,
      title: map['title'] ?? 'İsimsiz Görev',
      description: map['description'] ?? 'Açıklama yok.',
      category: QuestCategory.values.byName(map['category'] ?? 'engagement'),
      // YENİ: Veritabanından progressType okunuyor
      progressType: QuestProgressType.values.byName(map['progressType'] ?? 'increment'),
      reward: map['reward'] ?? 10,
      goalValue: map['goalValue'] ?? 1,
      currentProgress: map['currentProgress'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      expiryDate: map['expiryDate'] ?? Timestamp.now(),
      actionRoute: map['actionRoute'] ?? '/home',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'progressType': progressType.name, // YENİ ALAN
      'reward': reward,
      'goalValue': goalValue,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'expiryDate': expiryDate,
      'actionRoute': actionRoute,
    };
  }

  Quest copyWith({
    int? currentProgress,
    bool? isCompleted,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      category: category,
      progressType: progressType, // YENİ ALAN
      reward: reward,
      goalValue: goalValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      expiryDate: expiryDate,
      actionRoute: actionRoute,
    );
  }
}