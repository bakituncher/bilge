// lib/data/models/test_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String id;
  final String testName;
  final DateTime date;
  // Ders bazında netleri tutmak için esnek bir yapı
  // Örnek: {'Türkçe': {'dogru': 35, 'yanlis': 5, 'bos': 0}}
  final Map<String, Map<String, int>> scores;
  final double totalNet;

  TestModel({
    required this.id,
    required this.testName,
    required this.date,
    required this.scores,
    required this.totalNet,
  });

  factory TestModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final scoresData = (data['scores'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as Map<String, dynamic>).cast<String, int>()),
    );

    return TestModel(
      id: doc.id,
      testName: data['testName'],
      date: (data['date'] as Timestamp).toDate(),
      scores: scoresData,
      totalNet: (data['totalNet'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'date': Timestamp.fromDate(date),
      'scores': scores,
      'totalNet': totalNet,
    };
  }
}