class LeaderboardEntry {
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

  // Bu model, doğrudan kullanıcı dökümanlarından okunacak şekilde tasarlanmıştır.
  // Not: Bu alanların (avgNet, testCount) bir Cloud Function ile güncellenmesi en sağlıklısıdır.
  factory LeaderboardEntry.fromUser(Map<String, dynamic> userData) {
    return LeaderboardEntry(
      userId: userData['uid'] ?? '',
      userName: userData['name'] ?? 'Bilinmeyen Oyuncu',
      averageNet: (userData['averageNet'] ?? 0.0).toDouble(),
      testCount: userData['testCount'] ?? 0,
    );
  }
}