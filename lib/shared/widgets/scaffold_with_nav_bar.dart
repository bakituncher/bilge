// lib/shared/widgets/scaffold_with_nav_bar.dart
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/features/home/screens/dashboard_screen.dart';
import 'package:bilge_ai/features/onboarding/providers/tutorial_provider.dart';
import 'package:bilge_ai/features/onboarding/widgets/tutorial_overlay.dart';
import 'package:bilge_ai/features/onboarding/models/tutorial_step.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  // YENİ: Eğiticinin bu oturumda kontrol edilip edilmediğini tutar.
  bool _isTutorialCheckPerformed = false;

  // KALDIRILDI: Artık initState'e ihtiyacımız yok.
  /*
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider).value;
      if (user != null && !user.tutorialCompleted) {
        ref.read(tutorialProvider.notifier).start();
      }
    });
  }
  */

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // YENİ: Kullanıcı profilini dinleyerek eğiticiyi başlatma mantığı
    ref.listen<AsyncValue<UserModel?>>(userProfileProvider, (previous, next) {
      final user = next.value;
      // Kullanıcı verisi geldiyse, eğiticiyi tamamlamadıysa ve bu oturumda henüz kontrol yapılmadıysa...
      if (user != null && !user.tutorialCompleted && !_isTutorialCheckPerformed) {
        // Eğiticiyi başlat.
        ref.read(tutorialProvider.notifier).start();
        // Kontrolün yapıldığını işaretle ki tekrar başlamasın.
        setState(() {
          _isTutorialCheckPerformed = true;
        });
      }
    });

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

    return ProviderScope(
      overrides: [
        tutorialProvider.overrideWith((ref) => TutorialNotifier(tutorialSteps.length, widget.navigationShell)),
      ],
      child: Consumer(
          builder: (context, ref, child) {
            ref.watch(tutorialProvider);

            return Stack(
              children: [
                Scaffold(
                  body: widget.navigationShell,
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
                        _buildNavItem(context, icon: Icons.school_rounded, label: 'Koç', index: 1, key: coachKey),
                        const SizedBox(width: 56),
                        _buildNavItem(context, icon: Icons.military_tech_rounded, label: 'Arena', index: 3, key: arenaKey),
                        _buildNavItem(context, icon: Icons.person_rounded, label: 'Profil', index: 4, key: profileKey),
                      ],
                    ),
                  ),
                ),
                TutorialOverlay(steps: tutorialSteps),
              ],
            );
          }
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index, required GlobalKey? key}) {
    final isSelected = widget.navigationShell.currentIndex == index;
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