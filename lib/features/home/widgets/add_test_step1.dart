// lib/features/home/widgets/add_test_step1.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/features/home/logic/add_test_notifier.dart';

class Step1TestInfo extends ConsumerWidget {
  const Step1TestInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addTestProvider);
    final notifier = ref.read(addTestProvider.notifier);

    final isButtonEnabled = state.testName.isNotEmpty && state.selectedSection != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Deneme Bilgileri", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.testName,
            decoration: const InputDecoration(labelText: 'Deneme Adı (Örn: 3D Genel Deneme)'),
            onChanged: (value) => notifier.setTestName(value),
          ),
          const SizedBox(height: 24),
          if (state.availableSections.length > 1)
            DropdownButtonFormField<ExamSection>(
              value: state.selectedSection,
              decoration: const InputDecoration(labelText: 'Deneme Türü'),
              hint: const Text('Bölüm Seçin'),
              items: state.availableSections.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (value) => notifier.setSection(value),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: isButtonEnabled ? () => notifier.nextStep() : null,
            child: const Text('İlerle'),
          ),
        ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
      ),
    );
  }
}