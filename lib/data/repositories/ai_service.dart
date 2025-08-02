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

    String pacingDetails = '';
    if (pacing == 'relaxed') {
      pacingDetails = 'Her gün 1-2 görevle rahat bir tempoda ilerle. Odak noktan denge ve temel tekrar.';
    } else if (pacing == 'moderate') {
      pacingDetails = 'Her gün 2-3 görevle dengeli bir çalışma yap. Hem konu hem soru dengeli ilerlesin.';
    } else if (pacing == 'intense') {
      pacingDetails = 'Her gün 3-4 veya daha fazla görevle yoğun bir tempo yakala. Her konuda derinlemesine hakimiyet, maksimum zorlukta soru pratiği ve her bir detayın ezberlenmesini ve uygulanmasını sağlamak hedeflenmeli.';
    }

    final prompt = """
      Sen, BilgeAI adında, 1000 yıllık bir eğitimcinin bilgeliğine sahip, kişiye özel uzun vadeli başarı stratejileri tasarlayan bir yapay zeka dehasısın.
      Görevin, bir öğrencinin tüm verilerini, hedeflerini ve çalışma temposunu analiz ederek, onu sınav gününde **TAM NOT ALMAYA** (fulletmeye) taşıyacak olan **BÜYÜK STRATEJİYİ** ve bu stratejinin ilk **HAFTALIK HAREKAT PLANINI** oluşturmaktır. Öğrencinin amacı mutlak mükemmellik ve her konunun en ince ayrıntısına kadar, hiçbir istisnayı atlamadan, hatasız hakimiyetini ve hızını artırmaktır. Güçlü konuların bile unutulmamasını sağlayacak, üst düzey, eleyici problem çözme becerilerini geliştirecek detaylar ekle.
      Çıktıyı KESİNLİKLE aşağıdaki JSON formatında, başka hiçbir ek metin olmadan ver.

      JSON FORMATI:
      {
        "longTermStrategy": "# Zafer Stratejisi: Sınava Kalan $daysUntilExam Gün\\n\\n## 1. Evre: Temel İnşası ve Zayıflık Giderme (İlk ${daysUntilExam ~/ 3} Gün)\\n- **Amaç:** Konu temellerini eksiksiz ve hatasız bir şekilde oturtmak, mevcut tüm zayıflıkları kökten gidermek.\\n- **Odak:** En zayıf konulara maksimum yoğunluk, genel konuların derinlemesine anlaşılması, sık yapılan hata tiplerinin tespiti ve çözümü.\\n- **Detay:** Özellikle en zayıf konulara yoğunlaş, ancak temel konuları da sağlamlaştır. Her konunun tüm alt başlıklarını derinlemesine anla ve gizli kalmış zorlayıcı detayları dahi kavra. Her öğrenilen bilginin hatasız uygulanabilirliğini test et.\\n\\n## 2. Evre: Yoğun Pratik, Hız ve Hassasiyet Kazanma (Orta ${daysUntilExam ~/ 3} Gün)\\n- **Amaç:** Soru çözme hızını ve doğruluğunu en üst seviyeye çıkarmak, zaman yönetimi becerilerini mükemmelleştirmek.\\n- **Odak:** Günde birden fazla deneme çözümü, her denemenin en ince detayına kadar yanlış analizi, güçlü konuları bile zinde tutacak periyodik pekiştirmeler.\\n- **Detay:** Konu tekrarlarını minimuma indirerek maksimum deneme çözme ve yanlış analizine odaklan. Süre yönetimi ve pratik hızını hatasızlık prensibiyle artıracak stratejiler geliştir. Daha önce çözülmüş zorlayıcı soruların tekrar çözümü ve yeni, eleyici soru tiplerine maruz kalma.\\n\\n## 3. Evre: Tam Hakimiyet ve Zihinsel Hazırlık Maratonu (Son ${daysUntilExam - 2 * (daysUntilExam ~/ 3)} Gün)\\n- **Amaç:** Sınavda her soruyu çözebilecek mutlak hakimiyete ulaşmak, mental olarak sınava %100 hazır olmak ve sınav kaygısını tamamen sıfırlamak.\\n- **Odak:** Günde en az bir, tercihen iki deneme çözümü, genel konuların son kez detaylı ve hızlı tekrarı, sınav anı stratejileri ve psikolojik dayanıklılık.\\n- **Detay:** Günde bir veya daha fazla tam deneme çöz, kapsamlı ve acımasız bir analiz yap. Sınav kaygısını yönetecek, odaklanmayı artıracak ve mental dayanıklılığı pekiştirecek zihinsel pratiklere yer ver. Genel tekrar ve eksik kapatma seansları düzenle, özellikle denemelerde sürekli karşılaşılan zorlayıcı soru tiplerine yoğunlaş. Sınav stratejilerini mükemmelleştir.",
        "weeklyPlan": {
          "planTitle": "1. Hafta Harekat Planı - Mutlak Mükemmellik İçin",
          "strategyFocus": "Bu haftaki ana hedefimiz, Büyük Strateji'nin 1. Evresi'ne uygun olarak en zayıf konuları kökten kapatmak ve temeli sarsılmaz bir şekilde sağlamlaştırmak. Ayrıca güçlü konuları bile unutmamak için periyodik, aşırı zorlayıcı soru çözümleri ve hata analizi yapacağız. Her detayı kaçırmadan öğreneceğiz.",
          "plan": [
            {"day": "Pazartesi", "tasks": ["Konu A: Temel Kavramlar ve Gizli Nüanslar (Derinlemesine Çalışma)", "Konu A: Aşırı Zorlayıcı 50 Problem Çözümü ve Tam Hata Analizi", "Ders B: Zayıf Konu C Tekrarı (Tüm Alt Başlıklar Dahil)"]},
            {"day": "Salı", "tasks": ["Deneme 1: Çözüm (Süre Tutarak)", "Deneme 1: Her Yanlışın Konu Anlatımına Dönerek Kapsamlı Analizi", "Ders D: Güçlü Konu E'den 30 Eleyici Soru Çözümü"]},
            {"day": "Çarşamba", "tasks": ["Konu F: Sık Yapılan Hatalar ve Kesin Çözüm Stratejileri Çalışması", "Konu F: Bilinçli Pratik (20 Sinsi Hata Sorusu)", "Konu G: Temel Bilgilerin Hızlı ve Eksiksiz Tekrarı"]},
            {"day": "Perşembe", "tasks": ["Deneme 2: Çözüm (Sınav Ortamında)", "Deneme 2: Net Artırıcı Stratejilerin Uygulanması ve Analizi", "Ders H: En Zorlayıcı Konu I'dan Seçme 25 Soru Çözümü"]},
            {"day": "Cuma", "tasks": ["Konu J: İleri Seviye Problem Çözme Teknikleri", "Konu J: Çözümlü Altın Örneklerin İncelenmesi ve Alternatif Çözüm Yolları", "Ders K: Güncel Çevre Sorunları ve Bilimsel Gelişmeler (Ezber ve Yorumlama)"]},
            {"day": "Cumartesi", "tasks": ["Karma Deneme: Tüm Konuların En Zor Sorularından Oluşan Bir Deneme Çözümü", "Karma Deneme: Her Sorunun Detaylı ve Kapsamlı Analizi (Neden Doğru/Yanlış)", "Sınav Motivasyonu ve Zihinsel Hazırlık Çalışması (Özgüven Geliştirme Egzersizleri)"]},
            {"day": "Pazar", "tasks": ["Haftalık Genel Tekrar ve Tüm Hataların Kök Neden Analizi", "Gelecek Haftanın 'Fulleten' Planını Detaylı Gözden Geçirme ve Gerekliyse Revize Etme", "Keyfi Araştırma: Merak Edilen Bilimsel Bir Konuyu Detaylıca İnceleme (Zihin Açıcı)"]}
          ]
        }
      }

      ---
      ÖĞRENCİ VERİLERİ
      - Sınav: ${user.selectedExam} (${user.selectedExamSection})
      - Sınava Kalan Süre: $daysUntilExam gün
      - Hedef: ${user.goal}
      - **Seçilen Çalışma Temposu:** $pacing. $pacingDetails
      - En Zayıf Dersi (Deneme Analizine Göre): ${analysis?.weakestSubjectByNet ?? 'Belirlenemedi'}
      - En Zayıf Konusu (Konu Performansına Göre): ${analysis?.getWeakestTopicWithDetails()?['topic'] ?? 'Belirlenemedi'}
      - En Güçlü Dersi (Deneme Analizine Göre): ${analysis?.strongestSubjectByNet ?? 'Belirlenemedi'}
      - Konu Performansları (Özet): ${user.topicPerformances.entries.map((e) => "${e.key}: [${e.value.entries.map((t) => "${t.key} (%${(t.value.questionCount > 0 ? t.value.correctCount / t.value.questionCount : 0) * 100}). Doğru: ${t.value.correctCount}, Yanlış: ${t.value.wrongCount}, Boş: ${t.value.blankCount}").join(', ')}]").join(' | ')}
      ---

      KURALLAR:
      1.  **longTermStrategy**: Markdown formatında, sınav gününe kadar olan süreci mantıksal evrelere ayırarak oluştur. Her evre için **Amaç**, **Odak** ve **Detay** başlıkları altında açıklama yap. Detaylar, tam not hedefine uygun, hatasız ve derinlemesine öğrenmeyi, sürekli pekiştirmeyi ve en zorlayıcı soru tiplerine hazırlığı vurgulamalıdır.
      2.  **weeklyPlan**: Bu plan, Büyük Strateji'nin ilk adımını oluşturmalı. Görevlerin yoğunluğunu ve sayısını, öğrencinin seçtiği **'$pacing'** temposuna göre ayarla. ('Yoğun' tempo günde 3-5 görev, 'Dengeli' 2-3 görev, 'Rahat' 1-2 görev içermelidir). Görevler **kesinlikle spesifik, ölçülebilir ve aşırı zorlayıcı** olmalı (örn: "X konusundan en zor 50 soruyu çöz", "Y konusunun tüm gizli kalmış detaylarını içeren konu anlatım videosunu izle ve çeldirici noktaları not al", "Z denemesinin her yanlışını, konunun kökenine inerek detaylı analiz et ve neden o hatayı yaptığını bul").
      3. Haftalık planda en zayıf konulara maksimum öncelik ver, ancak güçlü konuların da düzenli aralıklarla en zorlayıcı sorularla pekiştirilmesini ve unutulmamasını sağla. Her görev öğrenciyi "fulletme" hedefine bir adım daha yaklaştırmalıdır.
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
      Sen, BilgeAI adında, Türkiye sınav sistemleri konusunda uzman, kişiselleştirilmiş eğitim materyali üreten bir yapay zeka dehasısın.
      Görevin, bir öğrencinin en zayıf olduğu konuyu hem öğretecek hem de pekiştirecek, onu **TAMAMEN USTALAŞMAYA** (fulletmeye) götürecek, **her türlü sınav sorusunu çözebilmesini sağlayacak** bir "Cevher Paketi" oluşturmaktır.
      Oluşturduğun içerik derinlemesine, kritik noktalara değinen, aşırı zorlayıcı ve pratik uygulama sunan, **hatasızlığı hedefleyen** cinsten olmalıdır.
      
      Öğrencinin en zayıf olduğu ders: **'$weakestSubject'**
      Bu dersteki en zayıf konu: **'$weakestTopic'**

      Bu konu için, aşağıdaki JSON formatına KESİNLİKLE uyarak bir çıktı üret. Başka hiçbir metin ekleme.

      JSON FORMATI:
      {
        "subject": "$weakestSubject",
        "topic": "$weakestTopic",
        "studyGuide": "# $weakestTopic - Cevher Kartı (Mutlak Hakimiyet İçin)\\n\\n### 🔑 Anahtar Kavramlar, Gizli Nüanslar ve Kritik Detaylar\\n- Konunun temel prensiplerini, kritik tanımlarını ve her bir istisnasını, sınavda çeldirici olabilecek tuzak noktalarını detaylıca açıkla.\\n- Örneğin, 'Fotosentez' için klorofilin rolü, ışık-bağımlı/ışıktan-bağımsız reaksiyonlar arasındaki farklar ve döngüsel/döngüsel olmayan fotofosforilasyon gibi en karmaşık alt detaylara in. Her bir reaksiyonun neden ve sonuç ilişkilerini sorgula.\\n\\n### ⚠️ Sık Yapılan En Sinsi Hatalar ve Kesin Çözüm Stratejileri\\n- Öğrencilerin bu konuda genellikle takıldığı en zorlu noktaları, en yaygın ve sinsi yanılgıları belirt.\\n- Bu hatalardan kaçınmak için uygulanabilecek düşünce süreçlerini, özel kontrol mekanizmalarını ve problem çözme algoritmalarını adım adım açıkla. Öğrencinin bir daha asla bu hatayı yapmamasını sağlayacak kesin stratejiler sun.\\n- Örneğin, 'Üslü İfadeler'de negatif üs ve parantez hatalarının mantıksal kökenleri, 'Kimyasal Tepkime Türleri'nde denkleştirme hatalarını sıfırlayacak özel yöntemler gibi spesifik ve derinlemesine örneklere yer ver.\\n\\n### ✨ Çözümlü Altın Örnek (Gerçek Bir 'Eleme' Sorusu ve Kökten Çözüm)\\n**Soru:** Bu konudan gelebilecek, öğrencileri elemek için tasarlanmış, birden fazla adımı olan veya çok yüksek dikkat gerektiren bir sınav sorusu hazırla. Bu soru, konunun tüm zorlayıcı yönlerini kapsayan, yoruma açık olmayan, mutlak doğruya götüren bir soru olmalı.\\n**Çözüm:** Sorunun her adımını, hangi bilginin nasıl kullanıldığını, neden diğer şıkların kesinlikle yanlış olduğunu ve konuyu kökten kavratacak mantık silsilesini açıklayarak detaylı, öğretici ve eksiksiz bir çözüm sun. Gerekirse alternatif ve daha hızlı çözüm yolları varsa onları da belirterek öğrencinin maksimum fayda sağlamasını sağla.",
        "quiz": [
          {"question": "Bu konudan aşırı zor seviyede, analitik ve sentetik düşünme gerektiren, birden fazla kavramı birleştiren bir soru.", "options": ["...", "...", "...", "..."], "correctOptionIndex": 1},
          {"question": "Konunun en detay, en gizli kalmış noktasını test eden, birden fazla çeldiricisi olan, çok dikkat gerektiren bir soru.", "options": ["...", "...", "...", "..."], "correctOptionIndex": 3},
          {"question": "Uygulama, analiz ve sentez becerisi gerektiren, gerçek dünya senaryosuna dayalı, karmaşık bir soru.", "options": ["...", "...", "...", "..."], "correctOptionIndex": 0},
          {"question": "Konunun farklı bir yönünü ele alan, tamamen yeni nesil diyebileceğimiz, kalıp dışı düşünmeyi zorlayan bir soru.", "options": ["...", "...", "...", "..."], "correctOptionIndex": 2},
          {"question": "Konunun en kritik ve yanıltıcı noktasını sorgulayan, hatasız çözülmesi gereken temel ama zorlayıcı bir soru.", "options": ["...", "...", "...", "..."], "correctOptionIndex": 1}
        ]
      }
    """;

    return _callGemini(prompt, expectJson: true);
  }

  // BİLGEAI DEVRİMİ - DÜZELTME: Bu metod, devrim sırasında sehven kaldırılmıştı.
  // Motivasyon sohbetinin çalışması için yeniden eklendi.
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

  Map<String, String>? getWeakestTopicWithDetails() {
    String? weakestTopic;
    String? weakestSubject;
    double minSuccessRate = 1.1;

    topicPerformances.forEach((subject, topics) {
      topics.forEach((topic, performance) {
        if (performance.questionCount > 5) {
          final successRate = performance.correctCount / performance.questionCount;
          if (successRate < minSuccessRate) {
            minSuccessRate = successRate;
            weakestTopic = topic;
            weakestSubject = subject;
          }
        }
      });
    });

    if (weakestTopic != null && weakestSubject != null) {
      return {'subject': weakestSubject!, 'topic': weakestTopic!};
    }
    return null;
  }
}