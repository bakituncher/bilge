// lib/features/arena/models/leaderboard_entry_model.dart

class LeaderboardEntry {
  final String userName;
  final double averageNet;
  final int testCount;

  LeaderboardEntry({
    required this.userName,
    required this.averageNet,
    required this.testCount,
  });
}