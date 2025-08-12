// lib/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/features/home/screens/library_screen.dart';
import 'package:bilge_ai/features/settings/screens/settings_screen.dart'; // YENİ EKRANI EKLE
import 'package:bilge_ai/shared/widgets/loading_screen.dart';
import 'app_routes.dart';
import 'auth_routes.dart';
import 'onboarding_routes.dart';
import 'main_shell_routes.dart';

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
      GoRoute(
        path: AppRoutes.loading,
        builder: (c, s) => const LoadingScreen(),
      ),
      GoRoute(
          path: AppRoutes.library,
          parentNavigatorKey: rootNavigatorKey,
          builder: (c, s) => const LibraryScreen()
      ),
      // DÜZELTME: Ayarlar rotası artık ana rotalardan biri olarak burada tanımlanıyor.
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (c, s) => const SettingsScreen(),
      ),
      ...authRoutes,
      ...onboardingRoutes(rootNavigatorKey),
      mainShellRoutes(rootNavigatorKey),
    ],
  );
});