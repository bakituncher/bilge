// lib/main.dart
//Rahman ve Rahim olan Allah'ın adıyla
//Bismilahirrahmanirrahim
import 'package:bilge_ai/core/navigation/app_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('tr_TR', null);
  runApp(const ProviderScope(child: BilgeAiApp()));
}

class BilgeAiApp extends ConsumerWidget {
  const BilgeAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'BilgeAi',
      debugShowCheckedModeBanner: false,
      // BİLGEAI DEVRİMİ: Artık daha rafine bir tema kullanılıyor.
      theme: AppTheme.modernTheme,
      darkTheme: AppTheme.modernTheme, // Şimdilik tek ve güçlü bir tema
      themeMode: ThemeMode.dark, // Uygulama varsayılan olarak modern koyu temada başlar
      routerConfig: router,
    );
  }
}