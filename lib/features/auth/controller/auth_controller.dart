// lib/features/auth/controller/auth_controller.dart

import 'dart:async'; // HATA DÜZELTİLDİ: 'dart.async' değil 'dart:async'
import 'package:bilge_ai/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// HATA DÜZELTİLDİ: AsyncNotifierProvider yerine StreamNotifierProvider kullanıyoruz.
final authControllerProvider =
StreamNotifierProvider.autoDispose<AuthController, User?>(() {
  return AuthController();
});

// HATA DÜZELTİLDİ: AsyncNotifier yerine StreamNotifier kullanıyoruz.
class AuthController extends AutoDisposeStreamNotifier<User?> {
  // build metodu artık bir Stream döndürüyor ve bu, StreamNotifier için doğru kullanım.
  @override
  Stream<User?> build() {
    final authRepository = ref.watch(authRepositoryProvider);
    return authRepository.authStateChanges;
  }

  // Bu metodlar artık state yönetimi yapmıyor.
  // Sadece ilgili repository metodunu çağırıyorlar. Hata yönetimi UI katmanında yapılacak.
  Future<void> signIn({required String email, required String password}) {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({required String email, required String password}) {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.signOut();
  }
}