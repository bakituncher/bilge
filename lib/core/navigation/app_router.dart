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
import 'package:bilge_ai/features/coach/screens/ai_hub_screen.dart';
import 'package:bilge_ai/features/coach/screens/motivation_chat_screen.dart';
// BİLGEAI DEVRİMİ - DÜZELTME: Eksik olan ve hataya sebep olan import eklendi.
import 'package:bilge_ai/features/weakness_workshop/screens/weakness_workshop_screen.dart';
import 'package:bilge_ai/features/strategic_planning/screens/strategic_planning_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  final listenable = ValueNotifier<bool>(false);
  ref.listen(authControllerProvider, (_, __) => listenable.value = !listenable.value);
  ref.listen(userProfileProvider, (_, __) => listenable.value = !listenable.value);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final userProfileState = ref.read(userProfileProvider);

      final bool loggedIn = authState.value != null;
      final String location = state.matchedLocation;

      if (!loggedIn) {
        return location == '/login' || location == '/register' ? null : '/login';
      }

      if (userProfileState.isLoading) {
        return null; // Yüklenirken bekle
      }

      if(userProfileState.hasValue && userProfileState.value != null) {
        final user = userProfileState.value!;
        final onboardingCompleted = user.onboardingCompleted;
        final examSelected = user.selectedExam != null && user.selectedExam!.isNotEmpty;

        if (!onboardingCompleted) {
          return location == '/onboarding' ? null : '/onboarding';
        }
        if (!examSelected) {
          return location == '/exam-selection' ? null : '/exam-selection';
        }

        if (location == '/login' || location == '/register' || location == '/onboarding' || location == '/exam-selection') {
          return '/home';
        }
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
                  GoRoute(path: 'strategic-planning', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const StrategicPlanningScreen()),
                  GoRoute(path: 'weakness-workshop', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const WeaknessWorkshopScreen()),
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