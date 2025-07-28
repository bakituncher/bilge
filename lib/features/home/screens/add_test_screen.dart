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

  // Controller'larımızı tutan Map yapısı
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

  void _initializeControllers(ExamSection section) {
    // Önceki controller'ları temizle
    _clearControllers();
    final newControllers = <String, Map<String, TextEditingController>>{};
    for (var subject in section.subjects.keys) {
      newControllers[subject] = {
        'dogru': TextEditingController(),
        'yanlis': TextEditingController(),
        'bos': TextEditingController(),
      };
    }
    // State'i güncelle ve arayüzün yeniden çizilmesini sağla
    setState(() {
      _controllers.addAll(newControllers);
    });
  }

  void _saveTest() async {
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

    _controllers.forEach((subject, subjectControllers) {
      final correct = int.tryParse(subjectControllers['dogru']!.text) ?? 0;
      final wrong = int.tryParse(subjectControllers['yanlis']!.text) ?? 0;
      final blank = int.tryParse(subjectControllers['bos']!.text) ?? 0;

      // ✅ DÜZELTME: 'SubjectDetails' nesnesinden 'questionCount' alınıyor.
      final questionCountForSubject = _selectedSection!.subjects[subject]?.questionCount ?? 0;

      // Doğru, yanlış, boş toplamı dersin soru sayısını geçemez kontrolü
      if (correct + wrong + blank > questionCountForSubject) {
        // Hata durumunu kullanıcıya bildir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$subject dersi için girdiğiniz değerler toplam soru sayısını ($questionCountForSubject) aşıyor!')),
        );
        // İşlemi durdur
        setState(() => _isLoading = false);
        return;
      }

      scores[subject] = {'dogru': correct, 'yanlis': wrong, 'bos': blank};
      totalCorrect += correct;
      totalWrong += wrong;
      totalBlankCount += blank;
      // ✅ DÜZELTME: Toplam soru sayısına doğru değer ekleniyor.
      totalQuestionCount += questionCountForSubject;
    });

    if (!_isLoading) return; // Hatalı giriş nedeniyle işlem durduysa devam etme

    final totalNet = totalCorrect - (totalWrong * _selectedSection!.penaltyCoefficient);
    final userId = ref.read(authControllerProvider).value!.uid;

    final newTest = TestModel(
      id: '', // Firestore ID'yi kendisi atayacak
      userId: userId,
      testName: _testNameController.text.trim(),
      examType: selectedExamType,
      sectionName: _selectedSection!.name,
      date: DateTime.now(),
      scores: scores,
      totalNet: totalNet,
      totalQuestions: totalQuestionCount,
      totalCorrect: totalCorrect.toInt(), // double'dan int'e çevriliyor
      totalWrong: totalWrong.toInt(),     // double'dan int'e çevriliyor
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
    final userProfile = ref.watch(userProfileProvider).value;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userProfile.selectedExam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Lütfen profilden bir sınav seçin.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final selectedExamType = ExamType.values.byName(userProfile.selectedExam!);
    final selectedExam = ExamData.getExamByType(selectedExamType);

    // Eğer sınavın tek bölümü varsa ve _selectedSection henüz ayarlanmamışsa, ayarla.
    if (selectedExam.sections.length == 1 && _selectedSection == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedSection = selectedExam.sections.first;
          _initializeControllers(_selectedSection!);
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('${selectedExamType.displayName} Denemesi Ekle')),
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
                    labelText: 'Sınav Adı (Örn: TYT Genel Deneme 5)'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Sınav adı boş olamaz.' : null,
              ),
              const SizedBox(height: 24),

              if (selectedExam.sections.length > 1)
                DropdownButtonFormField<ExamSection>(
                  value: _selectedSection,
                  decoration: const InputDecoration(labelText: 'Sınav Bölümü'),
                  hint: const Text('Sınav bölümünü seçin'),
                  items: selectedExam.sections
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
                  validator: (v) => v == null ? 'Lütfen bir bölüm seçin.' : null,
                )
              else if (selectedExam.sections.isNotEmpty)
                ListTile(
                  title: const Text("Sınav Bölümü"),
                  subtitle: Text(selectedExam.sections.first.name),
                  contentPadding: EdgeInsets.zero,
                ),

              const SizedBox(height: 24),

              if (_selectedSection != null)
                ..._controllers.keys.map((subject) =>
                    _buildSubjectExpansionTile(subject, _selectedSection!.subjects[subject]!)),

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

  // ✅ DÜZELTME: Fonksiyon artık 'int' yerine 'SubjectDetails' nesnesi alıyor.
  Widget _buildSubjectExpansionTile(String subject, SubjectDetails subjectDetails) {
    return ExpansionTile(
      title: Text('$subject (${subjectDetails.questionCount} Soru)'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildScoreTextField('Doğru', _controllers[subject]!['dogru']!),
        _buildScoreTextField('Yanlış', _controllers[subject]!['yanlis']!),
        _buildScoreTextField('Boş', _controllers[subject]!['bos']!),
      ],
    );
  }

  Widget _buildScoreTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) =>
        v == null || v.isEmpty ? 'Bu alan boş olamaz.' : null,
      ),
    );
  }
}