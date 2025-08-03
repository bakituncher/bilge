// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
// HATA DÜZELTİLDİ: 'package.flutter_riverpod' -> 'package:flutter_riverpod'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';

// Rozet modelimiz
class Badge {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  Badge({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
  });
}

// Diğer tüm hatalar, hatalı import'tan kaynaklandığı için bu düzeltmeyle giderildi.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komuta Merkezin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }
          final tests = testsAsync.valueOrNull ?? [];
          final testCount = tests.length;
          final avgNet = testCount > 0 ? user.totalNetSum / testCount : 0.0;
          final badges = _generateBadges(user, testCount, avgNet);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(user, textTheme),
              const SizedBox(height: 24),
              _buildStatsGrid(context, testCount, avgNet, user.streak),
              const SizedBox(height: 32),
              Text("Savaşçı Rozetlerin", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              _buildBadgesSection(badges),
            ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }

  // Kullanıcı verilerine göre rozet listesini oluşturan devrimci fonksiyon
  List<Badge> _generateBadges(UserModel user, int testCount, double avgNet) {
    return [
      // Deneme Sayısı Rozetleri
      Badge(name: 'İlk Adım', description: 'İlk denemeni ekle.', icon: Icons.flag, color: Colors.green, isUnlocked: testCount >= 1),
      Badge(name: 'Acemi Savaşçı', description: '5 deneme ekle.', icon: Icons.shield_outlined, color: Colors.green, isUnlocked: testCount >= 5),
      Badge(name: 'Deneyimli Savaşçı', description: '15 deneme ekle.', icon: Icons.shield, color: Colors.green, isUnlocked: testCount >= 15),
      Badge(name: 'Usta Savaşçı', description: '30 deneme ekle.', icon: Icons.military_tech_outlined, color: Colors.green, isUnlocked: testCount >= 30),
      Badge(name: 'Deneme Fatihi', description: '50 deneme ekle.', icon: Icons.military_tech, color: Colors.green, isUnlocked: testCount >= 50),

      // Seri Rozetleri
      Badge(name: 'Kıvılcım', description: '3 günlük seri yakala.', icon: Icons.whatshot_outlined, color: Colors.orange, isUnlocked: user.streak >= 3),
      Badge(name: 'Ateşleyici', description: '7 günlük seri yakala.', icon: Icons.local_fire_department_outlined, color: Colors.orange, isUnlocked: user.streak >= 7),
      Badge(name: 'Alev Ustası', description: '14 günlük seri yakala.', icon: Icons.local_fire_department, color: Colors.orange, isUnlocked: user.streak >= 14),
      Badge(name: 'Durdurulamaz', description: '30 günlük seri yakala.', icon: Icons.wb_sunny, color: Colors.orange, isUnlocked: user.streak >= 30),

      // Net Ortalaması Rozetleri
      Badge(name: 'Yükseliş', description: '50 Net ortalamasını geç.', icon: Icons.trending_up, color: Colors.blue, isUnlocked: avgNet > 50),
      Badge(name: 'Nişancı', description: '70 Net ortalamasını geç.', icon: Icons.gps_fixed, color: Colors.blue, isUnlocked: avgNet > 70),
      Badge(name: 'Usta Nişancı', description: '90 Net ortalamasını geç.', icon: Icons.gps_not_fixed, color: Colors.blue, isUnlocked: avgNet > 90),
      Badge(name: 'Bilge Nişancı', description: '100 Net ortalamasını geç.', icon: Icons.gps_fixed, color: Colors.blue, isUnlocked: avgNet > 100),

      // Strateji ve Planlama Rozetleri
      Badge(name: 'Stratejist', description: 'İlk stratejini oluştur.', icon: Icons.insights, color: AppTheme.successColor, isUnlocked: user.longTermStrategy != null),
      Badge(name: 'Planlayıcı', description: 'Haftalık planındaki 10 görevi tamamla.', icon: Icons.checklist, color: AppTheme.successColor, isUnlocked: (user.completedDailyTasks.values.expand((e) => e).length) >= 10),
      Badge(name: 'Odaklanma Ustası', description: 'İlk Pomodoro seansını tamamla.', icon: Icons.timer, color: AppTheme.successColor, isUnlocked: true), // Pomodoro takibi eklenince güncellenmeli

      // Diğer Başarılar
      Badge(name: 'Kâşif', description: 'İlk zayıf konunu işle.', icon: Icons.construction, color: Colors.purple, isUnlocked: user.topicPerformances.isNotEmpty),
      Badge(name: 'Yazar', description: 'İlk günlük notunu ekle.', icon: Icons.edit, color: Colors.purple, isUnlocked: true), // Günlük takibi eklenince güncellenmeli
      Badge(name: 'Lider', description: 'Liderlik tablosuna gir.', icon: Icons.leaderboard, color: Colors.purple, isUnlocked: testCount > 0),
      Badge(name: 'Gecenin Baykuşu', description: 'Gece 12-4 arası bir görevi tamamla.', icon: Icons.nightlight_round, color: Colors.indigo, isUnlocked: false),
      Badge(name: 'Erken Kalkan', description: 'Sabah 5-8 arası bir görevi tamamla.', icon: Icons.light_mode, color: Colors.yellow, isUnlocked: false),
      Badge(name: 'Hafta Sonu Savaşçısı', description: 'Hafta sonu 5 görev tamamla.', icon: Icons.weekend, color: Colors.teal, isUnlocked: false),
      Badge(name: 'Mükemmel Hafta', description: 'Bir haftadaki tüm görevleri tamamla.', icon: Icons.celebration, color: Colors.pink, isUnlocked: false),
      Badge(name: 'Azim Abidesi', description: 'Toplam 100 saat odaklan.', icon: Icons.hourglass_bottom, color: Colors.red, isUnlocked: false),
    ];
  }


  Widget _buildProfileHeader(UserModel user, TextTheme textTheme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.lightSurfaceColor,
          child: Text(
            user.name?.substring(0, 1).toUpperCase() ?? 'B',
            style: textTheme.displayMedium?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text(user.name ?? 'İsimsiz Savaşçı', style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(user.email, style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int testCount, double avgNet, int streak) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard('Deneme', testCount.toString(), Icons.bar_chart_rounded, context),
        _buildStatCard('Ort. Net', avgNet.toStringAsFixed(2), Icons.track_changes_rounded, context),
        _buildStatCard('Seri', '$streak Gün', Icons.local_fire_department_rounded, context),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.secondaryTextColor, size: 28),
          const SizedBox(height: 8),
          Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(List<Badge> badges) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: badges.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadge(badge);
      },
    );
  }

  Widget _buildBadge(Badge badge) {
    return Tooltip(
      message: "${badge.name}\n${badge.description}",
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
              color: badge.isUnlocked ? badge.color.withOpacity(0.15) : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badge.isUnlocked ? badge.color : AppTheme.lightSurfaceColor.withOpacity(0.5), width: 1.5)
          ),
          child: Icon(
              badge.isUnlocked ? badge.icon : Icons.lock,
              color: badge.isUnlocked ? badge.color : AppTheme.lightSurfaceColor,
              size: 32
          ),
        ),
      ),
    );
  }
}