// lib/features/home/widgets/weekly_parchment.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';

class WeeklyParchment extends ConsumerStatefulWidget {
  const WeeklyParchment({super.key});

  @override
  ConsumerState<WeeklyParchment> createState() => _WeeklyParchmentState();
}

class _WeeklyParchmentState extends ConsumerState<WeeklyParchment> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _daysOfWeek = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];

  @override
  void initState() {
    super.initState();
    int initialIndex = DateTime.now().weekday - 1;
    if (initialIndex < 0) initialIndex = 6;
    _tabController = TabController(length: 7, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final weeklyPlanData = ref.watch(userProfileProvider.select((user) => user.value?.weeklyPlan));
    final userId = ref.watch(userProfileProvider.select((user) => user.value?.id));

    if (userId == null) {
      return const Card(child: Center(child: Text("Kullanıcı bulunamadı.")));
    }

    WeeklyPlan? weeklyPlan;
    if (weeklyPlanData != null) {
      weeklyPlan = WeeklyPlan.fromJson(weeklyPlanData);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Kader Parşömeni", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: weeklyPlan == null || weeklyPlan.plan.isEmpty
              ? _buildRestPrompt(context)
              : Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _daysOfWeek.map((day) => Tab(text: day.substring(0, 3))).toList(),
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: _daysOfWeek.map((dayName) {
                    final dailyPlan = weeklyPlan!.plan.firstWhere(
                          (p) => p.day == dayName,
                      orElse: () => DailyPlan(day: dayName, schedule: []),
                    );

                    if (dailyPlan.schedule.isEmpty) {
                      return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                "Bu gün dinlenme ve gücünü toplama günü olarak planlanmış.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic)
                            ),
                          ));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dailyPlan.schedule.length,
                      itemBuilder: (context, index) {
                        final scheduleItem = dailyPlan.schedule[index];
                        final today = DateTime.now();
                        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
                        final dateForTab = startOfWeek.add(Duration(days: _daysOfWeek.indexOf(dayName)));
                        final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);

                        return _DestinyTaskCard(
                          key: ValueKey("$dateKey-${scheduleItem.time}-${scheduleItem.activity}"),
                          item: scheduleItem,
                          dateKey: dateKey,
                          userId: userId,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 40),
          const SizedBox(height: 16),
          Text(
            "Kaderinin parşömeni boş. Stratejik planını oluşturarak mühürlerini buraya yazdır.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('${AppRoutes.aiHub}/${AppRoutes.strategicPlanning}'),
            child: const Text('Stratejini Oluştur'),
          )
        ],
      ),
    );
  }
}

class _DestinyTaskCard extends ConsumerStatefulWidget {
  final ScheduleItem item;
  final String dateKey;
  final String userId;

  const _DestinyTaskCard({
    super.key,
    required this.item,
    required this.dateKey,
    required this.userId,
  });

  @override
  ConsumerState<_DestinyTaskCard> createState() => _DestinyTaskCardState();
}

class _DestinyTaskCardState extends ConsumerState<_DestinyTaskCard> {
  bool _isExpanded = false;

  IconData _getIconForTaskType(String type) {
    switch (type.toLowerCase()) {
      case 'study': return Icons.book_rounded;
      case 'practice': case 'routine': return Icons.edit_note_rounded;
      case 'test': return Icons.quiz_rounded;
      case 'review': return Icons.history_edu_rounded;
      case 'preparation': return Icons.architecture_rounded;
      case 'break': return Icons.self_improvement_rounded;
      case 'sleep': return Icons.bedtime_rounded;
      default: return Icons.shield_moon_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskIdentifier = "${widget.item.time}-${widget.item.activity}";

    final isCompleted = ref.watch(userProfileProvider.select(
          (user) => user.value?.completedDailyTasks[widget.dateKey]?.contains(taskIdentifier) ?? false,
    ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        // DÜZELTİLDİ: AnimatedContainer -> Container
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: isCompleted ? AppTheme.successColor.withOpacity(0.1) : AppTheme.lightSurfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted ? AppTheme.successColor : AppTheme.lightSurfaceColor,
                width: 1.5,
              )
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(_getIconForTaskType(widget.item.type), color: isCompleted ? AppTheme.successColor : AppTheme.secondaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRichTextFromMarkdown("**${widget.item.time}:** ${widget.item.activity}", baseStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isCompleted ? AppTheme.secondaryTextColor : Colors.white, decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none), boldStyle: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? AppTheme.secondaryTextColor : Colors.white))),
                ],
              ),
              // DÜZELTİLDİ: AnimatedSize -> Kaldırıldı
              Visibility(
                visible: _isExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
                        userId: widget.userId,
                        dateKey: widget.dateKey,
                        task: taskIdentifier,
                        isCompleted: !isCompleted,
                      );
                    },
                    icon: Icon(isCompleted ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded),
                    label: Text(isCompleted ? "Mührü Geri Al" : "Görevi Mühürle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? AppTheme.lightSurfaceColor : AppTheme.secondaryColor,
                      foregroundColor: isCompleted ? Colors.white : AppTheme.primaryColor,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRichTextFromMarkdown(String text, {TextStyle? baseStyle, TextStyle? boldStyle}) {
    List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r"\*\*(.*?)\*\*");
    text.splitMapJoin(regExp,
        onMatch: (m) {
          spans.add(TextSpan(text: m.group(1), style: boldStyle ?? baseStyle?.copyWith(fontWeight: FontWeight.bold)));
          return '';
        },
        onNonMatch: (n) {
          spans.add(TextSpan(text: n));
          return '';
        }
    );
    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}