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

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  final String _apiKey = AppConfig.geminiApiKey;
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent";

  int _getDaysUntilExam(ExamType examType) {
    final now = DateTime.now();
    DateTime examDate;
    // Sınavların yaklaşık tarihlerini varsayıyoruz. Bu tarihler her yıl güncellenmeli.
    switch (examType) {
      case ExamType.lgs:
        examDate = DateTime(now.year, 6, 2); // Haziran'ın ilk hafta sonu
        break;
      case ExamType.yks:
        examDate = DateTime(now.year, 6, 15); // Haziran'ın ortası
        break;
      case ExamType.kpss:
        examDate = DateTime(now.year, 7, 14); // Temmuz ortası (Lisans)
        break;
    }
    // Eğer sınav tarihi geçtiyse, bir sonraki yılın sınav tarihini hesapla.
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
        // ✅ İYİLEŞTİRME: API'den gelen cevabın içeriğini kontrol et.
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

  // ✅ BİRLEŞTİRİLDİ: Artık tek bir koçluk seansı hem analiz hem de plan içeriyor.
  Future<String> getCoachingSession(UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) {
      return Future.value('{"error":"Analiz için önce bir sınav seçmelisiniz."}');
    }
    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests) : null;

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
      - Son 5 Deneme: $lastFiveTestsString
      ---
      
      ANALİZ RAPORU (analysisReport) İÇİN KURALLAR:
      1.  **Genel Trendi** yorumla. Bu gidişle hedefe ulaşılıp ulaşılamayacağını belirt.
      2.  **Ders Karnesi** çıkar: En güçlü ve en zayıf 3 dersi sırala.
      3.  **BİLGİ-PERFORMANS ÇELİŞKİSİ** analizi yap: Bitirdiği konulardan yanlış yapıyor mu?
      4.  **KİŞİSEL ENGEL ANALİZİ** yap: Belirttiği zorlukların performansını nasıl etkilediğini analiz et.
      5.  **ACİL EYLEM PLANI** olarak netleri en hızlı fırlatacak 3 konuyu belirle.

      HAFTALIK PLAN (weeklyPlan) İÇİN KURALLAR:
      1.  Planı, yukarıda yaptığın analize ve belirlediğin 3 acil eylem konusuna göre oluştur.
      2.  Sınava kalan süreye göre stratejiyi belirle (Uzun/Orta/Kısa Vade).
      3.  Görevler spesifik olsun ("Fizik çalış" DEĞİL, "Konu Tekrarı: Vektörler + 25 Soru" GİBİ).
      4.  Pazar gününü deneme ve hata analizine ayır.
    """;

    return _callGemini(prompt, expectJson: true);
  }

  // ✅ YENİ FONKSİYON: Zayıflık Avcısı için soru üretir.
  Future<String> generateTargetedQuestions(
      UserModel user, List<TestModel> tests) {
    if(tests.isEmpty){
      return Future.value('{"error":"Soru üretmek için en az bir deneme sonucu gereklidir."}');
    }
    final analysis = PerformanceAnalysis(tests);
    final weakestSubject = analysis.weakestSubject;
    final weakestTopic =
    analysis.getWeakerTopicInSubject(weakestSubject, user.completedTopics);

    final prompt = """
      Sen, bir öğrencinin en zayıf olduğu konudan, sınav formatına uygun, orijinal ve zorlayıcı bir soru üreten uzman bir soru yazarı yapay zekasın.
      Öğrencinin en zayıf olduğu ders '$weakestSubject' ve bu derste odaklanması gereken konu '$weakestTopic'.
      Bu konudan, 4 şıklı bir çoktan seçmeli soru oluştur.
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
        "correctOptionIndex": 2, // Doğru şıkkın indeksi (0'dan başlar, burada C şıkkı)
        "explanation": "..." // Sorunun detaylı ve öğretici çözümü
      }

      KURALLAR:
      1. Soru, belirtilen '$weakestTopic' konusundan olsun.
      2. Soru, öğrencinin seviyesini zorlayacak ama öğretici nitelikte olsun. Şıklardaki "A)", "B)" gibi ifadeleri KALDIR, sadece seçeneğin metnini yaz.
      3. Açıklama (explanation) kısmı, sadece doğru cevabı vermekle kalmasın, aynı zamanda konunun mantığını ve çözüm yöntemini de anlatsın.
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

// ✅ GÜNCELLEME: Analiz sınıfına zayıf konu bulma yeteneği eklendi.
class PerformanceAnalysis {
  final List<TestModel> tests;
  late String weakestSubject;
  late String strongestSubject;
  late Map<String, double> subjectAverages;

  PerformanceAnalysis(this.tests) {
    if (tests.isEmpty) {
      weakestSubject = "Belirlenemedi";
      strongestSubject = "Belirlenemedi";
      subjectAverages = {};
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
      weakestSubject = "Belirlenemedi";
      strongestSubject = "Belirlenemedi";
      subjectAverages = {};
      return;
    }

    subjectAverages = subjectNets.map(
            (subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));

    weakestSubject =
        subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    strongestSubject =
        subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String getWeakerTopicInSubject(String subject, Map<String, List<String>> completedTopics) {
    final allTopicsForSubject = ExamData.getAllTopicsForSubject(subject);
    final completedTopicsForSubject = completedTopics[subject] ?? [];

    // Henüz tamamlanmamış bir konu varsa onu döndür
    final notCompleted = allTopicsForSubject.where((topic) => !completedTopicsForSubject.contains(topic.name));
    if(notCompleted.isNotEmpty) {
      return notCompleted.first.name;
    }

    // Hepsi tamamlanmışsa rastgele birini döndür
    if (allTopicsForSubject.isNotEmpty) {
      return (allTopicsForSubject.toList()..shuffle()).first.name;
    }

    return "Genel Tekrar";
  }
}