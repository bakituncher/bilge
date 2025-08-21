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
import 'dart:ui'; // glass effect için eklendi

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
    if (userId == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: .85),
            AppTheme.primaryColor.withValues(alpha: .55),
            AppTheme.cardColor.withValues(alpha: .40),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.lightSurfaceColor.withValues(alpha: .35), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: _PlanView(
          weeklyPlan: weeklyPlanData != null ? WeeklyPlan.fromJson(weeklyPlanData) : null,
          userId: userId,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: .12, curve: Curves.easeOut);
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
    if (weeklyPlan == null || weeklyPlan!.plan.isEmpty) return const _EmptyStateCard();
    final selectedDayIndex = ref.watch(_selectedDayProvider);
    final dayName = _daysOfWeek[selectedDayIndex];
    final dailyPlan = weeklyPlan!.plan.firstWhere((p) => p.day == dayName, orElse: () => DailyPlan(day: dayName, schedule: []));
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dateForTab = startOfWeek.add(Duration(days: selectedDayIndex));
    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);
    final user = ref.watch(userProfileProvider).value;

    return Column(children: [
      _HeaderBar(dateForTab: dateForTab, weeklyPlan: weeklyPlan!, userId: userId),
      _DaySelector(days: _daysOfWeekShort),
      const SizedBox(height: 6),
      if (user != null && selectedDayIndex == (DateTime.now().weekday - 1))
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _TodayInlineCta(dailyPlan: dailyPlan, dateKey: dateKey, user: user)),
      const SizedBox(height: 8),
      Expanded(
        child: AnimatedSwitcher(
          duration: 300.ms,
          switchInCurve: Curves.easeOut,
          child: dailyPlan.schedule.isEmpty
              ? const _RestDay()
              : ListView.separated(
                  key: PageStorageKey<String>(dayName),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: dailyPlan.schedule.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scheduleItem = dailyPlan.schedule[index];
                    return _TaskTile(
                      key: ValueKey('$dateKey-${scheduleItem.time}-${scheduleItem.activity}'),
                      item: scheduleItem,
                      dateKey: dateKey,
                      userId: userId,
                    ).animate().fadeIn(delay: (40 * index).ms).slideX(begin: .15, curve: Curves.easeOutCubic);
                  },
                ),
        ),
      ),
    ]);
  }
}

class _HeaderBar extends ConsumerWidget {
  final DateTime dateForTab; final WeeklyPlan weeklyPlan; final String userId; const _HeaderBar({required this.dateForTab, required this.weeklyPlan, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    int total=0; int done=0; if(user!=null){ final now=DateTime.now(); final sow=now.subtract(Duration(days: now.weekday-1)); for(int i=0;i<weeklyPlan.plan.length;i++){ final dp=weeklyPlan.plan[i]; total+=dp.schedule.length; final d=sow.add(Duration(days:i)); final k=DateFormat('yyyy-MM-dd').format(d); done += (user.completedDailyTasks[k]??[]).length; } }
    final ratio = total==0?0: done/total;
    return Container(
      padding: const EdgeInsets.fromLTRB(20,18,20,16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        gradient: LinearGradient(colors:[AppTheme.secondaryColor.withOpacity(.18), AppTheme.secondaryColor.withOpacity(.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children:[
        Stack(alignment: Alignment.center, children:[
          SizedBox(height:58,width:58,child:CircularProgressIndicator(strokeWidth:6,value:ratio.clamp(0,1),backgroundColor:AppTheme.lightSurfaceColor.withOpacity(.35),valueColor:AlwaysStoppedAnimation(ratio>=.75?AppTheme.successColor:AppTheme.secondaryColor))),
          Column(mainAxisSize: MainAxisSize.min,children:[Text('${(ratio*100).round()}%',style: const TextStyle(fontWeight: FontWeight.bold,fontSize:14)), const Text('Hafta',style: TextStyle(fontSize:10,color:AppTheme.secondaryTextColor))])
        ]),
        const SizedBox(width:16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('Haftalık Harekât', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height:4),
          Text(DateFormat.yMMMMd('tr').format(dateForTab), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
          const SizedBox(height:6),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(minHeight:6,value:ratio.clamp(0,1),backgroundColor:AppTheme.lightSurfaceColor.withOpacity(.25), valueColor:AlwaysStoppedAnimation(ratio>=.75?AppTheme.successColor:AppTheme.secondaryColor)))
        ])),
        IconButton(tooltip:'Planı Aç', onPressed: ()=> context.go('/home/weekly-plan'), icon: const Icon(Icons.open_in_new_rounded,color:AppTheme.secondaryColor))
      ]),
    );
  }
}

class _RestDay extends StatelessWidget { const _RestDay(); @override Widget build(BuildContext context){ return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ const Icon(Icons.self_improvement_rounded,size:48,color:AppTheme.secondaryColor), const SizedBox(height:12), Text('Dinlenme Günü', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height:6), Text('Zihinsel depoları doldur – yarın yeniden hücum.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)) ]).animate().fadeIn(duration: 400.ms)); } }

class _TodayInlineCta extends StatelessWidget {
  final DailyPlan dailyPlan; final String dateKey; final dynamic user; // user tip: UserModel
  const _TodayInlineCta({required this.dailyPlan, required this.dateKey, required this.user});

  @override
  Widget build(BuildContext context) {
    if (dailyPlan.schedule.isEmpty) return const SizedBox.shrink();
    final completed = (user.completedDailyTasks[dateKey] ?? []) as List;
    final total = dailyPlan.schedule.length;
    final done = completed.length;
    if (done >= total) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: .6)),
          color: AppTheme.successColor.withValues(alpha: .12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Bugünkü plan tamamlandı! Dinlenebilir veya strateji gözden geçirebilirsin.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.successColor, fontWeight: FontWeight.w600),),
            ),
          ],
        ),
      );
    }
    final ratio = done/total;
    Color barColor;
    if (ratio >= .75) { barColor = Colors.greenAccent; }
    else if (ratio >= .5) { barColor = AppTheme.secondaryColor; }
    else { barColor = AppTheme.lightSurfaceColor.withValues(alpha: .9); }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // Kart zaten görünür; hafif titreşim / highlight için snackbar ipucu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eksik görevleri işaretleyerek tamamla: $done / $total')),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [barColor.withValues(alpha: .20), AppTheme.cardColor.withValues(alpha: .60)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: barColor.withValues(alpha: .7), width: 1.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 46,
                  width: 46,
                  child: CircularProgressIndicator(
                    value: ratio.clamp(0,1),
                    strokeWidth: 6,
                    backgroundColor: AppTheme.lightSurfaceColor.withValues(alpha: .25),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
                Icon(Icons.flag_rounded, color: barColor, size: 22),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bugünkü Planı Tamamla', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$done / $total görev tamamlandı', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondaryTextColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.secondaryTextColor),
          ],
        ),
      ),
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

    // HATA: Burada Material ve InkWell eklenerek düzeltildi.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => isCompleted ? null : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görevi tamamlamak için butona dokun.'))),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: (isCompleted? AppTheme.successColor: AppTheme.lightSurfaceColor).withOpacity(.35), width: 1),
            gradient: LinearGradient(colors:[ (isCompleted? AppTheme.successColor: AppTheme.secondaryColor).withOpacity(.08), AppTheme.cardColor.withOpacity(.35)], begin: Alignment.topLeft,end: Alignment.bottomRight),
          ),
          padding: const EdgeInsets.fromLTRB(14,12,6,12),
          child: Row(children:[
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: (isCompleted? AppTheme.successColor: AppTheme.secondaryColor).withOpacity(.18)), child: Animate(target: isCompleted?1:0, effects:[ScaleEffect(duration:300.ms, curve: Curves.easeOutBack)], child: Icon(_getIconForTaskType(item.type), color: isCompleted? AppTheme.successColor: AppTheme.secondaryColor))),
            const SizedBox(width:14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(item.activity, maxLines:2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize:15,fontWeight:FontWeight.w600,letterSpacing:.3,color: isCompleted? AppTheme.secondaryTextColor: Colors.white, decoration: isCompleted? TextDecoration.lineThrough: TextDecoration.none, decorationColor: AppTheme.secondaryTextColor)),
              const SizedBox(height:4),
              Row(children:[ Icon(Icons.schedule,size:13,color:AppTheme.secondaryTextColor.withOpacity(.9)), const SizedBox(width:4), Text(item.time, style: const TextStyle(color: AppTheme.secondaryTextColor,fontSize:11)) ])
            ])),
            IconButton(icon: AnimatedSwitcher(duration:250.ms, switchInCurve: Curves.elasticOut, child: Icon(isCompleted? Icons.check_circle_rounded: Icons.radio_button_unchecked_rounded, key: ValueKey<bool>(isCompleted), color: isCompleted? AppTheme.successColor: AppTheme.lightSurfaceColor, size:30)), onPressed: () async { ref.read(firestoreServiceProvider).updateDailyTaskCompletion(userId: userId, dateKey: dateKey, task: taskIdentifier, isCompleted: !isCompleted); if(!isCompleted){ final questId='schedule_${dateKey}_${taskIdentifier.hashCode}'; await ref.read(questNotifierProvider.notifier).updateQuestProgressById(questId); if(context.mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan görevi fethedildi: ${item.activity}'))); } } })
          ]),
        ),
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
