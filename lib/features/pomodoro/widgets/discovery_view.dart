// lib/features/pomodoro/widgets/discovery_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import '../logic/pomodoro_notifier.dart';

class DiscoveryView extends ConsumerStatefulWidget {
  const DiscoveryView({super.key});

  @override
  ConsumerState<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends ConsumerState<DiscoveryView> {
  final _discoveryController = TextEditingController();

  @override
  void dispose() {
    _discoveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          ElevatedButton(onPressed: () {
            ref.read(pomodoroProvider.notifier).completeDiscovery(_discoveryController.text.trim());
          }, child: const Text("Keşfi Mühürle ve Dinlen")),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}