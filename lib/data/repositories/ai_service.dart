// lib/data/repositories/ai_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:bilge_ai/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/core/prompts/strategy_prompts.dart';
import 'package:bilge_ai/core/prompts/workshop_prompts.dart';
import 'package:bilge_ai/core/prompts/motivation_prompts.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';

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
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"; //kesinlikle flash modelini kullan, pro modelini istemiyorum

  Future<String> _callGemini(String prompt, {bool expectJson = false}) async {
    if (_apiKey.isEmpty || _apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      final errorJson =
          '{"error": "API Anahtarı bulunamadı. Lütfen `lib/core/config/app_config.dart` dosyasına kendi Gemini API anahtarınızı ekleyin."}';
      return expectJson ? errorJson : "**HATA:** API Anahtarı bulunamadı.";
    }

    const maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
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
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['candidates'] != null && data['candidates'][0]['content'] != null) {
            String rawResponse = data['candidates'][0]['content']['parts'][0]['text'];

            // YENİ EKLENEN AKILLI TEMİZLEYİCİ
            // Yanıtın içinde ```json ... ``` bloğu varsa sadece o bloğu al.
            final jsonMarkdownMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(rawResponse);
            if (jsonMarkdownMatch != null) {
              return jsonMarkdownMatch.group(1)!;
            }

            // Markdown bloğu yoksa, sadece { ve } arasındaki ilk ve son bloğu bulmayı dene.
            final startIndex = rawResponse.indexOf('{');
            final endIndex = rawResponse.lastIndexOf('}');
            if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
              return rawResponse.substring(startIndex, endIndex + 1);
            }

            // Hiçbiri eşleşmezse, orijinal yanıtı olduğu gibi döndür.
            return rawResponse;
          } else {
            throw Exception('Yapay zeka servisinden beklenmedik bir formatta cevap alındı.');
          }
        } else if ((response.statusCode == 503 || response.statusCode == 500) && i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: i + 2));
          continue;
        } else {
          throw Exception('Yapay zeka servisinden bir cevap alınamadı. (Kod: ${response.statusCode})');
        }
      } catch (e) {
        if (i == maxRetries - 1) {
          final errorJson = '{"error": "Yapay zeka sunucuları şu anda çok yoğun veya internet bağlantınızda bir sorun var. Lütfen birkaç dakika sonra tekrar deneyin. Detay: ${e.toString()}"}';
          return expectJson ? errorJson : "**HATA:** Sunucular geçici olarak hizmet dışı.";
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return '{"error": "Tüm yeniden deneme denemeleri başarısız oldu."}';
  }

  int _getDaysUntilExam(String examType) {
    final now = DateTime.now();
    DateTime examDate;
    
    switch (examType) {
      case 'yks':
        examDate = DateTime(now.year, 6, 15); // YKS genellikle Haziran'da
        break;
      case 'lgs':
        examDate = DateTime(now.year, 6, 1); // LGS genellikle Haziran'da
        break;
      case 'kpss':
        examDate = DateTime(now.year, 7, 1); // KPSS genellikle Temmuz'da
        break;
      default:
        examDate = DateTime(now.year, 6, 1);
    }
    
    if (examDate.isBefore(now)) {
      examDate = examDate.add(const Duration(days: 365));
    }
    
    return examDate.difference(now).inDays;
  }

  // 🚀 QUANTUM YARDIMCI FONKSİYONLAR
  double _calculateAverageNet(List<TestModel> tests) {
    if (tests.isEmpty) return 0.0;
    
    double totalNet = 0.0;
    for (final test in tests) {
      totalNet += test.totalNet;
    }
    return totalNet / tests.length;
  }

  Map<String, double> _calculateSubjectAverages(List<TestModel> tests) {
    if (tests.isEmpty) return {};
    
    final Map<String, List<double>> subjectScores = {};
    
    for (final test in tests) {
      for (final subject in test.scores.entries) {
        final correct = subject.value['dogru'] ?? 0;
        final wrong = subject.value['yanlis'] ?? 0;
        final net = correct - (wrong * test.penaltyCoefficient);
        subjectScores.putIfAbsent(subject.key, () => []).add(net.toDouble());
      }
    }
    
    final Map<String, double> averages = {};
    for (final subject in subjectScores.entries) {
      final scores = subject.value;
      final average = scores.reduce((a, b) => a + b) / scores.length;
      averages[subject.key] = average;
    }
    
    return averages;
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
    String? revisionRequest,
  }) async {
    final examType = user.selectedExamType ?? 'yks';
    final daysUntilExam = _getDaysUntilExam(examType);
    final avgNet = _calculateAverageNet(tests);
    final subjectAverages = _calculateSubjectAverages(tests);
    final topicPerformancesJson = jsonEncode(user.topicPerformances);
    final availabilityJson = jsonEncode(user.availability ?? {});
    final weeklyPlanJson = user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : null;
    final completedTasksJson = user.completedTasks.isNotEmpty ? jsonEncode(user.completedTasks) : null;

    String prompt;
    if (examType == 'yks') {
      prompt = getYksPrompt(
        user.id,
        user.selectedExamSection,
        daysUntilExam,
        user.goal ?? 'Türkiye Birinciliği',
        user.challenges ?? [],
        pacing,
        tests.length,
        avgNet.toStringAsFixed(2),
        subjectAverages,
        topicPerformancesJson,
        availabilityJson,
        weeklyPlanJson,
        completedTasksJson,
        revisionRequest: revisionRequest,
      );
    } else {
      prompt = getLgsPrompt(
        user,
        avgNet.toStringAsFixed(2),
        subjectAverages,
        pacing,
        daysUntilExam,
        topicPerformancesJson,
        availabilityJson,
        revisionRequest: revisionRequest,
      );
    }

    return await _callGemini(prompt, expectJson: true);
  }

  // 🚀 QUANTUM STRATEJİ ÜRETİCİSİ - 2500'LERİN TEKNOLOJİSİ
  Future<String> generateQuantumStrategy({
    required UserModel user,
    required List<TestModel> tests,
    required String pacing,
    String? revisionRequest,
    required String analysisPhase,
  }) async {
    final examType = user.selectedExamType ?? 'yks';
    final daysUntilExam = _getDaysUntilExam(examType);
    final avgNet = _calculateAverageNet(tests);
    final subjectAverages = _calculateSubjectAverages(tests);
    final topicPerformancesJson = jsonEncode(user.topicPerformances);
    final availabilityJson = jsonEncode(user.availability ?? {});
    final weeklyPlanJson = user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : null;
    final completedTasksJson = user.completedTasks.isNotEmpty ? jsonEncode(user.completedTasks) : null;

    // 🧠 QUANTUM AI PROMPT - 2500'LERİN TEKNOLOJİSİ
    String prompt;
    if (examType == 'yks') {
      prompt = getYksPrompt(
        user.id,
        user.selectedExamSection,
        daysUntilExam,
        user.goal ?? 'Türkiye Birinciliği',
        user.challenges ?? [],
        pacing,
        tests.length,
        avgNet.toStringAsFixed(2),
        subjectAverages,
        topicPerformancesJson,
        availabilityJson,
        weeklyPlanJson,
        completedTasksJson,
        revisionRequest: revisionRequest,
      );
    } else {
      prompt = getLgsPrompt(
        user,
        avgNet.toStringAsFixed(2),
        subjectAverages,
        pacing,
        daysUntilExam,
        topicPerformancesJson,
        availabilityJson,
        revisionRequest: revisionRequest,
      );
    }

    return await _callGemini(prompt, expectJson: true);
  }

  Future<String> generateStudyGuideAndQuiz(UserModel user, List<TestModel> tests, {Map<String, String>? topicOverride, String difficulty = 'normal'}) async {
    final examType = user.selectedExamType ?? 'yks';
    // TODO: ExamData.getExamByType düzeltilecek - şimdilik geçici Exam objesi
    final tempExam = Exam(
      type: examType == 'yks' ? ExamType.yks : ExamType.lgs,
      name: examType == 'yks' ? 'YKS' : 'LGS',
      sections: [],
    );
    final analysis = tests.isNotEmpty ? StatsAnalysis(tests, user.topicPerformances, tempExam, user: user) : null;
    
    String prompt;
    if (topicOverride != null) {
      prompt = getWorkshopPrompt(
        user,
        tests,
        topicOverride['subject']!,
        topicOverride['topic']!,
        difficulty,
        analysis,
      );
    } else {
      final suggestions = analysis?.getWorkshopSuggestions(count: 1) ?? [];
      if (suggestions.isEmpty) {
        return '{"error": "Önerilecek konu bulunamadı."}';
      }
      
      final suggestion = suggestions.first;
      prompt = getWorkshopPrompt(
        user,
        tests,
        suggestion['subject'].toString(),
        suggestion['topic'].toString(),
        difficulty,
        analysis,
      );
    }

    return await _callGemini(prompt, expectJson: true);
  }

  // 🚀 QUANTUM STUDY GUIDE ÜRETİCİSİ - 2500'LERİN TEKNOLOJİSİ
  Future<String> generateQuantumStudyGuideAndQuiz(UserModel user, List<TestModel> tests, {Map<String, String>? topicOverride, String difficulty = 'quantum'}) async {
    final examType = user.selectedExamType ?? 'yks';
    // TODO: ExamData.getExamByType düzeltilecek - şimdilik geçici Exam objesi
    final tempExam = Exam(
      type: examType == 'yks' ? ExamType.yks : ExamType.lgs,
      name: examType == 'yks' ? 'YKS' : 'LGS',
      sections: [],
    );
    final analysis = tests.isNotEmpty ? StatsAnalysis(tests, user.topicPerformances, tempExam, user: user) : null;
    
    String prompt;
    if (topicOverride != null) {
      prompt = getQuantumWorkshopPrompt(
        user,
        tests,
        topicOverride['subject']!,
        topicOverride['topic']!,
        difficulty,
        analysis,
      );
    } else {
      final suggestions = analysis?.getWorkshopSuggestions(count: 1) ?? [];
      if (suggestions.isEmpty) {
        return '{"error": "Quantum önerilecek konu bulunamadı."}';
      }
      
      final suggestion = suggestions.first;
      prompt = getQuantumWorkshopPrompt(
        user,
        tests,
        suggestion['subject'].toString(),
        suggestion['topic'].toString(),
        difficulty,
        analysis,
      );
    }

    return await _callGemini(prompt, expectJson: true);
  }

  // YENİ EK: Psişik Harbiye İçin Motivasyon Üretimi
  Future<String> getPersonalizedMotivation({
    required UserModel user,
    required List<TestModel> tests,
    required String promptType,
    String? emotion,
  }) async {
    final examType = user.selectedExamType ?? 'yks';
    final daysUntilExam = _getDaysUntilExam(examType);
    final avgNet = _calculateAverageNet(tests);
    final subjectAverages = _calculateSubjectAverages(tests);
    final topicPerformancesJson = jsonEncode(user.topicPerformances);
    final availabilityJson = jsonEncode(user.availability ?? {});
    final weeklyPlanJson = user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : null;
    final completedTasksJson = user.completedTasks.isNotEmpty ? jsonEncode(user.completedTasks) : null;

    final prompt = getMotivationPrompt(
      user.id,
      examType == 'yks' ? 'YKS' : 'LGS',
      daysUntilExam,
      user.goal ?? 'Birincilik',
      user.challenges ?? [],
      promptType,
      tests.length,
      avgNet.toStringAsFixed(2),
      subjectAverages,
      topicPerformancesJson,
      availabilityJson,
      weeklyPlanJson,
      completedTasksJson,
      emotion,
    );

    return await _callGemini(prompt, expectJson: false);
  }

  // 🚀 QUANTUM KİŞİSELLEŞTİRİLMİŞ MOTİVASYON - 3000'LERİN TEKNOLOJİSİ
  Future<String> getQuantumPersonalizedMotivation({
    required UserModel user,
    required List<TestModel> tests,
    required String promptType,
    String? emotion,
    String? quantumMood,
  }) async {
    final examType = user.selectedExamType ?? 'yks';
    final daysUntilExam = _getDaysUntilExam(examType);
    final avgNet = _calculateAverageNet(tests);
    final subjectAverages = _calculateSubjectAverages(tests);
    final topicPerformancesJson = jsonEncode(user.topicPerformances);
    final availabilityJson = jsonEncode(user.availability ?? {});
    final weeklyPlanJson = user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : null;
    final completedTasksJson = user.completedTasks.isNotEmpty ? jsonEncode(user.completedTasks) : null;

    final prompt = getQuantumMotivationPrompt(
      user: user,
      tests: tests,
      analysis: null,
      examName: examType == 'yks' ? 'YKS' : 'LGS',
      promptType: promptType,
      emotion: emotion,
      quantumMood: quantumMood,
    );

    return await _callGemini(prompt, expectJson: false);
  }
}