// lib/features/onboarding/providers/tutorial_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorialNotifier extends StateNotifier<int?> {
  final int totalSteps;
  final StatefulNavigationShell? navigationShell;

  TutorialNotifier(this.totalSteps, this.navigationShell) : super(null); // Başlangıçta null (kapalı)

  void start() {
    state = 0; // Öğreticiyi ilk adımdan başlat
  }

  void next() {
    if (state != null) {
      // Özel adımlar için navigasyon mantığı
      // Adım 3'ten sonra Koç sekmesine git
      if (state == 3) {
        navigationShell?.goBranch(2); // AI Hub/Koç sekmesinin index'i 2
      }

      if (state! < totalSteps - 1) {
        state = state! + 1;
      } else {
        finish();
      }
    }
  }

  void finish() {
    // Tur bitince ana ekrana (index 0) dön
    if(navigationShell?.currentIndex != 0){
      navigationShell?.goBranch(0);
    }
    state = null; // Öğreticiyi bitir ve kapat
  }
}

// Bu provider, öğreticiyi yöneten ana beyin olacak.
// Onu kullanacağımız yerde (ScaffoldWithNavBar) yeniden yapılandıracağız.
final tutorialProvider = StateNotifierProvider<TutorialNotifier, int?>((ref) {
  // Bu hatayı görmek, provider'ı override etmeyi unuttuğumuz anlamına gelir.
  throw UnimplementedError('tutorialProvider must be overridden');
});