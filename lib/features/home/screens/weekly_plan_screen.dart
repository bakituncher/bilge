// lib/features/home/screens/weekly_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_notifier.dart';
import 'package:flutter/services.dart'; // Haptic için

final _selectedDayProvider = StateProvider.autoDispose<int>((ref) {
  int todayIndex = DateTime.now().weekday - 1;
  return todayIndex.clamp(0, 6);
});

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final planDoc = ref.watch(planProvider).value;
    final weeklyPlan = planDoc?.weeklyPlan != null ? WeeklyPlan.fromJson(planDoc!.weeklyPlan!) : null;

    if (user == null || weeklyPlan == null) {
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: WeeklyOverviewCard(weeklyPlan: weeklyPlan, userId: user.id),
              ),
              const SizedBox(height: 4),
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

class _TaskListView extends ConsumerStatefulWidget {
  final DailyPlan dailyPlan; final String userId;
  const _TaskListView({super.key, required this.dailyPlan, required this.userId});
  @override
  ConsumerState<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<_TaskListView> with AutomaticKeepAliveClientMixin<_TaskListView> {
  @override bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dailyPlan = widget.dailyPlan; final userId = widget.userId;
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dayIndex = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'].indexOf(dailyPlan.day);
    final dateForTab = startOfWeek.add(Duration(days: dayIndex));
    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);
    final totalTasks = dailyPlan.schedule.length;
    final completedList = ref.watch(completedTasksForDateProvider(dateForTab)).maybeWhen(data: (list)=> list, orElse: ()=> const <String>[]);
    final completedCount = dailyPlan.schedule.where((item) {
      final taskIdentifier = '${item.time}-${item.activity}';
      return completedList.contains(taskIdentifier);
    }).length;
    final progress = totalTasks == 0 ? 0.0 : completedCount / totalTasks;

    return Column(
      children: [
        _DaySummaryHeader(dayLabel: dailyPlan.day, date: dateForTab, completed: completedCount, total: totalTasks, progress: progress),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: dailyPlan.schedule.length,
            itemBuilder: (context, index) {
              final item = dailyPlan.schedule[index];
              final taskIdentifier = '${item.time}-${item.activity}';
              final isCompleted = completedList.contains(taskIdentifier);
              return RepaintBoundary(
                child: _TaskTimelineTile(
                  item: item,
                  isCompleted: isCompleted,
                  isFirst: index == 0,
                  isLast: index == dailyPlan.schedule.length - 1,
                  dateKey: dateKey,
                  onToggle: () async {
                    HapticFeedback.selectionClick();
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan görevi fethedildi: ${item.activity}')));
                      }
                    }
                  },
                ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: .12, curve: Curves.easeOutCubic),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DaySummaryHeader extends StatelessWidget {
  final String dayLabel; final DateTime date; final int completed; final int total; final double progress;
  const _DaySummaryHeader({required this.dayLabel, required this.date, required this.completed, required this.total, required this.progress});
  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM', 'tr_TR').format(date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardColor.withOpacity(.55),
        border: Border.all(color: AppTheme.lightSurfaceColor.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$dayLabel • $dateStr', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text('${(progress*100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppTheme.lightSurfaceColor.withOpacity(.18),
              valueColor: AlwaysStoppedAnimation(progress >= 1 ? AppTheme.successColor : AppTheme.secondaryColor),
            ),
          ),
          const SizedBox(height: 6),
          Text('$completed / $total görev', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }
}

class WeeklyOverviewCard extends ConsumerWidget {
  final WeeklyPlan weeklyPlan; final String userId;
  const WeeklyOverviewCard({super.key, required this.weeklyPlan, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dates = List.generate(7, (i)=> startOfWeek.add(Duration(days: i)));
    final todayIndex = today.weekday - 1;
    final dateKeys = dates.map((d)=> DateFormat('yyyy-MM-dd').format(d)).toList();
    final allDaily = weeklyPlan.plan;
    int totalTasks = 0; int completedTasks = 0; Map<String,int> dayTotals = {}; Map<String,int> dayCompleted = {};
    for (final d in allDaily) {
      final idx = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'].indexOf(d.day);
      if (idx < 0) continue;
      final dk = dateKeys[idx];
      totalTasks += d.schedule.length;
      dayTotals[dk] = d.schedule.length;
      final completedList = ref.watch(completedTasksForDateProvider(dates[idx])).maybeWhen(data: (list)=> list, orElse: ()=> const <String>[]);
      int compForDay = 0;
      for (final item in d.schedule) {
        final id = '${item.time}-${item.activity}';
        if (completedList.contains(id)) compForDay++;
      }
      completedTasks += compForDay;
      dayCompleted[dk] = compForDay;
    }
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final weekRange = '${DateFormat('d MMM', 'tr_TR').format(dates.first)} - ${DateFormat('d MMM', 'tr_TR').format(dates.last)}';

    return GestureDetector(
      onTap: () => _showWeekDetails(context, ref, dates, dateKeys, dayTotals, dayCompleted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.cardColor.withOpacity(.50),
          border: Border.all(color: AppTheme.lightSurfaceColor.withOpacity(.20)),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 54, width: 54,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppTheme.lightSurfaceColor.withOpacity(.18),
                  valueColor: AlwaysStoppedAnimation(progress>=1? AppTheme.successColor : AppTheme.secondaryColor),
                ),
                Text('${(progress*100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Haftalık Harekât', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(weekRange, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
                  const SizedBox(height: 6),
                  Text('$completedTasks / $totalTasks görev', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(7, (i){
                      final dk = dateKeys[i]; final total = dayTotals[dk] ?? 0; final done = dayCompleted[dk] ?? 0; final ratio = total==0?0.0: done/total;
                      final isToday = i == todayIndex;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: i==6?0:4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                (ratio>=1? AppTheme.successColor : AppTheme.secondaryColor).withOpacity(ratio==0 ? .15 : .85),
                                (ratio>=1? AppTheme.successColor : AppTheme.secondaryColor).withOpacity(ratio==0 ? .18 : 1),
                              ],
                            ),
                            border: isToday ? Border.all(color: Colors.white.withOpacity(.6), width: 1) : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (totalTasks>0) Text('${remainingLabel(completedTasks,totalTasks)}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
          ],
        ),
      ),
    );
  }

  String remainingLabel(int done, int total){
    if (total==0) return '-';
    final rem = total-done;
    if (rem==0) return 'Bitti';
    return 'Kalan $rem';
  }

  void _showWeekDetails(BuildContext context, WidgetRef ref, List<DateTime> dates, List<String> dateKeys, Map<String,int> dayTotals, Map<String,int> dayCompleted){
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor.withOpacity(.9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20,16,20,32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Text('Haftalık Detay', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(7, (i){
                final dk = dateKeys[i]; final date = dates[i];
                final total = dayTotals[dk] ?? 0; final done = dayCompleted[dk] ?? 0; final ratio = total==0?0.0: done/total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 84, child: Text(DateFormat('E d MMM','tr_TR').format(date), style: Theme.of(context).textTheme.labelSmall)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: AppTheme.lightSurfaceColor.withOpacity(.2),
                            valueColor: AlwaysStoppedAnimation(ratio>=1? AppTheme.successColor : AppTheme.secondaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$done/$total', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
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
  final String dateKey;

  const _TaskTimelineTile({
    required this.item,
    required this.isCompleted,
    required this.isFirst,
    required this.isLast,
    required this.onToggle,
    required this.dateKey,
  });

  Color _typeColor(String type){
    switch(type.toLowerCase()){
      case 'study': return AppTheme.secondaryColor;
      case 'practice': return Colors.orangeAccent;
      case 'test': return Colors.purpleAccent;
      case 'review': return Colors.tealAccent;
      case 'break': return Colors.blueGrey;
      default: return AppTheme.lightSurfaceColor;
    }
  }

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
  Widget build(BuildContext context) {
    final accent = _typeColor(item.type);
    final icon = _getIconForTaskType(item.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onToggle,
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isCompleted ? AppTheme.cardColor.withOpacity(.45) : AppTheme.cardColor.withOpacity(.82),
              border: Border.all(color: accent.withOpacity(.30)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.12),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(.25),
                          border: Border.all(color: accent.withOpacity(.55), width: 1),
                        ),
                        child: Icon(icon, size: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        width: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isCompleted ? AppTheme.successColor : accent.withOpacity(.55),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14,12,12,12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.activity,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: AppTheme.secondaryTextColor.withOpacity(.8)),
                            const SizedBox(width: 4),
                            Text(item.time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor.withOpacity(.8))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppTheme.successColor : accent.withOpacity(.28),
                      border: Border.all(color: accent.withOpacity(.55), width: 1.1),
                    ),
                    child: Icon(isCompleted ? Icons.check_rounded : Icons.circle_outlined, color: Colors.white)
                        .animate(target: isCompleted ? 1 : 0)
                        .scale(duration: 300.ms, curve: Curves.easeOutBack),
                  ),
                )
              ],
            ),
          ),
        ),
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