// lib/core/navigation/app_router.dart
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/auth/screens/login_screen.dart';
import 'package:bilge_ai/features/auth/screens/register_screen.dart';
import 'package:bilge_ai/features/coach/screens/coach_screen.dart';
import 'package:bilge_ai/features/coach/screens/subject_detail_screen.dart';
import 'package:bilge_ai/features/home/screens/test_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/home/screens/dashboard_screen.dart';
import 'package:bilge_ai/features/stats/screens/stats_screen.dart';
import 'package:bilge_ai/features/profile/screens/profile_screen.dart';
import 'package:bilge_ai/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:bilge_ai/features/home/screens/add_test_screen.dart';
// DÜZELTİLEN YERLER: Yeni ekranların importları
import 'package:bilge_ai/features/onboarding/screens/exam_selection_screen.dart';
import 'package:bilge_ai/features/journal/screens/journal_screen.dart';
import 'package:bilge_ai/features/arena/screens/arena_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final userProfileAsync = ref.watch(userProfileProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authState.value != null;
      final bool onAuthScreens = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn) {
        return onAuthScreens ? null : '/login';
      }

      if (userProfileAsync.isLoading || userProfileAsync.hasError) {
        return null; // Yüklenirken bekle
      }

      final userModel = userProfileAsync.value;
      if (userModel == null) {
        return '/login'; // Kullanıcı modeli yoksa login'e at
      }

      final bool onboardingCompleted = userModel.onboardingCompleted;
      final bool onOnboardingScreen = state.matchedLocation == '/onboarding';

      // Gerçek bir uygulamada sınav seçimi veritabanından okunmalı, şimdilik provider'dan okuyoruz.
      final bool examSelected = ref.watch(selectedExamProvider) != null;

      if (!onboardingCompleted) {
        return onOnboardingScreen ? null : '/onboarding';
      }

      // Onboarding tamamlandı ama sınav seçilmediyse
      if (onboardingCompleted && !examSelected && state.matchedLocation != '/exam-selection') {
        return '/exam-selection';
      }

      // Her şey tamamsa ve hala eski sayfalardaysa ana sayfaya yönlendir
      if (examSelected && (onAuthScreens || onOnboardingScreen || state.matchedLocation == '/exam-selection')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/exam-selection', builder: (c, s) => const ExamSelectionScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Ana Panel
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'add-test',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AddTestScreen(),
                  ),
                  GoRoute(
                    path: 'test-detail',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final test = state.extra as TestModel;
                      return TestDetailScreen(test: test);
                    },
                  ),
                  GoRoute(
                    path: 'journal',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const JournalScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Akıllı Koç
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/coach',
                  builder: (context, state) => const CoachScreen(),
                  routes: [
                    GoRoute(
                      path: 'subject-detail',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final subject = state.extra as String;
                        return SubjectDetailScreen(subject: subject);
                      },
                    ),
                  ]
              ),
            ],
          ),
          // Savaşçılar Arenası
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/arena',
                builder: (context, state) => const ArenaScreen(),
              ),
            ],
          ),
          // İstatistikler
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          // Profil
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