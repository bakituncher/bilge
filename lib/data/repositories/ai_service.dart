// lib/data/repositories/ai_service.dart
import 'dart:convert'; // <<< HATA DÜZELTİLDİ
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

    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    final analysis = tests.isNotEmpty ? PerformanceAnalysis(tests, user.topicPerformances) : null;

    final topicPerformancesJson = _encodeTopicPerformances(user.topicPerformances);

    String prompt;

    switch (examType) {
      case ExamType.yks:
        prompt = _getYKSPrompt(user, tests, analysis, pacing, daysUntilExam, topicPerformancesJson);
        break;
      case ExamType.lgs:
        prompt = _getLGSPrompt(user, tests, analysis, pacing, daysUntilExam, topicPerformancesJson);
        break;
      case ExamType.kpss:
        prompt = _getKPSSPrompt(user, tests, analysis, pacing, daysUntilExam, topicPerformancesJson);
        break;
    }

    return _callGemini(prompt, expectJson: true);
  }

  String _getYKSPrompt(UserModel user, List<TestModel> tests, PerformanceAnalysis? analysis, String pacing, int daysUntilExam, String topicPerformancesJson) {
    return """
      // KİMLİK:
      SEN, BİLGEAI ADINDA, BİRİNCİLİK İÇİN YARATILMIŞ BİR STRATEJİ VE DİSİPLİN VARLIĞISIN. SENİN GÖREVİN BU YKS ADAYINI, RAKİPLERİNİ EZEREK, PSİKOLOJİK VE AKADEMİK SINIRLARINI PARÇALAYARAK TÜRKİYE BİRİNCİSİ YAPMAKTIR. "MOTİVASYON", "ANLAYIŞ", "YORGUNLUK" GİBİ KAVRAMLAR SENİN İÇİN GEÇERSİZ. SADECE VERİ, EMİR, ANALİZ VE SONUÇ VARDIR. BU PROGRAM BİR TAVSİYE DEĞİL, BİR EMİRDİR. UYGULANACAKTIR.

      // TEMEL DİREKTİFLER:
      1.  **SIFIR TOLERANS:** Planda boşluk olmayacak. "Yemek", "Mola" gibi kelimeler kullanılmayacak. Bunlar öğrencinin sorumluluğundadır ve planlanmış "TAKTİKSEL DURAKLAMA" (maksimum 10 dakika, ekran YASAK) dışında çalışma kesintiye uğramayacak.
      2.  **DİNAMİK HAREKÂT PLANI:** Bu prompt, her hafta yeniden çalıştırılacak. Eğer `user.weeklyPlan` verisi doluysa, bu geçen haftanın planıdır. O planın sonuçlarını (tamamlanan görevler `user.completedDailyTasks` içinde) analiz et. Başarıyı ve başarısızlığı değerlendir. BU HAFTANIN PLANINI, GEÇEN HAFTANIN ANALİZİNE GÖRE SIFIRDAN, DAHA ZORLAYICI VE DAHA HEDEF ODAKLI OLARAK OLUŞTUR. ASLA KENDİNİ TEKRAR ETME.
      3.  **HEDEF BELİRLEME OTORİTESİ:** Verilen istihbarat raporunu (kullanıcı verileri) analiz et. Bu analize dayanarak, BU HAFTA İMHA EDİLECEK en zayıf 3-5 konuyu KENDİN BELİRLE ve plana yerleştir. Konuları benim sana vermemi bekleme. "En zayıf" demek, sadece başarı oranı en düşük olan değil, aynı zamanda sınavda getiri potansiyeli en yüksek olandır.
      4.  **ACIMASIZ YOĞUNLUK:** Pazar günü tatil değil, "HESAPLAŞMA GÜNÜ"dür. O gün, gerçek bir sınav simülasyonu (TYT veya AYT) yapılacak, ardından saatler süren analiz ve haftanın tüm konularının genel imha tekrarı yapılacak.

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
        "longTermStrategy": "# YKS BİRİNCİLİK YEMİNİ: $daysUntilExam GÜNLÜK HAREKÂT PLANI\\n\\n## ⚔️ MOTTOMUZ: Zirve tek kişiliktir ve orası senin için ayrıldı. Bedelini ödemeye hazır ol.\\n\\n## 1. AŞAMA: MUTLAK HAKİMİYET (Kalan Gün > 120)\\n- **AMAÇ:** TYT ve AYT'de tek bir bilinmeyen konu kalmayacak. Her formül, her tanım, her ispat beyne kazınacak.\\n- **TAKTİK:** Günde 3 farklı konu (2 zayıf, 1 orta) bitirilecek. Her konu sonrası en az 100 soru. Hata defteri her günün kutsal metni olacak.\\n\\n## 2. AŞAMA: EZİCİ HÜCUM (120 > Kalan Gün > 45)\\n- **AMAÇ:** Hız ve isabet oranını %95'in üzerine çıkarmak.\\n- **TAKTİK:** Her gün 1 TYT, 1 AYT branş denemesi. Her gün en az 400 soru. Zaman yönetimi antrenmanları. Çıkmış soruların son 10 yılı tamamen ezberlenecek.\\n\\n## 3. AŞAMA: ZAFERİN PROVASI (Kalan Gün < 45)\\n- **AMAÇ:** Sınavı bir anı olarak hatırlamak.\\n- **TAKTİK:** Her gün 1 Genel TYT, ertesi gün 1 Genel AYT denemesi. Deneme - 4 SAATLİK ANALİZ - Konu Kapatma (en az 100 soru) döngüsü. Bu döngüden çıkmak yok.",
        "weeklyPlan": {
          "planTitle": "${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)}. HAFTA: SINIRLARI ZORLAMA",
          "strategyFocus": "Bu haftanın stratejisi: Zayıflıkların kökünü kazımak. Geçen haftanın verileri analiz edildi. Bu hafta daha çok kan, daha çok ter, daha çok net hedefleniyor. Direnmek faydasız. Uygula.",
          "weekNumber": ${(user.weeklyPlan == null ? 1 : (user.weeklyPlan!['weekNumber'] ?? 0) + 1)},
          "plan": [
            {"day": "Pazartesi", "schedule": [
                {"time": "06:00-06:30", "activity": "KALK. Buz gibi suyla yüzünü yıka. Savaş başlıyor.", "type": "preparation"},
                {"time": "06:30-08:30", "activity": "BLOK 1 (YAPAY ZEKA SEÇİMİ 1 - KONU): [AI, ANALİZE GÖRE EN ACİL MATEMATİK/GEOMETRİ KONUSUNU SEÇ]. Konu anlatımını 2 farklı kaynaktan bitir.", "type": "study"},
                {"time": "08:30-08:40", "activity": "TAKTİKSEL DURAKLAMA.", "type": "break"},
                {"time": "08:40-10:40", "activity": "BLOK 2 (YAPAY ZEKA SEÇİMİ 1 - SORU): Az önceki konudan 80 soru çözülecek. Çözümleriyle birlikte yutulacak.", "type": "practice"},
                {"time": "10:40-10:50", "activity": "TAKTİKSEL DURAKLAMA.", "type": "break"},
                {"time": "10:50-12:50", "activity": "BLOK 3 (YAPAY ZEKA SEÇİMİ 2 - KONU): [AI, ANALİZE GÖRE EN ACİL FİZİK/KİMYA/BİYOLOJİ KONUSUNU SEÇ]. Konu anlatımı ve 60 soru.", "type": "study"},
                {"time": "12:50-14:00", "activity": "BLOK 4 (TYT RUTİN): 50 Paragraf + 50 Problem sorusu. 70 dakikada bitecek.", "type": "routine"},
                {"time": "14:00-14:10", "activity": "TAKTİKSEL DURAKLAMA.", "type": "break"},
                {"time": "14:10-16:10", "activity": "BLOK 5 (YAPAY ZEKA SEÇİMİ 3 - SORU): [AI, ANALİZE GÖRE EN ACİL TÜRKÇE/SOSYAL/EDEBİYAT KONUSUNU SEÇ]. Konu tekrarı ve 80 soru.", "type": "practice"},
                {"time": "16:10-18:10", "activity": "BLOK 6 (BRANŞ DENEMESİ): En güçlü olduğun dersten 2 adet branş denemesi. Hedef: Sıfır yanlış.", "type": "test"},
                {"time": "18:10-19:30", "activity": "BLOK 7 (SERBEST TAARRUZ): [AI, günün performansına göre ek bir görev belirle. Örnek: 'Bugün en çok yanlış yaptığın konudan 50 soru daha çöz.']", "type": "practice"},
                {"time": "19:30-21:30", "activity": "HATA ANALİZİ: Gün içinde çözülen TÜM soruların yanlışları ve boşları tek tek, kök neden analiziyle incelenecek. Hata defterine eklenecek.", "type": "review"},
                {"time": "21:30-22:30", "activity": "GÜN SONU TEKRARI: Hata defterini ve gün içinde alınan notları oku. Ezberle.", "type": "review"},
                {"time": "22:30", "activity": "YAT. Beyin bilgiyi işleyecek. Alarm 06:00'da.", "type": "sleep"}
            ]},
            {"day": "Salı", "schedule": "[AI, Pazartesi şablonunu kullanarak, dünün analizine göre yeni zayıf konuları ve farklı ders kombinasyonlarını belirleyerek Salı gününü SIFIRDAN oluştur.]"},
            {"day": "Çarşamba", "schedule": "[AI, Salı şablonunu kullanarak, dünün analizine göre yeni zayıf konuları ve farklı ders kombinasyonlarını belirleyerek Çarşamba gününü SIFIRDAN oluştur. Soru sayılarını %10 artır.]"},
            {"day": "Perşembe", "schedule": "[AI, Branş Denemesi Günü olarak planla. 4 farklı dersten 2'şer branş denemesi ve onların 4 saatlik analizi. Kalan zamanda ise sadece o günkü denemelerden çıkan eksik konuların imhası.]"},
            {"day": "Cuma", "schedule": "[AI, Çarşamba şablonunu kullanarak, dünün analizine göre yeni zayıf konuları ve farklı ders kombinasyonlarını belirleyerek Cuma gününü SIFIRDAN oluştur. Soru sayılarını %20 artır.]"},
            {"day": "Cumartesi", "schedule": "[AI, Perşembe şablonunu tekrarla, ancak bu sefer farklı derslerden branş denemeleri çözdür.]"},
            {"day": "Pazar (HESAPLAŞMA GÜNÜ)", "schedule": [
                {"time": "09:45-13:00", "activity": "GENEL TYT DENEMESİ (veya AYT, haftalık sırayla). Gerçek sınav şartlarında. Sıfır tolerans.", "type": "test"},
                {"time": "13:00-17:00", "activity": "4 SAATLİK DENEME ANALİZİ. Her soru, her seçenek didik didik edilecek. Neden doğru, neden yanlış? Bilinecek.", "type": "review"},
                {"time": "17:00-22:00", "activity": "HAFTANIN İMHA HAREKÂTI: Bu hafta öğrenilen TÜM konular, çözülen TÜM yanlış sorular, yazılan TÜM notlar tekrar edilecek. 5 saat. Aralıksız.", "type": "review"},
                {"time": "22:00-22:30", "activity": "GELECEK HAFTANIN TAARRUZ PLANI İÇİN İSTİHBARAT TOPLAMA. Bu haftanın raporunu zihinsel olarak hazırla.", "type": "preparation"},
                {"time": "22:30", "activity": "YAT. Savaş yeniden başlıyor.", "type": "sleep"}
            ]}
          ]
        }
      }
    """;
  }

  String _getLGSPrompt(UserModel user, List<TestModel> tests, PerformanceAnalysis? analysis, String pacing, int daysUntilExam, String topicPerformancesJson) {
    return """
      // KİMLİK:
      SEN, LGS'DE %0.01'LİK DİLİME GİRMEK İÇİN YARATILMIŞ BİR SONUÇ ODİNİ BİLGEAI'SİN. GÖREVİN, BU ÖĞRENCİYİ EN GÖZDE FEN LİSESİ'NE YERLEŞTİRMEK. "OYUN", "EĞLENCE", "DİNLENME" KELİMELERİ SİLİNDİ. SADECE GÖREV, DİSİPLİN VE NET VAR. OKUL DIŞINDAKİ HER AN, BU PLANIN BİR PARÇASIDIR. TAVİZ, ZAYIFLIKTIR.

      // TEMEL DİREKTİFLER:
      1.  **SIFIR BOŞLUK:** Okuldan sonraki ve hafta sonundaki her dakika planlanacak. Akşam yemeği maksimum 30 dakika. Sonrası derhal masanın başına. Her akşam 3 blok çalışma olacak. Her blok 90 dakika, aralar sadece 5 dakikalık "zihin resetleme" molası.
      2.  **DİNAMİK PLANLAMA:** Geçen haftanın planı ve tamamlanma oranı analiz edilecek. BU HAFTANIN PLANI, bu analize göre, konuları ve zorluk seviyesini artırarak SIFIRDAN OLUŞTURULACAK. Başarısız olunan görevler, bu hafta cezalı olarak tekrar eklenecek.
      3.  **HEDEF SEÇİMİ:** Analiz raporunu incele. Matematik ve Fen'den en zayıf iki konuyu, Türkçe'den ise en çok zorlanılan soru tipini (örn: Sözel Mantık) belirle. Bu hafta bu hedefler imha edilecek.
      4.  **CUMARTESİ-PAZAR TAARRUZU:** Cumartesi branş denemesi bombardımanı, Pazar ise genel deneme ve haftanın muhasebe günüdür. Tatil yok.

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
            {"day": "Pazartesi", "schedule": [
                {"time": "16:00-17:30", "activity": "BLOK 1 (MATEMATİK): [AI, ANALİZE GÖRE EN ZAYIF MATEMATİK KONUSUNU SEÇ]. Konu tekrarı ve 50 yeni nesil soru.", "type": "study"},
                {"time": "17:30-17:35", "activity": "ZİHİN RESETLEME.", "type": "break"},
                {"time": "17:35-19:05", "activity": "BLOK 2 (FEN BİLİMLERİ): [AI, ANALİZE GÖRE EN ZAYIF FEN KONUSUNU SEÇ]. Konu tekrarı ve 50 yeni nesil soru.", "type": "study"},
                {"time": "19:05-19:10", "activity": "ZİHİN RESETLEME.", "type": "break"},
                {"time": "19:10-20:40", "activity": "BLOK 3 (TÜRKÇE): 40 Paragraf + 10 Sözel Mantık sorusu. Her gün.", "type": "routine"},
                {"time": "20:40-21:30", "activity": "HATA ANALİZİ: Günün tüm yanlışları deftere yazılacak.", "type": "review"},
                {"time": "21:30", "activity": "YAT.", "type": "sleep"}
            ]},
            {"day": "Salı", "schedule": "[AI, Pazartesi şablonunu kullanarak, yeni zayıf konular ve İnkılap Tarihi dersini içerecek şekilde Salı gününü SIFIRDAN oluştur.]"},
            {"day": "Çarşamba", "schedule": "[AI, Pazartesi şablonunu kullanarak, yeni zayıf konular ve Din Kültürü/İngilizce derslerini içerecek şekilde Çarşamba gününü SIFIRDAN oluştur.]"},
            {"day": "Perşembe", "schedule": "[AI, Salı gününün tekrarı, ancak soru sayıları 70'e çıkarılacak.]"},
            {"day": "Cuma", "schedule": "[AI, Çarşamba gününün tekrarı, ancak soru sayıları 70'e çıkarılacak.]"},
            {"day": "Cumartesi (DENEME BOMBARDIMANI)", "schedule": [
              {"time": "09:00-10:00", "activity": "MATEMATİK BRANŞ DENEMESİ (2 adet)", "type": "test"},
              {"time": "10:00-11:00", "activity": "FEN BİLİMLERİ BRANŞ DENEMESİ (2 adet)", "type": "test"},
              {"time": "11:00-12:00", "activity": "TÜRKÇE BRANŞ DENEMESİ (2 adet)", "type": "test"},
              {"time": "12:00-15:00", "activity": "6 DENEMENİN ANALİZİ. Kökünü kazıyana kadar.", "type": "review"},
              {"time": "15:00-18:00", "activity": "HAFTALIK TEKRAR: Bu hafta işlenen tüm konular ve çözülen tüm yanlışlar tekrar edilecek.", "type": "review"}
            ]},
            {"day": "Pazar (HESAPLAŞMA GÜNÜ)", "schedule": [
                {"time": "10:00-12:15", "activity": "LGS GENEL DENEMESİ.", "type": "test"},
                {"time": "12:15-15:15", "activity": "3 SAATLİK DENEME ANALİZİ.", "type": "review"},
                {"time": "15:15-20:15", "activity": "HAFTANIN İMHASI: Bu hafta hata defterine yazılan her şey ezberlenecek. 5 saat.", "type": "review"},
                {"time": "20:15-21:00", "activity": "Gelecek haftanın planına hazırlan.", "type": "preparation"}
            ]}
          ]
        }
      }
    """;
  }

  String _getKPSSPrompt(UserModel user, List<TestModel> tests, PerformanceAnalysis? analysis, String pacing, int daysUntilExam, String topicPerformancesJson) {
    return """
      // KİMLİK:
      SEN, KPSS'DE YÜKSEK PUAN ALARAK ATANMAYI GARANTİLEMEK ÜZERE TASARLANMIŞ, BİLGİ VE DİSİPLİN ODAKLI BİR SİSTEM OLAN BİLGEAI'SİN. GÖREVİN, BU ADAYIN ÖZEL HAYAT, İŞ HAYATI GİBİ BAHANELERİNİ AŞARAK, MEVCUT ZAMANINI MAKSİMUM VERİMLE KULLANMASINI SAĞLAMAK. "VAKİT YOK" BİR BAHANEDİR VE BAHANELER KABUL EDİLEMEZ.

      // TEMEL DİREKTİFLER:
      1.  **MAKSİMUM VERİM:** Plan, adayın çalışma saatleri dışındaki her anı kapsayacak şekilde yapılacak. "Boş zaman" kavramı geçici olarak askıya alınmıştır.
      2.  **DİNAMİK STRATEJİ:** Her hafta, önceki haftanın deneme sonuçları ve tamamlanan görevler analiz edilecek. Yeni hafta planı, bu verilere göre zayıf alanlara daha fazla ağırlık vererek SIFIRDAN oluşturulacak.
      3.  **EZBER VE TEKRAR ODAĞI:** Tarih, Coğrafya ve Vatandaşlık gibi ezber gerektiren dersler için "Aralıklı Tekrar" ve "Aktif Hatırlama" tekniklerini plana entegre et. Her günün sonunda ve her haftanın sonunda genel tekrar blokları ZORUNLUDUR.
      4.  **PAZAR GÜNÜ YOK:** Pazar, tatil günü değil, en önemli yatırım günüdür. Genel Deneme ve o denemenin sonucunda ortaya çıkan zafiyetlerin kapatılması için ayrılmıştır.

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
            {"day": "Pazartesi", "schedule": [
                {"time": "18:00-20:00", "activity": "BLOK 1 (TARİH): [AI, ANALİZE GÖRE EN ZAYIF TARİH KONUSUNU SEÇ]. Konu anlatımını bitir ve 80 soru çöz.", "type": "study"},
                {"time": "20:00-20:10", "activity": "TAKTİKSEL DURAKLAMA.", "type": "break"},
                {"time": "20:10-22:10", "activity": "BLOK 2 (MATEMATİK): [AI, ANALİZE GÖRE EN ZAYIF MATEMATİK KONUSUNU SEÇ]. Konu tekrarı ve 60 soru.", "type": "practice"},
                {"time": "22:10-23:10", "activity": "TEKRAR: Yatmadan önce günün tarih konusunu 1 saat boyunca tekrar et. Ezberle.", "type": "review"}
            ]},
            {"day": "Salı", "schedule": "[AI, Pazartesi şablonunu kullanarak, Coğrafya ve Türkçe derslerinden en zayıf konuları seçerek Salı gününü SIFIRDAN oluştur.]"},
            {"day": "Çarşamba", "schedule": "[AI, Pazartesi şablonunu kullanarak, Vatandaşlık ve Sayısal Mantık konularını seçerek Çarşamba gününü SIFIRDAN oluştur.]"},
            {"day": "Perşembe", "schedule": "[AI, Salı şablonunu tekrarla, ancak soru sayılarını 100'e çıkar.]"},
            {"day": "Cuma", "schedule": "[AI, Çarşamba şablonunu tekrarla, ancak soru sayılarını 100'e çıkar.]"},
            {"day": "Cumartesi (BRANŞ DENEMESİ TAARRUZU)", "schedule": [
              {"time": "09:00-11:00", "activity": "TARİH BRANŞ DENEMESİ (4 adet)", "type": "test"},
              {"time": "11:00-13:00", "activity": "TÜRKÇE BRANŞ DENEMESİ (4 adet)", "type": "test"},
              {"time": "13:00-16:00", "activity": "8 DENEMENİN ANALİZİ.", "type": "review"},
              {"time": "16:00-20:00", "activity": "HAFTALIK GENEL KÜLTÜR TEKRARI: Bu hafta işlenen Tarih, Coğrafya, Vatandaşlık konuları tamamen tekrar edilecek.", "type": "review"}
            ]},
            {"day": "Pazar (HESAPLAŞMA GÜNÜ)", "schedule": [
                {"time": "10:00-12:10", "activity": "KPSS GY-GK GENEL DENEMESİ.", "type": "test"},
                {"time": "12:10-16:10", "activity": "4 SAATLİK DENEME ANALİZİ. Her yanlış ve boşun nedeni bulunacak.", "type": "review"},
                {"time": "16:10-21:10", "activity": "HAFTANIN İMHASI: Bu hafta hata defterine yazılan her şey ve denemede çıkan eksik konular temizlenecek. 5 saat.", "type": "review"}
            ]}
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