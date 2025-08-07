// lib/features/pomodoro/widgets/calibration_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class CalibrationView extends StatefulWidget {
  const CalibrationView({super.key});

  @override
  State<CalibrationView> createState() => _CalibrationViewState();
}

class _CalibrationViewState extends State<CalibrationView> with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(vsync: this, duration: 5.seconds)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
}