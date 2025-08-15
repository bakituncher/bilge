// lib/features/auth/application/auth_controller.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/features/auth/data/auth_repository.dart';
import 'package:bilge_ai/features/quests/logic/quest_notifier.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

final authControllerProvider = StreamNotifierProvider<AuthController, User?>(() {
  return AuthController();
});

class AuthController extends StreamNotifier<User?> {
  @override
  Stream<User?> build() {
    final authRepository = ref.watch(authRepositoryProvider);
    final authStream = authRepository.authStateChanges;
    final subscription = authStream.listen(_onAuthStateChanged);
    ref.onDispose(() => subscription.cancel());
    return authStream;
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      // --- GÖREV SİSTEMİ ENTEGRASYONU ---
      // Kullanıcı verileri yüklendikten sonra çalışması için kısa bir gecikme eklenir.
      Future.delayed(const Duration(seconds: 3), () {
        try {
          if (state.hasValue) { // Provider'ın hala "canlı" olduğundan emin ol.
            ref.read(questNotifierProvider).updateQuestProgress(QuestCategory.consistency);
          }
        } catch (e) {
          // Bu hata genellikle uygulamanın ilk açılışında, diğer provider'lar
          // henüz hazır değilken tetiklenir ve beklenen bir durumdur.
          print("Quest update on auth change failed (safe to ignore on startup): $e");
        }
      });
      // ------------------------------------
    }
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