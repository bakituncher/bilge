// lib/data/models/study_guide_model.dart

class StudyGuideAndQuiz {
  final String studyGuide; // Markdown formatında
  final List<QuizQuestion> quiz;
  final String topic;
  final String subject;

  StudyGuideAndQuiz({
    required this.studyGuide,
    required this.quiz,
    required this.topic,
    required this.subject,
  });

  factory StudyGuideAndQuiz.fromJson(Map<String, dynamic> json) {
    var quizList = (json['quiz'] as List<dynamic>?)
        ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList() ??
        [];

    return StudyGuideAndQuiz(
      studyGuide: json['studyGuide'] ?? "# Bilgi Alınamadı",
      quiz: quizList,
      topic: json['topic'] ?? "Bilinmeyen Konu",
      subject: json['subject'] ?? "Bilinmeyen Ders",
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation; // YENİ EKLENDİ

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation, // YENİ EKLENDİ
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // HATAYI GİDEREN ZIRHLI VERİ TEMİZLEYİCİ
    String cleanText(String text) {
      // Markdown karakterlerini ve baştaki/sondaki boşlukları temizle
      String cleaned = text.replaceAll(RegExp(r'[\\*_]'), '').trim();

      // Yapay zekanın bazen eklediği ['...'] veya [\"...\"] formatını temizle
      if (cleaned.startsWith("['") && cleaned.endsWith("']")) {
        cleaned = cleaned.substring(2, cleaned.length - 2);
      }
      if (cleaned.startsWith('["') && cleaned.endsWith('"]')) {
        cleaned = cleaned.substring(2, cleaned.length - 2);
      }
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }

      // Kalan tek veya çift tırnakları da temizle
      if ((cleaned.startsWith("'") && cleaned.endsWith("'")) || (cleaned.startsWith('"') && cleaned.endsWith('"'))) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }

      return cleaned.trim();
    }

    return QuizQuestion(
      question: cleanText(json['question'] ?? 'Soru yüklenemedi.'),
      options: (List<dynamic>.from(json['options'] ?? [])).map((option) => cleanText(option.toString())).toList(),
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: json['explanation'] ?? 'Bu soru için açıklama bulunamadı.',
    );
  }
}