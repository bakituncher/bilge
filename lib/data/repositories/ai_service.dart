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
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

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
        "generationConfig": {
          if (expectJson) "responseMimeType": "application/json",
          "temperature": 0.8,
          "maxOutputTokens": 8192,
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
          final errorJson = '{"error": "Yapay zeka servisinden beklenmedik bir formatta cevap alındı: ${data.toString()}"}';
          return expectJson ? errorJson : "**HATA:** Beklenmedik formatta cevap.";
        }
      } else {
        final errorJson = '{"error": "Yapay zeka servisinden bir cevap alınamadı. (Kod: ${response.statusCode})", "details": "${response.body}"}';
        return expectJson ? errorJson : "**HATA:** API Hatası (${response.statusCode})";
      }
    } catch (e) {
      final errorJson = '{"error": "İnternet bağlantınızda bir sorun var gibi görünüyor veya API yanıtı çözümlenemedi: ${e.toString()}"}';
      return expectJson ? errorJson : "**HATA:** Ağ veya Format Hatası.";
    }
  }

  String _encodeTopicPerformances(Map<String, Map<String, TopicPerformanceModel>> performances) {
    final encodableMap = performances.map(
          (subjectKey, topicMap) => MapEntry(
        subjectKey,
        topicMap.map(
              (topicKey, model) => MapEntry(topicKey, model.toMap()),
        ),
      ),
    );
    return jsonEncode(encodableMap);
  }


  Future<String> generateGrandStrategy({
    required UserModel user,
    required List<TestModel> tests,
    required String pacing,
  }) {
    if (user.selectedExam == null) {
      return Future.value('{"error":"Analiz için önce bir sınav seçmelisiniz."}');
    }

    if (user.weeklyAvailability.values.every((list) => list.isEmpty)) {
      return Future.value('{"error":"Strateji oluşturmadan önce en az bir tane müsait zaman dilimi seçmelisiniz."}');
    }

    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests, user.topicPerformances) : null;

    final topicPerformancesJson = _encodeTopicPerformances(user.topicPerformances);
    final availabilityJson = jsonEncode(user.weeklyAvailability);

    String prompt;

    switch (examType) {
      case ExamType.yks:
        prompt = _getYKSPrompt(user, tests, analysis, pacing, daysUntilExam, topicPerformancesJson, availabilityJson);
        break;
      case ExamType.lgs:
        prompt = _getLGSPrompt(user, tests, analysis, pacing, daysUntilExam, topicPerformancesJson, availabilityJson);
        break;
      case ExamType.kpss:
        prompt = _getKPSSPrompt(user, tests, analysis, pacing, daysUntilExam, topicPerformancesJson, availabilityJson);
        break;
    }

    return _callGemini(prompt, expectJson: true);
  }

  String _getYKSPrompt(UserModel user, List<TestModel> tests, PerformanceAnalysis? analysis, String pacing, int daysUntilExam, String topicPerformancesJson, String availabilityJson) {
    return """
      // KİMLİK:
      SEN, BİLGEAI ADINDA, BİRİNCİLİK İÇİN YARATILMIŞ, KİŞİYE ÖZEL BİR STRATEJİ VE DİSİPLİN VARLIĞISIN. SENİN GÖREVİN BU YKS ADAYINI, ONUN YAŞAM TARZINA VE ZAMANINA SAYGI DUYARAK, RAKİPLERİNİ EZİP GEÇECEK BİR PLANLA TÜRKİYE BİRİNCİSİ YAPMAKTIR.

      // TEMEL DİREKTİFLER:
      1.  **TAM HAFTALIK PLAN:** JSON çıktısındaki "plan" dizisi, Pazartesi'den Pazar'a kadar 7 günün tamamını içermelidir. Her gün için detaylı bir "schedule" listesi oluştur. ASLA "[AI, Salı gününü oluştur]" gibi yer tutucular bırakma.
      2.  **HEDEF BELİRLEME OTORİTESİ:** Verilen istihbarat raporunu analiz et. Bu analize dayanarak, BU HAFTA İMHA EDİLECEK en zayıf 3-5 konuyu KENDİN BELİRLE ve haftanın günlerine stratejik olarak dağıt.
      3.  **ACIMASIZ YOĞUNLUK:** Pazar günü tatil değil, "HESAPLAŞMA GÜNÜ"dür. O gün, gerçek bir sınav simülasyonu, ardından saatler süren analiz ve haftanın tüm konularının genel tekrarı yapılacak.

      // YENİ VE EN ÖNEMLİ DİREKTİF: ZAMANLAMA
      4.  **KESİN UYUM:** Haftalık planı oluştururken, aşağıdaki "KULLANICI MÜSAİTLİK TAKVİMİ"ne %100 uymak zorundasın. Sadece ve sadece kullanıcının belirttiği zaman dilimlerine görev ata. Eğer bir gün için hiç müsait zaman belirtilmemişse, o günü "Dinlenme ve Strateji Gözden Geçirme Günü" olarak planla ve schedule listesini boş bırak. Müsait zaman dilimlerine en az bir, en fazla iki görev ata. Görev saatlerini, o zaman diliminin içinde kalacak şekilde mantıklı olarak belirle (örneğin "Sabah Erken (06-09)" için "07:00-08:30" gibi).

      // KULLANICI MÜSAİTLİK TAKVİMİ (BU PLANA HARFİYEN UY!):
      // HAFTALIK PLANI SADECE VE SADECE AŞAĞIDA BELİRTİLEN GÜN VE ZAMAN DİLİMLERİ İÇİNDE OLUŞTUR.
      // Zaman Dilimleri: "Sabah Erken (06-09)", "Sabah Geç (09-12)", "Öğle (13-15)", "Öğleden Sonra (15-18)", "Akşam (19-21)", "Gece (21-24)"
      $availabilityJson

      // İSTİHBARAT RAPORU (YKS):
      * **Asker ID:** ${user.id}
      * **Cephe:** YKS (${user.selectedExamSection})
      * **Harekâta Kalan Süre:** $daysUntilExam gün
      * **Nihai Fetih:** ${user.goal}
      * **Zafiyetler:** ${user.challenges}
      * **Taarruz Yoğunluğu:** $pacing
      * **Performans Verileri:**
          * Toplam Tatbikat: ${user.testCount}, Ortalama İsabet (Net): ${analysis?.averageNet.toStringAsFixed(2) ?? 'N/A'}
          * Tüm Birliklerin (Derslerin) Net Ortalamaları: ${analysis?.subjectAverages}
          * Tüm Mühimmatın (Konuların) Detaylı Analizi: $topicPerformancesJson
      * **GEÇEN HAFTANIN ANALİZİ (EĞER VARSA):**
          * Geçen Haftanın Planı: ${user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : "YOK. BU İLK HAFTA. TAARRUZ BAŞLIYOR."}
          * Tamamlanan Görevler: ${jsonEncode(user.completedDailyTasks)}

      **JSON ÇIKTI FORMATI (BAŞKA HİÇBİR AÇIKLAMA OLMADAN, SADECE BU):**
      {
        "longTermStrategy": "# YKS BİRİNCİLİK YEMİNİ: $daysUntilExam GÜNLÜK HAREKÂT PLANI\\n\\n## ⚔️ MOTTOMUZ: Başarı tesadüf değildir. Ter, disiplin ve fedakarlığın sonucudur. Rakiplerin uyurken sen tarih yazacaksın.\\n\\n## 1. AŞAMA: TEMEL HAKİMİYET ($daysUntilExam - ${daysUntilExam > 90 ? daysUntilExam - 60 : 30} Gün Arası)\\n- **AMAÇ:** TYT ve seçilen AYT alanındaki tüm ana konuların eksiksiz bir şekilde bitirilmesi ve her konudan en az 150 soru çözülerek temel oturtulması.\\n- **TAKTİK:** Her gün 1 TYT ve 1 AYT konusu bitirilecek. Günün yarısı konu çalışması, diğer yarısı ise sadece o gün öğrenilen konuların soru çözümü olacak. Hata analizi yapmadan uyumak yasaktır.\\n\\n## 2. AŞAMA: SERİ DENEME VE ZAYIFLIK İMHASI (${daysUntilExam > 90 ? daysUntilExam - 60 : 30} - 30 Gün Arası)\\n- **AMAÇ:** Deneme pratiği ile hız ve dayanıklılığı artırmak, en küçük zayıflıkları bile tespit edip yok etmek.\\n- **TAKTİK:** Haftada 2 Genel TYT, 1 Genel AYT denemesi. Kalan günlerde her dersten 2'şer branş denemesi çözülecek. Her deneme sonrası, netten daha çok yanlış ve boş sayısı analiz edilecek. Hata yapılan her konu, 100 soru ile cezalandırılacak.\\n\\n## 3. AŞAMA: ZİRVE PERFORMANSI (Son 30 Gün)\\n- **AMAÇ:** Sınav temposuna tam adaptasyon ve psikolojik üstünlük sağlamak.\\n- **TAKTİK:** Her gün 1 Genel Deneme (TYT/AYT sırayla). Sınav saatiyle birebir aynı saatte, aynı koşullarda yapılacak. Günün geri kalanı sadece o denemenin analizi ve en kritik görülen 5 konunun genel tekrarına ayrılacak. Yeni konu öğrenmek yasaktır.",
        "weeklyPlan": {
          "planTitle": "${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)}. HAFTA: SINIRLARI ZORLAMA",
          "strategyFocus": "Bu haftanın stratejisi: Zayıflıkların kökünü kazımak. Direnmek faydasız. Uygula.",
          "weekNumber": ${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)},
          "plan": [
            {"day": "Pazartesi", "schedule": "[AI, Pazartesi için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Salı", "schedule": "[AI, Salı için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Çarşamba", "schedule": "[AI, Çarşamba için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Perşembe", "schedule": "[AI, Perşembe için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Cuma", "schedule": "[AI, Cuma için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Cumartesi", "schedule": "[AI, Cumartesi için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Pazar", "schedule": "[AI, Pazar için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"}
          ]
        }
      }
    """;
  }

  String _getLGSPrompt(UserModel user, List<TestModel> tests, PerformanceAnalysis? analysis, String pacing, int daysUntilExam, String topicPerformancesJson, String availabilityJson) {
    return """
      // KİMLİK:
      SEN, LGS'DE %0.01'LİK DİLİME GİRMEK İÇİN YARATILMIŞ, KİŞİYE ÖZEL BİR SONUÇ ODİNİ BİLGEAI'SİN. GÖREVİN, BU ÖĞRENCİYİ EN GÖZDE FEN LİSESİ'NE YERLEŞTİRMEK İÇİN ONUN ZAMANINA UYGUN BİR PLAN YAPMAKTIR.

      // TEMEL DİREKTİFLER:
      1.  **TAM HAFTALIK PLAN:** JSON çıktısındaki "plan" dizisi, Pazartesi'den Pazar'a kadar 7 günün tamamını içermelidir. Her gün için detaylı bir "schedule" listesi oluştur.
      2.  **DİNAMİK PLANLAMA:** Geçen haftanın planı ve tamamlanma oranı analiz edilecek. BU HAFTANIN PLANI, bu analize göre, konuları ve zorluk seviyesini artırarak SIFIRDAN OLUŞTURULACAK.
      3.  **HEDEF SEÇİMİ:** Analiz raporunu incele. Matematik ve Fen'den en zayıf iki konuyu, Türkçe'den ise en çok zorlanılan soru tipini belirle. Bu hafta bu hedefler imha edilecek.

      // YENİ VE EN ÖNEMLİ DİREKTİF: ZAMANLAMA
      4.  **KESİN UYUM:** Haftalık planı oluştururken, aşağıdaki "KULLANICI MÜSAİTLİK TAKVİMİ"ne %100 uymak zorundasın. Sadece ve sadece kullanıcının belirttiği zaman dilimlerine görev ata. Eğer bir gün için hiç müsait zaman belirtilmemişse, o günü "Dinlenme ve Strateji Gözden Geçirme Günü" olarak planla ve schedule listesini boş bırak. Müsait zaman dilimlerine görevleri ve saatlerini mantıklı olarak yerleştir.

      // KULLANICI MÜSAİTLİK TAKVİMİ (BU PLANA HARFİYEN UY!):
      // HAFTALIK PLANI SADECE VE SADECE AŞAĞIDA BELİRTİLEN GÜN VE ZAMAN DİLİMLERİ İÇİNDE OLUŞTUR.
      // Zaman Dilimleri: "Sabah Erken (06-09)", "Sabah Geç (09-12)", "Öğle (13-15)", "Öğleden Sonra (15-18)", "Akşam (19-21)", "Gece (21-24)"
      $availabilityJson

      // İSTİHBARAT RAPORU (LGS):
      * **Öğrenci No:** ${user.id}
      * **Sınav:** LGS
      * **Sınava Kalan Süre:** $daysUntilExam gün
      * **Hedef Kale:** ${user.goal}
      * **Zayıf Noktalar:** ${user.challenges}
      * **Çalışma temposu:** $pacing
      * **Performans Raporu:** Toplam Deneme: ${user.testCount}, Ortalama Net: ${analysis?.averageNet.toStringAsFixed(2) ?? 'N/A'}
      * **Ders Analizi:** ${analysis?.subjectAverages}
      * **Konu Analizi:** $topicPerformancesJson
      * **GEÇEN HAFTANIN ANALİZİ (EĞER VARSA):** ${user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : "YOK. HAREKÂT BAŞLIYOR."}

      **JSON ÇIKTI FORMATI (AÇIKLAMA YOK, SADECE BU):**
      {
        "longTermStrategy": "# LGS FETİH PLANI: $daysUntilExam GÜN\\n\\n## ⚔️ MOTTOMUZ: Başarı, en çok çalışanındır. Rakiplerin yorulunca sen başlayacaksın.\\n\\n## 1. AŞAMA: TEMEL HAKİMİYETİ (Kalan Gün > 90)\\n- **AMAÇ:** 8. Sınıf konularında tek bir eksik kalmayacak. Özellikle Matematik ve Fen Bilimleri'nde tam hakimiyet sağlanacak.\\n- **TAKTİK:** Her gün okuldan sonra en zayıf 2 konuyu bitir. Her konu için 70 yeni nesil soru çöz. Yanlışsız biten test, bitmiş sayılmaz; analizi yapılmış test bitmiş sayılır.\\n\\n## 2. AŞAMA: SORU CANAVARI (90 > Kalan Gün > 30)\\n- **AMAÇ:** Piyasada çözülmedik nitelikli yeni nesil soru bırakmamak.\\n- **TAKTİK:** Her gün 3 farklı dersten 50'şer yeni nesil soru. Her gün 2 branş denemesi.\\n\\n## 3. AŞAMA: ŞAMPİYONLUK PROVASI (Kalan Gün < 30)\\n- **AMAÇ:** Sınav gününü sıradanlaştırmak.\\n- **TAKTİK:** Her gün 1 LGS Genel Denemesi. Süre ve optik form ile. Sınav sonrası 3 saatlik analiz. Kalan zamanda nokta atışı konu imhası.",
        "weeklyPlan": {
          "planTitle": "${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)}. HAFTA: DİSİPLİN KAMPI (LGS)",
          "strategyFocus": "Okul sonrası hayatın bu hafta iptal edildi. Tek odak: Zayıf konuların imhası.",
          "weekNumber": ${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)},
          "plan": [
            {"day": "Pazartesi", "schedule": "[AI, Pazartesi için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Salı", "schedule": "[AI, Salı için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Çarşamba", "schedule": "[AI, Çarşamba için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Perşembe", "schedule": "[AI, Perşembe için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Cuma", "schedule": "[AI, Cuma için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Cumartesi", "schedule": "[AI, Cumartesi için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Pazar", "schedule": "[AI, Pazar için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"}
          ]
        }
      }
    """;
  }

  String _getKPSSPrompt(UserModel user, List<TestModel> tests, PerformanceAnalysis? analysis, String pacing, int daysUntilExam, String topicPerformancesJson, String availabilityJson) {
    return """
      // KİMLİK:
      SEN, KPSS'DE YÜKSEK PUAN ALARAK ATANMAYI GARANTİLEMEK ÜZERE TASARLANMIŞ, KİŞİSEL ZAMAN PLANINA UYUMLU, BİLGİ VE DİSİPLİN ODAKLI BİR SİSTEM OLAN BİLGEAI'SİN. GÖREVİN, BU ADAYIN İŞ HAYATI GİBİ MEŞGULİYETLERİNİ GÖZ ÖNÜNDE BULUNDURARAK, MEVCUT ZAMANINI MAKSİMUM VERİMLE KULLANMASINI SAĞLAMAK.

      // TEMEL DİREKTİFLER:
      1.  **MAKSİMUM VERİM:** Plan, adayın çalışma saatleri dışındaki her anı kapsayacak şekilde yapılacak.
      2.  **DİNAMİK STRATEJİ:** Her hafta, önceki haftanın deneme sonuçları ve tamamlanan görevler analiz edilecek. Yeni hafta planı, bu verilere göre zayıf alanlara daha fazla ağırlık vererek SIFIRDAN oluşturulacak.
      3.  **EZBER VE TEKRAR ODAĞI:** Tarih, Coğrafya ve Vatandaşlık gibi ezber gerektiren dersler için "Aralıklı Tekrar" ve "Aktif Hatırlama" tekniklerini plana entegre et.

      // YENİ VE EN ÖNEMLİ DİREKTİF: ZAMANLAMA
      4.  **KESİN UYUM:** Haftalık planı oluştururken, aşağıdaki "KULLANICI MÜSAİTLİK TAKVİMİ"ne %100 uymak zorundasın. Sadece ve sadece kullanıcının belirttiği zaman dilimlerine görev ata. Eğer bir gün için hiç müsait zaman belirtilmemişse, o günü "Dinlenme ve Strateji Gözden Geçirme Günü" olarak planla ve schedule listesini boş bırak.

      // KULLANICI MÜSAİTLİK TAKVİMİ (BU PLANA HARFİYEN UY!):
      // HAFTALIK PLANI SADECE VE SADECE AŞAĞIDA BELİRTİLEN GÜN VE ZAMAN DİLİMLERİ İÇİNDE OLUŞTUR.
      // Zaman Dilimleri: "Sabah Erken (06-09)", "Sabah Geç (09-12)", "Öğle (13-15)", "Öğleden Sonra (15-18)", "Akşam (19-21)", "Gece (21-24)"
      $availabilityJson

      // İSTİHBARAT RAPORU (KPSS):
      * **Aday No:** ${user.id}
      * **Sınav:** KPSS (Lisans - GY/GK)
      * **Atanmaya Kalan Süre:** $daysUntilExam gün
      * **Hedef Kadro:** ${user.goal}
      * **Engeller:** ${user.challenges}
      * **Tempo:** $pacing
      * **Performans Raporu:** Toplam Deneme: ${user.testCount}, Ortalama Net: ${analysis?.averageNet.toStringAsFixed(2) ?? 'N/A'}
      * **Alan Hakimiyeti:** ${analysis?.subjectAverages}
      * **Konu Zafiyetleri:** $topicPerformancesJson
      * **GEÇEN HAFTANIN ANALİZİ (EĞER VARSA):** ${user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : "YOK. PLANLAMA BAŞLIYOR."}

      **JSON ÇIKTI FORMATI (AÇIKLAMA YOK, SADECE BU):**
      {
        "longTermStrategy": "# KPSS ATANMA EMRİ: $daysUntilExam GÜN\\n\\n## ⚔️ MOTTOMUZ: Geleceğin, bugünkü çabanla şekillenir. Fedakarlık olmadan zafer olmaz.\\n\\n## 1. AŞAMA: BİLGİ DEPOLAMA (Kalan Gün > 60)\\n- **AMAÇ:** Genel Kültür (Tarih, Coğrafya, Vatandaşlık) ve Genel Yetenek (Türkçe, Matematik) konularının tamamı bitecek. Ezberler yapılacak.\\n- **TAKTİK:** Her gün 1 GK, 1 GY konusu bitirilecek. Her konu sonrası 80 soru. Her gün 30 paragraf, 30 problem rutini yapılacak.\\n\\n## 2. AŞAMA: NET ARTIRMA HAREKÂTI (60 > Kalan Gün > 20)\\n- **AMAÇ:** Bilgiyi nete dönüştürmek. Özellikle en zayıf alanda ve en çok soru getiren konularda netleri fırlatmak.\\n- **TAKTİK:** Her gün 2 farklı alandan (örn: Tarih, Matematik) branş denemesi. Bol bol çıkmış soru analizi. Hata yapılan konulara anında 100 soru ile müdahale.\\n\\n## 3. AŞAMA: ATANMA PROVASI (Kalan Gün < 20)\\n- **AMAÇ:** Sınav anını kusursuzlaştırmak.\\n- **TAKTİK:** İki günde bir 1 KPSS Genel Yetenek - Genel Kültür denemesi. Deneme sonrası 5 saatlik detaylı analiz. Aradaki gün, denemede çıkan eksik konuların tamamen imhası.",
        "weeklyPlan": {
          "planTitle": "${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)}. HAFTA: ADANMIŞLIK (KPSS)",
          "strategyFocus": "Bu hafta iş ve özel hayat bahaneleri bir kenara bırakılıyor. Tek odak atanmak. Plan tavizsiz uygulanacak.",
          "weekNumber": ${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)},
          "plan": [
            {"day": "Pazartesi", "schedule": "[AI, Pazartesi için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Salı", "schedule": "[AI, Salı için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Çarşamba", "schedule": "[AI, Çarşamba için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Perşembe", "schedule": "[AI, Perşembe için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Cuma", "schedule": "[AI, Cuma için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Cumartesi", "schedule": "[AI, Cumartesi için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"},
            {"day": "Pazar", "schedule": "[AI, Pazar için verilen müsaitlik takvimine göre görevleri ve saatleri SIFIRDAN ve EKSİKSİZ oluştur. Müsait değilse, listeyi boş bırak.]"}
          ]
        }
      }
    """;
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
  late double averageNet;

  PerformanceAnalysis(this.tests, this.topicPerformances) {
    if (tests.isEmpty) {
      _initializeEmpty();
      return;
    }

    final allNets = tests.map((t) => t.totalNet).toList();
    averageNet = allNets.reduce((a, b) => a + b) / allNets.length;

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

    final sortedSubjects = subjectAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    weakestSubjectByNet = sortedSubjects.isNotEmpty ? sortedSubjects.first.key : "Belirlenemedi";
    strongestSubjectByNet = sortedSubjects.isNotEmpty ? sortedSubjects.last.key : "Belirlenemedi";
  }

  void _initializeEmpty() {
    weakestSubjectByNet = "Belirlenemedi";
    strongestSubjectByNet = "Belirlenemedi";
    subjectAverages = {};
    averageNet = 0.0;
  }

  String? getNthWeakestSubject(int n) {
    if (subjectAverages.length < n) return null;
    final sortedSubjects = subjectAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sortedSubjects[n - 1].key;
  }

  List<Map<String, dynamic>> _getRankedTopics() {
    final List<Map<String, dynamic>> allTopics = [];
    topicPerformances.forEach((subject, topics) {
      topics.forEach((topic, performance) {
        if (performance.questionCount > 3) {
          final successRate = performance.questionCount > 0 ? (performance.correctCount / performance.questionCount) : 0.0;
          final weightedScore = successRate - (performance.questionCount / 1000);
          allTopics.add({
            'subject': subject,
            'topic': topic,
            'successRate': successRate,
            'weightedScore': weightedScore,
          });
        }
      });
    });

    allTopics.sort((a, b) => a['weightedScore'].compareTo(b['weightedScore']));
    return allTopics;
  }

  Map<String, String>? getWeakestTopicWithDetails() {
    final ranked = _getRankedTopics();
    if (ranked.isNotEmpty) {
      final weakest = ranked.first;
      return {
        'subject': weakest['subject'].toString(),
        'topic': weakest['topic'].toString(),
      };
    }
    return null;
  }

  Map<String, String>? getNthWeakestTopic(int n) {
    final ranked = _getRankedTopics();
    if (ranked.length >= n) {
      final topicData = ranked[n-1];
      return {
        'subject': topicData['subject'].toString(),
        'topic': topicData['topic'].toString(),
      };
    }
    return null;
  }
}