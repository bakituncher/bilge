// lib/features/weakness_workshop/screens/saved_workshops_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart'; // Rotaları import ediyoruz
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/features/weakness_workshop/models/saved_workshop_model.dart';
import 'package:intl/intl.dart';

final savedWorkshopsProvider = StreamProvider.autoDispose<List<SavedWorkshopModel>>((ref) {
  final userId = ref.watch(authControllerProvider).value?.uid;
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(firestoreServiceProvider).getSavedWorkshops(userId);
});

class SavedWorkshopsScreen extends ConsumerWidget {
  const SavedWorkshopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedWorkshopsAsync = ref.watch(savedWorkshopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cevher Kasan"),
      ),
      body: savedWorkshopsAsync.when(
        data: (workshops) {
          if (workshops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.secondaryTextColor),
                  const SizedBox(height: 16),
                  Text('Kasan Henüz Boş', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Atölyede işlediğin değerli cevherleri buraya kaydederek onlara istediğin zaman geri dönebilirsin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: workshops.length,
            itemBuilder: (context, index) {
              final workshop = workshops[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.diamond_outlined, color: AppTheme.secondaryColor),
                  title: Text(workshop.topic),
                  subtitle: Text("${workshop.subject} - ${DateFormat.yMd('tr').format(workshop.savedDate.toDate())}"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  onTap: () {
                    // *** KESİN ÇÖZÜM BURADA ***
                    // Rota'ya tam adresini vererek yönlendirme yapıyoruz.
                    context.push(
                      '${AppRoutes.aiHub}/${AppRoutes.weaknessWorkshop}/${AppRoutes.savedWorkshopDetail}',
                      extra: workshop,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Hata: $e")),
      ),
    );
  }
}