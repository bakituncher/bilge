// lib/core/navigation/app_router.dart

import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/auth/screens/login_screen.dart';
import 'package:bilge_ai/features/auth/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';

// Yeni ekranları ve ScaffoldWithNavBar'ı import et
import 'package:bilge_ai/features/home/screens/dashboard_screen.dart';
import 'package:bilge_ai/features/stats/screens/stats_screen.dart';
import 'package:bilge_ai/features/profile/screens/profile_screen.dart';
import 'package:bilge_ai/shared/widgets/scaffold_with_nav_bar.dart';


final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authState.value != null;
      final bool onAuthScreens = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Kullanıcı giriş yapmamışsa, login ekranına yönlendir.
      if (!loggedIn) {
        return onAuthScreens ? null : '/login';
      }

      // Kullanıcı giriş yapmışsa, profil verisini kontrol et.
      // Profil verisi yüklenirken veya hata alırken bir şey yapma, bekle.
      if (userProfileAsync.isLoading || userProfileAsync.hasError) {
        return null;
      }

      final userModel = userProfileAsync.value;
      if (userModel == null) {
        // Bu durum normalde yaşanmamalı ama güvenlik için login'e at.
        return '/login';
      }

      final bool onboardingCompleted = userModel.onboardingCompleted;
      final bool onOnboardingScreen = state.matchedLocation == '/onboarding';

      if (!onboardingCompleted) {
        // Onboarding tamamlanmamışsa, onboarding ekranına zorla.
        return onOnboardingScreen ? null : '/onboarding';
      }

      // Onboarding tamamlanmışsa ve auth/onboarding ekranlarındaysa, ana sayfaya at.
      if (onboardingCompleted && (onAuthScreens || onOnboardingScreen)) {
        return '/home';
      }

      return null; // Diğer durumlarda yönlendirme yapma.
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),

      // YENİ YAPI: Ana uygulama iskeleti (sekme navigasyonu)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Bu builder, navigasyon çubuğunu içeren ana iskeleti döner.
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 1. Dal (Ana Panel Sekmesi)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home', // Uygulama açıldığında ilk bu görünecek
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // 2. Dal (İstatistikler Sekmesi)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          // 3. Dal (Profil Sekmesi)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// GoRouterRefreshStream class'ı artık gerekli değil ve kaldırıldı.