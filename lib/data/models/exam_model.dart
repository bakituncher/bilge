// lib/data/models/exam_model.dart

// Sınav türlerini tanımlayan enum
enum ExamType { yks, lgs, kpss }

extension ExamTypeExtension on ExamType {
  String get displayName {
    switch (this) {
      case ExamType.yks:
        return 'YKS';
      case ExamType.lgs:
        return 'LGS';
      case ExamType.kpss:
        return 'KPSS';
    }
  }
}

// Bir sınavın bölümünü (örn: TYT, Sayısal Bölüm) temsil eder
class ExamSection {
  final String name;
  final Map<String, int> subjects; // Ders Adı -> Soru Sayısı
  // 4 yanlış 1 doğruyu götürür gibi kurallar için katsayı
  final double penaltyCoefficient;

  ExamSection({
    required this.name,
    required this.subjects,
    this.penaltyCoefficient = 0.25, // Varsayılan 4 yanlış 1 doğru
  });
}

// Ana sınav yapısını temsil eder (örn: YKS)
class Exam {
  final ExamType type;
  final String name;
  final List<ExamSection> sections; // Sınavın bölümleri (TYT, AYT vb.)

  Exam({
    required this.type,
    required this.name,
    required this.sections,
  });
}

// Sınav verilerinin merkezi
class ExamData {
  static final List<Exam> exams = [
    // YKS Tanımı
    Exam(
      type: ExamType.yks,
      name: 'Yükseköğretim Kurumları Sınavı',
      sections: [
        ExamSection(name: 'TYT', subjects: {
          'Türkçe': 40,
          'Sosyal Bilimler': 20,
          'Temel Matematik': 40,
          'Fen Bilimleri': 20,
        }),
        ExamSection(name: 'AYT - Sayısal', subjects: {
          'Matematik': 40,
          'Fizik': 14,
          'Kimya': 13,
          'Biyoloji': 13,
        }),
        ExamSection(name: 'AYT - Eşit Ağırlık', subjects: {
          'Matematik': 40,
          'Türk Dili ve Edebiyatı': 24,
          'Tarih-1': 10,
          'Coğrafya-1': 6,
        }),
        ExamSection(name: 'AYT - Sözel', subjects: {
          'Türk Dili ve Edebiyatı': 24,
          'Tarih-1': 10,
          'Coğrafya-1': 6,
          'Tarih-2': 11,
          'Coğrafya-2': 11,
          'Felsefe Grubu': 12,
          'Din Kültürü': 6,
        }),
      ],
    ),
    // LGS Tanımı
    Exam(
      type: ExamType.lgs,
      name: 'Liselere Geçiş Sistemi',
      sections: [
        ExamSection(name: 'Sözel Bölüm', subjects: {
          'Türkçe': 20,
          'T.C. İnkılap Tarihi': 10,
          'Din Kültürü': 10,
          'Yabancı Dil': 10,
        }, penaltyCoefficient: 1/3),
        ExamSection(name: 'Sayısal Bölüm', subjects: {
          'Matematik': 20,
          'Fen Bilimleri': 20,
        }, penaltyCoefficient: 1/3),
      ],
    ),
    // KPSS Tanımı
    Exam(
      type: ExamType.kpss,
      name: 'Kamu Personeli Seçme Sınavı',
      sections: [
        ExamSection(name: 'Genel Yetenek', subjects: {
          'Türkçe': 30,
          'Matematik': 30,
        }),
        ExamSection(name: 'Genel Kültür', subjects: {
          'Tarih': 27,
          'Coğrafya': 18,
          'Vatandaşlık': 9,
          'Güncel Bilgiler': 6,
        }),
      ],
    ),
  ];

  static Exam getExamByType(ExamType type) {
    return exams.firstWhere((exam) => exam.type == type);
  }
}