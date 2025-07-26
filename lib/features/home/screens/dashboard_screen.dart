// lib/features/home/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Panel')),
      body: const Center(
        child: Text('Yakında burada motive edici içerikler olacak!'),
      ),
    );
  }
}