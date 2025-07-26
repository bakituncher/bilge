// lib/data/repositories/firestore_service.dart
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

// Anlık giriş yapmış kullanıcının profilini getiren provider.
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(authControllerProvider).value; // auth_controller'dan anlık kullanıcıyı al
  if (user != null) {
    return ref.read(firestoreServiceProvider).getUserProfile(user.uid);
  }
  return Stream.value(null);
});

class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService(this._db);

  // Yeni bir kullanıcı için Firestore'da profil oluşturur.
  Future<void> createUserProfile(User user) async {
    final userProfile = UserModel(id: user.uid, email: user.email!);
    await _db.collection('users').doc(user.uid).set(userProfile.toJson());
  }

  // Onboarding bilgilerini günceller.
  Future<void> updateOnboardingData({
    required String userId,
    required String goal,
    required List<String> challenges,
    required double dailyStudyGoal,
  }) async {
    await _db.collection('users').doc(userId).update({
      'goal': goal,
      'challenges': challenges,
      'dailyStudyGoal': dailyStudyGoal,
      'onboardingCompleted': true,
    });
  }

  // Kullanıcı profilini stream olarak dinler.
  Stream<UserModel> getUserProfile(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromSnapshot(doc));
  }
}