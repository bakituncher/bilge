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
            final bestNet = tests.isEmpty ? 0.0 : tests.map((t) => t.totalNet).reduce((a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context, user.name ?? '', textTheme),
                const SizedBox(height: 16),
                _buildMotivationalQuoteCard(randomQuote),
                const SizedBox(height: 24),
                _buildStatsRow(avgNet, bestNet, user.streak), // HATA GİDERİLDİ: GridView -> Row
                const SizedBox(height: 24),
                _buildTodaysMissionCard(context, ref),
                const SizedBox(height: 24),
                _buildActionCenter(context),
                const SizedBox(height: 24),
                _buildWeeklyTasksCard(context, ref),
              ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (e, s) => Center(child: Text("Bir hata oluştu: $e")),
        ),
      ),
    );
  }

  // --- DEVİR DEĞİŞİKLİĞİ: GridView yerine Row kullanıldı ---
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

  // Diğer tüm widget'lar önceki devrimdeki gibi kalabilir, çünkü sorun GridView'daydı.
  // Ancak okunabilirlik ve bütünlük için tam kodu sağlıyorum.

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
          icon: const Icon(Icons.menu_book_rounded, color: AppTheme.secondaryTextColor, size: 28),
          tooltip: 'Başarı Günlüğüm',
          onPressed: () => context.go('/home/journal'),
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

  Widget _buildWeeklyTasksCard(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(userProfileProvider).value;

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayOfWeek = DateFormat('EEEE', 'tr_TR').format(DateTime.now());

    DailyPlan? todaysPlan;
    if (user?.weeklyPlan != null) {
      final plan = WeeklyPlan.fromJson(user!.weeklyPlan!);
      todaysPlan = plan.plan.firstWhere((p) => p.day == dayOfWeek, orElse: () => DailyPlan(day: dayOfWeek, tasks: []));
    }

    final completedTasksToday = user?.completedDailyTasks[todayKey] ?? [];
    final totalTasks = todaysPlan?.tasks.length ?? 0;
    final completedCount = completedTasksToday.length;
    final progress = totalTasks > 0 ? completedCount / totalTasks : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Günlük Vazifeler", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if(totalTasks > 0)
                  Row(
                    children: [
                      Expanded(child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: AppTheme.lightSurfaceColor,
                        color: AppTheme.successColor,
                      )),
                      const SizedBox(width: 12),
                      Text("$completedCount / $totalTasks", style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                    ],
                  ),
                if(totalTasks > 0) const Divider(height: 32),
                (todaysPlan == null || todaysPlan.tasks.isEmpty)
                    ? _buildPlanPrompt(context, isPlanGenerated: user?.weeklyPlan != null)
                    : Column(
                  children: todaysPlan.tasks.map((task) {
                    final isCompleted = completedTasksToday.contains(task);
                    return _buildTaskItem(context, ref, user!.id, todayKey, task, isCompleted);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, String userId, String dateKey, String task, bool isCompleted) {
    return InkWell(
      onTap: () {
        ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
          userId: userId,
          dateKey: dateKey,
          task: task,
          isCompleted: !isCompleted,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Checkbox(
                value: isCompleted,
                onChanged: (bool? value) {
                  ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
                    userId: userId,
                    dateKey: dateKey,
                    task: task,
                    isCompleted: value ?? false,
                  );
                },
                activeColor: AppTheme.successColor,
                checkColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.secondaryTextColor, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: _buildRichTextFromMarkdown(
                    task,
                    baseStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                    boldStyle: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? AppTheme.secondaryTextColor : Colors.white)
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPrompt(BuildContext context, {required bool isPlanGenerated}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(isPlanGenerated ? Icons.celebration_rounded : Icons.auto_awesome, color: AppTheme.secondaryColor.withOpacity(0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              !isPlanGenerated
                  ? "Stratejik planını oluşturarak günlük görevlerini burada gör."
                  : "Bugün için özel bir görevin yok. Dinlenmek de stratejinin bir parçasıdır!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
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
          mainAxisAlignment: MainAxisAlignment.spaceAround, // HATA GİDERİLDİ
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8), // HATA GİDERİLDİ
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