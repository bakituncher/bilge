// lib/data/models/test_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilge_ai/data/models/exam_model.dart';

class TestModel {
  final String id;
  final String userId;
  final String testName;
  final ExamType examType;
  final String sectionName;
  final DateTime date;
  final Map<String, Map<String, int>> scores;
  final double totalNet;
  final int totalQuestions;
  final int totalCorrect;
  final int totalWrong;
  final int totalBlank;
  final double penaltyCoefficient; // EKLENDİ

  TestModel({
    required this.id,
    required this.userId,
    required this.testName,
    required this.examType,
    required this.sectionName,
    required this.date,
    required this.scores,
    required this.totalNet,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalBlank,
    required this.penaltyCoefficient, // EKLENDİ
  });

  factory TestModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final scoresData = (data['scores'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as Map<String, dynamic>).cast<String, int>()),
    );

    return TestModel(
      id: doc.id,
      userId: data['userId'],
      testName: data['testName'],
      examType: ExamType.values.byName(data['examType']),
      sectionName: data['sectionName'],
      date: (data['date'] as Timestamp).toDate(),
      scores: scoresData,
      totalNet: (data['totalNet'] as num).toDouble(),
      totalQuestions: data['totalQuestions'],
      totalCorrect: data['totalCorrect'],
      totalWrong: data['totalWrong'],
      totalBlank: data['totalBlank'],
      // GÜNCELLENDİ: Firestore'dan okuma
      penaltyCoefficient: (data['penaltyCoefficient'] as num?)?.toDouble() ?? 0.25,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'testName': testName,
      'examType': examType.name,
      'sectionName': sectionName,
      'date': Timestamp.fromDate(date),
      'scores': scores,
      'totalNet': totalNet,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'totalBlank': totalBlank,
      'penaltyCoefficient': penaltyCoefficient, // EKLENDİ
    };
  }
}