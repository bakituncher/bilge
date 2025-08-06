// lib/data/repositories/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  // FirebaseStorage bağımlılığı kaldırıldı.
  return FirestoreService(FirebaseFirestore.instance);
});

// ... (diğer provider'lar aynı kalacak)
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

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final allUsers = await firestoreService.getAllUsers();

  final leaderboardEntries = <LeaderboardEntry>[];

  for (final user in allUsers) {
    if (user.name != null && user.name!.isNotEmpty && user.testCount > 0) {
      leaderboardEntries.add(LeaderboardEntry(
        userId: user.id,
        userName: user.name!,
        averageNet: user.totalNetSum / user.testCount,
        testCount: user.testCount,
      ));
    }
  }

  leaderboardEntries.sort((a, b) => b.averageNet.compareTo(a.averageNet));

  return leaderboardEntries;
});


class FirestoreService {
  final FirebaseFirestore _firestore;
  // _storage alanı kaldırıldı.
  FirestoreService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _testsCollection => _firestore.collection('tests');
  CollectionReference<Map<String, dynamic>> get _focusSessionsCollection => _firestore.collection('focusSessions');

  // ... (createUserProfile, updateOnboardingData, getUserProfile, getAllUsers aynı kalacak)
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

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
  }


  Future<void> addTestResult(TestModel test) async {
    final userDocRef = _usersCollection.doc(test.userId);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDocRef);
      if (!userSnapshot.exists) {
        throw Exception("Kullanıcı bulunamadı!");
      }
      final user = UserModel.fromSnapshot(userSnapshot as DocumentSnapshot<Map<String, dynamic>>);

      final newTestRef = _testsCollection.doc();
      transaction.set(newTestRef, test.toJson());

      transaction.update(userDocRef, {
        'testCount': FieldValue.increment(1),
        'totalNetSum': FieldValue.increment(test.totalNet),
      });

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastUpdate = user.lastStreakUpdate;

      if (lastUpdate == null) {
        transaction.update(userDocRef, {'streak': 1, 'lastStreakUpdate': Timestamp.fromDate(today)});
      } else {
        final lastUpdateDate = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
        if (!today.isAtSameMomentAs(lastUpdateDate)) {
          final yesterday = today.subtract(const Duration(days: 1));
          if (lastUpdateDate.isAtSameMomentAs(yesterday)) {
            transaction.update(userDocRef, {'streak': FieldValue.increment(1), 'lastStreakUpdate': Timestamp.fromDate(today)});
          } else {
            transaction.update(userDocRef, {'streak': 1, 'lastStreakUpdate': Timestamp.fromDate(today)});
          }
        }
      }
    });
  }

  // ... (getTestResults aynı kalacak)
  Stream<List<TestModel>> getTestResults(String userId) {
    return _testsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TestModel.fromSnapshot(doc))
        .toList());
  }

  // uploadProfilePicture fonksiyonu kaldırıldı.

  // ... (geri kalan tüm fonksiyonlar aynı kalacak)
  Future<void> saveExamSelection({
    required String userId,
    required ExamType examType,
    required String sectionName,
  }) async {
    await _usersCollection.doc(userId).update({
      'selectedExam': examType.name,
      'selectedExamSection': sectionName,
    });
  }

  Future<void> updateTopicPerformance({
    required String userId,
    required String subject,
    required String topic,
    required TopicPerformanceModel performance,
  }) async {
    final userDocRef = _usersCollection.doc(userId);
    final fieldPath = 'topicPerformances.$subject.$topic';

    await userDocRef.update({
      fieldPath: performance.toMap(),
    });
  }

  Future<void> addFocusSession(FocusSessionModel session) async {
    await _focusSessionsCollection.add(session.toMap());
  }

  Future<void> updateDailyTaskCompletion({
    required String userId,
    required String dateKey,
    required String task,
    required bool isCompleted,
  }) async {
    final userDocRef = _usersCollection.doc(userId);
    final fieldPath = 'completedDailyTasks.$dateKey';

    await userDocRef.update({
      fieldPath: isCompleted
          ? FieldValue.arrayUnion([task])
          : FieldValue.arrayRemove([task]),
    });
  }

  Future<void> updateStrategicPlan({
    required String userId,
    required String pacing,
    required String longTermStrategy,
    required Map<String, dynamic> weeklyPlan,
  }) async {
    await _usersCollection.doc(userId).update({
      'studyPacing': pacing,
      'longTermStrategy': longTermStrategy,
      'weeklyPlan': weeklyPlan,
    });
  }
}