// lib/features/arena/screens/arena_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart';
// BİLGEAI DEVRİMİ - DÜZELTME: Hatalı import yolu düzeltildi.
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

final weeklyLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final allTimeEntries = await ref.watch(leaderboardProvider.future);
  return allTimeEntries;
});

class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savaşçılar Arenası'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Haftanın Yıldızları'),
            Tab(text: 'Tüm Zamanlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardView(weeklyLeaderboardProvider),
          _buildLeaderboardView(leaderboardProvider),
        ],
      ),
    );
  }

  Widget _buildLeaderboardView(ProviderListenable<AsyncValue<List<LeaderboardEntry>>> provider) {
    final leaderboardAsync = ref.watch(provider);
    // BİLGEAI DEVRİMİ - DÜZELTME: Bu değişken artık doğru şekilde kullanılıyor.
    final currentUserId = ref.watch(authControllerProvider).value?.uid;

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('Liderlik tablosu için henüz yeterli veri yok.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            // BİLGEAI DEVRİMİ - DÜZELTME: Karşılaştırma artık güvenilir olan userId üzerinden yapılıyor.
            final bool isCurrentUser = entry.userId == currentUserId;
            return _buildLeaderboardCard(context, entry, index + 1, isCurrentUser)
                .animate()
                .fadeIn(delay: (100 * (index % 10)).ms, duration: 400.ms)
                .slideX(begin: 0.2, curve: Curves.easeOut);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
      error: (err, stack) => Center(child: Text('Liderlik tablosu yüklenemedi: $err')),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context, LeaderboardEntry entry, int rank, bool isCurrentUser) {
    final textTheme = Theme.of(context).textTheme;
    Color rankColor = AppTheme.secondaryTextColor;

    if (rank == 1) rankColor = const Color(0xFFFFD700); // Altın
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Gümüş
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronz

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentUser
            ? const BorderSide(color: AppTheme.successColor, width: 2)
            : BorderSide(color: rank <= 3 ? rankColor.withOpacity(0.5) : Colors.transparent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Column(
              children: [
                if (rank <= 3)
                  Icon(Icons.emoji_events, color: rankColor, size: 32)
                else
                  Text('$rank.', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondaryTextColor)),
              ],
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              backgroundColor: AppTheme.lightSurfaceColor,
              child: Text(entry.userName.substring(0, 1).toUpperCase(), style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.userName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('${entry.testCount} deneme', style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
                ],
              ),
            ),
            Text(
              '${entry.averageNet.toStringAsFixed(2)} Net',
              style: textTheme.titleLarge?.copyWith(
                color: rank <= 3 ? rankColor : AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}