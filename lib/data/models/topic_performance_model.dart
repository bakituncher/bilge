// lib/data/models/topic_performance_model.dart

class TopicPerformanceModel {
  final int questionCount;
  final int correctCount;
  final int wrongCount;

  TopicPerformanceModel({
    this.questionCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  // Firestore'dan okumak için
  factory TopicPerformanceModel.fromMap(Map<String, dynamic> map) {
    return TopicPerformanceModel(
      questionCount: map['questionCount'] ?? 0,
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
    );
  }

  // Firestore'a yazmak için
  Map<String, dynamic> toMap() {
    return {
      'questionCount': questionCount,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
    };
  }

  // Veri birleştirme için
  TopicPerformanceModelcopyWith({
    int? questionCount,
    int? correctCount,
    int? wrongCount,
  }) {
    return TopicPerformanceModel(
      questionCount: questionCount ?? this.questionCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
    );
  }
}