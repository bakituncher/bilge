// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
// BİLGEAI DEVRİMİ - NİHAİ DÜZELTME: 'packagepackage:' yazım hatası düzeltildi.
import 'package:bilge_ai/data/models/user_model.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }
          final tests = testsAsync.valueOrNull ?? [];
          final avgNet = tests.isNotEmpty ? tests.map((t) => t.totalNet).reduce((a, b) => a + b) / tests.length : 0.0;
          final testCount = tests.length;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.lightSurfaceColor,
                        child: Text(
                          user.name?.substring(0, 1).toUpperCase() ?? 'B',
                          style: textTheme.displayMedium?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name ?? 'İsimsiz Kullanıcı', style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(user.email, style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                      const SizedBox(height: 24),
                      const Divider(color: AppTheme.lightSurfaceColor),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Deneme', testCount.toString(), Icons.bar_chart_rounded, context),
                          _buildStatColumn('Ort. Net', avgNet.toStringAsFixed(2), Icons.track_changes_rounded, context),
                          _buildStatColumn('Seri', '${user.streak} Gün', Icons.local_fire_department_rounded, context),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              Text("Kazanılan Rozetler", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildBadgesSection(user),

              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppTheme.secondaryTextColor),
                title: const Text('Hedefin'),
                subtitle: Text(user.goal ?? 'Henüz bir hedef belirtilmemiş.', style: const TextStyle(color: Colors.white)),
              ),
              const Divider(color: AppTheme.lightSurfaceColor),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: AppTheme.secondaryTextColor),
                title: const Text('Haftalık Çalışma Hedefi'),
                subtitle: Text('${user.weeklyStudyGoal?.toStringAsFixed(1) ?? '0'} Saat', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryTextColor, size: 28),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
      ],
    );
  }

  Widget _buildBadgesSection(UserModel user) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        if (user.streak >= 7) _buildBadge('7 Günlük Seri', Icons.local_fire_department, Colors.orange).animate().fadeIn(delay: 200.ms),
        if (user.testCount >= 1) _buildBadge('İlk Adım', Icons.flag, Colors.green).animate().fadeIn(delay: 300.ms),
        _buildBadge('Çok Yakında', Icons.lock_outline, Colors.grey, isLocked: true).animate().fadeIn(delay: 400.ms),
        _buildBadge('Çok Yakında', Icons.lock_outline, Colors.grey, isLocked: true).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color, {bool isLocked = false}) {
    return Tooltip(
      message: label,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
              color: isLocked ? AppTheme.cardColor : color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLocked ? AppTheme.lightSurfaceColor : color, width: 1.5)
          ),
          child: Icon(icon, color: isLocked ? AppTheme.lightSurfaceColor : color, size: 32),
        ),
      ),
    );
  }
}