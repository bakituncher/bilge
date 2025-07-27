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

  ExamType? _selectedExamType;
  ExamSection? _selectedSection;

  Map<String, Map<String, TextEditingController>> _controllers = {};
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
    _controllers = {};
  }

  void _initializeControllers(ExamSection section) {
    _clearControllers();
    final newControllers = <String, Map<String, TextEditingController>>{};
    for (var subject in section.subjects.keys) {
      newControllers[subject] = {
        'dogru': TextEditingController(),
        'yanlis': TextEditingController(),
        'bos': TextEditingController(),
      };
    }
    setState(() {
      _controllers = newControllers;
    });
  }

  void _saveTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExamType == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen sınav ve bölüm seçin.'))
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
      final questionCountForSubject = _selectedSection!.subjects[subject] ?? 0;

      if(correct + wrong + blank != questionCountForSubject){
        // Optional: Add validation
      }

      scores[subject] = {'dogru': correct, 'yanlis': wrong, 'bos': blank};
      totalCorrect += correct;
      totalWrong += wrong;
      totalBlankCount += blank;
      totalQuestionCount += questionCountForSubject;
    });

    final totalNet = totalCorrect - (totalWrong * _selectedSection!.penaltyCoefficient);
    final userId = ref.read(authControllerProvider).value!.uid;

    final newTest = TestModel(
      id: '', // Firestore will generate
      userId: userId,
      testName: _testNameController.text.trim(),
      examType: _selectedExamType!,
      sectionName: _selectedSection!.name,
      date: DateTime.now(),
      scores: scores,
      totalNet: totalNet,
      totalQuestions: totalQuestionCount,
      totalCorrect: totalCorrect.toInt(),
      totalWrong: totalWrong.toInt(),
      totalBlank: totalBlankCount,
      penaltyCoefficient: _selectedSection!.penaltyCoefficient, // GÜNCELLENDİ
    );

    try {
      await ref.read(firestoreServiceProvider).addTestResult(newTest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deneme başarıyla kaydedildi!'), backgroundColor: Colors.green,)
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bir hata oluştu: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Deneme Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _testNameController,
                decoration: const InputDecoration(labelText: 'Sınav Adı (Örn: TYT Genel Deneme 5)'),
                validator: (v) => v!.isEmpty ? 'Sınav adı boş olamaz.' : null,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<ExamType>(
                value: _selectedExamType,
                decoration: const InputDecoration(labelText: 'Sınav Türü'),
                hint: const Text('Sınav türünü seçin'),
                items: ExamType.values
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExamType = value;
                    _selectedSection = null;
                    _clearControllers();
                  });
                },
                validator: (v) => v == null ? 'Lütfen bir sınav türü seçin.' : null,
              ),
              const SizedBox(height: 24),

              if (_selectedExamType != null)
                DropdownButtonFormField<ExamSection>(
                  value: _selectedSection,
                  decoration: const InputDecoration(labelText: 'Sınav Bölümü'),
                  hint: const Text('Sınav bölümünü seçin'),
                  items: ExamData.getExamByType(_selectedExamType!)
                      .sections
                      .map((section) => DropdownMenuItem(
                    value: section,
                    child: Text(section.name),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSection = value;
                      if (value != null) {
                        _initializeControllers(value);
                      }
                    });
                  },
                  validator: (v) => v == null ? 'Lütfen bir bölüm seçin.' : null,
                ),
              const SizedBox(height: 24),

              if (_selectedSection != null)
                ..._controllers.keys.map((subject) =>
                    _buildSubjectExpansionTile(subject, _selectedSection!.subjects[subject]!)),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTest,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kaydet'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectExpansionTile(String subject, int totalQuestions) {
    return ExpansionTile(
      title: Text('$subject ($totalQuestions Soru)'),
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
        validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz.' : null,
      ),
    );
  }
}