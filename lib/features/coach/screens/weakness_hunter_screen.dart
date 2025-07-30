// lib/features/coach/screens/weakness_hunter_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

// ... (GeneratedQuestion modeli aynı kalır) ...
class GeneratedQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String weakestTopic;
  final String weakestSubject;

  GeneratedQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.weakestTopic,
    required this.weakestSubject,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      question: json['question'] ?? 'Soru yüklenemedi.',
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: json['explanation'] ?? 'Açıklama mevcut değil.',
      weakestTopic: json['weakestTopic'] ?? 'Belirsiz Konu',
      weakestSubject: json['weakestSubject'] ?? 'Belirsiz Ders',
    );
  }
}

// BİLGEAI DEVRİMİ: "Soru Kasası" - Soru listesini ve mevcut zayıf konuyu tutar.
final weaknessHunterCacheProvider = StateProvider<({String weakTopic, List<GeneratedQuestion> questions})?>((ref) => null);

final weaknessHunterProvider = StateNotifierProvider.autoDispose<
    WeaknessHunterNotifier, AsyncValue<GeneratedQuestion>>((ref) {
  return WeaknessHunterNotifier(ref);
});

class WeaknessHunterNotifier extends StateNotifier<AsyncValue<GeneratedQuestion>> {
  final Ref _ref;
  WeaknessHunterNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchQuestion() async {
    state = const AsyncValue.loading();
    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;

    if (user == null || tests == null || tests.isEmpty) {
      state = AsyncValue.error("Analiz için yeterli deneme verisi bulunmuyor.", StackTrace.current);
      return;
    }

    final analysis = PerformanceAnalysis(tests, user.topicPerformances);
    final weakestTopicInfo = analysis.getWeakestTopicWithDetails();
    if (weakestTopicInfo == null) {
      state = AsyncValue.error("Zayıf bir konu bulunamadı. Lütfen önce konu performanslarınızı girin.", StackTrace.current);
      return;
    }
    final currentWeakTopic = weakestTopicInfo['topic']!;
    var cache = _ref.read(weaknessHunterCacheProvider);

    // BİLGEAI DEVRİMİ: Kasa kontrolü
    if (cache != null && cache.weakTopic == currentWeakTopic && cache.questions.isNotEmpty) {
      debugPrint("Soru Kasası'ndan yüklendi!");
      final question = cache.questions.removeAt(0); // Kasadan bir soru al ve listeden çıkar
      _ref.read(weaknessHunterCacheProvider.notifier).state = cache; // Güncellenmiş kasayı kaydet
      state = AsyncValue.data(question);
      return;
    }

    // Kasa boş veya konu değişti, API'yi çağır
    debugPrint("Soru Kasası boş veya konu değişti. API'den yeni set çekiliyor...");
    try {
      // BİLGEAI DEVRİMİ: AI servisi artık bir liste döndürüyor.
      final jsonString = await _ref.read(aiServiceProvider).generateTargetedQuestions(user, tests);
      final List<dynamic> decodedList = jsonDecode(jsonString);

      if (decodedList.isEmpty) throw Exception("Yapay zeka soru üretemedi.");

      List<GeneratedQuestion> newQuestions = decodedList.map((q) => GeneratedQuestion.fromJson(q)).toList();

      final firstQuestion = newQuestions.removeAt(0);
      // Kalan soruları yeni konuyla birlikte kasaya yaz.
      _ref.read(weaknessHunterCacheProvider.notifier).state = (weakTopic: currentWeakTopic, questions: newQuestions);
      state = AsyncValue.data(firstQuestion);

    } catch (e, s) {
      state = AsyncValue.error("Soru üretilirken bir hata oluştu: ${e.toString()}", s);
    }
  }
}

class WeaknessHunterScreen extends ConsumerStatefulWidget {
  const WeaknessHunterScreen({super.key});
  @override
  ConsumerState<WeaknessHunterScreen> createState() => _WeaknessHunterScreenState();
}

class _WeaknessHunterScreenState extends ConsumerState<WeaknessHunterScreen> {
  // ... (initState aynı kalır) ...
  int? _selectedOptionIndex;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(weaknessHunterProvider.notifier).fetchQuestion());
  }

  void _getNewQuestion() {
    setState(() {
      _selectedOptionIndex = null;
      _showAnswer = false;
    });
    ref.read(weaknessHunterProvider.notifier).fetchQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weaknessHunterProvider);
    final cache = ref.watch(weaknessHunterCacheProvider);
    final bool hasMoreQuestionsInCache = (cache?.questions.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Zayıflık Avcısı')),
      body: Center(
        child: state.when(
          data: (question) => _buildQuestionView(question, context),
          loading: () => const CircularProgressIndicator(color: AppTheme.secondaryColor),
          error: (e, s) => _buildErrorView(e.toString(), context),
        ),
      ),
      floatingActionButton: state.hasValue ? FloatingActionButton.extended(
        onPressed: _getNewQuestion,
        // BİLGEAI DEVRİMİ: Buton metni kasadaki duruma göre değişir.
        label: Text(hasMoreQuestionsInCache ? 'Sonraki Soru (${cache!.questions.length + 1})' : 'Yeni Soru İste'),
        icon: const Icon(Icons.refresh_rounded),
      ).animate().slide(begin: const Offset(0, 2)).fadeIn(delay: 500.ms) : null,
    );
  }
  // ... (Geri kalan UI metotları aynı, sadece _reset metodu _getNewQuestion oldu) ...
  Widget _buildQuestionView(GeneratedQuestion question, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Animate(
      key: ValueKey(question.question),
      effects: const [FadeEffect(duration: Duration(milliseconds: 600)), SlideEffect(begin: Offset(0, 0.1))],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: AppTheme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZAYIF NOKTA TESPİTİ',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "BilgeAI, '${question.weakestSubject}' dersindeki netlerin ile '${question.weakestTopic}' konusundaki bilgilerin arasında bir tutarsızlık tespit etti. Gel, bu konuyu pekiştirelim.",
                    style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(question.question, style: textTheme.headlineSmall),
          const SizedBox(height: 32),
          ...List.generate(question.options.length, (index) {
            return _buildOptionTile(
                question, index, colorScheme, textTheme);
          }),
          const SizedBox(height: 32),
          if (_showAnswer)
            _buildExplanationCard(question, colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentColor, size: 50),
          const SizedBox(height: 16),
          Text(
            'Bir Hata Oluştu',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(weaknessHunterProvider.notifier).fetchQuestion(),
            child: const Text('Tekrar Dene'),
          )
        ],
      ),
    );
  }

  Widget _buildOptionTile(GeneratedQuestion question, int index,
      ColorScheme colorScheme, TextTheme textTheme) {
    Color tileColor = AppTheme.cardColor;
    Color borderColor = AppTheme.lightSurfaceColor.withOpacity(0.5);
    IconData? trailingIcon;
    Color? iconColor;

    final isCorrect = index == question.correctOptionIndex;
    final isSelected = index == _selectedOptionIndex;

    if (_showAnswer) {
      if (isCorrect) {
        borderColor = AppTheme.successColor;
        iconColor = AppTheme.successColor;
        trailingIcon = Icons.check_circle;
      } else if (isSelected) {
        borderColor = AppTheme.accentColor;
        iconColor = AppTheme.accentColor;
        trailingIcon = Icons.cancel;
      }
    }

    return Card(
      color: tileColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: _showAnswer
            ? null
            : () {
          setState(() {
            _selectedOptionIndex = index;
            _showAnswer = true;
          });
        },
        title: Text(question.options[index], style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
        trailing: trailingIcon != null
            ? Icon(trailingIcon, color: iconColor)
            : null,
      ),
    ).animate(target: _showAnswer && (isCorrect || isSelected) ? 1: 0).shake(hz: 4, duration: 400.ms);
  }

  Widget _buildExplanationCard(GeneratedQuestion question,
      ColorScheme colorScheme, TextTheme textTheme) {
    return Animate(
      effects: const [FadeEffect(), ScaleEffect(begin: Offset(0.9, 0.9), curve: Curves.easeOutBack)],
      child: Card(
        color: AppTheme.lightSurfaceColor.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detaylı Açıklama',
                style: textTheme.titleLarge
                    ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20, color: AppTheme.lightSurfaceColor),
              Text(question.explanation, style: textTheme.bodyLarge?.copyWith(height: 1.5, color: AppTheme.secondaryTextColor)),
            ],
          ),
        ),
      ),
    );
  }
}