// lib/features/profile/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/features/profile/models/badge_model.dart' as app_badge; // DÜZELTİLDİ: Kod adı eklendi
import '../widgets/warrior_id_card.dart';
import '../widgets/war_stats.dart';
import '../widgets/profile_action_cards.dart';
import '../widgets/honor_wall.dart';
import '../widgets/future_victories.dart';

// Badge modeli kendi dosyasına taşındı ve artık kod adıyla çağırılıyor.

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

  // DÜZELTİLDİ: 'Badge' -> 'app_badge.Badge' olarak değiştirildi.
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
              final badges = _generateBadges(user, testCount, avgNet, focusSessions);
              final unlockedBadges = badges.where((b) => b.isUnlocked).toList();
              final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  WarriorIDCard(user: user, title: _getWarriorTitle(testCount, avgNet)),
                  const SizedBox(height: 24),
                  WarStats(testCount: testCount, avgNet: avgNet, streak: user.streak),
                  const SizedBox(height: 24),
                  const TimeManagementActions(),
                  const SizedBox(height: 12),
                  StrategicActions(user: user),
                  const SizedBox(height: 32),
                  HonorWall(unlockedBadges: unlockedBadges),
                  const SizedBox(height: 24),
                  FutureVictories(lockedBadges: lockedBadges),
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