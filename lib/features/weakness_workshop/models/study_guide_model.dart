// lib/features/weakness_workshop/models/study_guide_model.dart

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
    // (fazladan tırnak işaretleri, markdown karakterleri, iç içe listeler vb.)
    // temizlemek için kritik öneme sahiptir. Bu fonksiyonun kaldırılması,
    // Cevher Atölyesi'nde öngörülemeyen ve tespiti zor çökme hatalarına
    // neden olabilir. Bu bir zırhtır, kaldırma!
    String cleanText(dynamic rawText) {
      // Önce veriyi en iç katmanına kadar soy
      var current = rawText;
      while (current is List && current.isNotEmpty) {
        current = current.first;
      }
      String cleaned = current.toString().trim();

      // Sonra tırnakları ve parantezleri temizle
      bool changed = true;
      while (changed) {
        changed = false;
        if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
          cleaned = cleaned.substring(1, cleaned.length - 1).trim();
          changed = true;
        }
        if ((cleaned.startsWith("'") && cleaned.endsWith("'")) ||
            (cleaned.startsWith('"') && cleaned.endsWith('"'))) {
          cleaned = cleaned.substring(1, cleaned.length - 1).trim();
          changed = true;
        }
      }
      // Markdown ve kaçış karakterlerini son olarak temizle.
      return cleaned.replaceAll(RegExp(r'[\\*_]'), '').trim();
    }

    List<String> parsedOptions = [];

    // --- NİHAİ ÇÖZÜM: ÇİFT KATMANLI SAVUNMA MEKANİZMASI ---
    // 1. ÖNCELİK: Yeni ve güvenli "optionA, optionB..." formatını dene.
    if (json.containsKey('optionA')) {
      parsedOptions = [
        cleanText(json['optionA'] ?? ''),
        cleanText(json['optionB'] ?? ''),
        cleanText(json['optionC'] ?? ''),
        cleanText(json['optionD'] ?? ''),
      ];
    }
    // 2. YEDEK PLAN: Eğer yeni format yoksa, eski "options" listesi formatını
    // zırhlı temizleyici ile işlemeyi dene.
    else if (json['options'] is List) {
      parsedOptions = (json['options'] as List)
          .map((option) => cleanText(option))
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
      question: cleanText(json['question'] ?? 'Soru yüklenemedi.'),
      options: parsedOptions,
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: cleanText(json['explanation'] ?? 'Bu soru için açıklama bulunamadı.'),
    );
  }
}
