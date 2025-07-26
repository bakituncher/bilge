// lib/main.dart

import 'package:bilge_ai/core/navigation/app_router.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- YENİ İMPORT
import 'firebase_options.dart';

void main() async {
  // Flutter uygulamasının başlamadan önce diğer servislerin (Firebase gibi)
  // hazır olduğundan emin oluyoruz.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i `firebase_options.dart` dosyasındaki ayarlarla başlatıyoruz.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // YENİ EKLENDİ: intl paketini Türkçe yerelleştirmesi için başlatıyoruz.
  await initializeDateFormatting('tr_TR', null);

  // Uygulamayı ProviderScope ile sarmalayarak Riverpod'ı aktif ediyoruz.
  runApp(const ProviderScope(child: BilgeAiApp()));
}

// BilgeAiApp class'ı aynı kalacak...
class BilgeAiApp extends ConsumerWidget {
  const BilgeAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'BilgeAi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}