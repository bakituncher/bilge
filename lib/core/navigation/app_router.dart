// lib/core/navigation/app_router.dart

import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/features/auth/screens/login_screen.dart'; // Bunu oluşturman gerekiyor
import 'package:bilge_ai/features/auth/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


// Geçici Ana Ekran
// Geçici Ana Ekran
class HomeScreen extends ConsumerWidget { // StatelessWidget'ı ConsumerWidget'a çevir
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) { // Artık bu doğru
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Sayfa')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: const Text('Çıkış Yap'),
        ),
      ),
    );
  }
}


final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true, // Konsolda yönlendirme bilgilerini gösterir
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authState.value != null;
      final bool onAuthScreens = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Eğer kullanıcı giriş yapmamışsa ve auth ekranlarında değilse, login'e yönlendir.
      if (!loggedIn) {
        return onAuthScreens ? null : '/login';
      }

      // Eğer kullanıcı giriş yapmışsa ve auth ekranlarındaysa, ana sayfaya yönlendir.
      if (loggedIn && onAuthScreens) {
        return '/home';
      }

      // Diğer durumlarda yönlendirme yapma.
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(), // Bu ekranı oluşturmalısın!
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(), // Bu geçici bir ana ekran
      ),
    ],
  );
});