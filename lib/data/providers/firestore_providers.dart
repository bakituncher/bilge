// lib/data/providers/firestore_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart'; // EKLENDİ
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart'; // EKLENDİ
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import '../repositories/firestore_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firestoreProvider));
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).getUserProfile(user.uid);
  }
  return Stream.value(null);
});

final testsProvider = StreamProvider<List<TestModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).getTestResults(user.uid);
  }
  return Stream.value([]);
});

// Artık 'FutureProvider.family' doğru şekilde tanınıyor.
final leaderboardProvider = FutureProvider.family.autoDispose<List<LeaderboardEntry>, String>((ref, examType) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final users = await firestoreService.getLeaderboardUsers(examType);

  final leaderboardEntries = <LeaderboardEntry>[];

  for (final user in users) {
    if (user.name != null && user.name!.isNotEmpty) {
      leaderboardEntries.add(LeaderboardEntry(
        userId: user.id,
        userName: user.name!,
        score: user.engagementScore,
        testCount: user.testCount,
        avatarStyle: user.avatarStyle,
        avatarSeed: user.avatarSeed,
      ));
    }
  }


  return leaderboardEntries;
});