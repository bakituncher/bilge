import 'package:flutter/material.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.secondaryColor),
      ),
    );
  }
}