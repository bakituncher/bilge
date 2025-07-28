// lib/features/pomodoro/pomodoro_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int _workDuration = 25 * 60; // 25 dakika
  static const int _breakDuration = 5 * 60; // 5 dakika

  late int _timeRemaining;
  bool _isWorking = true;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeRemaining = _workDuration;
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isWorking = !_isWorking;
          _timeRemaining = _isWorking ? _workDuration : _breakDuration;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer(){
    _pauseTimer();
    setState(() {
      _isWorking = true;
      _timeRemaining = _workDuration;
    });
  }

  String get _formattedTime {
    final minutes = (_timeRemaining / 60).floor().toString().padLeft(2, '0');
    final seconds = (_timeRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = (_isWorking ? _workDuration - _timeRemaining : _breakDuration - _timeRemaining) /
        (_isWorking ? _workDuration : _breakDuration);

    return Scaffold(
      appBar: AppBar(title: const Text('Odaklanma Zamanı')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    backgroundColor: colorScheme.surface.withAlpha(128), // ~0.5 opacity
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _isWorking ? colorScheme.secondary : AppTheme.successColor),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formattedTime,
                          style: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _isWorking ? 'Çalışma' : 'Mola',
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(_isRunning)
                  ElevatedButton(
                    onPressed: _pauseTimer,
                    child: const Text('Durdur'),
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
                  )
                else
                  ElevatedButton(
                    onPressed: _startTimer,
                    child: const Text('Başlat'),
                  ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  iconSize: 32,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}