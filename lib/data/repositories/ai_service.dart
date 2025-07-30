// lib/data/repositories/ai_service.dart
import 'dart:convert';
import 'package:bilge_ai/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {required this.isUser});
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  AiService();

  final String _apiKey = AppConfig.geminiApiKey;
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent";

  int _getDaysUntilExam(ExamType examType) {
    final now = DateTime.now();
    DateTime examDate;
    switch (examType) {
      case ExamType.lgs:
        examDate = DateTime(now.year, 6, 2);
        break;
      case ExamType.yks:
        examDate = DateTime(now.year, 6, 15);
        break;
      case ExamType.kpss:
        examDate = DateTime(now.year, 7, 14);
        break;
    }
    if (now.isAfter(examDate)) {
      examDate = DateTime(now.year + 1, examDate.month, examDate.day);
    }
    return examDate.difference(now).inDays;
  }

  Future<String> _callGemini(String prompt, {bool expectJson = false}) async {
    if (_apiKey.isEmpty || _apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      final errorJson =
          '{"error": "API Anahtarı bulunamadı. Lütfen `lib/core/config/app_config.dart` dosyasına kendi Gemini API anahtarınızı ekleyin."}';
      return expectJson ? errorJson : "**HATA:** API Anahtarı bulunamadı.";
    }
    try {
      final body = {
        "contents": [{"parts": [{"text": prompt}]}],
        if (expectJson) "generationConfig": {"responseMimeType": "application/json"}
      };
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['candidates'] != null && data['candidates'][0]['content'] != null) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          final errorJson = '{"error": "Yapay zeka servisinden beklenmedik bir formatta cevap alındı."}';
          return expectJson ? errorJson : "**HATA:** Beklenmedik formatta cevap.";
        }
      } else {
        final errorJson = '{"error": "Yapay zeka servisinden bir cevap alınamadı. (Kod: ${response.statusCode})", "details": "${response.body}"}';
        return expectJson ? errorJson : "**HATA:** API Hatası (${response.statusCode})";
      }
    } catch (e) {
      final errorJson = '{"error": "İnternet bağlantınızda bir sorun var gibi görünüyor veya API yanıtı çözümlenemedi."}';
      return expectJson ? errorJson : "**HATA:** Ağ veya Format Hatası.";
    }
  }

  Future<String> generateGrandStrategy({
    required UserModel user,
    required List<TestModel> tests,
    required String pacing,
  }) {
    if (user.selectedExam == null) {
      return Future.value('{"error":"Analiz için önce bir sınav seçmelisiniz."}');
    }
    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests, user.topicPerformances) : null;

    final prompt = """
      Sen, BilgeAI adında, 1000 yıllık bir eğitimcinin bilgeliğine sahip, kişiye özel uzun vadeli başarı stratejileri tasarlayan bir yapay zeka dehasısın.
      Görevin, bir öğrencinin tüm verilerini, hedeflerini ve çalışma temposunu analiz ederek, onu sınav gününde zafere taşıyacak olan **BÜYÜK STRATEJİYİ** ve bu stratejinin ilk **HAFTALIK HAREKAT PLANINI** oluşturmaktır.
      Çıktıyı KESİNLİKLE aşağıdaki JSON formatında, başka hiçbir ek metin olmadan ver.

      JSON FORMATI:
      {
        "longTermStrategy": "# Zafer Stratejisi: Sınava Kalan $daysUntilExam Gün\\n\\n## 1. Evre: Temel İnşası ve Zayıflık Giderme (İlk ${daysUntilExam ~/ 3} Gün)\\n- **Amaç:** ...\\n- **Odak:** ...\\n\\n## 2. Evre: Yoğun Pratik ve Hız Kazanma (Orta ${daysUntilExam ~/ 3} Gün)\\n- **Amaç:** ...\\n- **Odak:** ...\\n\\n## 3. Evre: Deneme Maratonu ve Zihinsel Hazırlık (Son ${daysUntilExam - 2 * (daysUntilExam ~/ 3)} Gün)\\n- **Amaç:** ...\\n- **Odak:** ...",
        "weeklyPlan": {
          "planTitle": "1. Hafta Harekat Planı",
          "strategyFocus": "Bu haftaki ana hedefimiz, Büyük Strateji'nin 1. Evresi'ne uygun olarak en zayıf konuları kapatmak ve temeli sağlamlaştırmak.",
          "plan": [
            {"day": "Pazartesi", "tasks": ["...", "..."]},
            {"day": "Salı", "tasks": ["...", "..."]},
            {"day": "Çarşamba", "tasks": ["...", "..."]},
            {"day": "Perşembe", "tasks": ["...", "..."]},
            {"day": "Cuma", "tasks": ["...", "..."]},
            {"day": "Cumartesi", "tasks": ["...", "..."]},
            {"day": "Pazar", "tasks": ["Haftalık Genel Tekrar ve Hata Analizi"]}
          ]
        }
      }

      ---
      ÖĞRENCİ VERİLERİ
      - Sınav: ${user.selectedExam} (${user.selectedExamSection})
      - Sınava Kalan Süre: $daysUntilExam gün
      - Hedef: ${user.goal}
      - **Seçilen Çalışma Temposu:** $pacing
      - En Zayıf Dersi (Deneme Analizine Göre): ${analysis?.weakestSubjectByNet ?? 'Belirlenemedi'}
      - En Zayıf Konusu (Konu Performansına Göre): ${analysis?.getWeakestTopicWithDetails()?['topic'] ?? 'Belirlenemedi'}
      - Konu Performansları (Özet): ${user.topicPerformances.entries.map((e) => "${e.key}: [${e.value.entries.map((t) => "${t.key} (%${(t.value.questionCount > 0 ? t.value.correctCount / t.value.questionCount : 0) * 100})").join(', ')}]").join(' | ')}
      ---

      KURALLAR:
      1.  **longTermStrategy**: Markdown formatında, sınav gününe kadar olan süreci mantıksal evrelere ayırarak oluştur.
      2.  **weeklyPlan**: Bu plan, Büyük Strateji'nin ilk adımını oluşturmalı. Görevlerin yoğunluğunu ve sayısını, öğrencinin seçtiği **'$pacing'** temposuna göre ayarla. ('Yoğun' tempo günde 3-4 görev, 'Dengeli' 2-3 görev, 'Rahat' 1-2 görev içermelidir).
    """;

    return _callGemini(prompt, expectJson: true);
  }

  Future<String> generateStudyGuideAndQuiz(UserModel user, List<TestModel> tests) async {
    if (tests.isEmpty) {
      return Future.value('{"error":"Analiz için en az bir deneme sonucu gereklidir."}');
    }
    final analysis = PerformanceAnalysis(tests, user.topicPerformances);
    final weakestTopicInfo = analysis.getWeakestTopicWithDetails();

    if (weakestTopicInfo == null) {
      return Future.value('{"error":"Analiz için zayıf bir konu bulunamadı. Lütfen önce konu performans verilerinizi girin."}');
    }

    final weakestSubject = weakestTopicInfo['subject'];
    final weakestTopic = weakestTopicInfo['topic'];

    final prompt = """
      Sen, BilgeAI adında, Türkiye sınav sistemleri konusunda uzman, kişiselleştirilmiş eğitim materyali üreten bir yapay zeka dehasısın.
      Görevin, bir öğrencinin en zayıf olduğu konuyu hem öğretecek hem de pekiştirecek bir "Cevher Paketi" oluşturmaktır.
      
      Öğrencinin en zayıf olduğu ders: **'$weakestSubject'**
      Bu dersteki en zayıf konu: **'$weakestTopic'**

      Bu konu için, aşağıdaki JSON formatına KESİNLİKLE uyarak bir çıktı üret. Başka hiçbir metin ekleme.

      JSON FORMATI:
      {
        "subject": "$weakestSubject",
        "topic": "$weakestTopic",
        "studyGuide": "# $weakestTopic - Cevher Kartı\\n\\n### 🔑 Anahtar Kavramlar\\n- ...\\n- ...\\n\\n### ⚠️ Sık Yapılan Hatalar\\n- ...\\n- ...\\n\\n### ✨ Çözümlü Altın Örnek\\n**Soru:** ...\\n**Çözüm:** ...",
        "quiz": [
          {"question": "...", "options": ["...", "...", "...", "..."], "correctOptionIndex": 1},
          {"question": "...", "options": ["...", "...", "...", "..."], "correctOptionIndex": 3},
          {"question": "...", "options": ["...", "...", "...", "..."], "correctOptionIndex": 0},
          {"question": "...", "options": ["...", "...", "...", "..."], "correctOptionIndex": 2},
          {"question": "...", "options": ["...", "...", "...", "..."], "correctOptionIndex": 1}
        ]
      }
    """;

    return _callGemini(prompt, expectJson: true);
  }

  // BİLGEAI DEVRİMİ - DÜZELTME: Bu metod, devrim sırasında sehven kaldırılmıştı.
  // Motivasyon sohbetinin çalışması için yeniden eklendi.
  Future<String> getMotivationalResponse(List<ChatMessage> history) {
    final prompt = """
      Sen BilgeAI adında, öğrencilerle sohbet eden, onların moralini yükselten, anlayışlı ve bilge bir dostsun.
      Kısa, net ve samimi cevaplar ver. Asla bir yapay zeka olduğunu söyleme.
      
      SOHBET GEÇMİŞİ:
      ${history.map((m) => "${m.isUser ? 'Öğrenci' : 'BilgeAI'}: ${m.text}").join('\n')}
      
      Öğrencinin son mesajına uygun, motive edici ve pozitif bir cevap ver.
      """;
    return _callGemini(prompt, expectJson: false);
  }
}

class PerformanceAnalysis {
  final List<TestModel> tests;
  final Map<String, Map<String, TopicPerformanceModel>> topicPerformances;
  late String weakestSubjectByNet;
  late String strongestSubjectByNet;
  late Map<String, double> subjectAverages;

  PerformanceAnalysis(this.tests, this.topicPerformances) {
    if (tests.isEmpty) {
      _initializeEmpty();
      return;
    }

    final subjectNets = <String, List<double>>{};
    for (var test in tests) {
      test.scores.forEach((subject, scores) {
        final net = (scores['dogru'] ?? 0) - ((scores['yanlis'] ?? 0) * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    if (subjectNets.isEmpty) {
      _initializeEmpty();
      return;
    }

    subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));
    weakestSubjectByNet = subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    strongestSubjectByNet = subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _initializeEmpty() {
    weakestSubjectByNet = "Belirlenemedi";
    strongestSubjectByNet = "Belirlenemedi";
    subjectAverages = {};
  }

  Map<String, String>? getWeakestTopicWithDetails() {
    String? weakestTopic;
    String? weakestSubject;
    double minSuccessRate = 1.1;

    topicPerformances.forEach((subject, topics) {
      topics.forEach((topic, performance) {
        if (performance.questionCount > 5) {
          final successRate = performance.correctCount / performance.questionCount;
          if (successRate < minSuccessRate) {
            minSuccessRate = successRate;
            weakestTopic = topic;
            weakestSubject = subject;
          }
        }
      });
    });

    if (weakestTopic != null && weakestSubject != null) {
      return {'subject': weakestSubject!, 'topic': weakestTopic!};
    }
    return null;
  }
}