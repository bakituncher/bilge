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
import 'package:rive/rive.dart' hide LinearGradient; // HATA ÇÖZÜMÜ: Rive'dan gelen LinearGradient gizlendi.
import '../widgets/xp_bar.dart';

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

  (String, int, IconData) _getWarriorRank(int testCount, double avgNet, int score) {
    if (score > 15000 && testCount > 50 && avgNet > 90) return ("Efsanevi Komutan", 20000, Icons.workspace_premium);
    if (score > 8000 && testCount > 30 && avgNet > 70) return ("Usta Stratejist", 15000, Icons.star_rounded);
    if (score > 3000 && testCount > 15) return ("Kıdemli Savaşçı", 8000, Icons.military_tech);
    if (score > 1000 && testCount > 5) return ("Azimli Savaşçı", 3000, Icons.shield);
    return ("Acemi Kâşif", 1000, Icons.explore);
  }

  List<app_badge.Badge> _generateBadges(UserModel user, int testCount, double avgNet, List<FocusSessionModel> focusSessions) {
    return [
      // Deneme Madalyaları
      app_badge.Badge(name: 'İlk Adım', description: 'İlk denemeni başarıyla ekledin ve zafere giden yola çıktın.', icon: Icons.flag, color: AppTheme.successColor, isUnlocked: testCount >= 1, hint: "İlk denemeni ekleyerek başla."),
      app_badge.Badge(name: 'Acemi Savaşçı', description: '5 farklı denemede savaş meydanının tozunu attın.', icon: Icons.shield_outlined, color: AppTheme.successColor, isUnlocked: testCount >= 5, rarity: app_badge.BadgeRarity.common, hint: "Toplam 5 deneme ekle."),
      app_badge.Badge(name: 'Kıdemli Savaşçı', description: '15 deneme! Artık bu işin kurdu olmaya başladın.', icon: Icons.shield, color: AppTheme.successColor, isUnlocked: testCount >= 15, rarity: app_badge.BadgeRarity.rare, hint: "Toplam 15 deneme ekle."),
      app_badge.Badge(name: 'Deneme Fatihi', description: 'Tam 50 denemeyi arşivine ekledin. Önünde kimse duramaz!', icon: Icons.military_tech, color: AppTheme.successColor, isUnlocked: testCount >= 50, rarity: app_badge.BadgeRarity.epic, hint: "Toplam 50 deneme ekle."),

      // Seri Madalyaları
      app_badge.Badge(name: 'Kıvılcım', description: 'Ateşi yaktın! 3 günlük çalışma serisine ulaştın.', icon: Icons.whatshot_outlined, color: Colors.orange, isUnlocked: user.streak >= 3, hint: "3 gün ara vermeden çalış."),
      app_badge.Badge(name: 'Alev Ustası', description: 'Tam 14 gün boyunca disiplini elden bırakmadın. Bu bir irade zaferidir!', icon: Icons.local_fire_department, color: Colors.orange, isUnlocked: user.streak >= 14, rarity: app_badge.BadgeRarity.rare, hint: "14 günlük seriye ulaş."),
      app_badge.Badge(name: 'Durdurulamaz', description: '30 gün! Sen artık bir alışkanlık abidesisin.', icon: Icons.wb_sunny, color: Colors.orange, isUnlocked: user.streak >= 30, rarity: app_badge.BadgeRarity.epic, hint: "Tam 30 gün ara verme."),

      // Net Ortalaması Madalyaları
      app_badge.Badge(name: 'Yükseliş', description: 'Ortalama 50 net barajını aştın. Bu daha başlangıç!', icon: Icons.trending_up, color: Colors.blueAccent, isUnlocked: avgNet > 50, hint: "Net ortalamanı 50'nin üzerine çıkar."),
      app_badge.Badge(name: 'Usta Nişancı', description: 'Ortalama 90 net! Elitler arasına hoş geldin.', icon: Icons.gps_not_fixed, color: Colors.blueAccent, isUnlocked: avgNet > 90, rarity: app_badge.BadgeRarity.rare, hint: "Net ortalamanı 90'ın üzerine çıkar."),
      app_badge.Badge(name: 'Bilge Nişancı', description: 'Ortalama 100 net barajını yıktın. Sen bir efsanesin!', icon: Icons.workspace_premium, color: Colors.blueAccent, isUnlocked: avgNet > 100, rarity: app_badge.BadgeRarity.epic, hint: "Net ortalamanı 100'ün üzerine çıkar."),

      // Strateji ve Planlama Madalyaları
      app_badge.Badge(name: 'Stratejist', description: 'BilgeAI ile ilk uzun vadeli stratejini oluşturdun.', icon: Icons.insights, color: Colors.purpleAccent, isUnlocked: user.longTermStrategy != null, hint: "AI Hub'da stratejini oluştur."),
      app_badge.Badge(name: 'Haftanın Hakimi', description: 'Bir haftalık plandaki tüm görevleri tamamladın.', icon: Icons.checklist, color: Colors.purpleAccent, isUnlocked: (user.completedDailyTasks.values.expand((e) => e).length) >= 15, rarity: app_badge.BadgeRarity.rare, hint: "Bir haftalık plandaki tüm görevleri bitir."),
      app_badge.Badge(name: 'Odaklanma Ninjası', description: 'Toplam 10 saat Pomodoro tekniği ile odaklandın.', icon: Icons.timer, color: Colors.purpleAccent, isUnlocked: focusSessions.fold(0, (p, c) => p + c.durationInSeconds) >= 36000, rarity: app_badge.BadgeRarity.rare, hint: "Toplam 10 saat odaklan."),

      // Atölye ve Arena Madalyaları
      app_badge.Badge(name: 'Cevher Avcısı', description: 'Cevher Atölyesi\'nde ilk zayıf konunu işledin.', icon: Icons.construction, color: AppTheme.secondaryColor, isUnlocked: user.topicPerformances.isNotEmpty, hint: "Cevher Atölyesi'ni kullan."),
      app_badge.Badge(name: 'Arena Gladyatörü', description: 'Liderlik tablosuna girerek adını duyurdun.', icon: Icons.leaderboard, color: AppTheme.secondaryColor, isUnlocked: user.engagementScore > 0, rarity: app_badge.BadgeRarity.common, hint: "Etkileşim puanı kazan."),
      app_badge.Badge(name: 'Efsane', description: 'Tüm madalyaları toplayarak ölümsüzleştin!', icon: Icons.auto_stories, color: Colors.amber, isUnlocked: false, rarity: app_badge.BadgeRarity.legendary, hint: "Tüm diğer madalyaları kazan."),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final focusSessionsAsync = ref.watch(focusSessionsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
              final (rankName, nextLevelXp, rankIcon) = _getWarriorRank(testCount, avgNet, user.engagementScore);

              return Stack(
                children: [
                  const RiveAnimation.asset(
                    'assets/rive/space_background.riv',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: AppTheme.cardColor,
                              child: Text(
                                user.name?.substring(0, 1).toUpperCase() ?? 'B',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).scale(),
                          const SizedBox(height: 12),
                          Text(user.name ?? 'İsimsiz Savaşçı', style: Theme.of(context).textTheme.headlineSmall).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 4),
                          Chip(
                            avatar: Icon(rankIcon, size: 18, color: AppTheme.secondaryColor),
                            label: Text(rankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 16),
                          XpBar(
                            currentXp: user.engagementScore,
                            nextLevelXp: nextLevelXp,
                            rankName: "Rütbe Puanı",
                          ).animate().fadeIn(delay: 400.ms),
                          const Spacer(flex: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(value: testCount.toString(), label: 'Deneme', icon: Icons.library_books_rounded).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
                              _StatItem(value: avgNet.toStringAsFixed(1), label: 'Ort. Net', icon: Icons.track_changes_rounded).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
                              _StatItem(value: user.streak.toString(), label: 'Günlük Seri', icon: Icons.local_fire_department_rounded).animate().fadeIn(delay: 700.ms).slideY(begin: 0.5),
                            ],
                          ),
                          const Spacer(flex: 2),
                          _ActionCard(
                            title: "Şeref Duvarı",
                            subtitle: "$unlockedCount / ${allBadges.length} Madalya",
                            icon: Icons.military_tech_rounded,
                            onTap: () => context.push('/profile/honor-wall', extra: allBadges),
                          ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.5),
                          const SizedBox(height: 16),
                          _ActionCard(
                            title: "Stratejik Plan",
                            subtitle: "Uzun vadeli zafer planını görüntüle.",
                            icon: Icons.map_rounded,
                            onTap: () => context.push('${AppRoutes.aiHub}/${AppRoutes.commandCenter}', extra: user),
                          ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.5),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatItem({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryTextColor, size: 28),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.lightSurfaceColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.secondaryColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
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