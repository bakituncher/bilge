// lib/features/pomodoro/pomodoro_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/features/coach/screens/ai_coach_screen.dart';
// BİLGEAI DEVRİMİ - DÜZELTME: 'WeeklyPlan' modelini tanımak için import eklendi.
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

// Pomodoro durumları için bir enum
enum PomodoroState { idle, selectingTask, breathing, working, shortBreak }

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> with TickerProviderStateMixin {
  // Zamanlayıcı Ayarları
  static const int _workDuration = 25 * 60;
  static const int _breakDuration = 5 * 60;
  static const int _breathingDuration = 60;

  // State Yönetimi
  int _timeRemaining = _workDuration;
  PomodoroState _currentState = PomodoroState.idle;
  Timer? _timer;
  String _selectedTask = "Genel Çalışma";

  // Animasyon Kontrolcüleri
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(vsync: this, duration: 4.seconds)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _timer?.cancel();
        _handleStateChange();
      }
    });
  }

  void _handleStateChange({bool fromButton = false}) {
    if (fromButton && _currentState != PomodoroState.idle) { // Reset
      _timer?.cancel();
      setState(() => _currentState = PomodoroState.idle);
      return;
    }

    switch (_currentState) {
      case PomodoroState.idle:
        setState(() => _currentState = PomodoroState.selectingTask);
        _selectTask();
        break;
      case PomodoroState.selectingTask: // Görev seçildikten sonra
        setState(() {
          _currentState = PomodoroState.breathing;
          _timeRemaining = _breathingDuration;
        });
        _startTimer();
        break;
      case PomodoroState.breathing:
        setState(() {
          _currentState = PomodoroState.working;
          _timeRemaining = _workDuration;
        });
        _startTimer();
        break;
      case PomodoroState.working:
        _saveSession(); // Çalışma seansını kaydet
        setState(() {
          _currentState = PomodoroState.shortBreak;
          _timeRemaining = _breakDuration;
        });
        _startTimer();
        break;
      case PomodoroState.shortBreak:
        setState(() => _currentState = PomodoroState.idle);
        break;
    }
  }

  void _saveSession() {
    final userId = ref.read(authControllerProvider).value?.uid;
    if (userId == null) return;

    final session = FocusSessionModel(
      userId: userId,
      date: DateTime.now(),
      durationInSeconds: _workDuration,
      task: _selectedTask,
    );
    ref.read(firestoreServiceProvider).addFocusSession(session);
  }

  Future<void> _selectTask() async {
    final analysisData = ref.read(aiAnalysisProvider)?.data;
    List<String> tasks = ["Genel Çalışma", "Konu Tekrarı"];

    if (analysisData != null && analysisData['weeklyPlan'] != null) {
      final plan = WeeklyPlan.fromJson(analysisData['weeklyPlan']);
      tasks.addAll(plan.plan.expand((day) => day.tasks));
    }

    final String? chosenTask = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskSelectionSheet(tasks: tasks.toSet().toList()), // Tekrarları kaldır
    );

    if (chosenTask != null) {
      setState(() => _selectedTask = chosenTask);
      _handleStateChange();
    } else {
      // Kullanıcı görev seçmeden kapattı, başa dön
      setState(() => _currentState = PomodoroState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Odaklanma Merkezi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimerDisplay(),
            const SizedBox(height: 50),
            _buildControlButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Animate(
      target: _currentState.index.toDouble(),
      // BİLGEAI DEVRİMİ - DÜZELTME: `const` ifadesi, animasyon süresi gibi dinamik
      // olabilecek bir extension method ile kullanılamayacağı için kaldırıldı.
      effects: [FadeEffect(duration: 600.ms)],
      child: Column(
        children: [
          if (_currentState == PomodoroState.breathing)
            _buildBreathingCircle(),
          if (_currentState == PomodoroState.working || _currentState == PomodoroState.shortBreak)
            _buildProgressCircle(),
          if (_currentState == PomodoroState.idle || _currentState == PomodoroState.selectingTask)
            _buildIdleDisplay(),
          const SizedBox(height: 20),
          _buildStatusText(),
        ],
      ),
    );
  }
  Widget _buildBreathingCircle() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut)),
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppTheme.successColor.withOpacity(0.5), AppTheme.primaryColor.withOpacity(0.1)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle() {
    final totalDuration = _currentState == PomodoroState.working ? _workDuration : _breakDuration;
    final progress = 1.0 - (_timeRemaining / totalDuration);
    final color = _currentState == PomodoroState.working ? AppTheme.secondaryColor : AppTheme.successColor;

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 12,
            backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${(_timeRemaining / 60).floor().toString().padLeft(2, '0')}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleDisplay() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.lightSurfaceColor, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.play_arrow_rounded, size: 100, color: AppTheme.secondaryColor),
      ),
    );
  }

  Widget _buildStatusText() {
    String status;
    String task = _selectedTask;
    switch (_currentState) {
      case PomodoroState.idle: status = "Başlamaya hazır mısın?"; break;
      case PomodoroState.selectingTask: status = "Görev seçiliyor..."; break;
      case PomodoroState.breathing: status = "Nefes Al... Nefes Ver..."; break;
      case PomodoroState.working: status = task; break;
      case PomodoroState.shortBreak: status = "Kısa bir mola."; break;
    }
    return Text(status, style: Theme.of(context).textTheme.headlineSmall);
  }
  Widget _buildControlButton() {
    String text = "Başla";
    IconData icon = Icons.play_arrow;
    VoidCallback? onPressed = () => _handleStateChange();

    if (_currentState != PomodoroState.idle && _currentState != PomodoroState.selectingTask) {
      text = "Sıfırla";
      icon = Icons.refresh;
      onPressed = () => _handleStateChange(fromButton: true);
    }
    if (_currentState == PomodoroState.selectingTask) {
      onPressed = null; // Görev seçilirken butonu devre dışı bırak
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      ),
    );
  }
}

class _TaskSelectionSheet extends StatelessWidget {
  final List<String> tasks;
  const _TaskSelectionSheet({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Bu seansta neye odaklanacaksın?",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(tasks[index]),
                      onTap: () => Navigator.of(context).pop(tasks[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}