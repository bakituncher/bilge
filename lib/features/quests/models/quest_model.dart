// lib/features/quests/models/quest_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// GÜNCELLENDİ: Yeni kategori eklendi.
enum QuestCategory { study, practice, engagement, consistency, test_submission }

enum QuestType { daily, weekly, achievement }

enum QuestProgressType {
  increment,
  set_to_value
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestCategory category;
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
    required this.category,
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
      category: QuestCategory.values.byName(map['category'] ?? 'engagement'),
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
      'category': category.name,
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
      category: category,
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
