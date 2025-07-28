// lib/core/navigation/app_router.dart
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/journal_entry_model.dart';
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
import 'package:bilge_ai/features/profile/screens/profile_screen.dart';
import 'package:bilge_ai/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:bilge_ai/features/home/screens/add_test_screen.dart';
import 'package:bilge_ai/features/onboarding/screens/exam_selection_screen.dart';
import 'package:bilge_ai/features/journal/screens/journal_screen.dart';
import 'package:bilge_ai/features/journal/screens/add_edit_journal_screen.dart';
import 'package:bilge_ai/features/arena/screens/arena_screen.dart';
import 'package:bilge_ai/features/pomodoro/pomodoro_screen.dart';
import 'package:bilge_ai/features/coach/screens/ai_coach_screen.dart';
import 'package:bilge_ai/features/coach/screens/motivation_chat_screen.dart';
import 'package:bilge_ai/features/coach/screens/ai_hub_screen.dart';

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
      final bool onAuthScreens = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!loggedIn) {
        return onAuthScreens ? null : '/login';
      }

      // Kullanıcı profili yüklenirken veya hata oluştuğunda bekle
      if (userProfileAsync.isLoading || userProfileAsync.hasError) {
        return null; // Yükleme ekranı veya hata ekranı gösterilebilir
      }

      final userModel = userProfileAsync.value;
      if (userModel == null) {
        return '/login'; // Kullanıcı modeli yoksa login'e yolla
      }

      final bool onboardingCompleted = userModel.onboardingCompleted;
      final bool onOnboardingScreen = state.matchedLocation == '/onboarding';
      final bool onExamSelectionScreen = state.matchedLocation == '/exam-selection';

      // Onboarding tamamlanmadıysa Onboarding ekranına yönlendir
      if (!onboardingCompleted) {
        return onOnboardingScreen ? null : '/onboarding';
      }

      // HATA DÜZELTİLDİ: Sınav seçimi, geçici state yerine Firestore'daki kullanıcı profilinden kontrol ediliyor.
      final bool examSelected = userModel.selectedExam != null && userModel.selectedExam!.isNotEmpty;

      // Onboarding tamamlandı ama sınav seçilmediyse Sınav Seçim ekranına yönlendir
      if (onboardingCompleted && !examSelected && !onExamSelectionScreen) {
        return '/exam-selection';
      }

      // Kullanıcı oturum açmış, onboarding'i tamamlamış ve sınavını seçmişse
      // artık login/register/onboarding/exam-selection ekranlarına gitmesini engelle
      if (loggedIn && examSelected && (onAuthScreens || onOnboardingScreen || onExamSelectionScreen)) {
        return '/home';
      }

      return null; // Başka bir yönlendirme gerekmiyorsa null döndür
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
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(path: 'add-test', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const AddTestScreen()),
                  GoRoute(
                      path: 'test-detail',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final test = state.extra as TestModel;
                        return TestDetailScreen(test: test);
                      }),
                  GoRoute(path: 'pomodoro', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const PomodoroScreen()),
                  GoRoute(
                      path: 'journal',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const JournalScreen(),
                      routes: [
                        GoRoute(path: 'add', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const AddEditJournalScreen()),
                        GoRoute(
                            path: 'edit',
                            parentNavigatorKey: rootNavigatorKey,
                            builder: (context, state) {
                              final entry = state.extra as JournalEntry;
                              return AddEditJournalScreen(entry: entry);
                            }),
                      ]),
                ]),
          ]),
          StatefulShellBranch(routes: [
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
                      }),
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/ai-hub',
                builder: (context, state) => const AiHubScreen(),
                routes: [
                  GoRoute(path: 'ai-coach', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const AiCoachScreen()),
                  GoRoute(path: 'motivation-chat', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const MotivationChatScreen()),
                ]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/arena', builder: (context, state) => const ArenaScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});