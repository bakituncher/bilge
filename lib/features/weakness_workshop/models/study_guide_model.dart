// lib/features/weakness_workshop/models/study_guide_model.dart
import 'package:bilge_ai/core/utils/json_text_cleaner.dart';

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
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // BİLGEAI UYARI: Gelecekteki ben veya başka bir geliştirici için not:
    // Bu fonksiyon, yapay zekanın döndürebileceği beklenmedik metin formatlarını
    // temizlemek için kritik öneme sahiptir. Zırh merkezileştirildi: JsonTextCleaner kullanılmalıdır.

    List<String> parsedOptions = [];

    // --- NİHAİ ÇÖZÜM: ÇİFT KATMANLI SAVUNMA MEKANİZMASI ---
    // 1. ÖNCELİK: Yeni ve güvenli "optionA, optionB..." formatını dene.
    if (json.containsKey('optionA')) {
      parsedOptions = [
        JsonTextCleaner.cleanDynamic(json['optionA'] ?? ''),
        JsonTextCleaner.cleanDynamic(json['optionB'] ?? ''),
        JsonTextCleaner.cleanDynamic(json['optionC'] ?? ''),
        JsonTextCleaner.cleanDynamic(json['optionD'] ?? ''),
      ];
    }
    // 2. YEDEK PLAN: Eğer yeni format yoksa, eski "options" listesi formatını
    // zırhlı temizleyici ile işlemeyi dene.
    else if (json['options'] is List) {
      parsedOptions = (json['options'] as List)
          .map((option) => JsonTextCleaner.cleanDynamic(option))
          .toList();
    }

    // 3. GÜVENLİK AĞI: Eğer herhangi bir seçenek temizlendikten sonra boş kalırsa,
    // görünmez olmasını engellemek için varsayılan bir metin ata.
    for (int i = 0; i < parsedOptions.length; i++) {
      if (parsedOptions[i].isEmpty) {
        parsedOptions[i] = "Seçenek ${String.fromCharCode(65 + i)}"; // A, B, C, D
      }
    }
    // Eğer hiç seçenek oluşmadıysa, 4 tane varsayılan seçenek oluştur.
    if (parsedOptions.isEmpty) {
      parsedOptions = ["Seçenek A", "Seçenek B", "Seçenek C", "Seçenek D"];
    }
    // --- BİTTİ ---

    return QuizQuestion(
      question: JsonTextCleaner.cleanDynamic(json['question'] ?? 'Soru yüklenemedi.'),
      options: parsedOptions,
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: JsonTextCleaner.cleanDynamic(json['explanation'] ?? 'Bu soru için açıklama bulunamadı.'),
    );
  }
}
