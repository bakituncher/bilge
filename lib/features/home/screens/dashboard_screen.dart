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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // BİLGEAI DEVRİMİ: Selamlama ve profil kısayolu
            userAsync.when(
              data: (user) => _buildHeader(context, user?.name ?? '', textTheme),
              loading: () => const SizedBox.shrink(),
              error: (e,s) => const SizedBox.shrink(),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // BİLGEAI DEVRİMİ: Günün Özü - En önemli ve bağlamsal kart
            _buildEssenceOfTheDayCard(context, ref).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 24),

            // BİLGEAI DEVRİMİ: İstatistikler ve Son Denemeler yan yana daha kompakt bir yapıda
            testsAsync.when(
              data: (tests) {
                if (tests.isEmpty) {
                  return _buildEmptyTestState(context, textTheme).animate().fadeIn(delay: 400.ms);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(tests, context),
                    const SizedBox(height: 24),
                    Text('Son Denemeler', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...tests.take(3).map((test) => _buildTestCard(context, test).animate().fadeIn(delay: (200 + tests.indexOf(test) * 100).ms).slideY(begin: 0.1))
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
            )
          ],
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

  Widget _buildEssenceOfTheDayCard(BuildContext context, WidgetRef ref) {
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
        final analysis = PerformanceAnalysis(tests, user.completedTopics);
        final weakestSubject = analysis.weakestSubject;
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

  Widget _buildStatsRow(List<TestModel> tests, BuildContext context) {
    final avgNet = tests.map((t) => t.totalNet).reduce((a, b) => a + b) / tests.length;
    final bestNet = tests.map((t) => t.totalNet).reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        Expanded(child: _buildStatSnapshotCard('Ortalama Net', avgNet.toStringAsFixed(2), Icons.track_changes_rounded, context)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatSnapshotCard('En Yüksek Net', bestNet.toStringAsFixed(2), Icons.emoji_events_rounded, context)),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildEmptyTestState(BuildContext context, TextTheme textTheme) {
    return const SizedBox.shrink(); // Artık "Günün Özü" kartı bu görevi üstleniyor.
  }

  Widget _buildStatSnapshotCard(String label, String value, IconData icon, BuildContext context){
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