// lib/features/strategic_planning/screens/command_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/features/strategic_planning/models/strategic_plan_model.dart';

class CommandCenterScreen extends StatefulWidget {
  final UserModel user;
  const CommandCenterScreen({super.key, required this.user});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  StrategicPlan? _plan;
  int _currentPhaseIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.user.longTermStrategy != null) {
      _plan = StrategicPlan.fromJson(widget.user.longTermStrategy!);
      // Burada normalde kullanıcının ilerlemesine göre mevcut aşama belirlenir.
      // Şimdilik ilk aşamayı aktif gösteriyoruz.
      _currentPhaseIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Komuta Merkezi")),
        body: const Center(
          child: Text("Harekat Planı yüklenemedi veya oluşturulmamış."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Harekât Karargahı"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCommanderProfile(textTheme),
          const SizedBox(height: 24),
          _buildMottoCard(textTheme),
          const SizedBox(height: 24),
          _buildPhasesStepper(textTheme),
        ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildCommanderProfile(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.lightSurfaceColor,
              child: Text(
                widget.user.name?.substring(0, 1).toUpperCase() ?? 'B',
                style: textTheme.headlineLarge?.copyWith(color: AppTheme.secondaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.name ?? "İsimsiz Savaşçı", style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text("Rütbe: Kıdemli Stratejist", style: textTheme.bodyMedium?.copyWith(color: AppTheme.successColor)),
                ],
              ),
            ),
            const Icon(Icons.shield_moon_rounded, color: AppTheme.secondaryColor, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMottoCard(TextTheme textTheme) {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          '"${_plan!.motto}"',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPhasesStepper(TextTheme textTheme) {
    return Stepper(
      currentStep: _currentPhaseIndex,
      onStepTapped: (step) => setState(() => _currentPhaseIndex = step),
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      physics: const ClampingScrollPhysics(),
      steps: _plan!.phases.map((phase) {
        return Step(
          title: Text(phase.phaseTitle, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: const Text("Aşama Detayları"),
          state: _currentPhaseIndex > phase.phaseNumber -1 ? StepState.complete :
          _currentPhaseIndex == phase.phaseNumber -1 ? StepState.indexed : StepState.disabled,
          isActive: _currentPhaseIndex >= phase.phaseNumber - 1,
          content: _buildPhaseContent(phase, textTheme),
        );
      }).toList(),
    );
  }

  Widget _buildPhaseContent(StrategyPhase phase, TextTheme textTheme) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.flag_circle_rounded, "AMAÇ:", phase.objective, AppTheme.secondaryColor),
            const Divider(height: 24),
            _buildDetailRow(Icons.military_tech_rounded, "TAKTİK:", phase.tactic, AppTheme.successColor),
            if (phase.exitCriteria.isNotEmpty) ...[
              const Divider(height: 24),
              _buildExitCriteria(phase.exitCriteria, textTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String content, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: TextStyle(color: AppTheme.secondaryTextColor, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExitCriteria(List<String> criteria, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.exit_to_app_rounded, color: AppTheme.accentColor, size: 20),
            const SizedBox(width: 12),
            Text("AŞAMA BİTİŞ KRİTERLERİ:", style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ...criteria.map((criterion) => Padding(
          padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(color: AppTheme.secondaryTextColor)),
              Expanded(child: Text(criterion, style: TextStyle(color: AppTheme.secondaryTextColor, height: 1.5))),
            ],
          ),
        )).toList(),
      ],
    );
  }
}