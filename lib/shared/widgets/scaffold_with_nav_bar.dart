// lib/shared/widgets/scaffold_with_nav_bar.dart
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/features/home/screens/dashboard_screen.dart';
import 'package:bilge_ai/features/onboarding/providers/tutorial_provider.dart';
import 'package:bilge_ai/features/onboarding/widgets/tutorial_overlay.dart';
import 'package:bilge_ai/features/onboarding/models/tutorial_step.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TutorialStep> tutorialSteps = [
      TutorialStep(
        title: "Karargaha Hoş Geldin!",
        text: "Ben Bilge Baykuş! Zafer yolundaki en büyük destekçin ben olacağım. Sana hızlıca komuta merkezini tanıtayım.",
      ),
      TutorialStep(
        highlightKey: todaysPlanKey,
        title: "Burası Harekat Merkezin",
        text: "Günlük görevlerin, haftalık planın ve performans raporun... En kritik bilgiler burada. Sağa kaydırarak diğer kartları görebilirsin!",
      ),
      TutorialStep(
        highlightKey: addTestKey,
        title: "Veri Güçtür!",
        text: "Buraya eklediğin her deneme, yapay zekanın seni daha iyi tanımasını ve sana özel stratejiler üretmesini sağlar! Hadi devam edelim.",
      ),
      TutorialStep(
        highlightKey: coachKey,
        title: "Stratejik Deha: Koç",
        text: "Şimdi en güçlü silahımızın olduğu yere, Koç sekmesine gidelim. Lütfen aşağıdaki 'Koç' ikonuna dokun.",
        buttonText: "Anladım, Koç'a Gidelim!",
        isNavigational: true,
      ),
      TutorialStep(
        highlightKey: aiHubFabKey,
        title: "İşte BilgeAI Çekirdeği!",
        text: "Burası sihrin gerçekleştiği yer! Buradan kişisel zafer planını oluşturabilir, en zayıf konularına özel çalışmalar yapabilirsin.",
      ),
      TutorialStep(
          highlightKey: arenaKey,
          title: "Savaşçılar Arenası",
          text: "Diğer savaşçılar arasındaki yerini gör ve rekabetin tadını çıkar! Ne kadar çok deneme eklersen o kadar yükselirsin.",
          buttonText: "Harika, Başlayalım!"
      ),
    ];

    // DÜZELTME: ProviderScope ve override, bu widget'ın en dışına sarıldı.
    return ProviderScope(
      overrides: [
        tutorialProvider.overrideWith((ref) => TutorialNotifier(tutorialSteps.length, navigationShell)),
      ],
      child: Consumer( // Consumer, ProviderScope'un hemen içinde olmalı
          builder: (context, ref, child) {
            // Bu, override edilmiş provider'ı dinlememizi sağlar.
            ref.watch(tutorialProvider);

            return Stack(
              children: [
                Scaffold(
                  body: navigationShell,
                  extendBody: true,
                  floatingActionButton: FloatingActionButton(
                    key: aiHubFabKey,
                    heroTag: 'main_fab',
                    onPressed: () => _onTap(2),
                    backgroundColor: AppTheme.secondaryColor,
                    child: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 28),
                    elevation: 4.0,
                    shape: const CircleBorder(),
                  ).animate().scale(delay: 500.ms),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: BottomAppBar(
                    shape: const CircularNotchedRectangle(),
                    notchMargin: 10.0,
                    padding: EdgeInsets.zero,
                    height: 70,
                    color: AppTheme.cardColor.withOpacity(0.95),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, icon: Icons.dashboard_rounded, label: 'Panel', index: 0, key: null),
                        // DÜZELTME: Koç'un doğru index'i 1'dir. FAB butonu 2. index'teki sayfayı açar (goBranch(2)).
                        _buildNavItem(context, icon: Icons.school_rounded, label: 'Koç', index: 1, key: coachKey),
                        const SizedBox(width: 56),
                        _buildNavItem(context, icon: Icons.military_tech_rounded, label: 'Arena', index: 3, key: arenaKey),
                        _buildNavItem(context, icon: Icons.person_rounded, label: 'Profil', index: 4, key: profileKey),
                      ],
                    ),
                  ),
                ),
                // Öğretici katmanını en üste ekle
                TutorialOverlay(steps: tutorialSteps),
              ],
            );
          }
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index, required GlobalKey? key}) {
    final isSelected = navigationShell.currentIndex == index;
    return IconButton(
      key: key,
      icon: Icon(icon, color: isSelected ? AppTheme.secondaryColor : AppTheme.secondaryTextColor, size: 28),
      onPressed: () => _onTap(index),
      tooltip: label,
      splashColor: AppTheme.secondaryColor.withOpacity(0.2),
      highlightColor: AppTheme.secondaryColor.withOpacity(0.1),
    );
  }
}