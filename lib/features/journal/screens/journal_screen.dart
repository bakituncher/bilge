// lib/features/journal/screens/journal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/journal_entry_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalEntriesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başarı Günlüğüm'),
      ),
      body: journalAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_note, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz hiç not eklemedin.',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sağ alttaki (+) butonuyla ilk başarını kaydet!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Animate(
                effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
                child: _buildJournalCard(context, ref, entry),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Hata: ${e.toString()}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/home/journal/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, WidgetRef ref, JournalEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: Icon(entry.category.icon, color: colorScheme.secondary),
        title: Text(entry.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${entry.category.displayName} - ${DateFormat.yMMMMd('tr').format(entry.date)}',
          style: textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            // Silme onayı
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Notu Sil'),
                content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
                actions: [
                  TextButton(onPressed: () => context.pop(false), child: const Text('İptal')),
                  TextButton(onPressed: () => context.pop(true), child: const Text('Sil')),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(firestoreServiceProvider).deleteJournalEntry(entry.id);
            }
          },
        ),
        onTap: () => context.go('/home/journal/edit', extra: entry),
      ),
    );
  }
}