// lib/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/auth/screens/login_screen.dart';
import 'package:bilge_ai/features/auth/screens/register_screen.dart';
import 'package:bilge_ai/features/coach/screens/coach_screen.dart';
import 'package:bilge_ai/features/coach/screens/update_topic_performance_screen.dart';
import 'package:bilge_ai/features/home/screens/test_detail_screen.dart';
import 'package:bilge_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:bilge_ai/features/home/screens/dashboard_screen.dart';
import 'package:bilge_ai/features/profile/screens/profile_screen.dart';
import 'package:bilge_ai/shared/widgets/loading_screen.dart';
import 'package:bilge_ai/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:bilge_ai/features/home/screens/add_test_screen.dart';
import 'package:bilge_ai/features/onboarding/screens/exam_selection_screen.dart';
import 'package:bilge_ai/features/onboarding/screens/availability_screen.dart';
import 'package:bilge_ai/features/arena/screens/arena_screen.dart';
import 'package:bilge_ai/features/pomodoro/pomodoro_screen.dart';
import 'package:bilge_ai/features/coach/screens/ai_hub_screen.dart';
import 'package:bilge_ai/features/coach/screens/motivation_chat_screen.dart';
import 'package:bilge_ai/features/weakness_workshop/screens/weakness_workshop_screen.dart';
import 'package:bilge_ai/features/strategic_planning/screens/strategic_planning_screen.dart';
import 'package:bilge_ai/features/home/screens/test_result_summary_screen.dart';
import 'package:bilge_ai/features/home/screens/library_screen.dart';
import 'package:bilge_ai/features/strategic_planning/screens/command_center_screen.dart';
import 'package:bilge_ai/features/stats/screens/stats_screen.dart';
import 'app_routes.dart'; // YENİ IMPORT

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  final listenable = ValueNotifier<bool>(false);
  ref.listen(authControllerProvider, (_, __) => listenable.value = !listenable.value);
  ref.listen(userProfileProvider, (_, __) => listenable.value = !listenable.value);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.loading,
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final userProfileState = ref.read(userProfileProvider);
      final location = state.matchedLocation;

      final isLoading = authState.isLoading || (authState.hasValue && userProfileState.isLoading);
      if (isLoading) {
        return AppRoutes.loading;
      }

      final isLoggedIn = authState.hasValue && authState.value != null;
      final onAuthScreen = location == AppRoutes.login || location == AppRoutes.register;

      if (!isLoggedIn) {
        return onAuthScreen ? null : AppRoutes.login;
      }

      if (userProfileState.hasError) {
        return AppRoutes.login;
      }

      if (userProfileState.hasValue) {
        final user = userProfileState.value!;

        if (!user.onboardingCompleted) {
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }
        if (user.selectedExam == null || user.selectedExam!.isEmpty) {
          return location == AppRoutes.examSelection ? null : AppRoutes.examSelection;
        }
        if (user.weeklyAvailability.isEmpty) {
          return location == AppRoutes.availability ? null : AppRoutes.availability;
        }

        final onInitialSetupScreen = location == AppRoutes.onboarding || location == AppRoutes.examSelection;
        if (onAuthScreen || onInitialSetupScreen || location == AppRoutes.loading) {
          return AppRoutes.home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.loading, builder: (c, s) => const LoadingScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.examSelection, builder: (c, s) => const ExamSelectionScreen()),
      GoRoute(path: AppRoutes.availability, parentNavigatorKey: rootNavigatorKey, builder: (c, s) => const AvailabilityScreen()),
      GoRoute(path: AppRoutes.library, parentNavigatorKey: rootNavigatorKey, builder: (c, s) => const LibraryScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(path: AppRoutes.addTest, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const AddTestScreen()),
                  GoRoute(path: AppRoutes.testDetail, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => TestDetailScreen(test: state.extra as TestModel)),
                  GoRoute(path: AppRoutes.testResultSummary, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => TestResultSummaryScreen(test: state.extra as TestModel)),
                  GoRoute(path: AppRoutes.pomodoro, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const PomodoroScreen()),
                  GoRoute(path: AppRoutes.stats, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const StatsScreen()),
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.coach,
                builder: (context, state) => const CoachScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.updateTopicPerformance,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return UpdateTopicPerformanceScreen(
                        subject: args['subject'] as String,
                        topic: args['topic'] as String,
                        initialPerformance: args['performance'] as TopicPerformanceModel,
                      );
                    },
                  ),
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.aiHub,
                builder: (context, state) => const AiHubScreen(),
                routes: [
                  GoRoute(path: AppRoutes.strategicPlanning, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const StrategicPlanningScreen()),
                  GoRoute(path: AppRoutes.commandCenter, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => CommandCenterScreen(user: state.extra as UserModel)),
                  GoRoute(path: AppRoutes.weaknessWorkshop, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const WeaknessWorkshopScreen()),
                  GoRoute(path: AppRoutes.motivationChat, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const MotivationChatScreen()),
                ]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.arena, builder: (context, state) => const ArenaScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});