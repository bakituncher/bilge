// lib/features/pomodoro/pomodoro_screen.dart
import 'dart:async'; // HATA BURADAYDI: 'dart:async' import'u eklendi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';

// Pomodoro durumları için bir enum
enum PomodoroState {
  idle,
  selectingTask,
  breathing,
  working,
  shortBreak,
  feedback
}

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
  // Zamanlayıcı Ayarları
  static const int _workDuration = 25 * 60;
  static const int _breakDuration = 5 * 60;
  static const int _breathingDuration = 10; // 10 saniyelik nefes egzersizi

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
    _breathingController =
    AnimationController(vsync: this, duration: 4.seconds)
      ..repeat(reverse: true);
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
    if (fromButton) { // Reset
      _timer?.cancel();
      setState(() => _currentState = PomodoroState.idle);
      return;
    }

    switch (_currentState) {
      case PomodoroState.idle:
        setState(() => _currentState = PomodoroState.selectingTask);
        _selectTask();
        break;
      case PomodoroState.selectingTask:
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
        _saveSession();
        setState(() => _currentState = PomodoroState.feedback);
        break;
      case PomodoroState.feedback:
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
    final user = ref.read(userProfileProvider).value;
    List<String> tasks = ["Genel Çalışma", "Konu Tekrarı", "Soru Çözümü"];

    if (user != null && user.weeklyPlan != null) {
      final plan = WeeklyPlan.fromJson(user.weeklyPlan!);
      final allTasks = plan.plan.expand((day) => day.tasks).toList();
      tasks.addAll(allTasks);
    }
    // Tekrarları kaldır
    tasks = tasks.toSet().toList();

    final String? chosenTask = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskSelectionSheet(tasks: tasks),
    );

    if (chosenTask != null) {
      setState(() => _selectedTask = chosenTask);
      _handleStateChange();
    } else {
      setState(() => _currentState = PomodoroState.idle);
    }
  }

  void _handleFeedback(String feedbackType) {
    if (feedbackType == 'test' || feedbackType == 'deneme') {
      context.go('/home/add-test');
    } else {
      _handleStateChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Odaklanma Merkezi')),
      body: AnimatedContainer(
        duration: 500.ms,
        color: _getBackgroundColor(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimerDisplay(),
              _buildControlButton(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_currentState) {
      case PomodoroState.working:
        return AppTheme.primaryColor.withBlue(60);
      case PomodoroState.shortBreak:
        return AppTheme.successColor.withOpacity(0.2);
      default:
        return AppTheme.scaffoldBackgroundColor;
    }
  }

  Widget _buildTimerDisplay() {
    return Animate(
      key: ValueKey(_currentState),
      effects: [FadeEffect(duration: 600.ms), ScaleEffect(begin: const Offset(0.9, 0.9))],
      child: switch (_currentState) {
        PomodoroState.breathing => _buildBreathingCircle(),
        PomodoroState.working ||
        PomodoroState.shortBreak =>
            _buildProgressCircle(),
        PomodoroState.feedback => _buildFeedbackView(),
        _ => _buildIdleDisplay(),
      },
    );
  }

  Widget _buildBreathingCircle() {
    return Column(
      children: [
        FadeTransition(
          opacity: CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut)),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.successColor.withOpacity(0.5),
                    _getBackgroundColor().withOpacity(0.1)
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text("Nefes Al... Nefes Ver...", style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildProgressCircle() {
    final totalDuration = _currentState == PomodoroState.working ? _workDuration : _breakDuration;
    final progress = 1.0 - (_timeRemaining / totalDuration);
    final color = _currentState == PomodoroState.working ? AppTheme.secondaryColor : AppTheme.successColor;

    return Column(
      children: [
        SizedBox(
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
        ),
        const SizedBox(height: 20),
        Text(_selectedTask, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildIdleDisplay() {
    return Column(
      children: [
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.lightSurfaceColor, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.play_arrow_rounded, size: 100, color: AppTheme.secondaryColor),
          ),
        ),
        const SizedBox(height: 20),
        Text("Başlamaya hazır mısın?", style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildFeedbackView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 80),
          const SizedBox(height: 24),
          Text(
            "Harika bir seans!",
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Bu 25 dakikada ne üzerine odaklandın?",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeedbackButton(
            "Konu Çalıştım / Tekrar Yaptım",
            Icons.menu_book,
                () => _handleFeedback('konu'),
          ),
          const SizedBox(height: 16),
          _buildFeedbackButton(
            "Test Çözdüm / Deneme Analizi",
            Icons.checklist,
                () => _handleFeedback('test'),
          ),
          const SizedBox(height: 16),
          _buildFeedbackButton(
            "Deneme Çözdüm",
            Icons.assignment,
                () => _handleFeedback('deneme'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: AppTheme.lightSurfaceColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildControlButton() {
    String text = "Başla";
    IconData icon = Icons.play_arrow;
    VoidCallback? onPressed = () => _handleStateChange();

    if (_currentState == PomodoroState.working || _currentState == PomodoroState.shortBreak) {
      text = "Sıfırla";
      icon = Icons.refresh;
      onPressed = () => _handleStateChange(fromButton: true);
    }
    if (_currentState == PomodoroState.selectingTask || _currentState == PomodoroState.breathing || _currentState == PomodoroState.feedback) {
      onPressed = null;
    }

    return Animate(
      key: ValueKey(text),
      effects: const [FadeEffect(), ScaleEffect()],
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: AppTheme.primaryColor,
        ),
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