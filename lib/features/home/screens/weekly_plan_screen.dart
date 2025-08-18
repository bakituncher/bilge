// lib/features/home/screens/weekly_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/quests/logic/quest_notifier.dart';

final _selectedDayProvider = StateProvider.autoDispose<int>((ref) {
  int todayIndex = DateTime.now().weekday - 1;
  return todayIndex.clamp(0, 6);
});

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final weeklyPlan = user?.weeklyPlan != null ? WeeklyPlan.fromJson(user!.weeklyPlan!) : null;

    if (user == null || weeklyPlan == null) {
      // Normalde bu ekrana plan olmadan gelinmez ama güvenlik için eklendi.
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("Aktif bir haftalık plan bulunamadı.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harekât Takvimi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.cardColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stratejik Odak:",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor),
                    ),
                    Text(
                      weeklyPlan.strategyFocus,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.secondaryColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              ),
              const SizedBox(height: 10),
              _DaySelector(
                days: const ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'],
              ),
              const Divider(height: 1, color: AppTheme.lightSurfaceColor),
              _buildPlanView(context, ref, weeklyPlan, user.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanView(BuildContext context, WidgetRef ref, WeeklyPlan weeklyPlan, String userId) {
    final selectedDayIndex = ref.watch(_selectedDayProvider);
    final dayName = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][selectedDayIndex];
    final dailyPlan = weeklyPlan.plan.firstWhere((p) => p.day == dayName, orElse: () => DailyPlan(day: dayName, schedule: []));

    return Expanded(
      child: AnimatedSwitcher(
        duration: 400.ms,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: dailyPlan.schedule.isEmpty
            ? _EmptyDayView(key: ValueKey(dayName))
            : _TaskListView(key: ValueKey(dayName), dailyPlan: dailyPlan, userId: userId),
      ),
    );
  }
}

class _DaySelector extends ConsumerWidget {
  final List<String> days;
  const _DaySelector({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayIndex = ref.watch(_selectedDayProvider);
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = selectedDayIndex == index;
          return GestureDetector(
            onTap: () => ref.read(_selectedDayProvider.notifier).state = index,
            child: AnimatedContainer(
              duration: 300.ms,
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondaryColor : AppTheme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: AppTheme.lightSurfaceColor),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskListView extends ConsumerWidget {
  final DailyPlan dailyPlan;
  final String userId;

  const _TaskListView({super.key, required this.dailyPlan, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dayIndex = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'].indexOf(dailyPlan.day);
    final dateForTab = startOfWeek.add(Duration(days: dayIndex));
    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: dailyPlan.schedule.length,
      itemBuilder: (context, index) {
        final item = dailyPlan.schedule[index];
        final taskIdentifier = '${item.time}-${item.activity}';
        final isCompleted = ref.watch(userProfileProvider.select(
              (user) => user.value?.completedDailyTasks[dateKey]?.contains(taskIdentifier) ?? false,
        ));

        return _TaskTimelineTile(
          item: item,
          isCompleted: isCompleted,
          isFirst: index == 0,
          isLast: index == dailyPlan.schedule.length - 1,
          dateKey: dateKey,
          onToggle: () async {
            ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
              userId: userId,
              dateKey: dateKey,
              task: taskIdentifier,
              isCompleted: !isCompleted,
            );
            if(!isCompleted) {
              final questId = 'schedule_${dateKey}_${taskIdentifier.hashCode}';
              await ref.read(questNotifierProvider.notifier).updateQuestProgressById(questId);
              if(context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Plan görevi fethedildi: ${item.activity}')),
                );
              }
            }
          },
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.5, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _TaskTimelineTile extends StatelessWidget {
  final ScheduleItem item;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onToggle;
  final String dateKey; // yeni

  const _TaskTimelineTile({
    required this.item,
    required this.isCompleted,
    required this.isFirst,
    required this.isLast,
    required this.onToggle,
    required this.dateKey,
  });

  IconData _getIconForTaskType(String type) {
    // ... (öncekiyle aynı ikon fonksiyonu)
    switch (type.toLowerCase()) {
      case 'study': return Icons.book_rounded;
      case 'practice': case 'routine': return Icons.edit_note_rounded;
      case 'test': return Icons.quiz_rounded;
      case 'review': return Icons.history_edu_rounded;
      case 'break': return Icons.self_improvement_rounded;
      default: return Icons.shield_moon_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ZAMAN TÜNELİ ÇİZGİSİ VE İKONU
          SizedBox(
            width: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: AppTheme.lightSurfaceColor)),
                if (isFirst) const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.secondaryColor, width: 2),
                    color: AppTheme.cardColor,
                  ),
                  child: Icon(_getIconForTaskType(item.type), color: AppTheme.secondaryColor, size: 20),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppTheme.lightSurfaceColor)),
                if (isLast) const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // GÖREV KARTI VE TAMAMLAMA BUTONU
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Card(
                color: isCompleted ? AppTheme.cardColor.withOpacity(0.5) : AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.activity,
                              style: TextStyle(
                                fontSize: 16,
                                color: isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                            Text(item.time, style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggle,
                        child: AnimatedContainer(
                          duration: 300.ms,
                          width: 50,
                          decoration: BoxDecoration(
                              color: isCompleted ? AppTheme.successColor : AppTheme.lightSurfaceColor.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              )
                          ),
                          child: Center(
                            child: Icon(isCompleted ? Icons.check : Icons.circle_outlined, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  const _EmptyDayView({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_moon_rounded, size: 64, color: AppTheme.secondaryTextColor),
        const SizedBox(height: 16),
        Text(
          "Dinlenme ve Strateji Günü",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            "Zihnini dinlendir, yarınki fethe hazırlan!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}