// lib/features/auth/controller/auth_controller.dart
import 'dart:async';
import 'package:bilge_ai/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// DEĞİŞİKLİK: .autoDispose kaldırıldı
final authControllerProvider =
StreamNotifierProvider<AuthController, User?>(() {
  return AuthController();
});

// DEĞİŞİKLİK: AutoDisposeStreamNotifier -> StreamNotifier
class AuthController extends StreamNotifier<User?> {
  @override
  Stream<User?> build() {
    final authRepository = ref.watch(authRepositoryProvider);
    return authRepository.authStateChanges;
  }

  Future<void> signIn({required String email, required String password}) {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({required String name, required String email, required String password}) {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.signUpWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.signOut();
  }
}