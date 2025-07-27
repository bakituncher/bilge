// lib/data/repositories/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

// GÜNCELLENDİ: Servis provider'ı sadeleştirildi.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
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

class FirestoreService {
  // GÜNCELLENDİ: Gereksiz _db alanı kaldırıldı.
  final CollectionReference<Map<String, dynamic>> _usersCollection =
  FirebaseFirestore.instance.collection('users');

  final CollectionReference<Map<String, dynamic>> _testsCollection =
  FirebaseFirestore.instance.collection('tests');

  // GÜNCELLENDİ: `name` parametresi eklendi.
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