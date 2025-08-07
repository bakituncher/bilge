// lib/features/home/screens/add_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:bilge_ai/shared/widgets/score_slider.dart'; // YENİ IMPORT

// State Management Provider'ları
final _stepperProvider = StateProvider.autoDispose<int>((ref) => 0);
final _selectedSectionProvider = StateProvider.autoDispose<ExamSection?>((ref) => null);
final _scoresProvider = StateProvider.autoDispose<Map<String, Map<String, int>>>((ref) => {});
final _testNameProvider = StateProvider.autoDispose<String>((ref) => '');
final _isSavingProvider = StateProvider.autoDispose<bool>((ref) => false);


class AddTestScreen extends ConsumerWidget {
  const AddTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final int currentStep = ref.watch(_stepperProvider);

    if (userProfile?.selectedExam == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("Lütfen önce profilden bir sınav seçin.")));
    }

    final selectedExamType = ExamType.values.byName(userProfile!.selectedExam!);
    final exam = ExamData.getExamByType(selectedExamType);

    List<ExamSection> availableSections;
    if (selectedExamType == ExamType.yks) {
      final tytSection = exam.sections.firstWhere((s) => s.name == 'TYT');
      final userAytSection = exam.sections.firstWhere(
            (s) => s.name == userProfile.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      availableSections = (tytSection.name == userAytSection.name) ? [tytSection] : [tytSection, userAytSection];
    } else {
      availableSections = exam.sections;
    }

    if (availableSections.length == 1 && ref.read(_selectedSectionProvider) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(context.mounted) {
          ref.read(_selectedSectionProvider.notifier).state = availableSections.first;
        }
      });
    }

    final List<Widget> steps = [
      Step1TestInfo(availableSections: availableSections),
      const Step2ScoreEntry(),
      const Step3Summary(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('${selectedExamType.displayName} Sonuç Bildirimi')),
      body: steps[currentStep],
    );
  }
}

// Adım 1: Deneme Bilgileri
class Step1TestInfo extends ConsumerWidget {
  final List<ExamSection> availableSections;
  final TextEditingController _testNameController = TextEditingController();

  Step1TestInfo({super.key, required this.availableSections});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _testNameController.text = ref.watch(_testNameProvider);
    _testNameController.selection = TextSelection.fromPosition(TextPosition(offset: _testNameController.text.length));
    final selectedSection = ref.watch(_selectedSectionProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Deneme Bilgileri", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: _testNameController,
            decoration: const InputDecoration(labelText: 'Deneme Adı (Örn: 3D Genel Deneme)'),
            onChanged: (value) => ref.read(_testNameProvider.notifier).state = value,
          ),
          const SizedBox(height: 24),
          if (availableSections.length > 1)
            DropdownButtonFormField<ExamSection>(
              value: selectedSection,
              decoration: const InputDecoration(labelText: 'Deneme Türü'),
              hint: const Text('Bölüm Seçin'),
              items: availableSections.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (value) => ref.read(_selectedSectionProvider.notifier).state = value,
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: (selectedSection != null && _testNameController.text.isNotEmpty)
                ? () {
              final section = ref.read(_selectedSectionProvider);
              if (section != null) {
                final initialScores = {
                  for (var subject in section.subjects.keys)
                    subject: {'dogru': 0, 'yanlis': 0}
                };
                ref.read(_scoresProvider.notifier).state = initialScores;
              }
              ref.read(_stepperProvider.notifier).state = 1;
            }
                : null,
            child: const Text('İlerle'),
          ),
        ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
      ),
    );
  }
}

// Adım 2: Sonuç Bildirimi
class Step2ScoreEntry extends ConsumerStatefulWidget {
  const Step2ScoreEntry({super.key});

  @override
  ConsumerState<Step2ScoreEntry> createState() => _Step2ScoreEntryState();
}

class _Step2ScoreEntryState extends ConsumerState<Step2ScoreEntry> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = ref.watch(_selectedSectionProvider);
    if (section == null) return const Center(child: Text("Bölüm seçilmedi."));

    final subjects = section.subjects.entries.toList();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subjectEntry = subjects[index];
              return _SubjectScoreCard(
                key: ValueKey(subjectEntry.key),
                subjectName: subjectEntry.key,
                details: subjectEntry.value,
                isFirst: index == 0,
                isLast: index == subjects.length - 1,
                onNext: () => _pageController.nextPage(duration: 300.ms, curve: Curves.easeOut),
                onPrevious: () => _pageController.previousPage(duration: 300.ms, curve: Curves.easeOut),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () => ref.read(_stepperProvider.notifier).state = 2,
            child: const Text('Özeti Görüntüle'),
          ),
        )
      ],
    );
  }
}

class _SubjectScoreCard extends ConsumerWidget {
  final String subjectName;
  final SubjectDetails details;
  final bool isFirst, isLast;
  final VoidCallback onNext, onPrevious;

  const _SubjectScoreCard({
    super.key,
    required this.subjectName,
    required this.details,
    required this.isFirst,
    required this.isLast,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(_scoresProvider);
    final subjectScores = scores[subjectName] ?? {'dogru': 0, 'yanlis': 0};

    int correct = subjectScores['dogru']!;
    int wrong = subjectScores['yanlis']!;
    int blank = details.questionCount - correct - wrong;
    final section = ref.watch(_selectedSectionProvider)!;
    double net = correct - (wrong * section.penaltyCoefficient);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(subjectName, style: Theme.of(context).textTheme.displaySmall),
          Text("${details.questionCount} Soru", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.secondaryTextColor)),
          const SizedBox(height: 48),

          ScoreSlider( // DEĞİŞİKLİK
            label: "Doğru",
            value: correct.toDouble(),
            max: details.questionCount.toDouble(),
            color: AppTheme.successColor,
            onChanged: (value) {
              final newCorrect = value.toInt();
              final currentWrong = subjectScores['yanlis']!;
              if (newCorrect + currentWrong > details.questionCount) {
                final adjustedWrong = details.questionCount - newCorrect;
                ref.read(_scoresProvider.notifier).state = {
                  ...scores,
                  subjectName: {'dogru': newCorrect, 'yanlis': adjustedWrong}
                };
              } else {
                ref.read(_scoresProvider.notifier).state = {
                  ...scores,
                  subjectName: {'dogru': newCorrect, 'yanlis': currentWrong}
                };
              }
            },
          ),
          ScoreSlider( // DEĞİŞİKLİK
            label: "Yanlış",
            value: wrong.toDouble(),
            max: (details.questionCount - correct).toDouble(),
            color: AppTheme.accentColor,
            onChanged: (value) {
              final newWrong = value.toInt();
              ref.read(_scoresProvider.notifier).state = {
                ...scores,
                subjectName: {'dogru': correct, 'yanlis': newWrong}
              };
            },
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatDisplay(label: "Boş", value: blank.toString()),
              _StatDisplay(label: "Net", value: net.toStringAsFixed(2)),
            ],
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isFirst) IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: onPrevious),
              if (isFirst) const Spacer(),
              if (!isLast) IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: onNext),
              if (isLast) const Spacer(),
            ],
          )
        ],
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  final String label;
  final String value;

  const _StatDisplay({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }
}

// Adım 3: Özet ve Kaydet
class Step3Summary extends ConsumerWidget {
  const Step3Summary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(_selectedSectionProvider)!;
    final scores = ref.watch(_scoresProvider);
    final testName = ref.watch(_testNameProvider);
    final user = ref.watch(userProfileProvider).value;
    final isSaving = ref.watch(_isSavingProvider);

    int totalCorrect = 0;
    int totalWrong = 0;
    int totalBlank = 0;
    int totalQuestions = 0;

    final Map<String, Map<String, int>> finalScores = {};

    scores.forEach((subject, values) {
      final subjectDetails = section.subjects[subject]!;
      final correct = values['dogru']!;
      final wrong = values['yanlis']!;
      final blank = subjectDetails.questionCount - correct - wrong;

      totalCorrect += correct;
      totalWrong += wrong;
      totalBlank += blank;
      totalQuestions += subjectDetails.questionCount;

      finalScores[subject] = {'dogru': correct, 'yanlis': wrong, 'bos': blank};
    });

    double totalNet = totalCorrect - (totalWrong * section.penaltyCoefficient);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Genel Özet", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          _SummaryRow(label: "Toplam Doğru", value: totalCorrect.toString(), color: AppTheme.successColor),
          _SummaryRow(label: "Toplam Yanlış", value: totalWrong.toString(), color: AppTheme.accentColor),
          _SummaryRow(label: "Toplam Boş", value: totalBlank.toString(), color: AppTheme.secondaryTextColor),
          const Divider(height: 32),
          _SummaryRow(label: "Toplam Net", value: totalNet.toStringAsFixed(2), isTotal: true),
          const Spacer(),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              if (user == null) return;

              ref.read(_isSavingProvider.notifier).state = true;

              final newTest = TestModel(
                id: const Uuid().v4(),
                userId: user.id,
                testName: testName,
                examType: ExamType.values.byName(user.selectedExam!),
                sectionName: section.name,
                date: DateTime.now(),
                scores: finalScores,
                totalNet: totalNet,
                totalQuestions: totalQuestions,
                totalCorrect: totalCorrect,
                totalWrong: totalWrong,
                totalBlank: totalBlank,
                penaltyCoefficient: section.penaltyCoefficient,
              );

              try {
                await ref.read(firestoreServiceProvider).addTestResult(newTest);
                if (context.mounted) {
                  context.go('/home/test-result-summary', extra: newTest);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              } finally {
                if(context.mounted) {
                  ref.read(_isSavingProvider.notifier).state = false;
                }
              }
            },
            child: isSaving
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                : const Text('Kaydet ve Raporu Görüntüle'),
          ),
          TextButton(
              onPressed: () => ref.read(_stepperProvider.notifier).state = 1,
              child: const Text('Geri Dön ve Düzenle')
          )
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? textTheme.titleLarge : textTheme.bodyLarge),
          Text(value, style: textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}