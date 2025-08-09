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
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:bilge_ai/data/models/user_model.dart'; // HATA DÜZELTİLDİ
import 'package:bilge_ai/data/models/test_model.dart'; // HATA DÜZELTİLDİ

// DEV DEĞİŞİKLİK: Bu widget artık kaydırılabilir kartları barındıran ana merkez.
class TodaysPlan extends ConsumerWidget {
  const TodaysPlan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageController controller = PageController(viewportFraction: 0.9);

    return SizedBox(
      height: 400, // Kartların yüksekliğini belirledik
      child: PageView(
        controller: controller,
        padEnds: false, // İlk kartın kenara yaslanmasını sağlar
        children: const [
          _TodaysMissionCard(),
          _WeeklyPlanCard(),
        ],
      ),
    );
  }
}

// YENİ WIDGET: Günün Önceliği Kartı
class _TodaysMissionCard extends ConsumerWidget {
  const _TodaysMissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider).valueOrNull;
    final user = ref.watch(userProfileProvider).valueOrNull;

    return Card(
      margin: const EdgeInsets.only(left: 16, right: 8),
      elevation: 4,
      shadowColor: AppTheme.secondaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: user == null || tests == null
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.secondaryColor))
          : _buildMissionContent(context, ref, user, tests),
    );
  }

  Widget _buildMissionContent(
      BuildContext context, WidgetRef ref, UserModel user, List<TestModel> tests) {
    if (user.selectedExam == null) {
      return const SizedBox.shrink();
    }
    final examType = ExamType.values.byName(user.selectedExam!);

    return FutureBuilder<Exam>(
      future: ExamData.getExamByType(examType),
      builder: (context, examSnapshot) {
        if (!examSnapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor));
        }

        final exam = examSnapshot.data!;
        final textTheme = Theme.of(context).textTheme;

        IconData icon;
        String title;
        String subtitle;
        VoidCallback? onTap;
        String buttonText;

        if (tests.isEmpty) {
          title = 'Yolculuğa Başla';
          subtitle =
          'Potansiyelini ortaya çıkarmak için ilk deneme sonucunu ekle.';
          onTap = () => context.go('${AppRoutes.home}/${AppRoutes.addTest}');
          buttonText = 'İlk Denemeni Ekle';
          icon = Icons.add_chart_rounded;
        } else {
          final analysis =
          StatsAnalysis(tests, user.topicPerformances, exam, user: user);
          final weakestTopicInfo = analysis.getWeakestTopicWithDetails();
          title = 'Günün Önceliği';
          subtitle = weakestTopicInfo != null
              ? 'BilgeAI, en zayıf noktanın **\'${weakestTopicInfo['subject']}\'** dersindeki **\'${weakestTopicInfo['topic']}\'** konusu olduğunu tespit etti. Bu cevheri işlemeye hazır mısın?'
              : 'Harika gidiyorsun! Şu an belirgin bir zayıf noktan tespit edilmedi. Yeni konu verileri girerek analizi derinleştirebilirsin.';
          onTap = weakestTopicInfo != null
              ? () => context.push('${AppRoutes.aiHub}/${AppRoutes.weaknessWorkshop}')
              : null;
          buttonText = 'Cevher Atölyesine Git';
          icon = Icons.construction_rounded;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.1),
                  AppTheme.cardColor
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: AppTheme.secondaryColor),
                  const SizedBox(width: 12),
                  Text(title,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              _buildRichTextFromMarkdown(subtitle,
                  baseStyle: textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.secondaryTextColor, height: 1.5),
                  boldStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.textColor)),
              const Spacer(),
              if (onTap != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    child: Text(buttonText),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRichTextFromMarkdown(String text,
      {TextStyle? baseStyle, TextStyle? boldStyle}) {
    List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    text.splitMapJoin(regExp, onMatch: (m) {
      spans.add(TextSpan(
          text: m.group(1),
          style: boldStyle ?? baseStyle?.copyWith(fontWeight: FontWeight.bold)));
      return '';
    }, onNonMatch: (n) {
      spans.add(TextSpan(text: n));
      return '';
    });
    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}

// YENİ WIDGET: Haftalık Plan Kartı
class _WeeklyPlanCard extends ConsumerWidget {
  const _WeeklyPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyPlanData =
    ref.watch(userProfileProvider.select((user) => user.value?.weeklyPlan));
    final userId = ref.watch(userProfileProvider.select((user) => user.value?.id));

    return Card(
      margin: const EdgeInsets.only(left: 8, right: 16),
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: userId == null
          ? const SizedBox.shrink()
          : _PlanView(
          weeklyPlan: weeklyPlanData != null
              ? WeeklyPlan.fromJson(weeklyPlanData)
              : null,
          userId: userId),
    );
  }
}

// --- Haftalık Plan Kartının İçindeki Parçalar ---

final selectedDayProvider = StateProvider.autoDispose<int>((ref) {
  int todayIndex = DateTime.now().weekday - 1;
  return todayIndex.clamp(0, 6);
});

class _PlanView extends ConsumerWidget {
  final WeeklyPlan? weeklyPlan;
  final String userId;
  final List<String> _daysOfWeek = const [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  final List<String> _daysOfWeekShort = const [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz'
  ];

  const _PlanView({required this.weeklyPlan, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (weeklyPlan == null || weeklyPlan!.plan.isEmpty) {
      return const _EmptyStateCard();
    }

    final selectedDayIndex = ref.watch(selectedDayProvider);
    final dayName = _daysOfWeek[selectedDayIndex];
    final dailyPlan = weeklyPlan!.plan.firstWhere(
          (p) => p.day == dayName,
      orElse: () => DailyPlan(day: dayName, schedule: []),
    );
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dateForTab = startOfWeek.add(Duration(days: selectedDayIndex));
    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Haftalık Plan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        _DaySelector(days: _daysOfWeekShort),
        const Divider(height: 1, color: AppTheme.lightSurfaceColor),
        Expanded(
          child: AnimatedSwitcher(
            duration: 300.ms,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: dailyPlan.schedule.isEmpty
                ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Bugün için özel bir görev planlanmamış.\nDinlen ve gücünü topla!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontStyle: FontStyle.italic)),
                ))
                : ListView.builder(
              key: PageStorageKey<String>(dayName),
              padding: const EdgeInsets.all(16),
              itemCount: dailyPlan.schedule.length,
              itemBuilder: (context, index) {
                final scheduleItem = dailyPlan.schedule[index];
                return _TaskCard(
                  key: ValueKey(
                      '$dateKey-${scheduleItem.time}-${scheduleItem.activity}'),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedDayIndex == index;
          return GestureDetector(
            onTap: () => ref.read(selectedDayProvider.notifier).state = index,
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryTextColor,
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

  const _TaskCard(
      {super.key,
        required this.item,
        required this.dateKey,
        required this.userId});

  IconData _getIconForTaskType(String type) {
    switch (type.toLowerCase()) {
      case 'study':
        return Icons.book_rounded;
      case 'practice':
      case 'routine':
        return Icons.edit_note_rounded;
      case 'test':
        return Icons.quiz_rounded;
      case 'review':
        return Icons.history_edu_rounded;
      case 'break':
        return Icons.self_improvement_rounded;
      default:
        return Icons.shield_moon_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskIdentifier = '${item.time}-${item.activity}';
    final isCompleted = ref.watch(userProfileProvider.select(
          (user) =>
      user.value?.completedDailyTasks[dateKey]?.contains(taskIdentifier) ??
          false,
    ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Animate(
            target: isCompleted ? 1 : 0,
            effects: [ScaleEffect(duration: 300.ms, curve: Curves.easeOut)],
            child: Icon(_getIconForTaskType(item.type),
                color: isCompleted
                    ? AppTheme.successColor
                    : AppTheme.secondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity,
                  style: TextStyle(
                    color: isCompleted
                        ? AppTheme.secondaryTextColor
                        : Colors.white,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppTheme.secondaryTextColor,
                  ),
                ),
                Text(item.time,
                    style: const TextStyle(
                        color: AppTheme.secondaryTextColor, fontSize: 12)),
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
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 40),
          const SizedBox(height: 16),
          Text(
            'Kader parşömenin mühürlenmeyi bekliyor.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Stratejik planını oluşturarak görevlerini buraya yazdır.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.go('${AppRoutes.aiHub}/${AppRoutes.strategicPlanning}'),
            child: const Text('Stratejini Oluştur'),
          )
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}