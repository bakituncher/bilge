// lib/data/repositories/ai_service.dart
import 'dart:convert'; // HATA DÜZELTİLDİ: Eksik olan kütüphane eklendi.
import 'package:bilge_ai/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';

// Bu provider, AI servisine uygulama genelinden erişimi sağlar.
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  final String _apiKey = AppConfig.geminiApiKey;
  final String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent";

  /// Yapay zekaya bir komut gönderir ve metin tabanlı bir cevap alır.
  Future<String> _callGemini(String prompt) async {
    if (_apiKey.isEmpty || _apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      return "**HATA:** API Anahtarı bulunamadı. Lütfen `lib/core/config/app_config.dart` dosyasına kendi Gemini API anahtarınızı ekleyin.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ // Artık bu komut tanınıyor.
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      );

      if (response.statusCode == 200) {
        // Artık 'utf8' ve 'jsonDecode' komutları tanınıyor.
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        if (response.statusCode == 429) {
          print('API Kota Hatası: ${response.body}');
          return "**HATA:** Yapay zeka servisinin günlük ücretsiz kullanım limiti aşıldı. Bu normal bir durumdur ve Google Cloud projenizde faturalandırmayı etkinleştirerek çözülebilir.";
        }
        print('API Hatası: ${response.body}');
        return "**HATA:** Yapay zeka servisinden bir cevap alınamadı. Lütfen API anahtarınızı ve internet bağlantınızı kontrol edin.";
      }
    } catch (e) {
      print('Ağ Hatası: $e');
      return "**HATA:** İnternet bağlantınızda bir sorun var gibi görünüyor. Lütfen kontrol edip tekrar deneyin.";
    }
  }

  /// Kullanıcının verilerini analiz edip kişisel tavsiyeler üretir.
  Future<String> getAIRecommendations(UserModel user, List<TestModel> tests) {
    final prompt = """
      Sen BilgeAI adında, öğrencilere yol gösteren, pozitif ve motive edici bir yapay zeka koçusun.
      Aşağıdaki verileri kullanarak, bu öğrenci için kişiselleştirilmiş, uygulanabilir ve cesaret verici tavsiyeler oluştur.
      Analizini 3 ana başlıkta (✅ Güçlü Yönlerin, 🎯 Geliştirilmesi Gereken Alanlar, 🚀 Stratejik Tavsiyeler) sun.
      Markdown formatını kullanarak başlıkları kalın ve emojili yap.

      ÖĞRENCİ BİLGİLERİ:
      - Adı: ${user.name}
      - Hedefi: ${user.goal}
      - En Çok Zorlandığı Alanlar: ${user.challenges?.join(', ')}
      - Haftalık Çalışma Hedefi: ${user.weeklyStudyGoal} saat

      SON DENEME SINAVI SONUCLARI (En yeniden en eskiye):
      ${tests.take(5).map((t) => "- ${t.testName}: Toplam Net: ${t.totalNet.toStringAsFixed(2)}, Ders Netleri: ${t.scores.entries.map((e) => "${e.key}: ${(e.value['dogru']! - (e.value['yanlis']! * t.penaltyCoefficient)).toStringAsFixed(2)}").join(', ')}").join('\n')}

      Lütfen bu verilere dayanarak bir analiz ve tavsiye metni oluştur.
    """;
    return _callGemini(prompt);
  }

  /// Kullanıcının verilerine göre haftalık bir çalışma programı oluşturur.
  Future<String> generateWeeklyPlan(UserModel user, List<TestModel> tests) {
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests) : null;
    final prompt = """
      Sen BilgeAI adında, öğrencilere kişiselleştirilmiş haftalık ders çalışma programları hazırlayan bir yapay zeka planlama asistanısın.
      Aşağıdaki verileri kullanarak, öğrencinin hedeflerine ve eksiklerine uygun, dengeli ve motive edici bir haftalık ders programı oluştur.
      Programı KESİNLİKLE AŞAĞIDAKİ JSON FORMATINDA, başka hiçbir ek metin olmadan, sadece JSON olarak döndür.
      Haftanın her günü için 3 adet görev (task) oluştur. Görevler kısa ve net olmalı.

      JSON FORMATI:
      {
        "plan": [
          {"day": "Pazartesi", "tasks": ["Görev 1", "Görev 2", "Görev 3"]},
          {"day": "Salı", "tasks": ["Görev 1", "Görev 2", "Görev 3"]},
          {"day": "Çarşamba", "tasks": ["Görev 1", "Görev 2", "Görev 3"]},
          {"day": "Perşembe", "tasks": ["Görev 1", "Görev 2", "Görev 3"]},
          {"day": "Cuma", "tasks": ["Görev 1", "Görev 2", "Görev 3"]},
          {"day": "Cumartesi", "tasks": ["Görev 1", "Görev 2", "Görev 3"]},
          {"day": "Pazar", "tasks": ["Görev 1", "Görev 2", "Görev 3"]}
        ]
      }

      ÖĞRENCİ BİLGİLERİ:
      - Geliştirmesi Gereken Öncelikli Ders: ${analysis?.weakestSubject ?? "Matematik"}
      - Güçlü Olduğu Ders: ${analysis?.strongestSubject ?? "Türkçe"}

      Lütfen bu bilgilere göre JSON formatında bir haftalık program oluştur.
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
}

// Analiz sınıfı ve ChatMessage modeli (kolaylık için aynı dosyada)
class PerformanceAnalysis {
  final List<TestModel> tests;
  late String weakestSubject;
  late String strongestSubject;

  PerformanceAnalysis(this.tests) {
    final subjectNets = <String, List<double>>{};
    for (var test in tests) {
      test.scores.forEach((subject, scores) {
        final net = scores['dogru']! - (scores['yanlis']! * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }
    final subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));

    weakestSubject = subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    strongestSubject = subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {required this.isUser});
}