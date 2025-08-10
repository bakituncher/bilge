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
import 'package:bilge_ai/features/coach/screens/ai_hub_screen.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // YENİ VE GELİŞTİRİLMİŞ ÖĞRETİCİ ADIMLARI
    final List<TutorialStep> tutorialSteps = [
      TutorialStep( // Adım 0
        title: "Karargaha Hoş Geldin!",
        text: "Ben Bilge Baykuş! Zafer yolundaki en büyük destekçin ben olacağım. Sana hızlıca komuta merkezini tanıtayım.",
      ),
      TutorialStep( // Adım 1
        highlightKey: todaysPlanKey,
        title: "Burası Harekat Merkezin",
        text: "Günlük görevlerin, haftalık planın ve performans raporun... En kritik bilgiler burada. Sağa kaydırarak diğer kartları görebilirsin!",
        requiredScreenIndex: 0,
      ),
      TutorialStep( // Adım 2
        highlightKey: addTestKey,
        title: "Veri Güçtür!",
        text: "Buraya eklediğin her deneme, yapay zekanın seni daha iyi tanımasını ve sana özel stratejiler üretmesini sağlar! Hadi devam edelim.",
        requiredScreenIndex: 0,
      ),
      TutorialStep( // Adım 3
        highlightKey: coachKey,
        title: "Stratejik Deha: Koç",
        text: "Şimdi en güçlü silahımızın olduğu yere, yani BilgeAI Çekirdeği'ne gidelim. Lütfen aşağıdaki 'Koç' ikonuna dokun.",
        buttonText: "Anladım, Koç'a Gidiyorum!",
        isNavigational: true,
        requiredScreenIndex: 0,
      ),
      TutorialStep( // Adım 4
        highlightKey: aiHubFabKey,
        title: "İşte BilgeAI Çekirdeği!",
        text: "Burası sihrin gerçekleştiği yer! Buradan kişisel zafer planını oluşturabilir, en zayıf konularına özel çalışmalar yapabilirsin.",
        requiredScreenIndex: 1,
      ),
      TutorialStep( // Adım 5
        highlightKey: arenaKey,
        title: "Savaşçılar Arenası",
        text: "Diğer savaşçılar arasındaki yerini gör ve rekabetin tadını çıkar! Hadi Arena sekmesine dokun.",
        buttonText: "Arenayı Ziyaret Et!",
        isNavigational: true,
        requiredScreenIndex: 1,
      ),
      TutorialStep( // Adım 6
        highlightKey: profileKey,
        title: "Komuta Merkezin",
        text: "Son olarak burası senin profilin. Madalyalarını ve genel istatistiklerini buradan takip edebilirsin. Profil sekmesine dokun.",
        buttonText: "Profilime Gidelim!",
        isNavigational: true,
        requiredScreenIndex: 3,
      ),
      TutorialStep( // Adım 7
        title: "Keşif Turu Bitti!",
        text: "Harika! Artık karargahı tanıyorsun. Unutma, zafer azim, strateji ve doğru rehberlikle kazanılır. Ben her zaman buradayım!",
        buttonText: "Harika, Başlayalım!",
        requiredScreenIndex: 4,
      ),
    ];

    return ProviderScope(
      overrides: [
        tutorialProvider.overrideWith((ref) => TutorialNotifier(tutorialSteps.length, navigationShell)),
      ],
      child: Consumer(
          builder: (context, ref, child) {
            final currentStepIndex = ref.watch(tutorialProvider);
            final currentScreenIndex = navigationShell.currentIndex;

            final shouldShowTutorial = currentStepIndex != null &&
                (tutorialSteps[currentStepIndex].requiredScreenIndex == null ||
                    tutorialSteps[currentStepIndex].requiredScreenIndex == currentScreenIndex);

            return Stack(
              children: [
                Scaffold(
                  body: navigationShell,
                  extendBody: true,
                  floatingActionButton: FloatingActionButton(
                    key: aiHubFabKey,
                    heroTag: 'main_fab',
                    onPressed: () => _onTap(2, ref, tutorialSteps),
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
                        _buildNavItem(context, icon: Icons.dashboard_rounded, label: 'Panel', index: 0, key: null, ref: ref, steps: tutorialSteps),
                        _buildNavItem(context, icon: Icons.school_rounded, label: 'Koç', index: 1, key: coachKey, ref: ref, steps: tutorialSteps),
                        const SizedBox(width: 56),
                        _buildNavItem(context, icon: Icons.military_tech_rounded, label: 'Arena', index: 3, key: arenaKey, ref: ref, steps: tutorialSteps),
                        _buildNavItem(context, icon: Icons.person_rounded, label: 'Profil', index: 4, key: profileKey, ref: ref, steps: tutorialSteps),
                      ],
                    ),
                  ),
                ),
                if (shouldShowTutorial)
                  TutorialOverlay(steps: tutorialSteps),
              ],
            );
          }
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index, required GlobalKey? key, required WidgetRef ref, required List<TutorialStep> steps}) {
    final isSelected = navigationShell.currentIndex == index;
    return IconButton(
      key: key,
      icon: Icon(icon, color: isSelected ? AppTheme.secondaryColor : AppTheme.secondaryTextColor, size: 28),
      onPressed: () => _onTap(index, ref, steps),
      tooltip: label,
      splashColor: AppTheme.secondaryColor.withOpacity(0.2),
      highlightColor: AppTheme.secondaryColor.withOpacity(0.1),
    );
  }

  void _onTap(int index, WidgetRef ref, List<TutorialStep> tutorialSteps) {
    final tutorialNotifier = ref.read(tutorialProvider.notifier);
    final currentStepIndex = ref.read(tutorialProvider);

    if (currentStepIndex != null) {
      if (currentStepIndex >= tutorialSteps.length) return; // Güvenlik kontrolü
      final step = tutorialSteps[currentStepIndex];
      if (step.isNavigational) {
        if ( (currentStepIndex == 3 && index == 1) ||
            (currentStepIndex == 5 && index == 3) ||
            (currentStepIndex == 6 && index == 4) ) {
          tutorialNotifier.next();
        }
      }
      return;
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}