// lib/data/models/topic_performance_model.dart

class TopicPerformanceModel {
  final String subject;
  final String topic;
  final int questionCount;
  final int correctCount;
  final int wrongCount;
  final int blankCount;

  TopicPerformanceModel({
    required this.subject,
    required this.topic,
    this.questionCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.blankCount = 0,
  });

  factory TopicPerformanceModel.fromMap(Map<String, dynamic> map) {
    return TopicPerformanceModel(
      subject: map['subject'] ?? '',
      topic: map['topic'] ?? '',
      questionCount: map['questionCount'] ?? 0,
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
      blankCount: map['blankCount'] ?? 0,
    );
  }

  // YENİ EKLENEN KOD: Bu metot, nesnenin JSON'a çevrilmesini sağlar.
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'topic': topic,
      'questionCount': questionCount,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'blankCount': blankCount,
    };
  }

  TopicPerformanceModel copyWith({
    String? subject,
    String? topic,
    int? questionCount,
    int? correctCount,
    int? wrongCount,
    int? blankCount,
  }) {
    return TopicPerformanceModel(
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      questionCount: questionCount ?? this.questionCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      blankCount: blankCount ?? this.blankCount,
    );
  }
}