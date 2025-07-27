// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Profil Kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.secondary.withOpacity(0.2),
                        child: Text(
                          user.name?.substring(0, 1).toUpperCase() ?? 'B',
                          style: textTheme.headlineLarge?.copyWith(color: colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name ?? 'İsimsiz Kullanıcı', style: textTheme.headlineSmall),
                      Text(user.email, style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Seri (Streak) Kartı
              Card(
                color: colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, color: colorScheme.secondary, size: 40),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.streak} Günlük Seri',
                            style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Harika gidiyorsun, devam et!',
                            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hedef Kartı
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Hedefin'),
                subtitle: Text(user.goal ?? 'Belirtilmemiş'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.track_changes),
                title: const Text('Haftalık Çalışma Hedefi'),
                subtitle: Text('${user.weeklyStudyGoal?.toStringAsFixed(1) ?? '0'} Saat'),
              ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}