// lib/features/pomodoro/pomodoro_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/coach/screens/weekly_plan_screen.dart';

// Gözlemevi Aşamaları
enum ObservatoryState {
  starcharting,   // Yıldız Haritası (Hazırlık)
  calibration,    // Kalibrasyon (Nefes)
  voyage,         // Seyahat (Odaklanma)
  discovery,      // Keşif (Yansıma)
  stargazing,     // Yıldız Gözlemi (Mola)
}

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> with TickerProviderStateMixin {
  // Seyahat Süreleri
  static const int _voyageDuration = 25 * 60;
  static const int _stargazingDuration = 5 * 60;
  static const int _calibrationDuration = 10;

  // Durum Yönetimi
  int _timeRemaining = _voyageDuration;
  ObservatoryState _currentState = ObservatoryState.starcharting;
  Timer? _timer;
  String _selectedConstellation = "Genel Çalışma";
  final TextEditingController _discoveryController = TextEditingController();

  // Animasyon Kontrolcüleri
  late AnimationController _breathingController;
  late AnimationController _celestialRotationController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(vsync: this, duration: 5.seconds)..repeat(reverse: true);
    _celestialRotationController = AnimationController(vsync: this, duration: 100.seconds)..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _celestialRotationController.dispose();
    _discoveryController.dispose();
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

  void _handleStateChange({bool reset = false}) {
    if (reset) {
      _timer?.cancel();
      setState(() {
        _currentState = ObservatoryState.starcharting;
        _timeRemaining = _voyageDuration;
      });
      return;
    }

    switch (_currentState) {
      case ObservatoryState.starcharting:
        _selectConstellationToExplore();
        break;
      case ObservatoryState.calibration:
        setState(() {
          _currentState = ObservatoryState.voyage;
          _timeRemaining = _voyageDuration;
        });
        _startTimer();
        break;
      case ObservatoryState.voyage:
        setState(() => _currentState = ObservatoryState.discovery);
        break;
      case ObservatoryState.discovery:
        _saveSession();
        setState(() {
          _currentState = ObservatoryState.stargazing;
          _timeRemaining = _stargazingDuration;
        });
        _startTimer();
        break;
      case ObservatoryState.stargazing:
        setState(() => _currentState = ObservatoryState.starcharting);
        break;
    }
  }

  void _saveSession() {
    final userId = ref.read(authControllerProvider).value?.uid;
    if (userId == null) return;
    final session = FocusSessionModel(
      userId: userId,
      date: DateTime.now(),
      durationInSeconds: _voyageDuration,
      task: _selectedConstellation,
    );
    ref.read(firestoreServiceProvider).addFocusSession(session);
    _discoveryController.clear();
  }

  Future<void> _selectConstellationToExplore() async {
    final user = ref.read(userProfileProvider).value;
    List<String> tasks = ["Genel Çalışma", "Konu Tekrarı", "Soru Çözümü"];
    if (user?.weeklyPlan != null) {
      final plan = WeeklyPlan.fromJson(user!.weeklyPlan!);
      // ** HATA DÜZELTİLDİ: Artık eski '.tasks' yerine yeni ve güçlü '.schedule' yapısını kullanıyoruz. **
      // Her günün programındaki her bir aktiviteyi (ScheduleItem.activity) alıp listeye ekliyoruz.
      tasks.addAll(plan.plan.expand((day) => day.schedule.map((item) => item.activity)));
    }
    tasks = tasks.toSet().toList();

    final String? chosenTask = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskSelectionSheet(tasks: tasks),
    );

    if (chosenTask != null) {
      setState(() {
        _selectedConstellation = chosenTask;
        _currentState = ObservatoryState.calibration;
        _timeRemaining = _calibrationDuration;
      });
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zihinsel Gözlemevi'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedContainer(
        duration: 800.ms,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              _getBackgroundColor().withOpacity(0.3),
              AppTheme.primaryColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: 800.ms,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_currentState) {
      case ObservatoryState.voyage: return AppTheme.secondaryColor;
      case ObservatoryState.stargazing: return AppTheme.successColor;
      case ObservatoryState.calibration: return Colors.blueAccent;
      default: return AppTheme.lightSurfaceColor;
    }
  }

  Widget _buildCurrentView() {
    switch (_currentState) {
      case ObservatoryState.starcharting: return _buildStarchartingView();
      case ObservatoryState.calibration: return _buildCalibrationView();
      case ObservatoryState.voyage: return _buildVoyageView();
      case ObservatoryState.discovery: return _buildDiscoveryView();
      case ObservatoryState.stargazing: return _buildStargazingView();
    }
  }

  Widget _buildStarchartingView() {
    return Column(
      key: const ValueKey('starcharting'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.explore_rounded, size: 80, color: AppTheme.secondaryColor),
        const SizedBox(height: 24),
        Text("Keşfe Hazır Ol", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text("Yıldız haritanı oluştur ve zihninin derinliklerine bir yolculuğa çık.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor)),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: () => _handleStateChange(),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text("Yolculuğa Başla"),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCalibrationView() {
    return Column(
      key: const ValueKey('calibration'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut)),
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.blueAccent.withOpacity(0.5), Colors.transparent])),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text("Aletler Kalibre Ediliyor...", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text("Evrenle hizalanmak için nefesine odaklan.", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }

  Widget _buildVoyageView() {
    return Column(
      key: const ValueKey('voyage'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Spacer(),
        Text(_selectedConstellation, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Expanded(
          flex: 3,
          child: _CelestialCompass(
            progress: 1 - (_timeRemaining / _voyageDuration),
            rotation: _celestialRotationController,
          ),
        ),
        Text('${(_timeRemaining / 60).floor().toString().padLeft(2, '0')}:${(_timeRemaining % 60).toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _handleStateChange(reset: true),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text("Yolculuğu Sonlandır"),
          style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryTextColor),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDiscoveryView() {
    return Padding(
      key: const ValueKey('discovery'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flare_rounded, size: 80, color: AppTheme.successColor),
          const SizedBox(height: 24),
          Text("Keşfini Kaydet", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text("Bu seyahatte öğrendiğin en parlak bilgiyi bir cümleyle not et.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor)),
          const SizedBox(height: 32),
          TextField(controller: _discoveryController, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "Örn: İki kare farkı formülünün mantığı...")),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: () => _handleStateChange(), child: const Text("Keşfi Mühürle ve Dinlen")),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStargazingView() {
    return Column(
      key: const ValueKey('stargazing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bedtime_rounded, size: 80, color: AppTheme.successColor),
        const SizedBox(height: 24),
        Text("Yıldız Gözlemi", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text('${(_timeRemaining / 60).floor().toString().padLeft(2, '0')}:${(_timeRemaining % 60).toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.secondaryTextColor)),
        const SizedBox(height: 32),
        Text("Zihnin, yeni keşiflere hazırlanmak için dinleniyor.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic)),
      ],
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
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text("Hangi Takımyıldızını Keşfedeceksin?", style: Theme.of(context).textTheme.headlineSmall)),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: tasks.length,
                itemBuilder: (context, index) => ListTile(title: Text(tasks[index], maxLines: 2, overflow: TextOverflow.ellipsis,), onTap: () => Navigator.of(context).pop(tasks[index])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelestialCompass extends StatelessWidget {
  final double progress;
  final Animation<double> rotation;
  const _CelestialCompass({required this.progress, required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        ScaleEffect(delay: 200.ms, duration: 1200.ms, curve: Curves.elasticOut, begin: const Offset(0.5, 0.5)),
        FadeEffect(duration: 800.ms),
      ],
      child: AnimatedBuilder(
        animation: rotation,
        builder: (context, child) {
          return CustomPaint(
            painter: _CelestialCompassPainter(
              progress: progress,
              rotation: rotation.value,
              random: Random(),
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

class _CelestialCompassPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final double rotation; // 0.0 -> 1.0
  final Random random;
  final int starCount = 100;
  final List<Offset> stars;

  _CelestialCompassPainter({required this.progress, required this.rotation, required this.random})
      : stars = List.generate(100, (i) => Offset(random.nextDouble(), random.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Arka plan yıldızları
    final starPaint = Paint()..color = AppTheme.lightSurfaceColor.withOpacity(0.5);
    for (var star in stars) {
      final starPos = Offset(star.dx * size.width, star.dy * size.height);
      canvas.drawCircle(starPos, random.nextDouble() * 1.2, starPaint);
    }

    // Dönen halkalar
    final ringPaint = Paint()
      ..color = AppTheme.secondaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * pi);
    canvas.drawCircle(Offset.zero, radius * 0.8, ringPaint);
    canvas.rotate(rotation * 4 * pi); // Ters yönde daha hızlı
    canvas.drawCircle(Offset.zero, radius * 0.6, ringPaint..strokeWidth = 1);
    canvas.restore();

    // Zaman ilerleme yayı
    final progressPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..style = PaintingStyle.stroke..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      -pi / 2,
      progress * 2 * pi,
      false,
      progressPaint,
    );

    // Zaman iğnesi
    final needlePaint = Paint()..color = Colors.white..strokeWidth = 2;
    final needleEnd = Offset(
      center.dx + radius * 0.9 * cos(progress * 2 * pi - pi / 2),
      center.dy + radius * 0.9 * sin(progress * 2 * pi - pi / 2),
    );
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _CelestialCompassPainter oldDelegate) =>
      progress != oldDelegate.progress || rotation != oldDelegate.rotation;
}