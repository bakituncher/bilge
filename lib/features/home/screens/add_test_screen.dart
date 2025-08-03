// lib/features/home/screens/add_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Adımları yönetmek için bir state provider
final _stepperProvider = StateProvider<int>((ref) => 0);
// Seçilen bölümü saklamak için
final _selectedSectionProvider = StateProvider<ExamSection?>((ref) => null);
// Girilen skorları saklamak için
final _scoresProvider = StateProvider<Map<String, Map<String, int>>>((ref) => {});

class AddTestScreen extends ConsumerWidget {
  const AddTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final int currentStep = ref.watch(_stepperProvider);

    if (userProfile?.selectedExam == null) {
      // Bu durum normalde router tarafından engellenir, ama bir güvenlik önlemi.
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("Lütfen önce profilden bir sınav seçin.")));
    }

    final selectedExamType = ExamType.values.byName(userProfile!.selectedExam!);
    final exam = ExamData.getExamByType(selectedExamType);

    // YKS için özel bölüm listesi oluşturma
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

    // Eğer tek bölüm varsa, otomatik olarak seç.
    if (availableSections.length == 1 && ref.read(_selectedSectionProvider) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(_selectedSectionProvider.notifier).state = availableSections.first;
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
                ? () => ref.read(_stepperProvider.notifier).state = 1
                : null,
            child: const Text('İlerle'),
          ),
        ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
      ),
    );
  }
}

// Adım 2: Sonuç Bildirimi (Devrimin Kalbi)
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
    double net = correct - (wrong * 0.25); // Katsayı eklenebilir

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(subjectName, style: Theme.of(context).textTheme.displaySmall),
          Text("${details.questionCount} Soru", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.secondaryTextColor)),
          const SizedBox(height: 48),

          _ScoreSlider(
            label: "Doğru",
            value: correct.toDouble(),
            max: details.questionCount.toDouble(),
            color: AppTheme.successColor,
            onChanged: (value) {
              if (value.toInt() + wrong > details.questionCount) {
                wrong = details.questionCount - value.toInt();
              }
              ref.read(_scoresProvider.notifier).state = {
                ...scores,
                subjectName: {'dogru': value.toInt(), 'yanlis': wrong}
              };
            },
          ),
          _ScoreSlider(
            label: "Yanlış",
            value: wrong.toDouble(),
            max: (details.questionCount - correct).toDouble(),
            color: AppTheme.accentColor,
            onChanged: (value) {
              ref.read(_scoresProvider.notifier).state = {
                ...scores,
                subjectName: {'dogru': correct, 'yanlis': value.toInt()}
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

class _ScoreSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final Function(double) onChanged;

  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toInt()}", style: Theme.of(context).textTheme.titleLarge),
        Slider(
          value: value,
          max: max < 0 ? 0 : max,
          divisions: max.toInt() > 0 ? max.toInt() : 1,
          label: value.toInt().toString(),
          activeColor: color,
          inactiveColor: color.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
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
    // Hesaplamalar
    final section = ref.watch(_selectedSectionProvider)!;
    final scores = ref.watch(_scoresProvider);

    int totalCorrect = 0;
    int totalWrong = 0;
    int totalBlank = 0;
    int totalQuestions = 0;

    scores.forEach((subject, values) {
      totalCorrect += values['dogru']!;
      totalWrong += values['yanlis']!;
    });

    section.subjects.forEach((key, value) {
      totalQuestions += value.questionCount;
    });

    totalBlank = totalQuestions - totalCorrect - totalWrong;
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
            onPressed: () {
              // TODO: Kaydetme işlemini buraya ekle
              context.pop(); // Önceki ekrana dön
            },
            child: const Text('Kaydet ve Bitir'),
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