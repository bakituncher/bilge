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
      case ExamType.kpssLisans:
        examDate = DateTime(now.year, 7, 14);
        break;
      case ExamType.kpssOnlisans:
        examDate = DateTime(now.year, 9, 7);
        break;
      case ExamType.kpssOrtaogretim:
        examDate = DateTime(now.year, 9, 21);
        break;
    }
    if (now.isAfter(examDate)) {
      examDate = DateTime(now.year + 1, examDate.month, examDate.day);
    }
    return examDate.difference(now).inDays;
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
    if (user.selectedExam == null) {
      return '{"error":"Analiz için önce bir sınav seçmelisiniz."}';
    }
    if (user.weeklyAvailability.values.every((list) => list.isEmpty)) {
      return '{"error":"Strateji oluşturmadan önce en az bir tane müsait zaman dilimi seçmelisiniz."}';
    }
    final examType = ExamType.values.byName(user.selectedExam!);
    final daysUntilExam = _getDaysUntilExam(examType);
    final examData = await ExamData.getExamByType(examType);
    final analysis = tests.isNotEmpty ? StatsAnalysis(tests, user.topicPerformances, examData, user: user) : null;
    final avgNet = analysis?.averageNet.toStringAsFixed(2) ?? 'N/A';
    final subjectAverages = analysis?.subjectAverages ?? {};
    final topicPerformancesJson = _encodeTopicPerformances(user.topicPerformances);
    final availabilityJson = jsonEncode(user.weeklyAvailability);
    final weeklyPlanJson = user.weeklyPlan != null ? jsonEncode(user.weeklyPlan) : null;
    final completedTasksJson = jsonEncode(user.completedDailyTasks);
    String prompt;
    switch (examType) {
      case ExamType.yks:
        prompt = getYksPrompt(
            user.id, user.selectedExamSection ?? '',
            daysUntilExam, user.goal ?? '',
            user.challenges, pacing,
            user.testCount, avgNet,
            subjectAverages, topicPerformancesJson,
            availabilityJson, weeklyPlanJson,
            completedTasksJson,
            revisionRequest: revisionRequest
        );
        break;
      case ExamType.lgs:
        prompt = getLgsPrompt(
            user,
            avgNet, subjectAverages,
            pacing, daysUntilExam,
            topicPerformancesJson, availabilityJson,
            revisionRequest: revisionRequest
        );
        break;
      default:
        prompt = getKpssPrompt(
            user,
            avgNet, subjectAverages,
            pacing, daysUntilExam,
            topicPerformancesJson, availabilityJson,
            examType.displayName,
            revisionRequest: revisionRequest
        );
        break;
    }
    return _callGemini(prompt, expectJson: true);
  }

  Future<String> generateStudyGuideAndQuiz(UserModel user, List<TestModel> tests, {Map<String, String>? topicOverride, String difficulty = 'normal'}) async {
    if (tests.isEmpty) {
      return '{"error":"Analiz için en az bir deneme sonucu gereklidir."}';
    }
    if (user.selectedExam == null) {
      return '{"error":"Sınav türü bulunamadı."}';
    }

    String weakestSubject;
    String weakestTopic;

    if (topicOverride != null) {
      weakestSubject = topicOverride['subject']!;
      weakestTopic = topicOverride['topic']!;
    } else {
      final examType = ExamType.values.byName(user.selectedExam!);
      final examData = await ExamData.getExamByType(examType);
      final analysis = StatsAnalysis(tests, user.topicPerformances, examData, user: user);
      final weakestTopicInfo = analysis.getWeakestTopicWithDetails();

      if (weakestTopicInfo == null) {
        return '{"error":"Analiz için zayıf bir konu bulunamadı. Lütfen önce konu performans verilerinizi girin."}';
      }
      weakestSubject = weakestTopicInfo['subject']!;
      weakestTopic = weakestTopicInfo['topic']!;
    }

    final prompt = getStudyGuideAndQuizPrompt(weakestSubject, weakestTopic, user.selectedExam, difficulty);

    return _callGemini(prompt, expectJson: true);
  }

  // YENİ EK: Psişik Harbiye İçin Motivasyon Üretimi
  Future<String> getPersonalizedMotivation({
    required UserModel user,
    required List<TestModel> tests,
    required String promptType,
    required String? emotion,
    Map<String, dynamic>? workshopContext,
  }) async {
    final examType = user.selectedExam != null ? ExamType.values.byName(user.selectedExam!) : null;
    final examData = examType != null ? await ExamData.getExamByType(examType) : null;
    final analysis = tests.isNotEmpty && examData != null ? StatsAnalysis(tests, user.topicPerformances, examData, user: user) : null;

    final prompt = getMotivationPrompt(
      user: user,
      tests: tests,
      analysis: analysis,
      examName: examType?.displayName,
      promptType: promptType,
      emotion: emotion,
      workshopContext: workshopContext,
    );
    return _callGemini(prompt, expectJson: false);
  }
}