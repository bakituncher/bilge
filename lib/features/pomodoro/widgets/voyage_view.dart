// lib/features/pomodoro/widgets/voyage_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import '../logic/pomodoro_notifier.dart';

class VoyageView extends ConsumerStatefulWidget {
  const VoyageView({super.key});

  @override
  ConsumerState<VoyageView> createState() => _VoyageViewState();
}

class _VoyageViewState extends ConsumerState<VoyageView> with SingleTickerProviderStateMixin {
  late final AnimationController _celestialRotationController;

  @override
  void initState() {
    super.initState();
    _celestialRotationController = AnimationController(vsync: this, duration: 100.seconds)..repeat();
  }

  @override
  void dispose() {
    _celestialRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = ref.watch(pomodoroProvider);
    final timeRemaining = pomodoro.timeRemaining;
    final voyageDuration = pomodoro.voyageDuration;

    return Column(
      key: const ValueKey('voyage'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Spacer(),
        Text(pomodoro.selectedTask, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Expanded(
          flex: 3,
          child: _CelestialCompass(
            progress: voyageDuration > 0 ? 1 - (timeRemaining / voyageDuration) : 1,
            rotation: _celestialRotationController,
          ),
        ),
        Text('${(timeRemaining / 60).floor().toString().padLeft(2, '0')}:${(timeRemaining % 60).toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => ref.read(pomodoroProvider.notifier).reset(),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text("Yolculuğu Sonlandır"),
          style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryTextColor),
        ),
        const SizedBox(height: 20),
      ],
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
  final double progress;
  final double rotation;
  final Random random;
  final List<Offset> stars;

  _CelestialCompassPainter({required this.progress, required this.rotation, required this.random})
      : stars = List.generate(100, (i) => Offset(random.nextDouble(), random.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final starPaint = Paint()..color = AppTheme.lightSurfaceColor.withOpacity(0.5);
    for (var star in stars) {
      final starPos = Offset(star.dx * size.width, star.dy * size.height);
      canvas.drawCircle(starPos, random.nextDouble() * 1.2, starPaint);
    }

    final ringPaint = Paint()
      ..color = AppTheme.secondaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * pi);
    canvas.drawCircle(Offset.zero, radius * 0.8, ringPaint);
    canvas.rotate(rotation * 4 * pi);
    canvas.drawCircle(Offset.zero, radius * 0.6, ringPaint..strokeWidth = 1);
    canvas.restore();

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
  }

  @override
  bool shouldRepaint(covariant _CelestialCompassPainter oldDelegate) =>
      progress != oldDelegate.progress || rotation != oldDelegate.rotation;
}