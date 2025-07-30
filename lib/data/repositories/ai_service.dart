// lib/data/repositories/ai_service.dart
import 'dart:convert';
import 'package:bilge_ai/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {required this.isUser});
}

// BİLGEAI DEVRİMİ - DÜZELTME: Servisin Ref'e doğrudan bağımlılığı kaldırıldı.
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  // BİLGEAI DEVRİMİ - DÜZELTME: Kullanılmayan _ref alanı kaldırıldı.
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
      return expectJson
          ? errorJson
          : "**HATA:** API Anahtarı bulunamadı.";
    }

    try {
      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        if (expectJson)
          "generationConfig": {
            "responseMimeType": "application/json",
          }
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
        final errorJson =
            '{"error": "Yapay zeka servisinden bir cevap alınamadı. (Kod: ${response.statusCode})", "details": "${response.body}"}';
        return expectJson
            ? errorJson
            : "**HATA:** API Hatası (${response.statusCode})";
      }
    } catch (e) {
      final errorJson =
          '{"error": "İnternet bağlantınızda bir sorun var gibi görünüyor veya API yanıtı çözümlenemedi."}';
      return expectJson ? errorJson : "**HATA:** Ağ veya Format Hatası.";
    }
  }

  Future<String> getCoachingSession(UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) {
      return Future.value('{"error":"Analiz için önce bir sınav seçmelisiniz."}');
    }
    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests, user.completedTopics) : null;

    String lastFiveTestsString = tests.take(5).map((t) => "- **${t.testName}**: Toplam Net: ${t.totalNet.toStringAsFixed(2)}. Ders Netleri: [${t.scores.entries.map((e) => "${e.key}: ${(e.value['dogru']! - (e.value['yanlis']! * t.penaltyCoefficient)).toStringAsFixed(2)}").join(', ')}]").join('\n');
    if (lastFiveTestsString.isEmpty) {
      lastFiveTestsString = "Henüz deneme sonucu girilmemiş.";
    }

    final prompt = """
      Sen, BilgeAI adında, Türkiye sınav sistemleri konusunda uzman, veriye dayalı çalışan ve doğrudan konuşan elit bir performans stratejistisin.
      Görevin, öğrencinin verilerini bir bütün olarak analiz edip, zayıflıklarını, potansiyelini ve kişisel engellerini net bir şekilde ortaya koyan, eyleme geçirilebilir bir **ANALİZ RAPORU** ve bu rapora uygun **HAFTALIK EYLEM PLANI** hazırlamaktır.
      Çıktıyı KESİNLİKLE JSON formatında, başka hiçbir ek metin olmadan ver.

      JSON FORMATI:
      {
        "analysisReport": "...", // Markdown formatında detaylı analiz metni
        "weeklyPlan": {
          "planTitle": "Haftalık Stratejik Plan",
          "strategyFocus": "...", // Haftanın ana stratejisi
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
      - En Zayıf Dersi (Analize Göre): ${analysis?.weakestSubject ?? 'Belirlenemedi'}
      - **En Sorunlu Konusu (Analize Göre)**: ${analysis?.getWeakerTopicInSubject(analysis.weakestSubject) ?? 'Belirlenemedi'}
      - Tamamladığını belirttiği konular: ${user.completedTopics.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join(' | ')}
      - Son 5 Deneme: $lastFiveTestsString
      ---
      
      ANALİZ RAPORU (analysisReport) İÇİN KURALLAR:
      1.  **Genel Trendi** yorumla. Netleri artıyor mu, azalıyor mu, yerinde mi sayıyor?
      2.  **En Güçlü ve En Zayıf Dersleri** sırala. Zayıf derslerdeki net kaybının nedenlerini tahmin et (konu eksiği, pratik eksiği vb.).
      3.  **BİLGİ-PERFORMANS ÇELİŞKİSİ** analizi yap: Öğrencinin "tamamladım" dediği konularla en zayıf olduğu konular arasında bir çelişki var mı? Varsa bunu vurgula. Örneğin: "Fizik'te 'Vektörler' konusunu tamamladığını belirtmişsin ancak Fizik netlerin hala düşük. Bu konuyu gerçekten anladığından emin misin?".
      4.  **KİŞİSEL ENGEL ANALİZİ** yap: Belirttiği zorlukların (örn: Stres, Zaman Yönetimi) performansını nasıl etkilediğini analiz et.
      5.  **ACİL EYLEM PLANI** olarak netleri en hızlı fırlatacak 2-3 spesifik konuyu belirle. Bu konular, özellikle "tamamlanmış" ama hala sorunlu görünen konular olmalı.

      HAFTALIK PLAN (weeklyPlan) İÇİN KURALLAR:
      1.  Planı, yukarıda yaptığın analize ve belirlediğin acil eylem konularına göre oluştur.
      2.  Sınava kalan süreye göre stratejiyi belirle (Uzun/Orta/Kısa Vade).
      3.  Görevler spesifik olsun ("Fizik çalış" DEĞİL, "Konu Tekrarı: Vektörler + 25 Soru" GİBİ).
      4.  Pazar gününü deneme ve hata analizine ayır.
    """;

    return _callGemini(prompt, expectJson: true);
  }

  Future<String> generateTargetedQuestions(UserModel user, List<TestModel> tests) {
    if(tests.isEmpty){
      return Future.value('{"error":"Soru üretmek için en az bir deneme sonucu gereklidir."}');
    }
    final analysis = PerformanceAnalysis(tests, user.completedTopics);
    final weakestSubject = analysis.weakestSubject;
    final weakestTopic = analysis.getWeakerTopicInSubject(weakestSubject);

    if (weakestTopic == null) {
      return Future.value('{"error":"Analiz için zayıf bir konu bulunamadı. Lütfen önce konu listenizi güncelleyin."}');
    }

    final prompt = """
      Sen, bir öğrencinin en zayıf olduğu konudan, sınav formatına uygun, orijinal ve zorlayıcı bir soru üreten uzman bir soru yazarı yapay zekasın.
      Öğrencinin en zayıf olduğu ders **'$weakestSubject'**. Bu derste özellikle sorun yaşadığı konu ise **'$weakestTopic'**. Bu konuyu bildiğini düşünmesine rağmen test sonuçları aksini gösteriyor olabilir.
      Şimdi bu **'$weakestTopic'** konusundan, öğrencinin bilgisini gerçekten test edecek, 4 şıklı bir çoktan seçmeli soru oluştur.
      Çıktıyı KESİNLİKLE AŞAĞIDAKİ JSON FORMATINDA, başka hiçbir ek metin olmadan, sadece JSON olarak döndür.
      
      JSON FORMATI:
      {
        "question": "...", // Soru metni
        "options": [
          "...", // A şıkkı
          "...", // B şıkkı
          "...", // C şıkkı
          "..."  // D şıkkı
        ],
        "correctOptionIndex": 2, // Doğru şıkkın indeksi (0'dan başlar)
        "explanation": "...", // Sorunun detaylı ve öğretici çözümü
        "weakestTopic": "$weakestTopic", // Hangi konudan soru üretildiği
        "weakestSubject": "$weakestSubject" // Hangi dersten soru üretildiği
      }

      KURALLAR:
      1. Soru, belirtilen '$weakestTopic' konusundan olsun.
      2. Soru, öğrencinin seviyesini zorlayacak ama öğretici nitelikte olsun. Şıklardaki "A)", "B)" gibi ifadeleri KALDIR, sadece seçeneğin metnini yaz.
      3. Açıklama (explanation) kısmı, sadece doğru cevabı vermekle kalmasın, aynı zamanda konunun mantığını, çözüm yöntemini ve yaygın yapılan hataları da anlatsın.
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
  final Map<String, List<String>> completedTopics;
  late String weakestSubject;
  late String strongestSubject;
  late Map<String, double> subjectAverages;

  PerformanceAnalysis(this.tests, this.completedTopics) {
    if (tests.isEmpty) {
      _initializeEmpty();
      return;
    }

    final subjectNets = <String, List<double>>{};
    for (var test in tests) {
      test.scores.forEach((subject, scores) {
        final net = (scores['dogru'] ?? 0) -
            ((scores['yanlis'] ?? 0) * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    if (subjectNets.isEmpty) {
      _initializeEmpty();
      return;
    }

    subjectAverages = subjectNets.map(
            (subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));

    weakestSubject =
        subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    strongestSubject =
        subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _initializeEmpty() {
    weakestSubject = "Belirlenemedi";
    strongestSubject = "Belirlenemedi";
    subjectAverages = {};
  }

  String? getWeakerTopicInSubject(String subject) {
    final allTopicsForSubject = ExamData.getAllTopicsForSubject(subject);
    if (allTopicsForSubject.isEmpty) return null;

    final completedTopicsForSubject = completedTopics[subject] ?? [];

    if (completedTopicsForSubject.isNotEmpty) {
      return (completedTopicsForSubject..shuffle()).first;
    }

    final notCompleted = allTopicsForSubject.where((topic) => !completedTopicsForSubject.contains(topic.name));
    if(notCompleted.isNotEmpty) {
      return notCompleted.first.name;
    }

    return (allTopicsForSubject.toList()..shuffle()).first.name;
  }
}