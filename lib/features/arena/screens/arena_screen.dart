// lib/features/arena/screens/arena_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:go_router/go_router.dart'; // YENİ: Navigasyon için import
import 'package:bilge_ai/core/navigation/app_routes.dart'; // YENİ: Rota isimleri için import
import 'package:flutter_svg/flutter_svg.dart'; // YENİ: Avatar için import

class ArenaScreen extends ConsumerWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProfileProvider).value;

    if (currentUser == null || currentUser.selectedExam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zafer Panteonu')),
        body: const Center(child: Text("Arenaya girmek için bir sınav seçmelisiniz.")),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zafer Panteonu'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          bottom: const TabBar(
            indicatorColor: AppTheme.secondaryColor,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: [
              Tab(text: 'Bu Haftanın Onuru'),
              Tab(text: 'Tüm Zamanların Efsaneleri'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaderboardView(isAllTime: false),
            _LeaderboardView(isAllTime: true),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardView extends ConsumerWidget {
  final bool isAllTime;
  const _LeaderboardView({required this.isAllTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authControllerProvider).value?.uid;
    final currentUserExam = ref.watch(userProfileProvider).value?.selectedExam;

    if (currentUserExam == null) return const SizedBox.shrink();

    final leaderboardAsync = ref.watch(leaderboardProvider(currentUserExam));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.cardColor.withOpacity(0.8),
          ],
        ),
      ),
      child: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(context);
          }

          final currentUserIndex = entries.indexWhere((e) => e.userId == currentUserId);
          final LeaderboardEntry? currentUserEntry = currentUserIndex != -1 ? entries[currentUserIndex] : null;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    int rank = index + 1;

                    return GestureDetector(
                      // GÜNCELLENDİ: Artık diyalog yerine yeni ekrana yönlendiriyor.
                      onTap: () {
                        context.push('${AppRoutes.arena}/${entry.userId}');
                      },
                      child: _RankCard(
                        entry: entry,
                        rank: rank,
                        isCurrentUser: entry.userId == currentUserId,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (60 * (index % 15)).ms)
                          .slideX(begin: index.isEven ? -0.1 : 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                    );
                  },
                ),
              ),
              if (currentUserEntry != null && currentUserIndex >= 15)
                _CurrentUserCard(
                  entry: currentUserEntry,
                  rank: currentUserIndex + 1,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (err, stack) => Center(child: Text('Liderlik tablosu yüklenemedi: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_moon_rounded, size: 80, color: AppTheme.secondaryTextColor),
            const SizedBox(height: 16),
            Text('Arena Henüz Boş', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Deneme ekleyerek veya Pomodoro seansları tamamlayarak Bilgelik Puanı kazan ve adını bu panteona yazdır!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)));
  }
}

class _RankCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _RankCard({required this.entry, required this.rank, this.isCurrentUser = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700), // Gold
      2 => const Color(0xFFC0C0C0), // Silver
      3 => const Color(0xFFCD7F32), // Bronze
      _ => AppTheme.lightSurfaceColor,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(isCurrentUser ? 0.9 : 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrentUser ? AppTheme.successColor : rankColor.withOpacity(0.5)),
        boxShadow: [
          if (isCurrentUser)
            BoxShadow(color: AppTheme.successColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
          if (rank <= 3 && !isCurrentUser) // Mevcut kullanıcı değilse ve ilk 3'teyse normal gölge
            BoxShadow(color: rankColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: (rank <= 3)
                ? Icon(
              Icons.emoji_events,
              color: rankColor,
              size: rank == 1 ? 32 : (rank == 2 ? 28 : 24),
            )
                : Text(
              '$rank',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(color: rankColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // *** GÜNCELLENDİ: Avatar gösterimi entegre edildi ***
          CircleAvatar(
            backgroundColor: AppTheme.lightSurfaceColor,
            child: ClipOval(
              child: (entry.avatarStyle != null && entry.avatarSeed != null)
                  ? SvgPicture.network(
                "https://api.dicebear.com/9.x/${entry.avatarStyle}/svg?seed=${entry.avatarSeed}",
                fit: BoxFit.cover,
              )
                  : Text(entry.userName.isNotEmpty ? entry.userName.substring(0, 1).toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                // Kullanıcı kendi kartında değilse ve 1. sıradaysa tacı göster
                if (rank == 1 && !isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(Icons.workspace_premium, color: const Color(0xFFFFD700), size: 22),
                  ),
                Expanded(
                  child: Text(
                    entry.userName,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${entry.score} BP',
            style: textTheme.titleLarge?.copyWith(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// KULLANICI KARTI (GÜVENLİ BÖLGEYE ALINDI)
class _CurrentUserCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  const _CurrentUserCard({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    // Kullanıcının kendi kartı her zaman vurgulu olacak
    return Animate(
      effects: [
        SlideEffect(begin: const Offset(0, 1), duration: 500.ms, curve: Curves.easeOutCubic),
        FadeEffect(duration: 500.ms),
      ],
      child: Animate(
        onPlay: (controller) => controller.repeat(reverse: true),
        effects: [
          ScaleEffect(
            delay: 500.ms,
            duration: 1500.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            curve: Curves.easeInOut,
          ),
        ],
        child: Container(
          decoration: BoxDecoration(
              color: AppTheme.cardColor, // Vurgu için belki farklı bir renk veya daha opak
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                // Vurguyu artırmak için gölgeyi belirginleştirebiliriz
                BoxShadow(color: AppTheme.successColor.withOpacity(0.6), blurRadius: 25, spreadRadius: 6),
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
              ],
              border: Border.all(color: AppTheme.successColor, width: 2) // Ekstra vurgu için çerçeve
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0), // Consistent padding
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _RankCard(
                  entry: entry,
                  rank: rank,
                  isCurrentUser: true, // Her zaman true çünkü bu _CurrentUserCard
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}