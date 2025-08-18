// lib/features/home/widgets/dashboard_cards/weekly_plan_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
import 'package:bilge_ai/features/quests/logic/quest_notifier.dart';

// Bu kartın kendi içindeki günü yönetmesi için özel provider
final _selectedDayProvider = StateProvider.autoDispose<int>((ref) {
  int todayIndex = DateTime.now().weekday - 1;
  return todayIndex.clamp(0, 6);
});

class WeeklyPlanCard extends ConsumerWidget {
  const WeeklyPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyPlanData = ref.watch(userProfileProvider.select((user) => user.value?.weeklyPlan));
    final userId = ref.watch(userProfileProvider.select((user) => user.value?.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withValues(alpha: AppTheme.primaryColor.opacity * 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: userId == null
          ? const SizedBox.shrink()
          : _PlanView(
        weeklyPlan: weeklyPlanData != null ? WeeklyPlan.fromJson(weeklyPlanData) : null,
        userId: userId,
      ),
    );
  }
}

class _PlanView extends ConsumerWidget {
  final WeeklyPlan? weeklyPlan;
  final String userId;
  final List<String> _daysOfWeek = const ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  final List<String> _daysOfWeekShort = const ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'];

  const _PlanView({required this.weeklyPlan, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (weeklyPlan == null || weeklyPlan!.plan.isEmpty) {
      return const _EmptyStateCard();
    }

    final selectedDayIndex = ref.watch(_selectedDayProvider);
    final dayName = _daysOfWeek[selectedDayIndex];
    final dailyPlan = weeklyPlan!.plan.firstWhere((p) => p.day == dayName, orElse: () => DailyPlan(day: dayName, schedule: []));
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dateForTab = startOfWeek.add(Duration(days: selectedDayIndex));
    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Haftalık Harekât', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    DateFormat.yMMMMd('tr').format(dateForTab),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _WeeklyProgressSummary(weeklyPlan: weeklyPlan!, userId: userId),
            ],
          ),
        ),
        _DaySelector(days: _daysOfWeekShort),
        const Divider(height: 1, thickness: 1, color: AppTheme.lightSurfaceColor, indent: 20, endIndent: 20),
        Expanded(
          child: AnimatedSwitcher(
            duration: 300.ms,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: dailyPlan.schedule.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text('Bugün dinlenme ve strateji gözden geçirme günü.\nZihnini dinlendir, yarınki fethe hazırlan!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic)),
              ),
            ).animate().fadeIn()
                : ListView.builder(
              key: PageStorageKey<String>(dayName),
              padding: const EdgeInsets.all(20),
              itemCount: dailyPlan.schedule.length,
              itemBuilder: (context, index) {
                final scheduleItem = dailyPlan.schedule[index];
                return _TaskTile(
                  key: ValueKey('$dateKey-${scheduleItem.time}-${scheduleItem.activity}'),
                  item: scheduleItem,
                  dateKey: dateKey,
                  userId: userId,
                ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.2);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgressSummary extends ConsumerWidget {
  final WeeklyPlan weeklyPlan;
  final String userId;
  const _WeeklyProgressSummary({required this.weeklyPlan, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null) return const SizedBox.shrink();

    // Haftanın başlangıcı
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    int total = 0; int done = 0;
    for (int i=0;i<weeklyPlan.plan.length;i++) {
      final dp = weeklyPlan.plan[i];
      total += dp.schedule.length;
      final date = startOfWeek.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      done += (user.completedDailyTasks[key] ?? []).length;
    }
    if (total == 0) return const SizedBox.shrink();
    final ratio = done/total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0,1),
                  minHeight: 8,
                  backgroundColor: AppTheme.lightSurfaceColor,
                  valueColor: AlwaysStoppedAnimation<Color>(ratio >= .75 ? AppTheme.successColor : AppTheme.secondaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${(ratio*100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Haftalık ilerleme: $done / $total görev', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
        ),
      ],
    );
  }
}

class _DaySelector extends ConsumerWidget {
  final List<String> days;
  const _DaySelector({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayIndex = ref.watch(_selectedDayProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(days.length, (index) {
            // HATA BURADAYDI, DÜZELTİLDİ: 'isSelected' değişkeni tekrar tanımlandı.
            final isSelected = selectedDayIndex == index;
            return GestureDetector(
              onTap: () => ref.read(_selectedDayProvider.notifier).state = index,
              child: AnimatedContainer(
                duration: 250.ms,
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final ScheduleItem item;
  final String dateKey;
  final String userId;

  const _TaskTile({super.key, required this.item, required this.dateKey, required this.userId});

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
    final taskIdentifier = '${item.time}-${item.activity}';
    final isCompleted = ref.watch(userProfileProvider.select(
          (user) => user.value?.completedDailyTasks[dateKey]?.contains(taskIdentifier) ?? false,
    ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppTheme.successColor.withValues(alpha: AppTheme.successColor.opacity * 0.15) : AppTheme.secondaryColor.withValues(alpha: AppTheme.secondaryColor.opacity * 0.15),
            ),
            child: Animate(
              target: isCompleted ? 1 : 0,
              effects: [ScaleEffect(duration: 300.ms, curve: Curves.easeOut)],
              child: Icon(_getIconForTaskType(item.type),
                  color: isCompleted ? AppTheme.successColor : AppTheme.secondaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity,
                  style: TextStyle(
                    fontSize: 16,
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
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey<bool>(isCompleted),
                color: isCompleted ? AppTheme.successColor : AppTheme.lightSurfaceColor,
              ),
            ),
            onPressed: () async {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 40),
          const SizedBox(height: 16),
          Text('Kader parşömenin mühürlenmeyi bekliyor.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Stratejik planını oluşturarak görevlerini buraya yazdır.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('${AppRoutes.aiHub}/${AppRoutes.strategicPlanning}'),
            child: const Text('Stratejini Oluştur'),
          )
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}