// lib/features/onboarding/screens/availability_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

final availabilityProvider = StateProvider.autoDispose<Map<String, List<String>>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  return Map<String, List<String>>.from(user?.weeklyAvailability.map((key, value) => MapEntry(key, List<String>.from(value))) ?? {});
});

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  final List<String> days = const ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
  final List<String> timeSlots = const [
    "Sabah Erken (06-09)",
    "Sabah Geç (09-12)",
    "Öğle (13-15)",
    "Öğleden Sonra (15-18)",
    "Akşam (19-21)",
    "Gece (21-24)"
  ];

  void _onSave(BuildContext context, WidgetRef ref) async {
    final availability = ref.read(availabilityProvider);
    final userId = ref.read(userProfileProvider).value!.id;

    if (availability.values.every((list) => list.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir tane müsait zaman dilimi seçin.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    await ref.read(firestoreServiceProvider).updateWeeklyAvailability(
      userId: userId,
      availability: availability,
    );

    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zaman Haritan"),
        automaticallyImplyLeading: context.canPop(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => _onSave(context, ref),
              child: const Text("Kaydet"),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hangi zaman dilimlerinde genellikle ders çalışmaya müsaitsin?",
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "BilgeAI, haftalık planını sadece seçtiğin bu zaman aralıklarına göre oluşturacak.",
              style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
            ),
            const SizedBox(height: 24),
            ...days.map((day) {
              return _DayAvailabilitySelector(
                key: ValueKey(day),
                day: day,
                timeSlots: timeSlots,
              ).animate().fadeIn(delay: (100 * days.indexOf(day)).ms).slideX(begin: -0.2);
            }).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _DayAvailabilitySelector extends ConsumerWidget {
  const _DayAvailabilitySelector({
    super.key,
    required this.day,
    required this.timeSlots,
  });

  final String day;
  final List<String> timeSlots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(availabilityProvider);
    final selectedSlots = availability[day] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: timeSlots.map((slot) {
                final isSelected = selectedSlots.contains(slot);
                return FilterChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    final currentSlots = List<String>.from(availability[day] ?? []);
                    if (selected) {
                      currentSlots.add(slot);
                    } else {
                      currentSlots.remove(slot);
                    }
                    ref.read(availabilityProvider.notifier).state = {
                      ...availability,
                      day: currentSlots,
                    };
                  },
                  selectedColor: AppTheme.successColor.withOpacity(0.3),
                  checkmarkColor: AppTheme.successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(
                      color: isSelected ? AppTheme.successColor : AppTheme.lightSurfaceColor,
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}