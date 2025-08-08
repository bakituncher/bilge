// lib/features/auth/data/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.watch(firestoreServiceProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;

  AuthRepository(this._firebaseAuth, this._firestoreService);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _firestoreService.createUserProfile(userCredential.user!, name);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Girdiğiniz şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        throw 'Bu e-posta adresi zaten kullanımda.';
      } else {
        throw 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'E-posta veya şifre hatalı.';
      } else {
        throw 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}