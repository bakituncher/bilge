// lib/features/home/screens/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';

const List<String> motivationalQuotes = [
  "Başarının sırrı, başlamaktır.",
  "Bugünün emeği, yarının zaferidir.",
  "En büyük zafer, kendine karşı kazandığın zaferdir.",
  "Hayal edebiliyorsan, yapabilirsin.",
  "Küçük adımlar, büyük başarılara götürür.",
  "Disiplin, hedefler ve başarı arasındaki köprüdür.",
  "Vazgeçenler asla kazanamaz, kazananlar asla vazgeçmez."
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'Tünaydın';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;
    final randomQuote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Kullanıcı verisi yüklenemedi."));
            final tests = ref.watch(testsProvider).valueOrNull ?? [];
            final testCount = tests.length;
            final avgNet = testCount > 0 ? user.totalNetSum / testCount : 0.0;
            final bestNet = tests.isEmpty ? 0.0 : tests.map((t) => t.totalNet).reduce(max);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context, user.name ?? '', textTheme),
                const SizedBox(height: 16),
                _buildMotivationalQuoteCard(randomQuote),
                const SizedBox(height: 24),
                _buildStatsRow(avgNet, bestNet, user.streak),
                const SizedBox(height: 24),
                _buildTodaysMissionCard(context, ref),
                const SizedBox(height: 24),
                _buildActionCenter(context),
                const SizedBox(height: 24),
                _WeeklyParchment(),
              ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (e, s) => Center(child: Text("Bir hata oluştu: $e")),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getGreeting()},', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300, color: AppTheme.secondaryTextColor)),
            Text(name.split(' ').first, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.history_edu_rounded, color: AppTheme.secondaryTextColor, size: 28),
          tooltip: 'Bilgelik Kütüphanesi',
          onPressed: () => context.go('/library'),
        ),
      ],
    );
  }

  Widget _buildMotivationalQuoteCard(String quote) {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.format_quote, color: AppTheme.secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quote,
                style: const TextStyle(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(double avgNet, double bestNet, int streak) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.track_changes_rounded, value: avgNet.toStringAsFixed(1), label: 'Ortalama Net', color: Colors.blueAccent)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.emoji_events_rounded, value: bestNet.toStringAsFixed(1), label: 'En Yüksek Net', color: Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, value: streak.toString(), label: 'Günlük Seri', color: Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildTodaysMissionCard(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider).valueOrNull;
    final user = ref.watch(userProfileProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;

    IconData icon;
    String title;
    String subtitle;
    VoidCallback? onTap;
    String buttonText;

    if (user != null && tests != null) {
      if (tests.isEmpty) {
        title = "Yolculuğa Başla";
        subtitle = "Potansiyelini ortaya çıkarmak için ilk deneme sonucunu ekle.";
        onTap = () => context.go('/home/add-test');
        buttonText = "İlk Denemeni Ekle";
        icon = Icons.add_chart_rounded;
      } else {
        final analysis = PerformanceAnalysis(tests, user.topicPerformances);
        final weakestTopicInfo = analysis.getWeakestTopicWithDetails();
        title = "Günün Önceliği";
        subtitle = weakestTopicInfo != null
            ? "BilgeAI, en zayıf noktanın **'${weakestTopicInfo['subject']}'** dersindeki **'${weakestTopicInfo['topic']}'** konusu olduğunu tespit etti. Bu cevheri işlemeye hazır mısın?"
            : "Harika gidiyorsun! Şu an belirgin bir zayıf noktan tespit edilmedi. Yeni konu verileri girerek analizi derinleştirebilirsin.";
        onTap = weakestTopicInfo != null ? () => context.go('/ai-hub/weakness-workshop') : null;
        buttonText = "Cevher Atölyesine Git";
        icon = Icons.construction_rounded;
      }
    } else {
      title = "BilgeAI Hazırlanıyor...";
      subtitle = "Kişisel komuta merkezin kuruluyor. Lütfen bekle...";
      onTap = null;
      buttonText = "Bekleniyor...";
      icon = Icons.hourglass_top_rounded;
    }

    return Card(
      elevation: 4,
      shadowColor: AppTheme.secondaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [AppTheme.secondaryColor.withOpacity(0.9), AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
              _buildRichTextFromMarkdown(
                  subtitle,
                  baseStyle: textTheme.bodyLarge?.copyWith(color: AppTheme.primaryColor.withOpacity(0.9), height: 1.5),
                  boldStyle: const TextStyle(fontWeight: FontWeight.bold)
              ),
              if (onTap != null) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                    ),
                    child: Text(buttonText),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCenter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onTap: () => context.go('/home/add-test'),
            icon: Icons.add_chart_outlined,
            label: "Deneme Ekle",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            onTap: () => context.go('/home/pomodoro'),
            icon: Icons.timer_outlined,
            label: "Odaklan",
          ),
        ),
      ],
    );
  }
}

class _WeeklyParchment extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WeeklyParchment> createState() => _WeeklyParchmentState();
}

class _WeeklyParchmentState extends ConsumerState<_WeeklyParchment> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _daysOfWeek = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];

  @override
  void initState() {
    super.initState();
    int initialIndex = DateTime.now().weekday - 1;
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
    final user = ref.watch(userProfileProvider).value;

    WeeklyPlan? weeklyPlan;
    if (user?.weeklyPlan != null) {
      weeklyPlan = WeeklyPlan.fromJson(user!.weeklyPlan!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Kader Parşömeni", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: weeklyPlan == null || weeklyPlan.plan.isEmpty
              ? _buildRestPrompt(context, isPlanGenerated: false)
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

                    // Haftanın başlangıcını (Pazartesi) bul
                    final today = DateTime.now();
                    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
                    final dateForTab = startOfWeek.add(Duration(days: _daysOfWeek.indexOf(dayName)));
                    final dateKey = DateFormat('yyyy-MM-dd').format(dateForTab);

                    final completedTasks = user?.completedDailyTasks[dateKey] ?? [];

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
                        final taskIdentifier = "${scheduleItem.time}-${scheduleItem.activity}";
                        final isCompleted = completedTasks.contains(taskIdentifier);

                        return _DestinyTaskCard(
                          item: scheduleItem,
                          isCompleted: isCompleted,
                          onToggle: () {
                            if (user != null) {
                              ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
                                userId: user.id,
                                dateKey: dateKey,
                                task: taskIdentifier,
                                isCompleted: !isCompleted,
                              );
                            }
                          },
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
}

class _DestinyTaskCard extends StatefulWidget {
  final ScheduleItem item;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _DestinyTaskCard({
    required this.item,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  State<_DestinyTaskCard> createState() => _DestinyTaskCardState();
}

class _DestinyTaskCardState extends State<_DestinyTaskCard> {
  bool _isExpanded = false;

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
      case 'preparation':
        return Icons.architecture_rounded;
      case 'break':
        return Icons.self_improvement_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      default:
        return Icons.shield_moon_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: widget.isCompleted ? AppTheme.successColor.withOpacity(0.1) : AppTheme.lightSurfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isCompleted ? AppTheme.successColor : AppTheme.lightSurfaceColor,
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
                    child: Icon(
                      _getIconForTaskType(widget.item.type),
                      color: widget.isCompleted ? AppTheme.successColor : AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRichTextFromMarkdown(
                      "**${widget.item.time}:** ${widget.item.activity}",
                      baseStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: widget.isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                        decoration: widget.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      boldStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isCompleted ? AppTheme.secondaryTextColor : Colors.white
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: 300.ms,
                curve: Curves.easeInOut,
                child: Visibility(
                  visible: _isExpanded,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: widget.onToggle,
                      icon: Icon(widget.isCompleted ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded),
                      label: Text(widget.isCompleted ? "Mührü Geri Al" : "Görevi Mühürle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isCompleted ? AppTheme.lightSurfaceColor : AppTheme.secondaryColor,
                        foregroundColor: widget.isCompleted ? Colors.white : AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 44),
                      ),
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

  return RichText(
    text: TextSpan(
      style: baseStyle,
      children: spans,
    ),
  );
}

Widget _buildRestPrompt(BuildContext context, {required bool isPlanGenerated}) {
  return Padding(
    padding: const EdgeInsets.all(48.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isPlanGenerated ? Icons.shield_moon_rounded : Icons.auto_awesome, color: AppTheme.secondaryColor.withOpacity(0.8), size: 40),
        const SizedBox(height: 16),
        Text(
          !isPlanGenerated
              ? "Kaderinin parşömeni boş. Stratejik planını oluşturarak mühürlerini buraya yazdır."
              : "Haftalık planın henüz oluşturulmamış veya yüklenemedi.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor, height: 1.5),
        ),
        if (!isPlanGenerated) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/ai-hub/strategic-planning'),
            child: const Text('Stratejini Oluştur'),
          )
        ]
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.lightSurfaceColor.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor), maxLines: 1, overflow: TextOverflow.ellipsis,),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _ActionButton({required this.onTap, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}