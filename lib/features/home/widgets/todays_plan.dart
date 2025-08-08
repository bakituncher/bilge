// lib/features/home/widgets/todays_plan.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';

// Seçili günü yönetmek için yeni bir state provider
final selectedDayProvider = StateProvider.autoDispose<int>((ref) {
  int todayIndex = DateTime.now().weekday - 1;
  return todayIndex.clamp(0, 6);
});

class TodaysPlan extends ConsumerWidget {
  const TodaysPlan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyPlanData = ref.watch(userProfileProvider.select((user) => user.value?.weeklyPlan));
    final userId = ref.watch(userProfileProvider.select((user) => user.value?.id));

    if (userId == null) {
      return const SizedBox.shrink(); // Kullanıcı yoksa bir şey gösterme
    }

    WeeklyPlan? weeklyPlan;
    if (weeklyPlanData != null) {
      weeklyPlan = WeeklyPlan.fromJson(weeklyPlanData);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Günün Görevleri", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        weeklyPlan == null || weeklyPlan.plan.isEmpty
            ? const _EmptyStateCard()
            : _PlanView(weeklyPlan: weeklyPlan, userId: userId),
      ],
    );
  }
}

class _PlanView extends ConsumerWidget {
  final WeeklyPlan weeklyPlan;
  final String userId;
  final List<String> _daysOfWeek = const ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
  final List<String> _daysOfWeekShort = const ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];

  const _PlanView({required this.weeklyPlan, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayIndex = ref.watch(selectedDayProvider);
    final dayName = _daysOfWeek[selectedDayIndex];
    final dailyPlan = weeklyPlan.plan.firstWhere(
          (p) => p.day == dayName,
      orElse: () => DailyPlan(day: dayName, schedule: []),
    );
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dateForTab = startOfWeek.add(Duration(days: selectedDayIndex));
    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);


    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _DaySelector(days: _daysOfWeekShort),
          const Divider(height: 1, color: AppTheme.lightSurfaceColor),
          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            child: SizedBox(
              height: 220,
              child: dailyPlan.schedule.isEmpty
                  ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        "Bugün için özel bir görev planlanmamış.\nDinlen ve gücünü topla!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic)
                    ),
                  ))
                  : ListView.builder(
                // *** KESİN VE NİHAİ ÇÖZÜM BURADA ***
                // Bu anahtar, listenin kaydırma pozisyonunu hafızasına alır
                // ve yeniden çizimlerde kaybolmasını ENGELLER.
                key: PageStorageKey<String>(dayName),
                padding: const EdgeInsets.all(16),
                itemCount: dailyPlan.schedule.length,
                itemBuilder: (context, index) {
                  final scheduleItem = dailyPlan.schedule[index];
                  return _TaskCard(
                    key: ValueKey("$dateKey-${scheduleItem.time}-${scheduleItem.activity}"),
                    item: scheduleItem,
                    dateKey: dateKey,
                    userId: userId,
                  ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.2);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends ConsumerWidget {
  final List<String> days;
  const _DaySelector({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayIndex = ref.watch(selectedDayProvider);
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = selectedDayIndex == index;
          return GestureDetector(
            onTap: () => ref.read(selectedDayProvider.notifier).state = index,
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
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

class _TaskCard extends ConsumerWidget {
  final ScheduleItem item;
  final String dateKey;
  final String userId;

  const _TaskCard({super.key, required this.item, required this.dateKey, required this.userId});

  IconData _getIconForTaskType(String type) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final taskIdentifier = "${item.time}-${item.activity}";
    final isCompleted = ref.watch(userProfileProvider.select(
          (user) => user.value?.completedDailyTasks[dateKey]?.contains(taskIdentifier) ?? false,
    ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Animate(
            target: isCompleted ? 1 : 0,
            effects: [ScaleEffect(duration: 300.ms, curve: Curves.easeOut)],
            child: Icon(_getIconForTaskType(item.type), color: isCompleted ? AppTheme.successColor : AppTheme.secondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity,
                  style: TextStyle(
                    color: isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppTheme.secondaryTextColor,
                  ),
                ),
                Text(item.time, style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: 200.ms,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey<bool>(isCompleted),
                color: AppTheme.successColor,
              ),
            ),
            onPressed: () {
              ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
                userId: userId,
                dateKey: dateKey,
                task: taskIdentifier,
                isCompleted: !isCompleted,
              );
            },
          )
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 40),
            const SizedBox(height: 16),
            Text(
              "Kader parşömenin mühürlenmeyi bekliyor.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "Stratejik planını oluşturarak görevlerini buraya yazdır.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('${AppRoutes.aiHub}/${AppRoutes.strategicPlanning}'),
              child: const Text('Stratejini Oluştur'),
            )
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}