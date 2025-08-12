// lib/features/settings/logic/settings_notifier.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';

// Ayarlar ekranının durumunu tutan model
class SettingsState extends Equatable {
  final bool isLoading;
  const SettingsState({this.isLoading = false});

  SettingsState copyWith({bool? isLoading}) {
    return SettingsState(isLoading: isLoading ?? this.isLoading);
  }

  @override
  List<Object> get props => [isLoading];
}

// Ayarlar ekranının mantığını yöneten Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  SettingsNotifier(this._ref) : super(const SettingsState());

  Future<bool> updateUserName(String newName) async {
    state = state.copyWith(isLoading: true);
    final userId = _ref.read(authControllerProvider).value?.uid;

    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    try {
      await _ref
          .read(firestoreServiceProvider)
          .updateUserName(userId: userId, newName: newName);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

// Bu Notifier'ı tüm uygulamada kullanılabilir hale getiren Provider
final settingsNotifierProvider =
StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});