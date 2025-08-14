// lib/features/profile/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/features/profile/models/badge_model.dart' as app_badge;
import 'package:bilge_ai/core/navigation/app_routes.dart';
import '../widgets/warrior_id_card.dart';
import '../widgets/war_stats.dart';
import '../widgets/profile_action_cards.dart';

// HonorWall ve FutureVictories importları kaldırıldı.

final focusSessionsProvider = StreamProvider.autoDispose<List<FocusSessionModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return FirebaseFirestore.instance
        .collection('focusSessions')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FocusSessionModel.fromSnapshot(doc)).toList());
  }
  return Stream.value([]);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Çıkış Yap"),
          content: const Text("Oturumu sonlandırmak istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal", style: TextStyle(color: AppTheme.secondaryTextColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Çıkış Yap", style: TextStyle(color: AppTheme.accentColor)),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        );
      },
    );
  }

  String _getWarriorTitle(int testCount, double avgNet) {
    if (testCount < 5) return "Acemi Kâşif";
    if (avgNet > 90 && testCount > 20) return "Efsanevi Komutan";
    if (avgNet > 70) return "Usta Stratejist";
    if (testCount > 15) return "Kıdemli Savaşçı";
    return "Azimli Savaşçı";
  }

  List<app_badge.Badge> _generateBadges(UserModel user, int testCount, double avgNet, List<FocusSessionModel> focusSessions) {
    return [
      app_badge.Badge(name: 'İlk Adım', description: 'İlk denemeni ekle.', icon: Icons.flag, color: Colors.green, isUnlocked: testCount >= 1),
      app_badge.Badge(name: 'Acemi Savaşçı', description: '5 deneme ekle.', icon: Icons.shield_outlined, color: Colors.green, isUnlocked: testCount >= 5),
      app_badge.Badge(name: 'Deneyimli Savaşçı', description: '15 deneme ekle.', icon: Icons.shield, color: Colors.green, isUnlocked: testCount >= 15),
      app_badge.Badge(name: 'Usta Savaşçı', description: '30 deneme ekle.', icon: Icons.military_tech_outlined, color: Colors.green, isUnlocked: testCount >= 30),
      app_badge.Badge(name: 'Deneme Fatihi', description: '50 deneme ekle.', icon: Icons.military_tech, color: Colors.green, isUnlocked: testCount >= 50),
      app_badge.Badge(name: 'Kıvılcım', description: '3 günlük seri yakala.', icon: Icons.whatshot_outlined, color: Colors.orange, isUnlocked: user.streak >= 3),
      app_badge.Badge(name: 'Ateşleyici', description: '7 günlük seri yakala.', icon: Icons.local_fire_department_outlined, color: Colors.orange, isUnlocked: user.streak >= 7),
      app_badge.Badge(name: 'Alev Ustası', description: '14 günlük seri yakala.', icon: Icons.local_fire_department, color: Colors.orange, isUnlocked: user.streak >= 14),
      app_badge.Badge(name: 'Durdurulamaz', description: '30 günlük seri yakala.', icon: Icons.wb_sunny, color: Colors.orange, isUnlocked: user.streak >= 30),
      app_badge.Badge(name: 'Yükseliş', description: '50 Net ortalamasını geç.', icon: Icons.trending_up, color: Colors.blue, isUnlocked: avgNet > 50),
      app_badge.Badge(name: 'Nişancı', description: '70 Net ortalamasını geç.', icon: Icons.gps_fixed, color: Colors.blue, isUnlocked: avgNet > 70),
      app_badge.Badge(name: 'Usta Nişancı', description: '90 Net ortalamasını geç.', icon: Icons.gps_not_fixed, color: Colors.blue, isUnlocked: avgNet > 90),
      app_badge.Badge(name: 'Bilge Nişancı', description: '100 Net ortalamasını geç.', icon: Icons.gps_fixed, color: Colors.blue, isUnlocked: avgNet > 100),
      app_badge.Badge(name: 'Stratejist', description: 'İlk stratejini oluştur.', icon: Icons.insights, color: AppTheme.successColor, isUnlocked: user.longTermStrategy != null),
      app_badge.Badge(name: 'Planlayıcı', description: 'Haftalık planındaki 10 görevi tamamla.', icon: Icons.checklist, color: AppTheme.successColor, isUnlocked: (user.completedDailyTasks.values.expand((e) => e).length) >= 10),
      app_badge.Badge(name: 'Odaklanma Ustası', description: 'İlk Pomodoro seansını tamamla.', icon: Icons.timer, color: AppTheme.successColor, isUnlocked: focusSessions.isNotEmpty),
      app_badge.Badge(name: 'Kâşif', description: 'İlk zayıf konunu işle.', icon: Icons.construction, color: Colors.purple, isUnlocked: user.topicPerformances.isNotEmpty),
      app_badge.Badge(name: 'Lider', description: 'Liderlik tablosuna gir.', icon: Icons.leaderboard, color: Colors.purple, isUnlocked: user.engagementScore > 0),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final focusSessionsAsync = ref.watch(focusSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komuta Merkezi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Ayarlar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
            tooltip: 'Güvenli Çıkış',
          )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Komutan bulunamadı.'));

          return focusSessionsAsync.when(
            data: (focusSessions) {
              final tests = testsAsync.valueOrNull ?? [];
              final testCount = tests.length;
              final avgNet = testCount > 0 ? user.totalNetSum / testCount : 0.0;
              final allBadges = _generateBadges(user, testCount, avgNet, focusSessions);
              final unlockedCount = allBadges.where((b) => b.isUnlocked).length;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  WarriorIDCard(user: user, title: _getWarriorTitle(testCount, avgNet)),
                  const SizedBox(height: 24),
                  WarStats(testCount: testCount, avgNet: avgNet, streak: user.streak),
                  const SizedBox(height: 24),

                  // YENİ ŞEREF DUVARI KARTI
                  _HonorWallPreviewCard(
                    unlockedCount: unlockedCount,
                    totalCount: allBadges.length,
                    onTap: () => context.push('/profile/honor-wall', extra: allBadges),
                  ),

                  const SizedBox(height: 12),
                  const TimeManagementActions(),
                  const SizedBox(height: 12),
                  StrategicActions(user: user),
                  const SizedBox(height: 24),
                ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
            error: (e, s) => Center(child: Text('Odaklanma verileri yüklenemedi: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text('Karargâh Yüklenemedi: $e')),
      ),
    );
  }
}

// YENİ WIDGET: Şeref Duvarı Önizleme ve Giriş Kartı
class _HonorWallPreviewCard extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;
  final VoidCallback onTap;

  const _HonorWallPreviewCard({
    required this.unlockedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                    ),
                  ),
                  const Icon(Icons.military_tech_rounded, color: AppTheme.secondaryColor, size: 32),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Şeref Duvarı", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("$totalCount madalyadan $unlockedCount tanesini kazandın.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
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
}