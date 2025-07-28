// lib/features/journal/screens/add_edit_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/journal_entry_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:go_router/go_router.dart';

class AddEditJournalScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  const AddEditJournalScreen({super.key, this.entry});

  @override
  ConsumerState<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends ConsumerState<AddEditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late JournalCategory _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _selectedCategory = widget.entry?.category ?? JournalCategory.note;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final userId = ref.read(authControllerProvider).value!.uid;

      final newEntry = JournalEntry(
        id: widget.entry?.id ?? '',
        userId: userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        date: DateTime.now(),
      );

      try {
        await ref.read(firestoreServiceProvider).saveJournalEntry(newEntry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Günlük kaydı başarıyla kaydedildi!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Yeni Not Ekle' : 'Notu Düzenle'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEntry,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Bugünkü başarın neydi?',
                ),
                validator: (value) => value!.isEmpty ? 'Başlık boş olamaz.' : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<JournalCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: JournalCategory.values
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'İçerik',
                  hintText: 'Neler öğrendin, nasıl hissettin? Detayları yaz...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value!.isEmpty ? 'İçerik boş olamaz.' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}