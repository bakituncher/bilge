// lib/features/arena/models/leaderboard_entry_model.dart

class LeaderboardEntry {
  // BİLGEAI DEVRİMİ - DÜZELTME: Mevcut kullanıcıyı güvenilir bir şekilde belirlemek için userId eklendi.
  final String userId;
  final String userName;
  final double averageNet;
  final int testCount;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.averageNet,
    required this.testCount,
  });
}