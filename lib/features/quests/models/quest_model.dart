// lib/features/quests/models/quest_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// HATA GİDERİLDİ: Bu enum, görev ikonlarını belirlemek için kritikti ve geri eklendi.
enum QuestCategory { study, practice, engagement, consistency }

// YENİ: Görevin katmanını belirler (Günlük, Haftalık, Başarım).
enum QuestType { daily, weekly, achievement }

// GÜNCELLENDİ: Görevin ilerlemesinin nasıl hesaplanacağını netleştirir.
enum QuestProgressType {
  increment,    // Her eylemde sayacı artırır (örn: 1 pomodoro yap).
  set_to_value  // İlerlemeyi doğrudan bir değere eşitler (örn: kullanıcının serisine).
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestCategory category; // HATA GİDERİLDİ: Bu alan sisteme geri eklendi.
  final QuestProgressType progressType;
  final int reward;
  final int goalValue;
  final int currentProgress;
  final bool isCompleted;
  final String actionRoute;
  final Timestamp? completionDate;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category, // HATA GİDERİLDİ: Constructor'a eklendi.
    required this.progressType,
    required this.reward,
    required this.goalValue,
    this.currentProgress = 0,
    this.isCompleted = false,
    required this.actionRoute,
    this.completionDate,
  });

  factory Quest.fromMap(Map<String, dynamic> map, String id) {
    return Quest(
      id: id,
      title: map['title'] ?? 'İsimsiz Görev',
      description: map['description'] ?? 'Açıklama yok.',
      type: QuestType.values.byName(map['type'] ?? 'daily'),
      category: QuestCategory.values.byName(map['category'] ?? 'engagement'), // HATA GİDERİLDİ
      progressType: QuestProgressType.values.byName(map['progressType'] ?? 'increment'),
      reward: map['reward'] ?? 10,
      goalValue: map['goalValue'] ?? 1,
      currentProgress: map['currentProgress'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      actionRoute: map['actionRoute'] ?? '/home',
      completionDate: map['completionDate'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category.name, // HATA GİDERİLDİ
      'progressType': progressType.name,
      'reward': reward,
      'goalValue': goalValue,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'actionRoute': actionRoute,
      'completionDate': completionDate,
    };
  }

  Quest copyWith({
    int? currentProgress,
    bool? isCompleted,
    Timestamp? completionDate,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      type: type,
      category: category, // HATA GİDERİLDİ
      progressType: progressType,
      reward: reward,
      goalValue: goalValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      actionRoute: actionRoute,
      completionDate: completionDate ?? this.completionDate,
    );
  }
}