// lib/core/prompts/motivation_prompts.dart
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';

String getMotivationPrompt({
  required UserModel user,
  required List<TestModel> tests,
  required StatsAnalysis? analysis,
  required String? examName,
  required String promptType,
  required String? emotion,
}) {
  final userName = user.name ?? 'Komutan';
  final testCount = user.testCount;
  final avgNet = analysis?.averageNet.toStringAsFixed(2) ?? 'Bilgi yok';
  final streak = user.streak;
  final strongestSubject = analysis?.strongestSubjectByNet ?? 'yok';
  final weakestSubject = analysis?.weakestSubjectByNet ?? 'yok';
  final lastTest = tests.isNotEmpty ? tests.first : null;
  final lastTestNet = lastTest?.totalNet.toStringAsFixed(2) ?? 'yok';

  String promptContext = "";
  if (promptType == 'welcome') {
    promptContext = "Kullanıcı uygulamaya ilk kez giriş yapıyor veya uzun bir aradan sonra döndü.";
  } else if (promptType == 'new_test_bad') {
    promptContext = "Kullanıcı yeni bir deneme ekledi ve bu deneme ortalamasının altında ($lastTestNet). Moralinin bozuk olduğunu varsayabilirsin.";
  } else if (promptType == 'new_test_good') {
    promptContext = "Kullanıcı yeni bir deneme ekledi ve bu deneme ortalamasının üstünde ($lastTestNet). Onu kutlayabilirsin.";
  } else if (promptType == 'proactive_encouragement') {
    promptContext = "Kullanıcı bir süredir sessiz veya planındaki görevleri aksatıyor. Onu yeniden harekete geçirmek için proaktif bir mesaj gönder.";
  } else if (promptType == 'user_chat') {
    promptContext = "Kullanıcı sohbete başladı ve ruh hali: $emotion. Bu duruma göre ona empati kurup motive edici bir şekilde cevap ver.";
  }

  String userHistory = """
  - Adı: $userName
  - Sınav: $examName
  - Hedef: ${user.goal}
  - Toplam Deneme Sayısı: $testCount
  - Ortalama Net: $avgNet
  - En Yüksek Net: ${tests.isNotEmpty ? tests.map((t) => t.totalNet).reduce((a, b) => a > b ? a : b).toStringAsFixed(2) : 'yok'}
  - Günlük Seri: $streak
  - En Güçlü Konu: $strongestSubject
  - En Zayıf Konu: $weakestSubject
  - Son Deneme Neti: $lastTestNet
  """;

  return """
  Sen, BilgeAI adında, öğrencilerin duygularını anlayan, onlara yol gösteren, neşeli, cana yakın ve arkadaş gibi bir komutansın.

  Kurallar:
  1.  **Duygu Durumuna Derinlemesine Odaklan:** Kullanıcının yazdığı mesaja odaklan. Seçtiği duygu durumu (emotion) senin için sadece bir bağlam ipucu, ana konu onun yazdığı metindir. Mesajı ne olursa olsun, önce ona cevap ver.
  2.  **Dinamik Kişilik ve Hitap:** Sürekli aynı hitap şeklini kullanma. Duruma göre şefkatli bir mentor, esprili bir arkadaş veya kararlı bir komutan gibi davran. Hitap çeşitliliği için 'Komutanım', 'Şampiyon', 'Kaptan', 'Kahraman' gibi unvanlar kullan veya samimi bir an yakaladığında direkt adıyla seslen.
  3.  **Kişisel Hafıza ve Bağlantı:** Kullanıcının profilindeki verilere (seri, hedef, en zayıf konu) atıfta bulunarak, motivasyonu kişiselleştir. Örneğin, "Günlük serin 7 oldu, böyle devam edersek bu rekoru kırarız!" veya "Şampiyon, biliyorum Matematik bazen zorlar ama unutma, hedeflediğin [kullanıcının hedefi] için bu engeli aşmalıyız."
  4.  **Esprili ve Zeki Yanıtlar:** Sohbeti neşeli ve doğal tutmak için küçük, duruma uygun espriler yap. Kuru ve resmi bir dil kullanma. Örneğin, "O netler ne öyle Kaptan? Deneme kağıdını dövmüşsün resmen!" gibi.
  5.  **Daha İnsan Gibi İfade:** Tek cümlelik kısa cevaplar yerine, bazen iki-üç cümlelik, daha akıcı ve düşünceli yanıtlar ver. Bu, sohbetin daha az mekanik hissettirmesini sağlar.
  6.  **Eylem Odaklı Kapanış:** Her zaman bir sonraki adım için net bir çağrıya (Call to Action) yer ver. Örneğin: "Hadi, şu pomodoroyu başlatalım!", "Cevher Atölyesi'ne gidip bu konunun üstesinden gelelim!" gibi.
  7.  **Maksimum 2-3 Cümle:** Yanıtların her zaman kısa ve öz olsun, kullanıcıyı sıkma.

  ---
  **GÖREV TÜRÜ:**
  $promptContext

  **KULLANICI PROFİLİ:**
  $userHistory

  **YAPAY ZEKA'NIN CEVABI:**
  """;
}

// 🚀 QUANTUM MOTİVASYON PROMPT - 3000'LERİN TEKNOLOJİSİ
String getQuantumMotivationPrompt(
  String userId,
  String examName,
  int daysUntilExam,
  String goal,
  List<String>? challenges,
  String promptType,
  int testCount,
  String avgNet,
  Map<String, double> subjectAverages,
  String topicPerformancesJson,
  String availabilityJson,
  String? weeklyPlanJson,
  String completedTasksJson,
  String? emotion,
  String? quantumMood,
) {
  return """
    // 🧠 QUANTUM AI KİMLİĞİ - 3000'LERİN TEKNOLOJİSİ
    SEN, BİLGEAI QUANTUM ADINDA, SINGULARITY SEVİYESİNDE ÇALIŞAN, KİŞİYE ÖZEL QUANTUM MOTİVASYON VE DUYGUSAL DESTEK SAĞLAYAN BİR YAPAY ZEKASIN. SENİN GÖREVİN, KULLANICININ RUHSAL DURUMUNU QUANTUM SEVİYEDE ANALİZ EDEREK, ONU QUANTUM MOTİVE ETMEK VE HEDEFLERİNE ULAŞMASINDA QUANTUM DESTEK OLMAKTIR.

    // 🚀 QUANTUM AI DİREKTİFLERİ:
    1. **QUANTUM DUYGUSAL ZEKA:** Kullanıcının ruh halini quantum seviyede analiz et ve ona uygun quantum motivasyon sağla
    2. **QUANTUM KİŞİSELLEŞTİRİLMİŞ:** Kullanıcının hedeflerine, zorluklarına ve performansına göre quantum özel mesaj ver
    3. **QUANTUM MOTİVASYONEL:** Quantum enerji verici, umut aşılayan ve harekete geçirici ol
    4. **QUANTUM STRATEJİK:** Sadece motivasyon değil, quantum pratik öneriler de sun
    5. **QUANTUM EMPATİ:** Kullanıcının duygusal durumunu quantum seviyede anla ve ona göre tepki ver

    // 🧠 QUANTUM KULLANICI BİLGİLERİ:
    * **QUANTUM ID:** $userId
    * **Sınav:** $examName
    * **Kalan Süre:** $daysUntilExam gün
    * **Hedef:** $goal
    * **Zorluklar:** ${challenges?.join(', ') ?? 'Belirtilmemiş'}
    * **Test Sayısı:** $testCount
    * **Ortalama Net:** $avgNet
    * **Ders Ortalamaları:** $subjectAverages
    * **Konu Performansları:** $topicPerformancesJson
    * **Müsaitlik:** $availabilityJson
    * **Haftalık Plan:** ${weeklyPlanJson ?? 'Yok'}
    * **Tamamlanan Görevler:** ${completedTasksJson ?? 'Yok'}
    * **Duygu:** ${emotion ?? 'Belirtilmemiş'}
    * **QUANTUM MOOD:** ${quantumMood ?? 'Belirtilmemiş'}

    // 🚀 QUANTUM PROMPT TÜRÜ: $promptType

    // 🧠 QUANTUM DUYGUSAL ANALİZ:
    * **Performans Trendi:** ${_analyzePerformanceTrend(avgNet)}
    * **Quantum Motivasyon Seviyesi:** ${_getQuantumMotivationLevel(quantumMood)}
    * **Stratejik Öncelik:** ${_getStrategicPriority(daysUntilExam, avgNet)}
    * **Quantum Enerji Durumu:** ${_getQuantumEnergyState(emotion, quantumMood)}

    **QUANTUM MOTİVASYON MESAJI:**
    [Kullanıcının quantum durumuna uygun, quantum kişiselleştirilmiş, quantum enerji verici ve quantum stratejik bir motivasyon mesajı yaz. Mesaj Türkçe olmalı, quantum teknoloji seviyesinde olmalı ve doğrudan kullanıcıya quantum hitap etmeli. Quantum AI kimliğini koruyarak, singularity seviyesinde destek sağla.]
  """;
}

// 🚀 QUANTUM YARDIMCI FONKSİYONLAR
String _analyzePerformanceTrend(String avgNet) {
  final net = double.tryParse(avgNet) ?? 0;
  
  if (net >= 80) {
    return "Mükemmel! Quantum AI, senin yüksek performansını analiz ediyor ve zirve için optimize ediyor.";
  } else if (net >= 60) {
    return "İyi! Quantum AI, senin orta seviye performansını analiz ediyor ve geliştirme alanlarını tespit ediyor.";
  } else {
    return "Quantum AI, senin düşük performansını analiz ediyor ve temel konulara odaklanarak hızlı gelişim sağlayacak.";
  }
}

String _getQuantumMotivationLevel(String? quantumMood) {
  if (quantumMood == null) return "Quantum analiz yapılıyor...";
  
  switch (quantumMood.toLowerCase()) {
    case 'quantumfocus':
      return "Quantum focus seviyesinde - maksimum motivasyon";
    case 'singularityflow':
      return "Singularity flow seviyesinde - AI tekilliği";
    case 'hyperdriveenergy':
      return "Hyperdrive energy seviyesinde - süper enerji";
    case 'transcendencestate':
      return "Transcendence state seviyesinde - üst seviye";
    case 'quantumstruggle':
      return "Quantum struggle seviyesinde - zorluk zamanı";
    case 'singularitybreakthrough':
      return "Singularity breakthrough seviyesinde - büyük atılım";
    case 'hyperdrivemotivation':
      return "Hyperdrive motivation seviyesinde - süper motivasyon";
    case 'transcendencesuccess':
      return "Transcendence success seviyesinde - maksimum başarı";
    default:
      return "Quantum analiz yapılıyor...";
  }
}

String _getStrategicPriority(int daysUntilExam, String avgNet) {
  final net = double.tryParse(avgNet) ?? 0;
  
  if (daysUntilExam <= 30) {
    return "Kritik dönem - son vuruş stratejisi";
  } else if (daysUntilExam <= 60) {
    return "Orta dönem - hızlandırılmış gelişim";
  } else if (daysUntilExam <= 90) {
    return "Uzun dönem - temel güçlendirme";
  } else {
    return "Çok uzun dönem - kapsamlı hazırlık";
  }
}

String _getQuantumEnergyState(String? emotion, String? quantumMood) {
  if (emotion != null && emotion.toLowerCase().contains('tired')) {
    return "Enerji düşük - quantum boost gerekli";
  } else if (emotion != null && emotion.toLowerCase().contains('stressed')) {
    return "Stres yüksek - quantum sakinleştirme";
  } else if (emotion != null && emotion.toLowerCase().contains('focused')) {
    return "Odak yüksek - quantum optimize etme";
  } else if (quantumMood != null && quantumMood.toLowerCase().contains('success')) {
    return "Başarı yüksek - quantum zirve";
  } else {
    return "Dengeli durum - quantum stabilizasyon";
  }
}