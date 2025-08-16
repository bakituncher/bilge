// lib/features/arena/screens/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
// HATA ÇÖZÜMÜ: Rive'dan gelen LinearGradient gizlendi.
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:bilge_ai/features/profile/widgets/xp_bar.dart';
import 'package:bilge_ai/features/profile/models/badge_model.dart' as app_badge;

// Bu provider, ID'ye göre tek bir kullanıcı profili getirmek için kullanılır.
final publicUserProfileProvider = FutureProvider.family.autoDispose<UserModel?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getUserById(userId);
});


class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  // Bu fonksiyonlar profile_screen.dart dosyasından kopyalandı ve uyarlandı.
  (String, int, IconData) _getWarriorRank(int testCount, double avgNet, int score) {
    if (score > 15000 && testCount > 50 && avgNet > 90) return ("Efsanevi Komutan", 20000, Icons.workspace_premium);
    if (score > 8000 && testCount > 30 && avgNet > 70) return ("Usta Stratejist", 15000, Icons.star_rounded);
    if (score > 3000 && testCount > 15) return ("Kıdemli Savaşçı", 8000, Icons.military_tech);
    if (score > 1000 && testCount > 5) return ("Azimli Savaşçı", 3000, Icons.shield);
    return ("Acemi Kâşif", 1000, Icons.explore);
  }

  int _getUnlockedBadgeCount(UserModel user, int testCount, double avgNet) {
    // Gerçek badge listesini oluşturmadan sadece sayıyı hesaplamak için basit bir mantık
    int count = 0;
    if (testCount >= 1) count++;
    if (testCount >= 5) count++;
    if (testCount >= 15) count++;
    if (testCount >= 50) count++;
    if (user.streak >= 3) count++;
    if (user.streak >= 14) count++;
    if (user.streak >= 30) count++;
    if (avgNet > 50) count++;
    if (avgNet > 90) count++;
    if (avgNet > 100) count++;
    if (user.longTermStrategy != null) count++;
    if ((user.completedDailyTasks.values.expand((e) => e).length) >= 15) count++;
    // Odaklanma ve diğerleri şimdilik atlandı.
    return count;
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(publicUserProfileProvider(userId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Savaşçı Künyesi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userProfileAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Savaşçı bulunamadı.'));
          }

          final testCount = user.testCount;
          final avgNet = testCount > 0 ? user.totalNetSum / testCount : 0.0;
          final (rankName, nextLevelXp, rankIcon) = _getWarriorRank(testCount, avgNet, user.engagementScore);
          final unlockedBadgeCount = _getUnlockedBadgeCount(user, testCount, avgNet);
          // Toplam badge sayısı şimdilik sabit bir değer olabilir.
          const totalBadgeCount = 17;


          return Stack(
            children: [
              const RiveAnimation.asset(
                'assets/rive/space_background.riv',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient( // ARTIK HATA VERMEYECEK
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
                        rankName: "Bilgelik Puanı",
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
                        subtitle: "$unlockedBadgeCount / $totalBadgeCount Madalya",
                        icon: Icons.military_tech_rounded,
                        onTap: () {
                          // Gelecekte bu kullanıcının madalya duvarına gidilebilir
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Diğer savaşçıların madalya duvarı yakında açılacak!")),
                          );
                        },
                      ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.5),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text('Savaşçı Künyesi Yüklenemedi: $e')),
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