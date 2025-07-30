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
import 'package:bilge_ai/features/coach/screens/ai_coach_screen.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';

// BİLGEAI DEVRİMİ: Ana paneli sekmeli bir yapıya dönüştürmek için StatefulWidget kullanıldı.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'Tünaydın';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: userAsync.when(
                    data: (user) => _buildHeader(context, user?.name ?? '', textTheme),
                    loading: () => const SizedBox.shrink(),
                    error: (e,s) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.secondaryColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                    tabs: const [
                      Tab(text: "Bugünün Planı"),
                      Tab(text: "BilgeAI Analizi"),
                      Tab(text: "Genel Bakış"),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTodaysPlanView(),
              _buildAiAnalysisView(),
              _buildOverviewView(),
            ],
          ),
        ),
      ),
    );
  }

  // BÖLÜM 1: Bugünün Planı
  Widget _buildTodaysPlanView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTodaysTasksCard(context, ref),
        const SizedBox(height: 16),
        _buildFocusCard(context),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // BÖLÜM 2: BilgeAI Analizi (Kullanıcının istediği "zayıflık" ekranı)
  Widget _buildAiAnalysisView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEssenceOfTheDayCard(context, ref),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // BÖLÜM 3: Genel Bakış
  Widget _buildOverviewView() {
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return testsAsync.when(
      data: (tests) {
        if (tests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("İstatistikleri görmek için ilk denemeni ekle.", style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor)),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsRow(tests, context),
            const SizedBox(height: 24),
            Text('Son Denemeler', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...tests.take(5).map((test) => _buildTestCard(context, test))
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
      error: (err, stack) => Center(child: Text('Hata: $err')),
    ).animate().fadeIn(duration: 400.ms);
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildHeader(BuildContext context, String name, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()},',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300, color: AppTheme.secondaryTextColor),
            ),
            Text(
              name.split(' ').first,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
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

  Widget _buildTodaysTasksCard(BuildContext context, WidgetRef ref) {
    // ... Bu widget önceki haliyle aynı kalır ...
    final textTheme = Theme.of(context).textTheme;
    final analysisAsync = ref.watch(aiAnalysisProvider);
    final user = ref.watch(userProfileProvider).value;

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayOfWeek = DateFormat('EEEE', 'tr_TR').format(DateTime.now());
    final completedTasksToday = user?.completedDailyTasks[todayKey] ?? [];

    DailyPlan? todaysPlan;
    if (analysisAsync != null && !analysisAsync.data.containsKey("error")) {
      final weeklyPlanData = analysisAsync.data['weeklyPlan'] as Map<String, dynamic>?;
      if (weeklyPlanData != null) {
        final plan = WeeklyPlan.fromJson(weeklyPlanData);
        todaysPlan = plan.plan.firstWhere((p) => p.day == dayOfWeek, orElse: () => DailyPlan(day: dayOfWeek, tasks: []));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bugünün Görevleri", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            if (todaysPlan == null || todaysPlan.tasks.isEmpty)
              _buildPlanPrompt(context, analysisAsync != null)
            else
              ...todaysPlan.tasks.map((task) {
                final isCompleted = completedTasksToday.contains(task);
                return _buildTaskItem(context, ref, user!.id, todayKey, task, isCompleted);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, String userId, String dateKey, String task, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
            userId: userId,
            dateKey: dateKey,
            task: task,
            isCompleted: !isCompleted,
          );
        },
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPrompt(BuildContext context, bool isPlanGenerated) {
    return Row(
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
    );
  }

  Widget _buildEssenceOfTheDayCard(BuildContext context, WidgetRef ref) {
    // ... Bu widget önceki haliyle aynı kalır ...
    final tests = ref.watch(testsProvider).valueOrNull;
    final user = ref.watch(userProfileProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;

    IconData icon = Icons.auto_awesome_outlined;
    String title;
    String subtitle;
    VoidCallback? onTap;
    String buttonText;

    if (user != null && tests != null) {
      if (tests.isEmpty) {
        title = "Yolculuğa Başla";
        subtitle = "Potansiyelini ortaya çıkarmak için ilk deneme sonucunu ekle.";
        onTap = () => context.go('/home/add-test');
        buttonText = "Deneme Ekle";
        icon = Icons.add_chart_rounded;
      } else {
        final analysis = PerformanceAnalysis(tests, user.topicPerformances);
        final weakestSubject = analysis.weakestSubjectByNet;
        title = "Zayıf Nokta Tespiti";
        subtitle = "Analizlere göre en çok zorlandığın ders '$weakestSubject'. Bu konunun üzerine gitmek için Zayıflık Avcısı'nı kullan.";
        onTap = () => context.go('/ai-hub/weakness-hunter');
        buttonText = "Avcı'yı Başlat";
        icon = Icons.radar_outlined;
      }
    } else {
      title = "BilgeAI Hazır";
      subtitle = "Kişisel koçun, verilerini analiz etmek için sabırsızlanıyor.";
      buttonText = "Bekleniyor...";
    }

    return Card(
      color: AppTheme.secondaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.secondaryColor, width: 1.5)
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(140, 44)
                  ),
                  child: Text(buttonText),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/home/pomodoro'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Icon(Icons.timer_rounded, color: AppTheme.successColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Odaklanma Zamanı", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text("AI destekli planınla zamanını yönet.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<TestModel> tests, BuildContext context) {
    // ...
    final avgNet = tests.map((t) => t.totalNet).reduce((a, b) => a + b) / tests.length;
    final bestNet = tests.map((t) => t.totalNet).reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        Expanded(child: _buildStatSnapshotCard('Ortalama Net', avgNet.toStringAsFixed(2), Icons.track_changes_rounded, context)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatSnapshotCard('En Yüksek Net', bestNet.toStringAsFixed(2), Icons.emoji_events_rounded, context)),
      ],
    );
  }

  Widget _buildEmptyTestState(BuildContext context, TextTheme textTheme) {
    return const SizedBox.shrink();
  }

  Widget _buildStatSnapshotCard(String label, String value, IconData icon, BuildContext context){
    // ...
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.secondaryTextColor),
            const SizedBox(height: 8),
            Text(label, style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
            Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test) {
    // ...
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        onTap: () => context.go('/home/test-detail', extra: test),
        title: Text(test.testName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${test.examType.displayName} - ${DateFormat.yMMMMd('tr').format(test.date)}', style: TextStyle(color: AppTheme.secondaryTextColor)),
        trailing: Text(
          test.totalNet.toStringAsFixed(2),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.successColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// BİLGEAI DEVRİMİ: Sabitlenmiş TabBar'ı oluşturmak için özel bir delegate.
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.scaffoldBackgroundColor, // Arka plan rengiyle uyumlu
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}