// lib/features/coach/screens/weakness_hunter_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Modeller
class GeneratedQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  GeneratedQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      question: json['question'] ?? 'Soru yüklenemedi.',
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: json['explanation'] ?? 'Açıklama mevcut değil.',
    );
  }
}

// State Yönetimi
final weaknessHunterProvider = StateNotifierProvider.autoDispose<
    WeaknessHunterNotifier, AsyncValue<GeneratedQuestion>>((ref) {
  return WeaknessHunterNotifier(ref);
});

class WeaknessHunterNotifier
    extends StateNotifier<AsyncValue<GeneratedQuestion>> {
  final Ref _ref;
  WeaknessHunterNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchQuestion() async {
    state = const AsyncValue.loading();
    final user = _ref.read(userProfileProvider).value;
    final tests = _ref.read(testsProvider).value;

    if (user == null || tests == null || tests.isEmpty) {
      state = AsyncValue.error(
          "Analiz için yeterli deneme verisi bulunmuyor.", StackTrace.current);
      return;
    }

    try {
      final jsonString = await _ref
          .read(aiServiceProvider)
          .generateTargetedQuestions(user, tests);
      final decodedJson = jsonDecode(jsonString);
      if(decodedJson.containsKey('error')){
        throw Exception(decodedJson['error']);
      }
      final question = GeneratedQuestion.fromJson(decodedJson);
      state = AsyncValue.data(question);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

// Ekran
class WeaknessHunterScreen extends ConsumerStatefulWidget {
  const WeaknessHunterScreen({super.key});

  @override
  ConsumerState<WeaknessHunterScreen> createState() =>
      _WeaknessHunterScreenState();
}

class _WeaknessHunterScreenState extends ConsumerState<WeaknessHunterScreen> {
  int? _selectedOptionIndex;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz soruyu yükle
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(weaknessHunterProvider.notifier).fetchQuestion());
  }

  void _reset() {
    setState(() {
      _selectedOptionIndex = null;
      _showAnswer = false;
    });
    ref.read(weaknessHunterProvider.notifier).fetchQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weaknessHunterProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Zayıflık Avcısı')),
      body: Center(
        child: state.when(
          data: (question) => Animate(
            key: ValueKey(question.question), // Soru değiştiğinde animasyonu tekrar tetikle
            effects: const [FadeEffect(duration: Duration(milliseconds: 600)), SlideEffect(begin: Offset(0, 0.1))],
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Zayıf Nokta Tespiti:',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
                ),
                const SizedBox(height: 8),
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
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(
                  'Bir sorun oluştu',
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.read(weaknessHunterProvider.notifier).fetchQuestion(),
                  child: const Text('Tekrar Dene'),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reset,
        label: const Text('Yeni Soru'),
        icon: const Icon(Icons.refresh_rounded),
      ).animate().slide(begin: const Offset(0, 2)).fadeIn(delay: 500.ms),
    );
  }

  Widget _buildOptionTile(GeneratedQuestion question, int index,
      ColorScheme colorScheme, TextTheme textTheme) {
    Color? tileColor;
    Color? borderColor;
    IconData? trailingIcon;

    if (_showAnswer) {
      if (index == question.correctOptionIndex) {
        tileColor = Colors.green.withOpacity(0.2);
        borderColor = Colors.green;
        trailingIcon = Icons.check_circle;
      } else if (index == _selectedOptionIndex) {
        tileColor = Colors.red.withOpacity(0.2);
        borderColor = Colors.red;
        trailingIcon = Icons.cancel;
      }
    }

    return Card(
      color: tileColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: borderColor ?? Colors.grey.withOpacity(0.3), width: 1.5),
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
        title: Text(question.options[index], style: textTheme.bodyLarge),
        trailing: trailingIcon != null
            ? Icon(trailingIcon, color: borderColor)
            : null,
      ),
    );
  }

  Widget _buildExplanationCard(GeneratedQuestion question,
      ColorScheme colorScheme, TextTheme textTheme) {
    return Animate(
      effects: const [FadeEffect(), ScaleEffect()],
      child: Card(
        color: colorScheme.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Açıklama',
                style: textTheme.titleLarge
                    ?.copyWith(color: colorScheme.secondary),
              ),
              const Divider(height: 16),
              Text(question.explanation, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}