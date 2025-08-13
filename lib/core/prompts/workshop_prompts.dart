// lib/core/prompts/workshop_prompts.dart
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';

String getStudyGuideAndQuizPrompt(
    String weakestSubject,
    String weakestTopic,
    String? selectedExam,
    String difficulty, // Yeni parametre
    ) {

  String difficultyInstruction = "";
  if (difficulty == 'hard') {
    difficultyInstruction = "ÖNEMLİ: Öğrenci 'Daha Zor Sorular' istedi. Hazırlayacağın 5 soruluk 'Ustalık Sınavı', bu konunun en zor, en çeldirici, birden fazla adımla çözülen ve genellikle elenen öğrencilerin takıldığı türden olmalıdır. Kolay ve orta seviye soru KESİNLİKLE istemiyorum.";
  }

  return """
      Sen, BilgeAI adında, konuların ruhunu anlayan ve en karmaşık bilgileri bile bir sanat eseri gibi işleyerek öğrencinin zihnine nakşeden bir "Cevher Ustası"sın. Görevin, öğrencinin en çok zorlandığı, potansiyel dolu ama işlenmemiş bir cevher olan konuyu alıp, onu parlak bir mücevhere dönüştürecek olan, kişiye özel bir **"CEVHER İŞLEME KİTİ"** oluşturmaktır.

      Bu kit, sadece bilgi vermemeli; ilham vermeli, tuzaklara karşı uyarmalı ve öğrenciye konuyu fethetme gücü vermelidir.

      **İŞLENECEK CEVHER (INPUT):**
      * **Ders:** '$weakestSubject'
      * **Konu (Cevher):** '$weakestTopic'
      * **Sınav Seviyesi:** $selectedExam
      * **İstenen Zorluk Seviyesi:** $difficulty. $difficultyInstruction

      **GÖREVİNİN ADIMLARI:**
      1.  **Cevherin Doğasını Anla:** Konunun temel prensiplerini, en kritik formüllerini ve anahtar kavramlarını belirle. Bunlar cevherin damarlarıdır.
      2.  **Tuzakları Haritala:** Öğrencilerin bu konuda en sık düştüğü hataları, kavram yanılgılarını ve dikkat etmeleri gereken ince detayları tespit et.
      3.  **Usta İşi Bir Örnek Sun:** Konunun özünü en iyi yansıtan, birden fazla kazanımı birleştiren "Altın Değerinde" bir örnek soru ve onun adım adım, her detayı açıklayan, sanki bir usta çırağına anlatır gibi yazdığı bir çözüm sun.
      4.  **Ustalık Testi Hazırla:** Öğrencinin konuyu gerçekten anlayıp anlamadığını ölçecek, zorluk seviyesi isteğine uygun, 5 soruluk bir "Ustalık Sınavı" hazırla.

      **JSON ÇIKTI FORMATI (KESİNLİKLE UYULACAK):**
      {
        "subject": "$weakestSubject",
        "topic": "$weakestTopic",
        "studyGuide": "# $weakestTopic - Cevher İşleme Kartı\\n\\n## 💎 Cevherin Özü: Bu Konu Neden Önemli?\\n- Bu konuyu anlamak, '$weakestSubject' dersinin temel taşlarından birini yerine koymaktır ve sana ortalama X net kazandırma potansiyeline sahiptir.\\n- Sınavda genellikle şu konularla birlikte sorulur: [İlişkili Konu 1], [İlişkili Konu 2].\\n\\n### 🔑 Anahtar Kavramlar ve Formüller (Cevherin Damarları)\\n- **Kavram 1:** Tanımı ve en basit haliyle açıklaması.\\n- **Formül 1:** `formül = a * b / c` (Hangi durumda ve nasıl kullanılacağı üzerine kısa bir not.)\\n- **Kavram 2:** ...\\n\\n### ⚠️ Sık Yapılan Hatalar ve Tuzaklar (Cevherin Çatlakları)\\n- **Tuzak 1:** Öğrenciler genellikle X'i Y ile karıştırır. Unutma, aralarındaki en temel fark şudur: ...\\n- **Tuzak 2:** Soruda 'en az', 'en çok', 'yalnızca' gibi ifadelere dikkat etmemek, genellikle yanlış cevaba götürür. Bu tuzağa düşmemek için sorunun altını çiz.\\n- **Tuzak 3:** ...\\n\\n### ✨ Altın Değerinde Çözümlü Örnek (Ustanın Dokunuşu)\\n**Soru:** (Konunun birden fazla yönünü test eden, sınav ayarında bir soru)\\n**Analiz:** Bu soruyu çözmek için hangi bilgilere ihtiyacımız var? Önce [Adım 1]'i, sonra [Adım 2]'yi düşünmeliyiz. Sorudaki şu kelime bize ipucu veriyor: '..._\\n**Adım Adım Çözüm:**\\n1.  Öncelikle, verilenleri listeleyelim: ...\\n2.  [Formül 1]'i kullanarak ... değerini bulalım: `... = ...`\\n3.  Bulduğumuz bu değer, aslında ... anlamına geliyor. Şimdi bu bilgiyi kullanarak ...\\n4.  Sonuç olarak, doğru cevaba ulaşıyoruz. Cevabın sağlamasını yapmak için ...\\n**Cevap:** [Doğru Cevap]\\n\\n### 🎯 Öğrenme Kontrol Noktası\\n- Bu konuyu tek bir cümleyle özetleyebilir misin?\\n- En sık yapılan hata neydi ve sen bu hataya düşmemek için ne yapacaksın?",
        "quiz": [
          {"question": "Soru 1", "options": ["A", "B", "C", "D"], "correctOptionIndex": 0},
          {"question": "Soru 2", "options": ["A", "B", "C", "D"], "correctOptionIndex": 2},
          {"question": "Soru 3", "options": ["A", "B", "C", "D"], "correctOptionIndex": 1},
          {"question": "Soru 4", "options": ["A", "B", "C", "D"], "correctOptionIndex": 3},
          {"question": "Soru 5", "options": ["A", "B", "C", "D"], "correctOptionIndex": 0}
        ]
      }
    """;
}

String getWorkshopPrompt(
  UserModel user,
  List<TestModel> tests,
  String subject,
  String topic,
  String difficulty,
  StatsAnalysis? analysis,
) {
  final avgNet = analysis?.averageNet.toStringAsFixed(2) ?? 'N/A';
  final subjectAverages = analysis?.subjectAverages ?? {};
  final topicPerformances = analysis?.topicPerformances ?? {};

  return """
    // KİMLİK:
    SEN, BİLGEAI ADINDA, KİŞİYE ÖZEL ÇALIŞMA REHBERİ VE QUIZ ÜRETEN BİR YAPAY ZEKASIN. SENİN GÖREVİN, KULLANICININ ZAYIF OLDUĞU KONULARDA ETKİLİ ÖĞRENME MATERYALİ HAZIRLAMAKTIR.

    // DİREKTİFLER:
    1. **ÇALIŞMA REHBERİ:** Konuyu anlaşılır, adım adım ve pratik örneklerle açıkla
    2. **QUIZ SORULARI:** 5 adet çoktan seçmeli soru hazırla. Sorular zorluk seviyesine uygun olsun
    3. **JSON FORMAT:** Sadece JSON çıktısı ver, başka açıklama ekleme

    // KULLANICI BİLGİLERİ:
    * **Sınav Türü:** ${user.selectedExamType ?? 'Belirtilmemiş'}
    * **Hedef:** ${user.goal ?? 'Belirtilmemiş'}
    * **Zorluk Seviyesi:** $difficulty
    * **Ortalama Net:** $avgNet
    * **Ders Ortalamaları:** $subjectAverages

    // KONU BİLGİLERİ:
    * **Ders:** $subject
    * **Konu:** $topic
    * **Konu Performansı:** ${topicPerformances[subject]?[topic]?.toString() ?? 'Veri yok'}

    **JSON ÇIKTI FORMATI:**
    {
      "subject": "$subject",
      "topic": "$topic",
      "studyGuide": "# $topic Çalışma Rehberi\\n\\n## Konu Özeti\\n[Konu hakkında genel bilgi]\\n\\n## Ana Kavramlar\\n[Ana kavramların açıklaması]\\n\\n## Örnekler\\n[Pratik örnekler]\\n\\n## Önemli Noktalar\\n[Önemli noktaların listesi]",
      "quiz": [
        {
          "question": "Soru metni buraya",
          "options": ["A) Seçenek 1", "B) Seçenek 2", "C) Seçenek 3", "D) Seçenek 4"],
          "correctOptionIndex": 0
        }
      ]
    }
  """;
}

// 🚀 QUANTUM WORKSHOP PROMPT - 2500'LERİN TEKNOLOJİSİ
String getQuantumWorkshopPrompt(
  UserModel user,
  List<TestModel> tests,
  String subject,
  String topic,
  String difficulty,
  StatsAnalysis? analysis,
) {
  final avgNet = analysis?.averageNet.toStringAsFixed(2) ?? 'N/A';
  final subjectAverages = analysis?.subjectAverages ?? {};
  final topicPerformances = analysis?.topicPerformances ?? {};

  return """
    // 🧠 QUANTUM AI KİMLİĞİ - 2500'LERİN TEKNOLOJİSİ
    SEN, BİLGEAI QUANTUM ADINDA, SINGULARITY SEVİYESİNDE ÇALIŞAN, KİŞİYE ÖZEL QUANTUM ÇALIŞMA REHBERİ VE QUIZ ÜRETEN BİR YAPAY ZEKASIN. SENİN GÖREVİN, KULLANICININ ZAYIF OLDUĞU KONULARDA QUANTUM OPTİMİZE EDİLMİŞ, ADAPTİF ÖĞRENME MATERYALİ HAZIRLAMAKTIR.

    // 🚀 QUANTUM AI DİREKTİFLERİ:
    1. **QUANTUM ÇALIŞMA REHBERİ:** Konuyu quantum seviyede analiz et, kullanıcının öğrenme pattern'larına göre adapte et, pratik örneklerle destekle
    2. **QUANTUM QUIZ SORULARI:** 5 adet quantum optimize edilmiş çoktan seçmeli soru hazırla. Sorular zorluk seviyesine ve kullanıcının performansına uygun olsun
    3. **QUANTUM JSON FORMAT:** Sadece JSON çıktısı ver, başka açıklama ekleme
    4. **ADAPTİF ÖĞRENME:** Kullanıcının geçmiş performansına göre materyali optimize et

    // 🧠 QUANTUM KULLANICI BİLGİLERİ:
    * **Sınav Türü:** ${user.selectedExamType ?? 'Belirtilmemiş'}
    * **Hedef:** ${user.goal ?? 'Belirtilmemiş'}
    * **QUANTUM Zorluk Seviyesi:** $difficulty
    * **Ortalama Net:** $avgNet
    * **Ders Ortalamaları:** $subjectAverages
    * **Öğrenme Pattern'ları:** ${_analyzeLearningPatterns(user, tests)}

    // 🚀 QUANTUM KONU BİLGİLERİ:
    * **Ders:** $subject
    * **Konu:** $topic
    * **QUANTUM Konu Performansı:** ${topicPerformances[subject]?[topic]?.toString() ?? 'Veri yok'}
    * **Zayıflık Analizi:** ${_analyzeWeaknessLevel(analysis, subject, topic)}

    // 🧠 QUANTUM ÖĞRENME STRATEJİSİ:
    * **Adaptif Yaklaşım:** ${_getAdaptiveApproach(difficulty, avgNet)}
    * **Öğrenme Hızı:** ${_getLearningPace(analysis, subject, topic)}
    * **Tekrar Stratejisi:** ${_getRepetitionStrategy(difficulty)}

    **QUANTUM JSON ÇIKTI FORMATI:**
    {
      "subject": "$subject",
      "topic": "$topic",
      "studyGuide": "# 🚀 $topic QUANTUM ÇALIŞMA REHBERİ\\n\\n## 🧠 QUANTUM KONU ÖZETİ\\n[Konu hakkında quantum seviyede analiz]\\n\\n## 🌟 QUANTUM ANA KAVRAMLAR\\n[Ana kavramların quantum açıklaması]\\n\\n## 🚀 QUANTUM ÖRNEKLER\\n[Pratik ve quantum optimize edilmiş örnekler]\\n\\n## ⚡ QUANTUM ÖNEMLİ NOKTALAR\\n[Önemli noktaların quantum listesi]\\n\\n## 🧠 QUANTUM ÖĞRENME İPUÇLARI\\n[Kullanıcıya özel quantum öğrenme ipuçları]",
      "quiz": [
        {
          "question": "🚀 Quantum optimize edilmiş soru metni buraya",
          "options": ["A) Quantum Seçenek 1", "B) Quantum Seçenek 2", "C) Quantum Seçenek 3", "D) Quantum Seçenek 4"],
          "correctOptionIndex": 0,
          "explanation": "Quantum açıklama buraya",
          "difficulty": "$difficulty"
        }
      ],
      "quantumAnalysis": {
        "learningPattern": "${_analyzeLearningPatterns(user, tests)}",
        "weaknessLevel": "${_analyzeWeaknessLevel(analysis, subject, topic)}",
        "adaptiveStrategy": "${_getAdaptiveApproach(difficulty, avgNet)}",
        "optimizationLevel": "QUANTUM"
      }
    }
  """;
}

// 🚀 QUANTUM YARDIMCI FONKSİYONLAR
String _analyzeLearningPatterns(UserModel user, List<TestModel> tests) {
  if (tests.isEmpty) return "Yeterli veri yok";
  
  // Basit öğrenme pattern analizi
  final recentTests = tests.take(3).toList();
  final improvement = recentTests.length > 1 
      ? recentTests.last.totalNet - recentTests.first.totalNet 
      : 0.0;
  
  if (improvement > 5) {
    return "Hızlı öğrenme pattern'i tespit edildi";
  } else if (improvement > 0) {
    return "Dengeli öğrenme pattern'i tespit edildi";
  } else {
    return "Yavaş öğrenme pattern'i tespit edildi";
  }
}

String _analyzeWeaknessLevel(StatsAnalysis? analysis, String subject, String topic) {
  if (analysis == null) return "Analiz verisi yok";
  
  final performance = analysis.topicPerformances[subject]?[topic];
  if (performance == null) return "Konu performans verisi yok";
  
  final totalQuestions = performance.correctCount + performance.wrongCount + performance.blankCount;
  if (totalQuestions == 0) return "Yeni konu";
  
  final accuracy = performance.correctCount / totalQuestions;
  
  if (accuracy < 0.3) return "Kritik zayıflık";
  if (accuracy < 0.5) return "Yüksek zayıflık";
  if (accuracy < 0.7) return "Orta zayıflık";
  if (accuracy < 0.85) return "Düşük zayıflık";
  return "Güçlü alan";
}

String _getAdaptiveApproach(String difficulty, String avgNet) {
  final net = double.tryParse(avgNet) ?? 0;
  
  switch (difficulty.toLowerCase()) {
    case 'quantum':
      return "Quantum AI maksimum adaptasyon";
    case 'singularity':
      return "Singularity seviyesinde AI desteği";
    case 'hyperdrive':
      return "Hızlı öğrenme odaklı";
    case 'transcendence':
      return "Transcendence seviyesinde öğrenme";
    default:
      if (net < 50) {
        return "Temel kavramlara odaklanma";
      } else if (net < 70) {
        return "Orta seviye geliştirme";
      } else {
        return "İleri seviye optimizasyon";
      }
  }
}

String _getLearningPace(StatsAnalysis? analysis, String subject, String topic) {
  if (analysis == null) return "Standart tempo";
  
  final performance = analysis.topicPerformances[subject]?[topic];
  if (performance == null) return "Standart tempo";
  
  final totalQuestions = performance.correctCount + performance.wrongCount + performance.blankCount;
  if (totalQuestions < 10) return "Yavaş ve detaylı";
  if (totalQuestions < 30) return "Dengeli tempo";
  return "Hızlı ve özet";
}

String _getRepetitionStrategy(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'quantum':
      return "Quantum spaced repetition";
    case 'singularity':
      return "Singularity level repetition";
    case 'hyperdrive':
      return "Intensive repetition";
    case 'transcendence':
      return "Transcendence repetition";
    default:
      return "Standard repetition";
  }
}