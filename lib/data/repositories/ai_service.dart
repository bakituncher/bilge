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
    // BİLGEAI DEVRİMİ: Mevcut tarihe göre sınav tarihlerini dinamik olarak ayarlar.
    // Örnek tarihler kullanılmıştır.
    switch (examType) {
      case ExamType.lgs:
        examDate = DateTime(2026, 6, 6); // Örnek tarih
        break;
      case ExamType.yks:
        examDate = DateTime(2026, 6, 20); // Örnek tarih
        break;
      case ExamType.kpss:
        examDate = DateTime(2026, 7, 19); // Örnek tarih
        break;
    }
    // Eğer mevcut tarih sınav tarihini geçtiyse, bir sonraki yılın sınavını hedefler.
    if (now.isAfter(examDate)) {
      examDate = DateTime(examDate.year + 1, examDate.month, examDate.day);
    }
    return examDate.difference(now).inDays;
  }

  Future<String> _callGemini(String prompt, {bool expectJson = false}) async {
    // ... (Bu metodun içeriği doğru ve değişmedi) ...
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

  Future<String> getCoachingSession(UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) {
      return Future.value('{"error":"Analiz için önce bir sınav seçmelisiniz."}');
    }
    final examType = ExamType.values.byName(user.selectedExam!);
    // BİLGEAI DEVRİMİ - DÜZELTME: Bu değişken artık prompt içinde kullanılıyor.
    final daysUntilExam = _getDaysUntilExam(examType);
    // BİLGEAI DEVRİMİ - DÜZELTME: Bu değişken artık prompt içinde kullanılıyor.
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests, user.topicPerformances) : null;

    String lastFiveTestsString = tests.take(5).map((t) => "- **${t.testName}**: Toplam Net: ${t.totalNet.toStringAsFixed(2)}").join('\n');
    if (lastFiveTestsString.isEmpty) {
      lastFiveTestsString = "Henüz deneme sonucu girilmemiş.";
    }

    // BİLGEAI DEVRİMİ - DÜZELTME: Prompt, değişkenleri kullanacak şekilde eski haline getirildi ve daha da zenginleştirildi.
    final prompt = """
      Sen, BilgeAI adında, Türkiye sınav sistemleri konusunda uzman, veriye dayalı çalışan ve doğrudan konuşan elit bir performans stratejistisin.
      Görevin, öğrencinin verilerini bir bütün olarak analiz edip, zayıflıklarını, potansiyelini ve kişisel engellerini net bir şekilde ortaya koyan, eyleme geçirilebilir bir **ANALİZ RAPORU** ve bu rapora uygun **HAFTALIK EYLEM PLANI** hazırlamaktır.
      Çıktıyı KESİNLİKLE JSON formatında, başka hiçbir ek metin olmadan ver.

      JSON FORMATI:
      {
        "analysisReport": "...",
        "weeklyPlan": {
          "planTitle": "Haftalık Stratejik Plan",
          "strategyFocus": "...",
          "plan": [
            {"day": "Pazartesi", "tasks": ["...", "..."]},
            {"day": "Salı", "tasks": ["...", "..."]},
            {"day": "Çarşamba", "tasks": ["...", "..."]},
            {"day": "Perşembe", "tasks": ["...", "..."]},
            {"day": "Cuma", "tasks": ["...", "..."]},
            {"day": "Cumartesi", "tasks": ["...", "..."]},
            {"day": "Pazar", "tasks": ["Genel Deneme ve Hata Analizi"]}
          ]
        }
      }

      ---
      ÖĞRENCİ VERİLERİ
      - Sınav: ${user.selectedExam} (${user.selectedExamSection})
      - Sınava Kalan Süre: $daysUntilExam gün
      - Hedef: ${user.goal}
      - Belirttiği Zorluklar: ${user.challenges?.join(', ') ?? 'Belirtilmemiş'}
      - En Zayıf Dersi (Deneme Analizine Göre): ${analysis?.weakestSubjectByNet ?? 'Belirlenemedi'}
      - En Zayıf Konusu (Konu Performansına Göre): ${analysis?.getWeakestTopicWithDetails()?['topic'] ?? 'Belirlenemedi'}
      - Konu Performansları (Özet): ${user.topicPerformances.entries.map((e) {
      final subject = e.key;
      final topics = e.value.entries.map((t) {
        final successRate = t.value.questionCount > 0 ? (t.value.correctCount / t.value.questionCount) * 100 : 0;
        return "${t.key} (%${successRate.toStringAsFixed(0)})";
      }).join(', ');
      return "$subject: [$topics]";
    }).join(' | ')}
      - Son 5 Deneme: $lastFiveTestsString
      ---

      ANALİZ RAPORU (analysisReport) İÇİN KURALLAR:
      1.  **Genel Trendi** yorumla. Netleri artıyor mu, azalıyor mu, yerinde mi sayıyor?
      2.  **En Güçlü ve En Zayıf Dersleri** sırala.
      3.  **BİLGİ-PERFORMANS ÇELİŞKİSİ** analizi yap: Öğrencinin konu performans verileri ile deneme sonuçları arasında bir çelişki var mı? Varsa bunu vurgula. Örneğin: "Fizik'te 'Vektörler' konusunda %90 başarı oranına sahip olduğunu belirtmişsin ancak denemelerdeki Fizik netlerin düşük. Bu, sınav anında zaman yönetimi veya stres gibi başka faktörlerin devreye girdiğini gösteriyor olabilir.".
      4.  **ACİL EYLEM PLANI** olarak netleri en hızlı fırlatacak 2-3 spesifik konuyu belirle. Bu konular, özellikle başarı oranı en düşük olanlar olmalı.

      HAFTALIK PLAN (weeklyPlan) İÇİN KURALLAR:
      1.  Planı, yukarıda yaptığın analize ve belirlediğin acil eylem konularına göre oluştur.
      2.  Sınava kalan süreye göre stratejiyi belirle.
      3.  Görevler spesifik olsun ("Fizik çalış" DEĞİL, "Konu Tekrarı: Vektörler + 25 Soru" GİBİ).
    """;

    return _callGemini(prompt, expectJson: true);
  }

  Future<String> generateTargetedQuestions(UserModel user, List<TestModel> tests) {
    if (tests.isEmpty) {
      return Future.value('{"error":"Soru üretmek için en az bir deneme sonucu gereklidir."}');
    }
    final analysis = PerformanceAnalysis(tests, user.topicPerformances);
    final weakestTopicInfo = analysis.getWeakestTopicWithDetails();

    if (weakestTopicInfo == null) {
      return Future.value('{"error":"Analiz için zayıf bir konu bulunamadı. Lütfen önce konu performans verilerinizi girin."}');
    }

    final weakestSubject = weakestTopicInfo['subject'];
    final weakestTopic = weakestTopicInfo['topic'];

    final prompt = """
      Sen, bir öğrencinin en zayıf olduğu konudan, sınav formatına uygun, orijinal ve zorlayıcı bir soru üreten uzman bir soru yazarı yapay zekasın.
      Öğrencinin en zayıf olduğu ders **'$weakestSubject'**. Bu derste özellikle sorun yaşadığı konu ise **'$weakestTopic'**. Bu konudaki başarı oranı oldukça düşük.
      Şimdi bu **'$weakestTopic'** konusundan, öğrencinin bilgisini gerçekten test edecek, 4 şıklı bir çoktan seçmeli soru oluştur.
      Çıktıyı KESİNLİKLE AŞAĞIDAKİ JSON FORMATINDA, başka hiçbir ek metin olmadan, sadece JSON olarak döndür.
      
      JSON FORMATI:
      {
        "question": "...",
        "options": ["...", "...", "...", "..."],
        "correctOptionIndex": 2,
        "explanation": "...",
        "weakestTopic": "$weakestTopic",
        "weakestSubject": "$weakestSubject"
      }
    """;

    return _callGemini(prompt, expectJson: true);
  }

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
        if (performance.questionCount > 5) { // Anlamlı bir veri için en az 5 soru çözülmüş olmalı
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