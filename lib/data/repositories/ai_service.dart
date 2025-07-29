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
  final String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent";

  // ✅ YENİ FONKSİYON: Sınava kalan günü hesaplamak için.
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
    // ... (Bu fonksiyon aynı kalıyor, değişiklik yok)
    if (_apiKey.isEmpty || _apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      final errorJson = '{"error": "API Anahtarı bulunamadı. Lütfen `lib/core/config/app_config.dart` dosyasına kendi Gemini API anahtarınızı ekleyin."}';
      return expectJson ? errorJson : "**HATA:** API Anahtarı bulunamadı.";
    }

    try {
      final body = {
        "contents": [
          {"parts": [{"text": prompt}]}
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
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        final errorJson = '{"error": "Yapay zeka servisinden bir cevap alınamadı. (Kod: ${response.statusCode})"}';
        return expectJson ? errorJson : "**HATA:** API Hatası (${response.statusCode})";
      }
    } catch (e) {
      final errorJson = '{"error": "İnternet bağlantınızda bir sorun var gibi görünüyor."}';
      return expectJson ? errorJson : "**HATA:** Ağ Hatası.";
    }
  }

  // ✅ GÜNCELLEME: Prompt, daha profesyonel ve sert bir analiz yapacak şekilde güncellendi.
  Future<String> getAIRecommendations(UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) {
      return Future.value("Analiz için önce bir sınav seçmelisiniz.");
    }
    final examType = ExamType.values.byName(user.selectedExam!);
    final exam = ExamData.getExamByType(examType);
    final daysUntilExam = _getDaysUntilExam(examType);

    // Mevcut koddaki detaylı müfredat ve veri toplama mantığı korunuyor
    String curriculumString = "";
    String relevantSectionName;
    if (exam.type == ExamType.lgs) {
      relevantSectionName = exam.name; // LGS
      for (var section in exam.sections) {
        curriculumString += "\n-- ${section.name} --\n";
        section.subjects.forEach((subjectName, details) {
          curriculumString += "\n### $subjectName Konuları:\n";
          curriculumString += details.topics.map((t) => "- ${t.name}").join("\n");
        });
      }
    } else { // YKS ve KPSS için benzer mantık
      final userSection = user.selectedExamSection ?? exam.sections.first.name;
      relevantSectionName = "${exam.name} ($userSection)";
      final relevantSections = exam.type == ExamType.yks
          ? [exam.sections.firstWhere((s) => s.name == 'TYT'), exam.sections.firstWhere((s) => s.name == userSection)]
          : [exam.sections.firstWhere((s) => s.name == userSection)];

      for (var section in relevantSections.toSet()) { // toSet() ile duplikasyon önlenir
        curriculumString += "\n-- ${section.name} --\n";
        section.subjects.forEach((subjectName, details) {
          curriculumString += "\n### $subjectName Konuları:\n";
          curriculumString += details.topics.map((t) => "- ${t.name}").join("\n");
        });
      }
    }

    String completedTopicsString = user.completedTopics.entries.map((e) =>
    "**${e.key}**: ${e.value.join(', ')}"
    ).join("\n");
    if (completedTopicsString.isEmpty) {
      completedTopicsString = "Henüz tamamlanmış konu işaretlenmemiş.";
    }

    String lastFiveTestsString = tests.take(5).map((t) => "- **${t.testName}**: Toplam Net: ${t.totalNet.toStringAsFixed(2)}. Ders Netleri: [${t.scores.entries.map((e) => "${e.key}: ${(e.value['dogru']! - (e.value['yanlis']! * t.penaltyCoefficient)).toStringAsFixed(2)}").join(', ')}]").join('\n');
    if (lastFiveTestsString.isEmpty) {
      lastFiveTestsString = "Henüz deneme sonucu girilmemiş.";
    }


    final prompt = """
      Sen, BilgeAI adında, Türkiye sınav sistemleri konusunda uzman, veriye dayalı çalışan ve doğrudan konuşan elit bir performans stratejistisin.
      Görevin, öğrencinin verilerini bir bütün olarak analiz edip, zayıflıklarını ve potansiyelini net bir şekilde ortaya koyan, eyleme geçirilebilir bir rapor hazırlamaktır.
      Yorumların acımasızca dürüst ama motive edici olmalı. Hedef sadece net artırmak değil, potansiyelin zirvesine ulaşmak.

      ---
      **KRİTİK VERİLER**
      ---
      - **Sınav:** $relevantSectionName
      - **Sınava Kalan Süre:** $daysUntilExam gün
      - **Hedef:** ${user.goal}
      - **Zorluklar:** ${user.challenges?.join(', ') ?? 'Belirtilmemiş'}
      - **Tamamlanan Konular:**
$completedTopicsString
      - **Son 5 Deneme Netleri (En yeniden eskiye):**
$lastFiveTestsString
      - **Müfredat (Sorumlu olunan tüm konular):**
$curriculumString
      ---
      **GÖREVİN (Markdown formatında):**
      ---
      **1. DURUM ANALİZİ:**
          - **Genel Trend:** Son denemelerdeki net grafiğini (istikrarlı artış, dalgalanma, platoda kalma vb.) yorumla. Bu gidişle hedefe ulaşılıp ulaşılamayacağını belirt.
          - **Ders Karnesi:** En güçlü ve en zayıf 3 dersi net ortalamalarına göre sırala. Zayıf derslerin hedefe ulaşmadaki en büyük engel olduğunu vurgula.
          - **BİLGİ-PERFORMANS ÇELİŞKİSİ:** "Bitirdim" denen konularla deneme sonuçlarını karşılaştır. Eğer bitirdiği bir konudan sistematik olarak yanlış yapıyorsa, bu yanılgıyı net bir şekilde yüzüne vur. Örnek: "'Üslü Sayılar' konusunu bitirmişsin ama son 4 denemenin 3'ünde bu konudan soru kaçırmışsın. Bu konu bitmemiş, sadece üstü kapatılmış."

      **2. STRATEJİK ÖNCELİKLER (TOP 3):**
          - Bu analize göre, netleri en hızlı fırlatacak, en kritik 3 konuyu belirle.
          - Her konu için neden öncelikli olduğunu bir cümleyle açıkla. (Örn: "1. Fonksiyonlar (AYT): Sadece kendi soru değeri için değil, Limit-Türev-İntegral üçgeninin temelini oluşturduğu için KRİTİK.")

      **3. ACİL EYLEM PLANI (3 GÜNLÜK):**
          - Bu 3 konuyu merkeze alan, 3 günlük yoğunlaştırılmış bir mini kamp programı sun. Güçlü olduğu derslerden bir deneme çözerek moral depolamasına izin ver.
    """;
    return _callGemini(prompt, expectJson: false);
  }

  // ✅ GÜNCELLEME: Prompt, sınava kalan süreye göre strateji değiştiren profesyonel bir koç gibi plan yapacak şekilde güncellendi.
  Future<String> generateWeeklyPlan(UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) return Future.value('{"error":"Sınav seçilmedi."}');

    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests) : null;
    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    String strategyFocus;
    String planTitle;

    if (daysUntilExam > 90) {
      planTitle = "Haftalık Stratejik Plan (Uzun Vade)";
      strategyFocus = "UZUN VADE Stratejisi: Odak noktamız, sağlam bir temel oluşturmak ve ana konu eksiklerini kapatmak. Bu dönemde hızdan çok, konuları derinlemesine anlamaya ve öğrenmeye odaklanacağız. Deneme sıklığı daha az olacak.";
    } else if (daysUntilExam > 30) {
      planTitle = "Haftalık Stratejik Plan (Orta Vade)";
      strategyFocus = "ORTA VADE Stratejisi: Artık vites yükseltiyoruz. Odak noktamız, zayıf olduğun ve soru değeri yüksek konulara yüklenmek, düzenli branş denemeleriyle pratik kazanmak ve genel deneme sıklığını artırmak.";
    } else {
      planTitle = "Haftalık Stratejik Plan (Kısa Vade/Saldırı)";
      strategyFocus = "KISA VADE (SALDIRI) Stratejisi: Konu öğrenme dönemi bitti. Artık her şey pratik ve hata analizi üzerine kurulu. Odak noktamız her gün deneme çözmek, eksik konuları sadece soru üzerinden hızlı tekrar etmek ve zaman yönetimi pratiği yapmak. Bu dönemde her bir net altın değerinde.";
    }

    final prompt = """
      Sen, BilgeAI adında, öğrencileri hedeflerine ulaştırmak için kişiselleştirilmiş, askeri disiplinde ve son derece profesyonel haftalık stratejik planlar hazırlayan bir yapay zeka koçusun.
      Görevin, öğrencinin verilerine ve sınava kalan süreye göre, onu en yüksek potansiyeline ulaştıracak bir plan oluşturmaktır.
      Planı KESİNLİKLE AŞAĞIDAKİ JSON FORMATINDA, başka hiçbir ek metin olmadan, sadece JSON olarak döndür.
      
      JSON FORMATI:
      {
        "planTitle": "$planTitle",
        "strategyFocus": "$strategyFocus",
        "plan": [
          {"day": "Pazartesi", "tasks": ["Sabah (09:00-12:00): Konu Tekrarı: [Zayıf Konu Adı] + 20 Soru", "Öğleden Sonra (14:00-16:00): Soru Çözümü: [Güçlü Ders Adı] (40 Soru)"]},
          {"day": "Salı", "tasks": ["..."]},
          {"day": "Çarşamba", "tasks": ["..."]},
          {"day": "Perşembe", "tasks": ["..."]},
          {"day": "Cuma", "tasks": ["..."]},
          {"day": "Cumartesi", "tasks": ["..."]},
          {"day": "Pazar", "tasks": ["..."]}
        ]
      }

      ÖĞRENCİ BİLGİLERİ:
      - Sınav Türü: ${user.selectedExam ?? 'Bilinmiyor'}
      - Sınava Kalan Süre: $daysUntilExam gün
      - Strateji Odağı: $strategyFocus
      - En Zayıf Ders: ${analysis?.weakestSubject ?? "Belirlenemedi"}
      - En Güçlü Ders: ${analysis?.strongestSubject ?? "Belirlenemedi"}
      - Haftalık Çalışma Hedefi: ${user.weeklyStudyGoal} saat

      KURALLAR:
      1. Planı, belirlenen Strateji Odağı'na göre şekillendir.
      2. Zayıf derse en az 3-4 gün yer ver. Güçlü dersi de tekrar ve denemelerle sıcak tut.
      3. Görevler "Fizik çalış" gibi genel olmasın. "Konu Tekrarı: Vektörler + 25 Soru" veya "Genel Tekrar: TYT Türkçe Branş Denemesi (Hata Analizi Dahil)" gibi spesifik ve eyleme geçirilebilir olsun.
      4. Pazar gününü, genel bir deneme ve hafta içi yapılan yanlışların analiz edildiği bir "Hata Defteri Günü" olarak planla. Bu çok önemli.
      5. Plan zorlayıcı ama gerçekçi olsun. Hedef fullemek!
    """;
    return _callGemini(prompt, expectJson: true);
  }

  Future<String> getMotivationalResponse(List<ChatMessage> history) {
    // ... (Bu fonksiyon aynı kalıyor, değişiklik yok)
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
  // ... (Bu sınıf aynı kalıyor, değişiklik yok)
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
        final net = (scores['dogru'] ?? 0) - ((scores['yanlis'] ?? 0) * test.penaltyCoefficient);
        subjectNets.putIfAbsent(subject, () => []).add(net);
      });
    }

    if (subjectNets.isEmpty) {
      weakestSubject = "Belirlenemedi";
      strongestSubject = "Belirlenemedi";
      return;
    }

    final subjectAverages = subjectNets.map((subject, nets) => MapEntry(subject, nets.reduce((a, b) => a + b) / nets.length));

    weakestSubject = subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    strongestSubject = subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}