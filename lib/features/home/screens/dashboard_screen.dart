// lib/features/home/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/repositories/ai_service.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';

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
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Kullanıcı verisi yüklenemedi."));
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context, user.name ?? '', textTheme).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                _buildSagesDirectiveCard(context, ref).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),

                _buildActionCenter(context).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),

                _buildWeeklyTasksCard(context, ref).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),

                testsAsync.when(
                  data: (tests) => tests.isEmpty
                      ? const SizedBox.shrink()
                      : _buildIntelReport(context, tests, textTheme).animate().fadeIn(delay: 500.ms),
                  loading: () => const SizedBox.shrink(),
                  error: (e,s) => const SizedBox.shrink(),
                ),
              ],
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
            Text(name.split(' ').first, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.menu_book_rounded, color: AppTheme.secondaryTextColor),
          tooltip: 'Başarı Günlüğüm',
          onPressed: () => context.go('/home/journal'),
        ),
      ],
    );
  }

  Widget _buildSagesDirectiveCard(BuildContext context, WidgetRef ref) {
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
        title = "Cevher Atölyesi Seni Bekliyor";
        subtitle = weakestTopicInfo != null
            ? "BilgeAI, en zayıf noktanın '${weakestTopicInfo['subject']}' dersindeki '${weakestTopicInfo['topic']}' konusu olduğunu tespit etti. Bu cevheri işlemeye hazır mısın?"
            : "Harika gidiyorsun! Şu an belirgin bir zayıf noktan tespit edilmedi. Yeni konu verileri girerek analizi derinleştirebilirsin.";
        onTap = weakestTopicInfo != null ? () => context.go('/ai-hub/weakness-workshop') : null;
        buttonText = "Atölyeye Git";
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
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.secondaryColor, width: 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: AppTheme.secondaryColor),
            const SizedBox(height: 12),
            Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle, style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor)),
            if (onTap != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
                  child: Text(buttonText),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionCenter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home/add-test'),
            icon: const Icon(Icons.add_chart_outlined),
            label: const Text("Deneme Ekle"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.lightSurfaceColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home/pomodoro'),
            icon: const Icon(Icons.timer_outlined),
            label: const Text("Odaklan"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.lightSurfaceColor,
              foregroundColor: Colors.white,
            ),
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
    final completedTasksToday = user?.completedDailyTasks[todayKey] ?? [];

    DailyPlan? todaysPlan;
    if (user != null && user.weeklyPlan != null) {
      final weeklyPlanData = user.weeklyPlan;
      final plan = WeeklyPlan.fromJson(weeklyPlanData!);
      todaysPlan = plan.plan.firstWhere((p) => p.day == dayOfWeek, orElse: () => DailyPlan(day: dayOfWeek, tasks: []));
    }

    return Card(
      child: ExpansionTile(
        title: Text("Haftalık Harekat Planı", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text("Bugün için ${todaysPlan?.tasks.length ?? 0} görev belirlendi.", style: const TextStyle(color: AppTheme.secondaryTextColor)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: (todaysPlan == null || todaysPlan.tasks.isEmpty)
                ? _buildPlanPrompt(context, isPlanGenerated: user?.weeklyPlan != null)
                : Column(
              children: todaysPlan.tasks.map((task) {
                final isCompleted = completedTasksToday.contains(task);
                return _buildTaskItem(context, ref, user!.id, todayKey, task, isCompleted);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, String userId, String dateKey, String task, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Checkbox(
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
          Expanded(
            child: Text(
              task,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isCompleted ? AppTheme.secondaryTextColor : Colors.white,
                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_circle_outline_rounded, color: isCompleted ? AppTheme.lightSurfaceColor : AppTheme.successColor),
            onPressed: isCompleted ? null : () => context.go('/home/pomodoro'),
            tooltip: "Bu Göreve Odaklan",
          )
        ],
      ),
    );
  }

  Widget _buildPlanPrompt(BuildContext context, {required bool isPlanGenerated}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.secondaryColor.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              !isPlanGenerated
                  ? "Stratejik Koçluk merkezinden haftalık planını oluşturarak görevlerini burada gör."
                  : "Bugün için özel bir görevin yok. Dinlenmek de stratejinin bir parçasıdır!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelReport(BuildContext context, List<TestModel> tests, TextTheme textTheme) {
    final latestTest = tests.first;
    final avgNet = tests.map((t) => t.totalNet).reduce((a, b) => a + b) / tests.length;
    final bestNet = tests.map((t) => t.totalNet).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("İstihbarat Raporu", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatSnapshotCard('Ortalama Net', avgNet.toStringAsFixed(2), Icons.track_changes_rounded, context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatSnapshotCard('En Yüksek Net', bestNet.toStringAsFixed(2), Icons.emoji_events_rounded, context)),
                  ],
                ),
                const Divider(height: 32, color: AppTheme.lightSurfaceColor),
                _buildTestCard(context, latestTest, isLatest: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatSnapshotCard(String label, String value, IconData icon, BuildContext context){
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.secondaryTextColor),
        const SizedBox(height: 8),
        Text(label, style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
        Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test, {bool isLatest = false}) {
    return ListTile(
      onTap: () => context.go('/home/test-detail', extra: test),
      leading: Icon(isLatest ? Icons.history_edu_rounded : Icons.article_outlined, color: AppTheme.secondaryTextColor),
      title: Text(test.testName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(isLatest ? "En Son Deneme" : '${test.examType.displayName} - ${DateFormat.yMMMMd('tr').format(test.date)}', style: TextStyle(color: AppTheme.secondaryTextColor)),
      trailing: Text(
        test.totalNet.toStringAsFixed(2),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.successColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}