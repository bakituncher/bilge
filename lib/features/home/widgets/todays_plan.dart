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
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';

class TodaysPlan extends ConsumerStatefulWidget {
  const TodaysPlan({super.key});

  @override
  ConsumerState<TodaysPlan> createState() => _TodaysPlanState();
}

class _TodaysPlanState extends ConsumerState<TodaysPlan> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).value;
    final tests = ref.watch(testsProvider).value;

    if (user == null || tests == null) {
      return const SizedBox(height: 420); // Yüklenirken boşluk bırak
    }

    final List<Widget> pages = [
      const _TodaysMissionCard(),
      const _WeeklyPlanCard(),
      // DEĞİŞİKLİK: Eski performans kartı, yeni analiz kartı ile değiştirildi.
      _PerformanceAnalysisCard(user: user, tests: tests),
    ];

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView(
            controller: _pageController,
            padEnds: false,
            children: pages,
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(pages.length),
      ],
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: 300.ms,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppTheme.secondaryColor : AppTheme.lightSurfaceColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// YENİ WIDGET: PERFORMANS ANALİZ KARTI
class _PerformanceAnalysisCard extends ConsumerWidget {
  final UserModel user;
  final List<TestModel> tests;
  const _PerformanceAnalysisCard({required this.user, required this.tests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
        margin: const EdgeInsets.only(left: 8, right: 16),
        elevation: 4,
        shadowColor: AppTheme.successColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<Exam?>(
            future: user.selectedExam != null ? ExamData.getExamByType(ExamType.values.byName(user.selectedExam!)) : null,
            builder: (context, examSnapshot) {
              if (!examSnapshot.hasData || tests.length < 2) {
                return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text("Performans trendini görebilmek için en az 2 deneme sonucu girmelisin.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.secondaryTextColor, height: 1.5)),
                    )
                );
              }
              final analysis = StatsAnalysis(tests, user.topicPerformances, examSnapshot.data!, user: user);
              final trend = analysis.trend;
              String title;
              String subtitle;
              IconData icon;
              Color iconColor;

              if (trend > 0.1) {
                title = "Yükseliştesin!";
                subtitle = "Netlerin deneme başına ortalama ${trend.toStringAsFixed(2)} artıyor. Bu harika gidişatı sürdürmek için kaleyi ve zayıf noktalarını gözden geçirelim.";
                icon = Icons.trending_up_rounded;
                iconColor = AppTheme.successColor;
              } else if (trend < -0.1) {
                title = "Stratejiyi Gözden Geçir";
                subtitle = "Son denemelerde bir düşüş var gibi görünüyor. Endişelenme, bu durumu tersine çevirmek için buradayız. Nerede hata yaptığımızı görmek için istatistikleri inceleyelim.";
                icon = Icons.trending_down_rounded;
                iconColor = AppTheme.accentColor;
              } else {
                title = "İstikrarını Koruyorsun";
                subtitle = "Netlerin stabil bir seyir izliyor. Şimdi bu platoyu aşıp yeni zirvelere ulaşma zamanı. Hadi gidişatı detaylıca inceleyelim.";
                icon = Icons.trending_flat_rounded;
                iconColor = AppTheme.secondaryColor;
              }


              return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 28, color: iconColor),
                          const SizedBox(width: 12),
                          Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        subtitle,
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor, height: 1.5),
                      ),
                      const Spacer(),
                      Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                              onPressed: ()=> context.push('/home/stats'),
                              child: const Text("İstatistik Kalesine Git")
                          )
                      ),
                    ],
                  )
              );
            }
        )
    );
  }
}


// AŞAĞIDAKİ KARTLARDA DEĞİŞİKLİK YOK, OLDUĞU GİBİ KALABİLİR.

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

final selectedDayProvider = StateProvider.autoDispose<int>((ref) {
  int todayIndex = DateTime.now().weekday - 1;
  return todayIndex.clamp(0, 6);
});

class _PlanView extends ConsumerWidget {
  final WeeklyPlan? weeklyPlan;
  final String userId;
  final List<String> _daysOfWeek = const [
    'Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'
  ];
  final List<String> _daysOfWeekShort = const [
    'Pzt','Sal','Çar','Per','Cum','Cmt','Paz'
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

    // Günlük ilerlemeyi hesapla
    final dailyTasks = dailyPlan.schedule;
    final completedDailyTasks = (ref.watch(userProfileProvider).value?.completedDailyTasks[dateKey] ?? []).toSet();
    final completedCount = dailyTasks.where((task) {
      final taskIdentifier = '${task.time}-${task.activity}';
      return completedDailyTasks.contains(taskIdentifier);
    }).length;
    final dailyProgress = dailyTasks.isNotEmpty ? completedCount / dailyTasks.length : 0.0;


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16,16,16,8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Haftalık Plan',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 40,
                height: 40,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: dailyProgress),
                  duration: 500.ms,
                  builder: (context, value, child) => Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                        color: AppTheme.successColor,
                      ),
                      Center(
                        child: Text(
                          '${(value * 100).toInt()}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
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