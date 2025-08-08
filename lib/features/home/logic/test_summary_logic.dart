// lib/features/home/logic/test_summary_logic.dart
import 'package:bilge_ai/data/models/test_model.dart';

class TestSummaryLogic {
  final TestModel test;

  TestSummaryLogic(this.test);

  // Kullanıcının performansına göre bir "Bilgelik Puanı" hesaplar.
  double calculateWisdomScore() {
    if (test.totalQuestions == 0) return 0;

    // Netin katkısı (%60)
    double netContribution = (test.totalNet / test.totalQuestions) * 60;

    // Doğruluk oranının katkısı (%25)
    final attemptedQuestions = test.totalCorrect + test.totalWrong;
    double accuracyContribution = attemptedQuestions > 0
        ? (test.totalCorrect / attemptedQuestions) * 25
        : 0;

    // Çaba/Katılım oranının katkısı (%15)
    double effortContribution = (attemptedQuestions / test.totalQuestions) * 15;

    double totalScore = netContribution + accuracyContribution + effortContribution;
    return totalScore.clamp(0, 100);
  }

  // Puan aralığına göre uzman yorumu ve unvanı döndürür.
  Map<String, String> getExpertVerdict(double score) {
    if (score > 85) {
      return {
        "title": "Efsanevi Savaşçı",
        "verdict": "Zirvedeki yerin sarsılmaz. Bilgin bir kılıç gibi keskin, iraden ise bir zırh kadar sağlam. Bu yolda devam et, zafer seni bekliyor."
      };
    } else if (score > 70) {
      return {
        "title": "Usta Stratejist",
        "verdict": "Savaş meydanını okuyorsun. Güçlü ve zayıf yönlerini biliyorsun. Küçük gedikleri kapatarak yenilmez olacaksın. Potansiyelin parlıyor."
      };
    } else if (score > 50) {
      return {
        "title": "Yetenekli Savaşçı",
        "verdict": "Gücün ve cesaretin takdire şayan. Temellerin sağlam, ancak bazı hamlelerinde tereddüt var. Pratik ve odaklanma ile bu savaşı kazanacaksın."
      };
    } else if (score > 30) {
      return {
        "title": "Azimli Acemi",
        "verdict": "Her büyük savaşçı bu yoldan geçti. Kaybettiğin her mevzi, öğrendiğin yeni bir derstir. Azmin en büyük silahın, pes etme."
      };
    } else {
      return {
        "title": "Yolun Başındaki Kâşif",
        "verdict": "Unutma, en uzun yolculuklar tek bir adımla başlar. Bu ilk adımı attın. Şimdi hatalarından öğrenme ve güçlenme zamanı. Yanındayım."
      };
    }
  }

  // En güçlü ve en zayıf dersleri bulan fonksiyon
  Map<String, MapEntry<String, double>> findKeySubjects() {
    if (test.scores.isEmpty) {
      return {};
    }

    MapEntry<String, double>? strongest;
    MapEntry<String, double>? weakest;

    test.scores.forEach((subject, scoresMap) {
      final net = scoresMap['dogru']! - (scoresMap['yanlis']! * test.penaltyCoefficient);
      if (strongest == null || net > strongest!.value) {
        strongest = MapEntry(subject, net);
      }
      if (weakest == null || net < weakest!.value) {
        weakest = MapEntry(subject, net);
      }
    });

    return {
      'strongest': strongest!,
      'weakest': weakest!,
    };
  }
}