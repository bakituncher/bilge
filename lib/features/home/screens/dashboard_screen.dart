// lib/features/home/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsyncValue = ref.watch(testsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ana Panel')),
      body: testsAsyncValue.when(
        data: (tests) {
          if (tests.isEmpty) {
            return const Center(
              child: Text('Henüz deneme sınavı eklemedin.\nSağ alttaki "+" butonuna tıkla!'),
            );
          }
          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return ListTile(
                title: Text(test.testName),
                subtitle: Text(DateFormat.yMMMMd('tr').format(test.date)),
                trailing: Text('${test.totalNet.toStringAsFixed(2)} Net'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/home/add-test'),
        child: const Icon(Icons.add),
      ),
    );
  }
}