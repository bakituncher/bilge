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
  // Bu StreamNotifier'ın tüm yaşam döngüsü boyunca dinleyeceği stream'i oluşturur.
  @override
  Stream<User?> build() {
    final authRepository = ref.watch(authRepositoryProvider);
    final authStream = authRepository.authStateChanges;

    // Stream'den bir olay geldiğinde _onAuthStateChanged fonksiyonunu tetikle.
    final subscription = authStream.listen(_onAuthStateChanged);

    // Bu provider (ve dolayısıyla stream) yok edildiğinde,
    // stream dinleyicisini de bellek sızıntısını önlemek için iptal et.
    // Bu, Riverpod'daki doğru ve modern "dispose" yöntemidir.
    ref.onDispose(() => subscription.cancel());

    return authStream;
  }

  // Kullanıcı durumu her değiştiğinde (giriş/çıkış) bu fonksiyon çalışır.
  void _onAuthStateChanged(User? user) {
    if (user != null) {
      // Görev sisteminin, kullanıcının diğer verileri yüklendikten sonra
      // çalışması için kısa bir gecikme ekliyoruz. Bu, uygulamanın
      // ilk açılışındaki "yarış" durumlarını engeller.
      Future.delayed(const Duration(seconds: 5), () {
        try {
          // Provider'ın hala "canlı" olduğundan emin oluyoruz.
          if (state.hasValue) {
            ref.read(questNotifierProvider).updateQuestProgress(QuestCategory.consistency);
          }
        } catch (e) {
          // Bu hata genellikle uygulamanın ilk açılışında, diğer provider'lar
          // henüz hazır değilken tetiklenir ve beklenen bir durumdur.
          // Konsola sadece bilgi amaçlı yazdırıyoruz.
          print("Quest update on auth change failed (safe to ignore on startup): $e");
        }
      });
    }
  }

  // --- Diğer Fonksiyonlar (Değişiklik Yok) ---

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