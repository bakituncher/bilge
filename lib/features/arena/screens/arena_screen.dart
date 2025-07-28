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
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Animate(
                // HATA DÜZELTİLDİ: Dinamik değer (index) kullanıldığı için const olamaz.
                // HATA DÜZELTİLDİ: `.ms` uzantısı Duration nesnesine çevrildi.
                delay: Duration(milliseconds: 100 * index),
                effects: const [ // Efekt listesi sabit olabilir
                  FadeEffect(duration: Duration(milliseconds: 400)),
                  SlideEffect(begin: Offset(0.1, 0))
                ],
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

    bool isTopThree = rank <= 3;
    Color? tileColor;
    // HATA DÜZELTİLDİ: withOpacity -> withAlpha
    if (rank == 1) tileColor = const Color(0xFFFFD700).withAlpha(51); // Altın
    if (rank == 2) tileColor = const Color(0xFFC0C0C0).withAlpha(51); // Gümüş
    if (rank == 3) tileColor = const Color(0xFFCD7F32).withAlpha(51); // Bronz

    return Card(
      color: tileColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          // HATA DÜZELTİLDİ: withOpacity -> withAlpha
            color: isTopThree ? tileColor!.withAlpha(204) : Colors.transparent,
            width: 1.5
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Column(
              children: [
                if (isTopThree)
                // HATA DÜZELTİLDİ: withOpacity -> withAlpha
                  Icon(Icons.emoji_events, color: tileColor!.withAlpha(255), size: 30)
                else
                  Text('$rank.', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 16),
            // HATA DÜZELTİLDİ: withOpacity -> withAlpha
            CircleAvatar(
              backgroundColor: colorScheme.primary.withAlpha(80),
              child: Text(entry.userName.substring(0, 1).toUpperCase(), style: textTheme.titleMedium?.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.userName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${entry.testCount} deneme', style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Text(
              '${entry.averageNet.toStringAsFixed(2)} Net',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}