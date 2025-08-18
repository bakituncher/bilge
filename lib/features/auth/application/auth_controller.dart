// lib/features/auth/application/auth_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
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
    // Uygulama her açıldığında veya kullanıcı durumu değiştiğinde tetiklenir.
    final subscription = authStream.listen(_onUserActivity);
    ref.onDispose(() => subscription.cancel());
    return authStream;
  }

  void _onUserActivity(User? user) {
    if (user != null) {
      // --- YENİ ZİYARET KAYIT VE GÖREV GÜNCELLEME MANTIĞI ---
      // Bu fonksiyon artık sadece kullanıcı aktivitesini kaydeder ve görevleri tetikler.
      Future.delayed(const Duration(seconds: 2), () {
        try {
          if (state.hasValue) { // Provider'ın hala "canlı" olduğundan emin ol.
            _recordVisitAndUpdateQuests(user.uid);
          }
        } catch (e) {
          print("Quest update on auth change failed (safe to ignore on startup): $e");
        }
      });
      // ------------------------------------
    }
  }

  /// Kullanıcının ziyaretini kaydeder ve tutarlılık görevlerini günceller.
  Future<void> _recordVisitAndUpdateQuests(String userId) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final userDoc = await firestoreService.usersCollection.doc(userId).get();
    if (!userDoc.exists) return;

    final user = UserModel.fromSnapshot(userDoc as DocumentSnapshot<Map<String, dynamic>>);
    final now = Timestamp.now();
    final today = DateTime(now.toDate().year, now.toDate().month, now.toDate().day);

    // Bugün dışındaki eski ziyaretleri temizle
    final todaysVisits = user.dailyVisits.where((ts) {
      final visitDate = ts.toDate();
      return visitDate.year == today.year && visitDate.month == today.month && visitDate.day == today.day;
    }).toList();

    // Son ziyaretten bu yana en az 1 saat geçtiyse yenisini ekle
    if (todaysVisits.isEmpty || now.toDate().difference(todaysVisits.last.toDate()).inHours >= 1) {
      todaysVisits.add(now);
      await firestoreService.usersCollection.doc(userId).update({
        'dailyVisits': todaysVisits,
      });
    }

    // Görev ilerlemesini tetikle
    ref.read(questNotifierProvider.notifier).updateQuestProgress(QuestCategory.consistency);
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