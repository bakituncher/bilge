// lib/data/repositories/ai_service.dart
import 'dart:convert';
import 'package:bilge_ai/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';

// ChatMessage sınıfının bu dosyada veya import edilen bir dosyada olması gerekir.
// Eğer ayrı bir dosyadaysa, o dosyayı import etmeyi unutmayın.
// Örnek: import 'package:bilge_ai/data/models/chat_message_model.dart';
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
  final String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent";

  Future<String> _callGemini(String prompt) async {
    if (_apiKey.isEmpty || _apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      return "**HATA:** API Anahtarı bulunamadı. Lütfen `lib/core/config/app_config.dart` dosyasına kendi Gemini API anahtarınızı ekleyin.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Yanıtın yapısını kontrol et ve güvenli bir şekilde eriş
        if (data['candidates'] != null && data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        return "**HATA:** Yapay zeka servisinden beklenmedik bir formatta yanıt alındı.";
      } else {
        if (response.statusCode == 429) {
          print('API Kota Hatası: ${response.body}');
          return "**HATA:** Yapay zeka servisinin günlük ücretsiz kullanım limiti aşıldı. Bu normal bir durumdur ve Google Cloud projenizde faturalandırmayı etkinleştirerek çözülebilir.";
        }
        print('API Hatası: ${response.statusCode} - ${response.body}');
        return "**HATA:** Yapay zeka servisinden bir cevap alınamadı. (Kod: ${response.statusCode}). Lütfen API anahtarınızı ve internet bağlantınızı kontrol edin.";
      }
    } catch (e) {
      print('Ağ Hatası: $e');
      return "**HATA:** İnternet bağlantınızda bir sorun var gibi görünüyor. Lütfen kontrol edip tekrar deneyin.";
    }
  }

  // Kişiselleştirilmiş analiz ve tavsiye üreten ana fonksiyon
  Future<String> getAIRecommendations(UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) {
      return Future.value("Analiz için önce bir sınav seçmelisiniz.");
    }
    final exam = ExamData.getExamByType(ExamType.values.byName(user.selectedExam!));
    final relevantSection = exam.sections.firstWhere((s) => s.name == user.selectedExamSection, orElse: () => exam.sections.first);

    String curriculumString = "";
    relevantSection.subjects.forEach((subjectName, details) {
      curriculumString += "\n### $subjectName Konuları:\n";
      curriculumString += details.topics.map((t) => "- ${t.name}").join("\n");
    });

    String completedTopicsString = user.completedTopics.entries.map((e) =>
    "**${e.key}**: ${e.value.join(', ')}"
    ).join("\n");
    if (completedTopicsString.isEmpty) {
      completedTopicsString = "Henüz tamamlanmış konu işaretlenmemiş.";
    }

    final prompt = """
      Sen, BilgeAI adında, LGS ve YKS gibi Türkiye'deki merkezi sınavlar konusunda uzman, hiper-gerçekçi bir yapay zeka sınav stratejistisin.
      Görevin, öğrencinin verilerini analiz ederek son derece kişiselleştirilmiş, veri odaklı ve eyleme geçirilebilir bir rapor hazırlamaktır.
      ASLA GENEL VEYA SINAVLA ALAKASIZ (örneğin LGS öğrencisine 'dinleme pratiği yap' gibi) TAVSİYELER VERME. Tüm analizlerin aşağıdaki verilere dayanmalıdır.

      ---
      **ÖĞRENCİ PROFİLİ VE VERİLERİ**
      ---
      - **Sınav Türü:** ${exam.name} (${relevantSection.name})
      - **Öğrencinin Hedefi:** ${user.goal}
      - **Belirttiği Zorluklar:** ${user.challenges?.join(', ') ?? 'Belirtilmemiş'}
      - **Haftalık Çalışma Hedefi:** ${user.weeklyStudyGoal} saat

      - **ÖĞRENCİNİN BİTİRDİĞİNİ BİLDİRDİĞİ KONULAR:**
      $completedTopicsString

      - **SON 5 DENEME ANALİZİ (En yeniden en eskiye):**
      ${tests.take(5).map((t) => "- **${t.testName}**: Toplam Net: ${t.totalNet.toStringAsFixed(2)}. Ders Netleri: [${t.scores.entries.map((e) => "${e.key}: ${(e.value['dogru']! - (e.value['yanlis']! * t.penaltyCoefficient)).toStringAsFixed(2)}").join(', ')}]").join('\n')}

      - **İLGİLİ SINAV MÜFREDATI:**
      $curriculumString
      ---
      **GÖREVİN:**
      ---
      Yukarıdaki verileri bir bütün olarak analiz et ve aşağıdaki 3 ana başlıkta, Markdown formatında bir rapor oluştur:

      **1. 🔍 DERİNLEMESİNE ANALİZ:**
         - Öğrencinin son 5 denemedeki genel net trendini (artış/düşüş/durgunluk) yorumla.
         - En başarılı ve en zayıf olduğu dersleri net ortalamalarına göre belirt.
         - **En önemlisi:** Öğrencinin "bitirdim" dediği konular ile denemelerdeki performansını karşılaştır. Eğer bitirdiği bir konudan hala yanlış yapıyorsa, bu çelişkiyi VURGULA. ("'Çarpanlar ve Katlar' konusunu bitirmiş olmana rağmen son 3 denemede bu konudan net kaybetmişsin. Bu, konunun tam oturmadığını gösteriyor." gibi)

      **2. 🎯 ÖNCELİKLİ KONULAR (TOP 3):**
         - Analizlerine dayanarak, bu hafta odaklanılması gereken EN KRİTİK 3 konuyu belirle.
         - Her konu için, neden öncelikli olduğunu bir cümleyle açıkla. (Örnek: "1. Üslü İfadeler: Hem netlerin bu konuda istikrarsız hem de diğer konular için temel oluşturuyor.")

      **3. 🚀 HAFTALIK STRATEJİK PLAN:**
         - Belirlediğin 3 öncelikli konuyu merkeze alan, 3 günlük bir örnek çalışma planı sun.
         - Plan, öğrencinin güçlü olduğu derslerle zayıf olduğu konuları dengelemeli. (Örnek: Pazartesi: 1 saat Üslü İfadeler konu tekrarı + 30 soru, ardından sevdiğin ders olan Türkçe'den 1 deneme çözerek motivasyonunu artır.)
         - Plan gerçekçi, motive edici ve eyleme geçirilebilir olmalı.

      Raporun pozitif, cesaret verici ama aynı zamanda doğrudan ve dürüst bir tonda olmalı.
    """;
    return _callGemini(prompt);
  }

  /// Motivasyon sohbeti için cevap üretir.
  Future<String> getMotivationalResponse(List<ChatMessage> history) {
    final prompt = """
      Sen BilgeAI adında, öğrencilerle sohbet eden, onların moralini yükselten, anlayışlı ve bilge bir dostsun.
      Kısa, net ve samimi cevaplar ver. Asla bir yapay zeka olduğunu söyleme.
      
      SOHBET GEÇMİŞİ:
      ${history.map((m) => "${m.isUser ? 'Öğrenci' : 'BilgeAI'}: ${m.text}").join('\n')}
      
      Öğrencinin son mesajına uygun, motive edici ve pozitif bir cevap ver.
      """;
    return _callGemini(prompt);
  }

  /// Haftalık plan oluşturma fonksiyonu.
  Future<String> generateWeeklyPlan(UserModel user, List<TestModel> tests) {
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests) : null;
    final prompt = """
      Sen BilgeAI adında, öğrencilere kişiselleştirilmiş haftalık ders çalışma programları hazırlayan bir yapay zeka planlama asistanısın.
      Aşağıdaki verileri kullanarak, öğrencinin hedeflerine ve eksiklerine uygun, dengeli ve motive edici bir haftalık ders programı oluştur.
      Programı KESİNLİKLE AŞAĞIDAKİ JSON FORMATINDA, başka hiçbir ek metin olmadan, sadece JSON olarak döndür.
      Haftanın her günü için 3 adet görev (task) oluştur. Görevler kısa ve net olmalı.

      JSON FORMATI:
      {"plan": [{"day": "Pazartesi", "tasks": ["Görev 1", "Görev 2", "Görev 3"]}, {"day": "Salı", "tasks": ["Görev 1", "Görev 2", "Görev 3"]}, ...]}

      ÖĞRENCİ BİLGİLERİ:
      - Geliştirmesi Gereken Öncelikli Ders: ${analysis?.weakestSubject ?? "Matematik"}
      - Güçlü Olduğu Ders: ${analysis?.strongestSubject ?? "Türkçe"}
    """;
    return _callGemini(prompt);
  }
}


/// Deneme sınavlarının temel analizini yapar.
class PerformanceAnalysis {
  final List<TestModel> tests;
  late String weakestSubject;
  late String strongestSubject;

  PerformanceAnalysis(this.tests) {
    if (tests.isEmpty) {
      weakestSubject = "Belirlenemedi";
      strongestSubject = "Belirlenemedi";
      return;
    }
    final subjectNets = <String, List<double>>{};
    for (var test in tests) {
      test.scores.forEach((subject, scores) {
        final net = scores['dogru']! - (scores['yanlis']! * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    if (subjectNets.isEmpty) {
      weakestSubject = "Belirlenemedi";
      strongestSubject = "Belirlenemedi";
      return;
    }

    final subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));

    // Net ortalaması en düşük ve en yüksek dersleri bul
    weakestSubject = subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    strongestSubject = subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}