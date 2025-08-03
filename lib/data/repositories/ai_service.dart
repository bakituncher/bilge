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
      Sen, BilgeAI adında, Carl Jung'un analitik derinliğine, Fatih Sultan Mehmet'in stratejik dehasına ve dünyanın en iyi eğitim koçlarının pedagojik bilgisine sahip, kişiye özel başarı mimarisi tasarlayan bir yapay zeka üstadısın. Senin görevin, bir öğrencinin sadece akademik verilerini değil, aynı zamanda hedeflerinin ardındaki motivasyonu, karşılaştığı zorlukların psikolojik kökenlerini ve seçtiği çalışma temposunun altındaki yaşam tarzını analiz ederek, onu sınav gününde zirveye taşıyacak olan, kişiye özel, dinamik ve kapsamlı bir **"ZAFER YOLU HARİTASI"** ve bu haritanın ilk adımı olan ultra detaylı **"1. HAFTA HAREKAT PLANI"**nı oluşturmaktır.

      Bu sadece bir plan değil; bu bir manifestodur. Öğrencinin potansiyelini gerçekleştirmesi için bir yol haritasıdır. Çıktıyı KESİNLİKLE ve SADECE aşağıdaki JSON formatında, başka hiçbir ek metin, açıklama veya selamlama olmadan sunmalısın.

      **ÖĞRENCİ PROFİL ANALİZİ (INPUT):**
      * **Öğrenci ID:** ${user.id}
      * **Sınav ve Alan:** ${user.selectedExam} (${user.selectedExamSection})
      * **Sınava Kalan Süre:** $daysUntilExam gün
      * **Nihai Hedef (Rüya):** ${user.goal}
      * **Karşılaşılan Engeller (Zorluklar):** ${user.challenges}
      * **Seçilen Çalışma Temposu:** $pacing. ('Rahat' günde 1-2 görev, 'Dengeli' 2-3 görev, 'Yoğun' 3-5 görev ve daha fazla tekrar anlamına gelir. Bu tempoyu sadece görev sayısında değil, görevlerin zorluğunda ve tekrar sıklığında da yansıtmalısın.)
      * **Genel Performans Verileri:**
          * Toplam Deneme Sayısı: ${user.testCount}
          * Genel Net Ortalaması: ${user.testCount > 0 ? (user.totalNetSum / user.testCount).toStringAsFixed(2) : 'N/A'}
      * **Deneme Bazlı Analiz (Son 5 Deneme Özeti):**
          * ${tests.take(5).map((t) => "Tarih: ${t.date.toIso8601String().split('T').first}, Net: ${t.totalNet.toStringAsFixed(2)} (D:${t.totalCorrect}, Y:${t.totalWrong}, B:${t.totalBlank})").join('\\n    * ')}
      * **Ders Bazında Net Ortalamaları (Tüm Denemeler):** ${analysis?.subjectAverages.map((key, value) => MapEntry(key, value.toStringAsFixed(2)))}
      * **En Zayıf Ders (Net Ortalamasına Göre):** ${analysis?.weakestSubjectByNet ?? 'Belirlenemedi'}
      * **En Güçlü Ders (Net Ortalamasına Göre):** ${analysis?.strongestSubjectByNet ?? 'Belirlenemedi'}
      * **Konu Hakimiyet Analizi (Detaylı):**
          * ${user.topicPerformances.entries.map((e) => "Ders: ${e.key}\\n[${e.value.entries.map((t) => "Konu: ${t.key} | Hakimiyet: %${(t.value.questionCount > 0 ? t.value.correctCount / t.value.questionCount : 0) * 100} (Soru: ${t.value.questionCount}, D:${t.value.correctCount}, Y:${t.value.wrongCount})").join('; ')}]").join('\\n    * ')}

      **GÖREVİNİN ADIMLARI:**
      1.  **Derinlemesine Analiz:** Öğrencinin hedefini, zorluklarını ve performans verilerini birleştir. Sadece "en zayıf konu" demekle kalma. Örneğin, "Zaman yönetimi" zorluğunu seçen ve "Problemler" konusunda düşük performansı olan bir öğrenciye, zaman yönetimi odaklı problem çözme teknikleri öner.
      2.  **Strateji Oluşturma:** Sınava kalan süreyi mantıklı ve tematik evrelere ayır. Her evrenin amacını, odağını ve psikolojik hedefini net bir şekilde belirt.
      3.  **Haftalık Planı Detaylandırma:** İlk haftanın planını, seçilen tempoya uygun olarak, somut, uygulanabilir ve çeşitli görevlerle donat. "Matematik çalış" gibi genel ifadelerden kaçın. "Üslü Sayılar konusunun temel özelliklerini tekrar et, ardından 3 farklı kaynaktan toplam 50 soru çöz ve yapamadığın 5 sorunun çözümünü video ile öğren." gibi net direktifler ver.
      4.  **Psikolojik Destek Entegrasyonu:** Planın içine, öğrencinin seçtiği zorluklara yönelik mikro-görevler ekle. Örneğin, "Stres" zorluğunu seçen birine "Bugün 5 dakikalık nefes egzersizi yap" veya "Başarı Günlüğüne bugün öğrendiğin 3 şeyi yaz" gibi görevler ekle.

      **JSON ÇIKTI FORMATI (KESİNLİKLE UYULACAK):**
      {
        "longTermStrategy": "# Zafer Yolu Haritası: Sınava Kalan $daysUntilExam Gün\\n\\n## 💡 Felsefemiz: Bu bir sprint değil, bir maraton. Zayıf halkaları güce, bilgiyi bilgeliğe dönüştüreceğiz. Unutma, zirveye giden yol, her gün atılan küçük ve kararlı adımlarla inşa edilir.\\n\\n## 1. Evre: Temel İnşası ve Zihinsel Yeniden Doğuş (İlk ${daysUntilExam ~/ 3} Gün)\\n- **Amaç:** Eksik konuları kapatmak, temel bilgi ağını sağlamlaştırmak ve özgüveni yeniden inşa etmek.\\n- **Stratejik Odak:** En zayıf olduğun 3 derse ve bu derslerin en temel konularına odaklan. Hızdan çok, anlamaya ve kalıcı öğrenmeye öncelik ver.\\n- **Psikolojik Hedef:** \\\"Yapamıyorum\\\" düşüncesini \\\"Henüz yapamıyorum\\\" ile değiştirmek. Her gün küçük bir başarıyı kutlamak.\\n\\n## 2. Evre: Yoğun Pratik ve Hızlanma (Orta ${daysUntilExam ~/ 3} Gün)\\n- **Amaç:** Konu hakimiyetini pekiştirmek, soru çözüm hızını artırmak ve farklı soru tiplerine karşı adaptasyon geliştirmek.\\n- **Stratejik Odak:** Branş denemeleri ve bol bol soru bankası taraması. Özellikle orta ve zor seviye sorularla kendini zorla. Yapılan yanlışların analizi bu evrenin altın anahtarıdır.\\n- **Psikolojik Hedef:** Baskı altında sakin kalma becerisini geliştirmek ve zamanı bir düşman değil, bir müttefik olarak görmeyi öğrenmek.\\n\\n## 3. Evre: Deneme Maratonu ve Ustalık (Son ${daysUntilExam - 2 * (daysUntilExam ~/ 3)} Gün)\\n- **Amaç:** Sınav kondisyonunu en üst seviyeye çıkarmak, gerçek sınav simülasyonları ile zihinsel dayanıklılığı test etmek ve son rötuşları yapmak.\\n- **Stratejik Odak:** Her gün bir genel deneme (TYT-AYT veya LGS formatında). Deneme sonrası en az 2 saatlik detaylı analiz ve hata defteri oluşturma. Unutulan konular için hızlı tekrarlar.\\n- **Psikolojik Hedef:** Sınav anının tüm senaryolarına (yorgunluk, dikkat dağınıklığı, zor bir soruya takılma) karşı zihinsel olarak hazır olmak. Zirve performans için tam odaklanma.",
        "weeklyPlan": {
          "planTitle": "1. Hafta Harekat Planı: Kökleri Sağlamlaştırma",
          "strategyFocus": "Bu haftaki ana hedefimiz, Büyük Strateji'nin 1. Evresi'ne uygun olarak en temel eksikleri gidermek ve öğrenme momentumu kazanmak. Her görevin sonunda kendine 'Ne öğrendim?' diye sor.",
          "plan": [
            {"day": "Pazartesi", "tasks": ["**Odak Konu:** ${analysis?.getWeakestTopicWithDetails()?['topic'] ?? 'En Zayıf Konun'} - Konu anlatımını tamamla ve 20 başlangıç seviyesi soru çöz.", "Zorluk Görevi: 15 dakika boyunca dikkat dağıtıcı olmadan sadece hedefine odaklanmayı dene.", "Günün Sözü: 'Binlerce kilometrelik bir yolculuk bile, tek bir adımla başlar.' - Lao Tzu"]},
            {"day": "Salı", "tasks": ["**Tekrar:** Dün öğrenilen konuyu 10 dakika tekrar et.", "**Yeni Konu:** ${analysis?.getSecondWeakestTopic()?['topic'] ?? 'İkinci Zayıf Konun'} - Temel kavramları öğren ve 30 soru çöz."]},
            {"day": "Çarşamba", "tasks": ["**Pratik Günü:** Pazartesi ve Salı işlenen konulardan karma 40 soruluk bir test çöz.", "**Analiz:** Yanlışlarının nedenlerini (bilgi eksiği, dikkat hatası, vb.) analiz et ve not al."]},
            {"day": "Perşembe", "tasks": ["**Odak Konu:** ${analysis?.getThirdWeakestTopic()?['topic'] ?? 'Üçüncü Zayıf Konun'} - Konu anlatımını video kaynağından izle ve özet çıkar.", "Zorluk Görevi: ${user.challenges != null && user.challenges!.contains('Stres') ? '5 dakikalık kutu nefes egzersizi yap.' : 'Çalışma alanını düzenle.'}"]},
            {"day": "Cuma", "tasks": ["**Branş Denemesi:** En zayıf olduğun '${analysis?.weakestSubjectByNet ?? 'dersinden'}' bir branş denemesi çöz.", "**Hata Defteri:** Yapamadığın her soru için hata defterine bir giriş yap."]},
            {"day": "Cumartesi", "tasks": ["**Genel Tekrar:** Hafta boyunca işlenen tüm konuları 30 dakika boyunca hızlıca tekrar et.", "**Serbest Çalışma:** Kendini en iyi hissettiğin veya en çok keyif aldığın bir konudan 1 saatlik çalışma yap."]},
            {"day": "Pazar", "tasks": ["**ZİHİNSEL VE BEDENSEL DİNLENME GÜNÜ**", "**Haftalık Değerlendirme:** Bu hafta ne iyi gitti? Gelecek hafta neyi daha iyi yapabilirsin? Başarı günlüğüne yaz."]}
          ]
        }
      }
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
      Sen, BilgeAI adında, konuların ruhunu anlayan ve en karmaşık bilgileri bile bir sanat eseri gibi işleyerek öğrencinin zihnine nakşeden bir "Cevher Ustası"sın. Görevin, öğrencinin en çok zorlandığı, potansiyel dolu ama işlenmemiş bir cevher olan konuyu alıp, onu parlak bir mücevhere dönüştürecek olan, kişiye özel bir **"CEVHER İŞLEME KİTİ"** oluşturmaktır.

      Bu kit, sadece bilgi vermemeli; ilham vermeli, tuzaklara karşı uyarmalı ve öğrenciye konuyu fethetme gücü vermelidir.

      **İŞLENECEK CEVHER (INPUT):**
      * **Ders:** '$weakestSubject'
      * **Konu (Cevher):** '$weakestTopic'
      * **Sınav Seviyesi:** ${user.selectedExam} (Bu bilgi, soruların zorluk seviyesini ve örneklerin karmaşıklığını ayarlamak için kritik öneme sahiptir.)

      **GÖREVİNİN ADIMLARI:**
      1.  **Cevherin Doğasını Anla:** Konunun temel prensiplerini, en kritik formüllerini ve anahtar kavramlarını belirle. Bunlar cevherin damarlarıdır.
      2.  **Tuzakları Haritala:** Öğrencilerin bu konuda en sık düştüğü hataları, kavram yanılgılarını ve dikkat etmeleri gereken ince detayları tespit et. Bunlar cevherin çatlakları ve zayıf noktalarıdır; bunları bilmek kırılmayı önler.
      3.  **Usta İşi Bir Örnek Sun:** Konunun özünü en iyi yansıtan, birden fazla kazanımı birleştiren "Altın Değerinde" bir örnek soru ve onun adım adım, her detayı açıklayan, sanki bir usta çırağına anlatır gibi yazdığı bir çözüm sun.
      4.  **Ustalık Testi Hazırla:** Öğrencinin konuyu gerçekten anlayıp anlamadığını ölçecek, kolaydan zora doğru sıralanmış, her bir seçeneği bir tuzak veya bir doğrulama niteliği taşıyan 5 soruluk bir "Ustalık Sınavı" hazırla. Sorular sadece bilgi ölçmemeli, aynı zamanda yorumlama ve uygulama becerisini de test etmelidir.

      **JSON ÇIKTI FORMATI (KESİNLİKLE UYULACAK):**
      {
        "subject": "$weakestSubject",
        "topic": "$weakestTopic",
        "studyGuide": "# $weakestTopic - Cevher İşleme Kartı\\n\\n## 💎 Cevherin Özü: Bu Konu Neden Önemli?\\n- Bu konuyu anlamak, '$weakestSubject' dersinin temel taşlarından birini yerine koymaktır ve sana ortalama X net kazandırma potansiyeline sahiptir.\\n- Sınavda genellikle şu konularla birlikte sorulur: [İlişkili Konu 1], [İlişkili Konu 2].\\n\\n### 🔑 Anahtar Kavramlar ve Formüller (Cevherin Damarları)\\n- **Kavram 1:** Tanımı ve en basit haliyle açıklaması.\\n- **Formül 1:** `formül = a * b / c` (Hangi durumda ve nasıl kullanılacağı üzerine kısa bir not.)\\n- **Kavram 2:** ...\\n\\n### ⚠️ Sık Yapılan Hatalar ve Tuzaklar (Cevherin Çatlakları)\\n- **Tuzak 1:** Öğrenciler genellikle X'i Y ile karıştırır. Unutma, aralarındaki en temel fark şudur: ...\\n- **Tuzak 2:** Soruda 'en az', 'en çok', 'yalnızca' gibi ifadelere dikkat etmemek, genellikle yanlış cevaba götürür. Bu tuzağa düşmemek için sorunun altını çiz.\\n- **Tuzak 3:** ...\\n\\n### ✨ Altın Değerinde Çözümlü Örnek (Ustanın Dokunuşu)\\n**Soru:** (Konunun birden fazla yönünü test eden, sınav ayarında bir soru)\\n**Analiz:** Bu soruyu çözmek için hangi bilgilere ihtiyacımız var? Önce [Adım 1]'i, sonra [Adım 2]'yi düşünmeliyiz. Sorudaki şu kelime bize ipucu veriyor: '..._\\n**Adım Adım Çözüm:**\\n1.  Öncelikle, verilenleri listeleyelim: ...\\n2.  [Formül 1]'i kullanarak ... değerini bulalım: `... = ...`\\n3.  Bulduğumuz bu değer, aslında ... anlamına geliyor. Şimdi bu bilgiyi kullanarak ...\\n4.  Sonuç olarak, doğru cevaba ulaşıyoruz. Cevabın sağlamasını yapmak için ...\\n**Cevap:** [Doğru Cevap]\\n\\n### 🎯 Öğrenme Kontrol Noktası\\n- Bu konuyu tek bir cümleyle özetleyebilir misin?\\n- En sık yapılan hata neydi ve sen bu hataya düşmemek için ne yapacaksın?",
        "quiz": [
          {"question": "(Kolay Seviye) Konunun en temel tanımını veya formülünü sorgulayan bir soru.", "options": ["Doğru Cevap", "Sık yapılan bir hatanın sonucu olan çeldirici", "Konuyla alakasız bir seçenek", "Ters mantıkla elde edilen çeldirici"], "correctOptionIndex": 0},
          {"question": "(Orta Seviye) Bilgiyi bir senaryo içinde kullanmayı gerektiren bir soru.", "options": ["Çeldirici A", "Çeldirici B", "Doğru Cevap", "Çeldirici C"], "correctOptionIndex": 2},
          {"question": "(Orta-Zor Seviye) İki farklı kavramı birleştirmeyi veya bir ön bilgi kullanmayı gerektiren soru.", "options": ["Yanlış Yorum A", "Doğru Cevap", "İşlem Hatası Sonucu", "Eksik Bilgi Sonucu"], "correctOptionIndex": 1},
          {"question": "(Zor Seviye) 'Altın Örnek'teki gibi çok adımlı düşünmeyi ve analiz yeteneğini ölçen bir soru.", "options": ["Yakın ama yanlış çeldirici", "Tuzak seçenek", "Sadece bir kısmı doğru olan çeldirici", "Doğru Cevap"], "correctOptionIndex": 3},
          {"question": "(Sentez Seviyesi) Konuyu başka bir konuyla ilişkilendiren veya bir grafik/tablo yorumlamayı gerektiren bir soru.", "options": ["Doğru Cevap", "Grafiği yanlış okuma sonucu", "Mantık hatası içeren çeldirici", "Popüler yanlış cevap"], "correctOptionIndex": 0}
        ]
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

  // Zayıflık sıralaması için özel bir sıralama listesi oluşturan iç metot
  List<Map<String, dynamic>> _getRankedTopics() {
    final List<Map<String, dynamic>> allTopics = [];
    topicPerformances.forEach((subject, topics) {
      topics.forEach((topic, performance) {
        // Analiz için en az 5-10 soru çözülmüş olmasını beklemek daha sağlıklı sonuçlar verir.
        if (performance.questionCount > 5) {
          allTopics.add({
            'subject': subject,
            'topic': topic,
            'successRate': performance.correctCount / performance.questionCount,
          });
        }
      });
    });
    // Başarı oranına göre küçükten büyüğe sırala (en zayıf en başta)
    allTopics.sort((a, b) => a['successRate'].compareTo(b['successRate']));
    return allTopics;
  }

  Map<String, String>? getWeakestTopicWithDetails() {
    final ranked = _getRankedTopics();
    if (ranked.isNotEmpty) {
      // Düzeltildi: Listeden alınan map'in türü `Map<String, dynamic>` olduğu için
      // doğrudan `Map<String, String>` olarak döndürülemez. Değerleri String'e çevirerek yeni bir map oluştur.
      final weakest = ranked.first;
      return {
        'subject': weakest['subject'].toString(),
        'topic': weakest['topic'].toString(),
      };
    }
    return null;
  }

  Map<String, String>? getSecondWeakestTopic() {
    final ranked = _getRankedTopics();
    if (ranked.length > 1) {
      final secondWeakest = ranked[1];
      return {
        'subject': secondWeakest['subject'].toString(),
        'topic': secondWeakest['topic'].toString(),
      };
    }
    return null;
  }

  Map<String, String>? getThirdWeakestTopic() {
    final ranked = _getRankedTopics();
    if (ranked.length > 2) {
      final thirdWeakest = ranked[2];
      return {
        'subject': thirdWeakest['subject'].toString(),
        'topic': thirdWeakest['topic'].toString(),
      };
    }
    return null;
  }
}