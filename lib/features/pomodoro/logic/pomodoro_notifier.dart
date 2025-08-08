// lib/features/pomodoro/logic/pomodoro_notifier.dart
import 'dart:async'; // HATA DÜZELTİLDİ: 'dart-async' -> 'dart:async'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';

enum PomodoroState { starcharting, calibration, voyage, discovery, stargazing }

class PomodoroModel {
  final PomodoroState currentState;
  final int timeRemaining;
  final String selectedTask;
  final int voyageDuration;

  PomodoroModel({
    this.currentState = PomodoroState.starcharting,
    required this.timeRemaining,
    this.selectedTask = "Genel Çalışma",
    required this.voyageDuration,
  });

  PomodoroModel copyWith({
    PomodoroState? currentState,
    int? timeRemaining,
    String? selectedTask,
  }) {
    return PomodoroModel(
      currentState: currentState ?? this.currentState,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      selectedTask: selectedTask ?? this.selectedTask,
      voyageDuration: voyageDuration,
    );
  }
}

const int _voyageDuration = 25 * 60;
const int _stargazingDuration = 5 * 60;
const int _calibrationDuration = 10;

class PomodoroNotifier extends StateNotifier<PomodoroModel> {
  final Ref _ref;
  Timer? _timer;

  PomodoroNotifier(this._ref) : super(PomodoroModel(timeRemaining: _voyageDuration, voyageDuration: _voyageDuration));

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        _timer?.cancel();
        _handleStateChange();
      }
    });
  }

  void startVoyage(String task) {
    state = state.copyWith(selectedTask: task, currentState: PomodoroState.calibration, timeRemaining: _calibrationDuration);
    _startTimer();
  }

  void completeDiscovery(String discoveryNote) {
    _saveSession(state.selectedTask);
    state = state.copyWith(currentState: PomodoroState.stargazing, timeRemaining: _stargazingDuration);
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroModel(timeRemaining: _voyageDuration, voyageDuration: _voyageDuration);
  }

  void _handleStateChange() {
    switch (state.currentState) {
      case PomodoroState.calibration:
        state = state.copyWith(currentState: PomodoroState.voyage, timeRemaining: _voyageDuration);
        _startTimer();
        break;
      case PomodoroState.voyage:
        state = state.copyWith(currentState: PomodoroState.discovery);
        break;
      case PomodoroState.stargazing:
        reset();
        break;
      default:
        break;
    }
  }

  void _saveSession(String task) {
    final userId = _ref.read(authControllerProvider).value?.uid;
    if (userId == null) return;
    final session = FocusSessionModel(
      userId: userId,
      date: DateTime.now(),
      durationInSeconds: _voyageDuration,
      task: task,
    );
    _ref.read(firestoreServiceProvider).addFocusSession(session);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider.autoDispose<PomodoroNotifier, PomodoroModel>((ref) {
  return PomodoroNotifier(ref);
});