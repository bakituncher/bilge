// lib/data/models/journal_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // HATA İÇİN EKLENDİ

enum JournalCategory {
  motivation,
  achievement,
  note,
}

extension JournalCategoryExtension on JournalCategory {
  String get displayName {
    switch (this) {
      case JournalCategory.motivation:
        return 'Motivasyon';
      case JournalCategory.achievement:
        return 'Başarım';
      case JournalCategory.note:
        return 'Notum';
    }
  }

  IconData get icon {
    switch (this) {
      case JournalCategory.motivation:
        return Icons.lightbulb_outline;
      case JournalCategory.achievement:
        return Icons.emoji_events_outlined;
      case JournalCategory.note:
        return Icons.edit_note_outlined;
    }
  }
}


class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final JournalCategory category;
  final DateTime date;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
  });

  factory JournalEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JournalEntry(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      content: data['content'],
      category: JournalCategory.values.byName(data['category']),
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'category': category.name,
      'date': Timestamp.fromDate(date),
    };
  }
}