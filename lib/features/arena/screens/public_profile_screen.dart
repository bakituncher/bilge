// lib/features/arena/screens/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:bilge_ai/features/profile/widgets/xp_bar.dart';
import 'package:bilge_ai/features/profile/logic/rank_service.dart'; // YENİ: Merkezi rütbe sistemi
import 'package:flutter_svg/flutter_svg.dart'; // YENİ: Avatar için

// Bu provider, ID'ye göre tek bir kullanıcı profili getirmek için kullanılır.
final publicUserProfileProvider = FutureProvider.family.autoDispose<UserModel?, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getUserById(userId);
});

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

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
          // *** GÜNCELLENDİ: Rütbe artık merkezi RankService'ten geliyor ***
          final rankInfo = RankService.getRankInfo(user.engagementScore);
          final rankName = rankInfo.current.name;
          final rankIcon = rankInfo.current.icon;
          final rankColor = rankInfo.current.color;

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
                      // *** GÜNCELLENDİ: Avatar gösterimi entegre edildi ***
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Container(
                            color: AppTheme.cardColor,
                            child: user.avatarStyle != null && user.avatarSeed != null
                                ? SvgPicture.network(
                              "https://api.dicebear.com/9.x/${user.avatarStyle}/svg?seed=${user.avatarSeed}",
                              fit: BoxFit.cover,
                              placeholderBuilder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                                : Center(
                              child: Text(
                                user.name?.substring(0, 1).toUpperCase() ?? 'B',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(),
                      const SizedBox(height: 12),
                      Text(user.name ?? 'İsimsiz Savaşçı', style: Theme.of(context).textTheme.headlineSmall).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 4),
                      Chip(
                        avatar: Icon(rankIcon, size: 18, color: rankColor),
                        label: Text(rankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: rankColor.withOpacity(0.2),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),
                      XpBar(
                        currentXp: user.engagementScore,
                        nextLevelXp: rankInfo.next.requiredScore,
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
                      const Spacer(flex: 3),
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