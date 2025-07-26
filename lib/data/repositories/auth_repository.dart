// lib/data/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart'; // Firestore servisini import et

// Bu provider, AuthRepository'nin bir örneğini oluşturur ve diğer provider'ların onu okumasını sağlar.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Artık FirestoreService'i de okuyup AuthRepository'e veriyor.
  return AuthRepository(
    FirebaseAuth.instance,
    ref.read(firestoreServiceProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  // FirestoreService'i de alması için constructor'ı güncelle
  final FirestoreService _firestoreService;

  AuthRepository(this._firebaseAuth, this._firestoreService);

  // Kullanıcının giriş durumunu dinleyen bir Stream.
  // Kullanıcı giriş yapınca, çıkış yapınca veya uygulama açıldığında bize haber verir.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // YENİ EKLENDİ: Kayıt başarılı olursa Firestore'da profil oluştur.
      if (userCredential.user != null) {
        await _firestoreService.createUserProfile(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      // Firebase'den gelen hataları daha anlaşılır bir formata çeviriyoruz.
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
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
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