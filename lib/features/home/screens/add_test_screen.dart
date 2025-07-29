// lib/features/home/screens/add_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

class AddTestScreen extends ConsumerStatefulWidget {
  const AddTestScreen({super.key});

  @override
  ConsumerState<AddTestScreen> createState() => _AddTestScreenState();
}

class _AddTestScreenState extends ConsumerState<AddTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();

  ExamSection? _selectedSection;

  final Map<String, Map<String, TextEditingController>> _controllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _testNameController.dispose();
    _clearControllers();
    super.dispose();
  }

  void _clearControllers() {
    _controllers.forEach((_, subjectControllers) {
      subjectControllers.forEach((_, controller) => controller.dispose());
    });
    _controllers.clear();
  }

  // ✅ UX GELİŞTİRMESİ: Otomatik boş hesaplaması için listener'lar eklendi.
  void _initializeControllers(ExamSection section) {
    _clearControllers();
    final newControllers = <String, Map<String, TextEditingController>>{};
    for (var subject in section.subjects.keys) {
      final correctController = TextEditingController();
      final wrongController = TextEditingController();
      final blankController = TextEditingController();
      final totalQuestions = section.subjects[subject]?.questionCount ?? 0;

      void updateBlank() {
        final correct = int.tryParse(correctController.text) ?? 0;
        final wrong = int.tryParse(wrongController.text) ?? 0;
        final blank = totalQuestions - correct - wrong;

        // Sadece geçerli bir sonuç varsa güncelle
        if (blank >= 0) {
          blankController.text = blank.toString();
        } else {
          // Negatif bir sonuç durumunda, kullanıcıya bir hata göstermek yerine
          // alanı boş bırakmak veya '0' olarak ayarlamak daha iyi bir UX olabilir.
          blankController.text = '0';
        }
      }

      correctController.addListener(updateBlank);
      wrongController.addListener(updateBlank);

      newControllers[subject] = {
        'dogru': correctController,
        'yanlis': wrongController,
        'bos': blankController,
      };
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _controllers.addAll(newControllers);
        });
      }
    });
  }

  void _saveTest() async {
    // ... Bu fonksiyonun içeriği doğru çalıştığı için aynı kalıyor ...
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile?.selectedExam == null) return;
    final selectedExamType = ExamType.values.byName(userProfile!.selectedExam!);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen sınav bölümünü seçin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final scores = <String, Map<String, int>>{};
    double totalCorrect = 0;
    double totalWrong = 0;
    int totalBlankCount = 0;
    int totalQuestionCount = 0;
    bool validationError = false;

    for (var subject in _controllers.keys) {
      final subjectControllers = _controllers[subject]!;
      final correct = int.tryParse(subjectControllers['dogru']!.text) ?? 0;
      final wrong = int.tryParse(subjectControllers['yanlis']!.text) ?? 0;
      final blank = int.tryParse(subjectControllers['bos']!.text) ?? 0;
      final questionCountForSubject =
          _selectedSection!.subjects[subject]?.questionCount ?? 0;

      if (correct + wrong + blank > questionCountForSubject) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '$subject dersi için girdiğiniz değerler toplam soru sayısını ($questionCountForSubject) aşıyor!')),
        );
        setState(() => _isLoading = false);
        validationError = true;
        break;
      }

      scores[subject] = {'dogru': correct, 'yanlis': wrong, 'bos': blank};
      totalCorrect += correct;
      totalWrong += wrong;
      totalBlankCount += blank;
      totalQuestionCount += questionCountForSubject;
    }

    if (validationError) return;

    final totalNet =
        totalCorrect - (totalWrong * _selectedSection!.penaltyCoefficient);
    final userId = ref.read(authControllerProvider).value!.uid;

    final newTest = TestModel(
      id: '',
      userId: userId,
      testName: _testNameController.text.trim(),
      examType: selectedExamType,
      sectionName: _selectedSection!.name,
      date: DateTime.now(),
      scores: scores,
      totalNet: totalNet,
      totalQuestions: totalQuestionCount,
      totalCorrect: totalCorrect.toInt(),
      totalWrong: totalWrong.toInt(),
      totalBlank: totalBlankCount,
      penaltyCoefficient: _selectedSection!.penaltyCoefficient,
    );

    try {
      await ref.read(firestoreServiceProvider).addTestResult(newTest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deneme başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... build metodunun üst kısmı (veri çekme ve kontrol) aynı kalıyor ...
    final userProfile = ref.watch(userProfileProvider).value;

    if (userProfile == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    }

    if (userProfile.selectedExam == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Hata')),
          body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Lütfen profilden bir sınav seçin.",
                    textAlign: TextAlign.center),
              )));
    }

    final selectedExamType = ExamType.values.byName(userProfile.selectedExam!);
    final exam = ExamData.getExamByType(selectedExamType);

    List<ExamSection> availableSections;
    if (selectedExamType == ExamType.lgs) {
      availableSections = exam.sections;
    } else if (selectedExamType == ExamType.yks) {
      final tytSection = exam.sections.firstWhere((s) => s.name == 'TYT');
      final userAytSection = exam.sections.firstWhere(
            (s) => s.name == userProfile.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      if (tytSection.name == userAytSection.name) {
        availableSections = [tytSection];
      } else {
        availableSections = [tytSection, userAytSection];
      }
    } else {
      final userSection = exam.sections.firstWhere(
              (s) => s.name == userProfile.selectedExamSection,
          orElse: () => exam.sections.first);
      availableSections = [userSection];
    }

    if (availableSections.length == 1 && _selectedSection == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){
          setState(() {
            _selectedSection = availableSections.first;
            _initializeControllers(_selectedSection!);
          });
        }
      });
    }

    return Scaffold(
      appBar:
      AppBar(title: Text('${selectedExamType.displayName} Denemesi Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _testNameController,
                decoration: const InputDecoration(
                    labelText: 'Sınav Adı (Örn: 3D TYT Genel Deneme)'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Sınav adı boş olamaz.' : null,
              ),
              const SizedBox(height: 24),
              if (availableSections.length > 1)
                DropdownButtonFormField<ExamSection>(
                  value: _selectedSection,
                  decoration: const InputDecoration(labelText: 'Deneme Türü'),
                  hint: const Text('Ekleyeceğin deneme türünü seç'),
                  items: availableSections
                      .map((section) => DropdownMenuItem(
                    value: section,
                    child: Text(section.name),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSection = value;
                        _initializeControllers(value);
                      });
                    }
                  },
                  validator: (v) =>
                  v == null ? 'Lütfen bir bölüm seçin.' : null,
                )
              else if (availableSections.isNotEmpty)
                ListTile(
                  title: const Text("Deneme Türü"),
                  subtitle: Text(availableSections.first.name),
                  contentPadding: EdgeInsets.zero,
                ),

              const SizedBox(height: 24),

              if (_selectedSection != null)
                ..._controllers.keys.map((subject) {
                  final subjectDetails = _selectedSection!.subjects[subject];
                  if (subjectDetails == null) return const SizedBox.shrink();
                  return _buildSubjectExpansionTile(subject, subjectDetails);
                }),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : const Text('Kaydet'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectExpansionTile(String subject, SubjectDetails subjectDetails) {
    return ExpansionTile(
      title: Text('$subject (${subjectDetails.questionCount} Soru)'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildScoreTextField('Doğru', _controllers[subject]!['dogru']!),
        _buildScoreTextField('Yanlış', _controllers[subject]!['yanlis']!),
        _buildScoreTextField('Boş', _controllers[subject]!['bos']!, readOnly: true),
      ],
    );
  }

  // ✅ UX GELİŞTİRMESİ: `readOnly` parametresi ve görsel stil eklendi.
  Widget _buildScoreTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          // Boş alanı görsel olarak ayırt etmek için
          filled: readOnly,
          fillColor: readOnly ? Theme.of(context).colorScheme.surface.withAlpha(100) : null,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) =>
        v == null || v.isEmpty ? 'Bu alan boş olamaz.' : null,
      ),
    );
  }
}