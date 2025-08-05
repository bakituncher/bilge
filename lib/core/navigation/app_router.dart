// lib/core/navigation/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ... Diğer tüm importlarınız ...
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/auth/screens/login_screen.dart';
import 'package:bilge_ai/features/auth/screens/register_screen.dart';
import 'package:bilge_ai/features/coach/screens/coach_screen.dart';
import 'package:bilge_ai/features/home/screens/test_detail_screen.dart';
import 'package:bilge_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/features/home/screens/dashboard_screen.dart';
import 'package:bilge_ai/features/profile/screens/profile_screen.dart';
import 'package:bilge_ai/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:bilge_ai/features/home/screens/add_test_screen.dart';
import 'package:bilge_ai/features/onboarding/screens/exam_selection_screen.dart';
import 'package:bilge_ai/features/arena/screens/arena_screen.dart';
import 'package:bilge_ai/features/pomodoro/pomodoro_screen.dart';
import 'package:bilge_ai/features/coach/screens/ai_hub_screen.dart';
import 'package:bilge_ai/features/coach/screens/motivation_chat_screen.dart';
import 'package:bilge_ai/features/weakness_workshop/screens/weakness_workshop_screen.dart';
import 'package:bilge_ai/features/strategic_planning/screens/strategic_planning_screen.dart';
import 'package:bilge_ai/features/home/screens/test_result_summary_screen.dart';
import 'package:bilge_ai/features/coach/screens/update_topic_performance_screen.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/features/home/screens/library_screen.dart';
import 'package:bilge_ai/features/strategic_planning/screens/command_center_screen.dart';


// 1. ADIM: GoRouter'ı state değişikliklerinden haberdar edecek bir Notifier oluştur.
class GoRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  // HATA GİDERİLDİ: Değişken tipleri 'ProviderSubscription' olarak düzeltildi.
  late final ProviderSubscription _authSubscription;
  late final ProviderSubscription _userProfileSubscription;

  GoRouterNotifier(this._ref) {
    _authSubscription = _ref.listen<AsyncValue<User?>>(authControllerProvider, (_, __) => notifyListeners());
    _userProfileSubscription = _ref.listen<AsyncValue<UserModel?>>(userProfileProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    // HATA GİDERİLDİ: ProviderSubscription'lar .cancel() ile değil, .close() ile kapatılır.
    _authSubscription.close();
    _userProfileSubscription.close();
    super.dispose();
  }
}

// 2. ADIM: GoRouter Provider'ını bu yeni Notifier'ı kullanacak şekilde güncelle.
final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  final notifier = GoRouterNotifier(ref);
  ref.onDispose(() => notifier.dispose());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final userProfileState = ref.read(userProfileProvider);

      if (authState.isLoading || userProfileState.isLoading) {
        return null;
      }

      final bool loggedIn = authState.valueOrNull != null;
      final user = userProfileState.valueOrNull;
      final location = state.matchedLocation;

      if (!loggedIn) {
        return location == '/login' || location == '/register' ? null : '/login';
      }

      if (user == null) {
        return null;
      }

      if (!user.onboardingCompleted) {
        return location == '/onboarding' ? null : '/onboarding';
      }

      if (user.selectedExam == null || user.selectedExam!.isEmpty) {
        return location == '/exam-selection' ? null : '/exam-selection';
      }

      if (location == '/login' || location == '/register' || location == '/onboarding' || location == '/exam-selection') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/exam-selection', builder: (c, s) => const ExamSelectionScreen()),
      GoRoute(path: '/library', parentNavigatorKey: rootNavigatorKey, builder: (c, s) => const LibraryScreen()),
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
                  GoRoute(
                    path: 'test-result-summary',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final test = state.extra as TestModel;
                      return TestResultSummaryScreen(test: test);
                    },
                  ),
                  GoRoute(path: 'pomodoro', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const PomodoroScreen()),
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/coach',
                builder: (context, state) => const CoachScreen(),
                routes: [
                  GoRoute(
                    path: 'update-topic-performance',
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
                path: '/ai-hub',
                builder: (context, state) => const AiHubScreen(),
                routes: [
                  GoRoute(path: 'strategic-planning', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const StrategicPlanningScreen()),
                  GoRoute(
                    path: 'command-center',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final user = state.extra as UserModel;
                      return CommandCenterScreen(user: user);
                    },
                  ),
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