// lib/features/pomodoro/logic/pomodoro_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:intl/intl.dart';

enum PomodoroState { stats, starcharting, calibration, voyage, discovery, stargazing }

class PomodoroModel {
  final PomodoroState currentState;
  final int timeRemaining;
  final String selectedTask;
  final String? selectedTaskIdentifier;
  final int voyageDuration;
  final int stargazingDuration;

  PomodoroModel({
    this.currentState = PomodoroState.stats,
    required this.timeRemaining,
    this.selectedTask = "Genel Çalışma",
    this.selectedTaskIdentifier,
    required this.voyageDuration,
    required this.stargazingDuration,
  });

  PomodoroModel copyWith({
    PomodoroState? currentState,
    int? timeRemaining,
    String? selectedTask,
    String? selectedTaskIdentifier,
    int? voyageDuration,
    int? stargazingDuration,
  }) {
    return PomodoroModel(
      currentState: currentState ?? this.currentState,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      selectedTask: selectedTask ?? this.selectedTask,
      selectedTaskIdentifier: selectedTaskIdentifier ?? this.selectedTaskIdentifier,
      voyageDuration: voyageDuration ?? this.voyageDuration,
      stargazingDuration: stargazingDuration ?? this.stargazingDuration,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroModel> {
  final Ref _ref;
  Timer? _timer;

  PomodoroNotifier(this._ref)
      : super(PomodoroModel(
    timeRemaining: 0,
    voyageDuration: 25 * 60,
    stargazingDuration: 5 * 60,
  ));

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

  void startStarcharting() {
    state = state.copyWith(currentState: PomodoroState.starcharting);
  }

  void startVoyage({
    required String task,
    required int workDuration,
    required int breakDuration,
    String? taskIdentifier,
  }) {
    state = state.copyWith(
      selectedTask: task,
      selectedTaskIdentifier: taskIdentifier,
      voyageDuration: workDuration,
      stargazingDuration: breakDuration,
      currentState: PomodoroState.calibration,
      timeRemaining: 10, // Kalibrasyon süresi
    );
    _startTimer();
  }

  void completeDiscovery({required bool isTaskCompleted}) {
    _saveSession(state.selectedTask, state.voyageDuration);
    if(isTaskCompleted && state.selectedTaskIdentifier != null) {
      _markTaskAsCompleted(state.selectedTaskIdentifier!);
    }
    state = state.copyWith(
      currentState: PomodoroState.stargazing,
      timeRemaining: state.stargazingDuration,
    );
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroModel(
      currentState: PomodoroState.stats,
      timeRemaining: 0,
      voyageDuration: 25 * 60,
      stargazingDuration: 5 * 60,
    );
  }

  void _handleStateChange() {
    switch (state.currentState) {
      case PomodoroState.calibration:
        state = state.copyWith(
          currentState: PomodoroState.voyage,
          timeRemaining: state.voyageDuration,
        );
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

  void _saveSession(String task, int duration) {
    final userId = _ref.read(authControllerProvider).value?.uid;
    if (userId == null) return;
    final session = FocusSessionModel(
      userId: userId,
      date: DateTime.now(),
      durationInSeconds: duration,
      task: task,
    );
    _ref.read(firestoreServiceProvider).addFocusSession(session);
  }

  void _markTaskAsCompleted(String taskIdentifier) {
    final userId = _ref.read(authControllerProvider).value!.uid;
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _ref.read(firestoreServiceProvider).updateDailyTaskCompletion(
      userId: userId,
      dateKey: dateKey,
      task: taskIdentifier,
      isCompleted: true,
    );
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