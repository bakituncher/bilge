// lib/features/auth/application/auth_controller.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/features/auth/data/auth_repository.dart';

// Bu, tüm ordunun kullanacağı ana telsiz frekansı.
final authControllerProvider = StreamNotifierProvider<AuthController, User?>(() {
  return AuthController();
});

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