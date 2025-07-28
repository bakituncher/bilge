// lib/data/repositories/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/journal_entry_model.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart'; // YENİ
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return ref.read(firestoreServiceProvider).getUserProfile(user.uid);
  }
  return Stream.value(null);
});

final testsProvider = StreamProvider.autoDispose<List<TestModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return ref.read(firestoreServiceProvider).getTestResults(user.uid);
  }
  return Stream.value([]);
});

final journalEntriesProvider = StreamProvider.autoDispose<List<JournalEntry>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return ref.read(firestoreServiceProvider).getJournalEntries(user.uid);
  }
  return Stream.value([]);
});

// YENİ: Liderlik Tablosu için Provider
final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);

  // 1. Tüm kullanıcıları al
  final allUsers = await firestoreService.getAllUsers();

  final leaderboardEntries = <LeaderboardEntry>[];

  // 2. Her kullanıcı için testlerini al ve ortalamasını hesapla
  for (final user in allUsers) {
    if (user.name == null || user.name!.isEmpty) continue;

    final tests = await firestoreService.getTestResults(user.id).first; // Stream'in ilk değerini al
    if (tests.isNotEmpty) {
      final totalNet = tests.map((t) => t.totalNet).reduce((a, b) => a + b);
      final averageNet = totalNet / tests.length;
      leaderboardEntries.add(LeaderboardEntry(
        userName: user.name!,
        averageNet: averageNet,
        testCount: tests.length,
      ));
    }
  }

  // 3. Kullanıcıları ortalama netlerine göre büyükten küçüğe sırala
  leaderboardEntries.sort((a, b) => b.averageNet.compareTo(a.averageNet));

  return leaderboardEntries;
});


class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _testsCollection => _firestore.collection('tests');
  CollectionReference<Map<String, dynamic>> get _journalCollection => _firestore.collection('journal');

  // ... (createUserProfile, updateOnboardingData, getUserProfile metotları burada)
  Future<void> createUserProfile(User user, String name) async {
    final userProfile = UserModel(id: user.uid, email: user.email!, name: name);
    await _usersCollection.doc(user.uid).set(userProfile.toJson());
  }

  Future<void> updateOnboardingData({
    required String userId,
    required String goal,
    required List<String> challenges,
    required double weeklyStudyGoal,
  }) async {
    await _usersCollection.doc(userId).update({
      'goal': goal,
      'challenges': challenges,
      'weeklyStudyGoal': weeklyStudyGoal,
      'onboardingCompleted': true,
    });
  }

  Stream<UserModel> getUserProfile(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromSnapshot(doc));
  }

  // YENİ: Liderlik tablosu için tüm kullanıcıları getiren metot
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
  }

  Future<void> addTestResult(TestModel test) async {
    await _testsCollection.add(test.toJson());
    await updateUserStreak(test.userId);
  }

  Stream<List<TestModel>> getTestResults(String userId) {
    return _testsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TestModel.fromSnapshot(doc))
        .toList());
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    if (entry.id.isEmpty) {
      await _journalCollection.add(entry.toJson());
    } else {
      await _journalCollection.doc(entry.id).update(entry.toJson());
    }
  }

  Stream<List<JournalEntry>> getJournalEntries(String userId) {
    return _journalCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => JournalEntry.fromSnapshot(doc))
        .toList());
  }

  Future<void> deleteJournalEntry(String entryId) async {
    await _journalCollection.doc(entryId).delete();
  }


  Future<void> updateUserStreak(String userId) async {
    final userDocRef = _usersCollection.doc(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final userSnapshot = await userDocRef.get();
    if (!userSnapshot.exists) return;

    final user = UserModel.fromSnapshot(userSnapshot);
    final lastUpdate = user.lastStreakUpdate;

    if (lastUpdate == null) {
      await userDocRef.update({'streak': 1, 'lastStreakUpdate': Timestamp.fromDate(today)});
    } else {
      final lastUpdateDate = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
      if (today.isAtSameMomentAs(lastUpdateDate)) {
        return;
      }

      final yesterday = today.subtract(const Duration(days: 1));
      if (lastUpdateDate.isAtSameMomentAs(yesterday)) {
        await userDocRef.update({'streak': FieldValue.increment(1), 'lastStreakUpdate': Timestamp.fromDate(today)});
      } else {
        await userDocRef.update({'streak': 1, 'lastStreakUpdate': Timestamp.fromDate(today)});
      }
    }
  }
}