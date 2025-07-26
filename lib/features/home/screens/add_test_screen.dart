// lib/features/home/screens/add_test_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final Map<String, Map<String, TextEditingController>> _controllers = {
    'Türkçe': {
      'dogru': TextEditingController(),
      'yanlis': TextEditingController(),
      'bos': TextEditingController(),
    },
    'Matematik': {
      'dogru': TextEditingController(),
      'yanlis': TextEditingController(),
      'bos': TextEditingController(),
    },
    // Diğer dersleri buraya ekleyebilirsin
  };
  bool _isLoading = false;

  @override
  void dispose() {
    _testNameController.dispose();
    _controllers.forEach((_, subjectControllers) {
      subjectControllers.forEach((_, controller) => controller.dispose());
    });
    super.dispose();
  }

  void _saveTest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final scores = <String, Map<String, int>>{};
      double totalCorrect = 0;
      double totalWrong = 0;

      _controllers.forEach((subject, subjectControllers) {
        final correct = int.tryParse(subjectControllers['dogru']!.text) ?? 0;
        final wrong = int.tryParse(subjectControllers['yanlis']!.text) ?? 0;
        final blank = int.tryParse(subjectControllers['bos']!.text) ?? 0;
        scores[subject] = {'dogru': correct, 'yanlis': wrong, 'bos': blank};
        totalCorrect += correct;
        totalWrong += wrong;
      });

      final totalNet = totalCorrect - (totalWrong * 0.25);
      final userId = ref.read(authControllerProvider).value!.uid;
      final newTest = TestModel(
        id: '', // Firestore ID'yi kendi atayacak
        testName: _testNameController.text.trim(),
        date: DateTime.now(),
        scores: scores,
        totalNet: totalNet,
      );

      try {
        await ref.read(firestoreServiceProvider).addTestResult(userId, newTest);
        if (mounted) context.pop();
      } catch (e) {
        // Hata yönetimi
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deneme Sınavı Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _testNameController,
                decoration: const InputDecoration(labelText: 'Sınav Adı (Örn: TYT Genel Deneme 5)'),
                validator: (v) => v!.isEmpty ? 'Sınav adı boş olamaz.' : null,
              ),
              const SizedBox(height: 16),
              ..._controllers.keys.map((subject) => _buildSubjectExpansionTile(subject)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTest,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Kaydet'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectExpansionTile(String subject) {
    return ExpansionTile(
      title: Text(subject),
      children: [
        _buildScoreTextField('Doğru', _controllers[subject]!['dogru']!),
        _buildScoreTextField('Yanlış', _controllers[subject]!['yanlis']!),
        _buildScoreTextField('Boş', _controllers[subject]!['bos']!),
      ],
    );
  }

  Widget _buildScoreTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) => v!.isEmpty ? 'Boş olamaz.' : null,
      ),
    );
  }
}