// lib/data/providers/user_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';

// Kullanıcı profil provider'ı - zaten firestore_providers.dart'ta tanımlı
// final userProfileProvider = StreamProvider<UserModel?>((ref) {
//   final firestoreService = ref.watch(firestoreServiceProvider);
//   return firestoreService.userStream;
// });

// Kullanıcı ID provider'ı
final userIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.value?.id;
});

// Kullanıcı adı provider'ı
final userNameProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.value?.name;
});

// Kullanıcı hedefi provider'ı
final userGoalProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.value?.goal;
});

// Kullanıcı streak provider'ı
final userStreakProvider = Provider<int>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.value?.streak ?? 0;
});