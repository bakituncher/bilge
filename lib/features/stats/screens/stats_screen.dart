// lib/features/stats/screens/stats_screen.dart
import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: const Center(
        child: Text('Yakında burada net grafikleri olacak!'),
      ),
    );
  }
}