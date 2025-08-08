// lib/features/arena/screens/arena_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';

// Şimdilik haftalık ve tüm zamanlar aynı provider'ı kullanacak.
// Gelecekte haftalık için ayrı bir Cloud Function ile bu provider güncellenebilir.
final weeklyLeaderboardProvider = leaderboardProvider;

class ArenaScreen extends ConsumerWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Savaşçılar Arenası'),
          bottom: const TabBar(
            indicatorColor: AppTheme.secondaryColor,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: 'Bu Hafta'),
              Tab(text: 'Tüm Zamanlar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaderboardView(provider: weeklyLeaderboardProvider),
            _LeaderboardView(provider: leaderboardProvider),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardView extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<LeaderboardEntry>>> provider;
  const _LeaderboardView({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(provider);
    final currentUserId = ref.watch(authControllerProvider).value?.uid;

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(context);
        }

        // Kullanıcının kendi sırasını ve bilgisini bul
        final currentUserIndex = entries.indexWhere((e) => e.userId == currentUserId);
        final LeaderboardEntry? currentUserEntry = currentUserIndex != -1 ? entries[currentUserIndex] : null;

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), // Altta boşluk bırak
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _LeaderboardCard(
                  entry: entry,
                  rank: index + 1,
                  isCurrentUser: entry.userId == currentUserId,
                ).animate().fadeIn(delay: (50 * (index % 15)).ms).slideX(begin: 0.2, curve: Curves.easeOut);
              },
            ),
            if (currentUserEntry != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _CurrentUserCard(
                  entry: currentUserEntry,
                  rank: currentUserIndex + 1,
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
      error: (err, stack) => Center(child: Text('Liderlik tablosu yüklenemedi: $err')),
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
              'Deneme ekleyerek veya Pomodoro seansları tamamlayarak Bilgelik Puanı kazan ve adını liderlik tablosuna yazdır!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardCard({required this.entry, required this.rank, this.isCurrentUser = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rankColor = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : rank == 3 ? const Color(0xFFCD7F32) : AppTheme.secondaryTextColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentUser
            ? const BorderSide(color: AppTheme.successColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '$rank.',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? rankColor : AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: AppTheme.lightSurfaceColor,
              child: Text(
                entry.userName.substring(0, 1).toUpperCase(),
                style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.userName,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.testCount} deneme',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      entry.score.toString(),
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_purple500_outlined, color: AppTheme.secondaryColor, size: 20),
                  ],
                ),
                Text('BP', style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUserCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  const _CurrentUserCard({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: const [SlideEffect(begin: Offset(0, 1)), FadeEffect()],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 5),
          ],
          border: const Border(top: BorderSide(color: AppTheme.successColor, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: _LeaderboardCard(
            entry: entry,
            rank: rank,
            isCurrentUser: true,
          ),
        ),
      ),
    );
  }
}