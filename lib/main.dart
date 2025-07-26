import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'package:bilge_ai/core/navigation/app_router.dart';

void main() async {
  // Flutter uygulamasının başlamadan önce diğer servislerin (Firebase gibi)
  // hazır olduğundan emin oluyoruz.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i `firebase_options.dart` dosyasındaki ayarlarla başlatıyoruz.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Uygulamayı ProviderScope ile sarmalayarak Riverpod'ı aktif ediyoruz.
  runApp(const ProviderScope(child: BilgeAiApp()));
}

class BilgeAiApp extends ConsumerWidget { // StatelessWidget'ı ConsumerWidget'a çevir
  const BilgeAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // build metoduna WidgetRef ref ekle
    final router = ref.watch(goRouterProvider); // router'ı provider'dan al

    return MaterialApp.router(
      title: 'BilgeAi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router, // MaterialApp yerine routerConfig kullan
    );
  }
}