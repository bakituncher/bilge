// lib/features/arena/screens/arena_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArenaScreen extends ConsumerWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    // DÜZELTME: Kullanılmadığı için aşağıdaki satır silindi.
    // final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savaşçılar Arenası'),
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Liderlik tablosu için henüz yeterli veri yok.'));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Animate(
                delay: (100 * index).ms,
                // DÜZELTME: 'const' ifadesi hatayı çözmek için kaldırıldı.
                effects: [FadeEffect(duration: 300.ms), SlideEffect(begin: Offset(-0.1, 0))],
                child: _buildLeaderboardCard(context, entry, index + 1),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Liderlik tablosu yüklenemedi: $err')),
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context, LeaderboardEntry entry, int rank) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // İlk 3 için özel ikon ve renkler
    IconData rankIcon;
    Color rankColor;
    if (rank == 1) {
      rankIcon = Icons.emoji_events;
      rankColor = const Color(0xFFFFD700); // Altın
    } else if (rank == 2) {
      rankIcon = Icons.emoji_events;
      rankColor = const Color(0xFFC0C0C0); // Gümüş
    } else if (rank == 3) {
      rankIcon = Icons.emoji_events;
      rankColor = const Color(0xFFCD7F32); // Bronz
    } else {
      rankIcon = Icons.circle;
      rankColor = Colors.transparent;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            // Sıralama
            SizedBox(
              width: 50,
              child: rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 30)
                  : Center(child: Text('$rank.', style: textTheme.titleMedium)),
            ),
            // Kullanıcı Avatarı ve Adı
            CircleAvatar(
              backgroundColor: colorScheme.primary.withAlpha(50),
              child: Text(entry.userName.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.userName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${entry.testCount} deneme', style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            // Ortalama Net
            Text(
              '${entry.averageNet.toStringAsFixed(2)} Net',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}