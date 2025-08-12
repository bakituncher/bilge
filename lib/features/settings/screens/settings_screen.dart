// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/features/settings/widgets/settings_section.dart';
import 'package:bilge_ai/features/settings/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text("Çıkış Yap"),
          content: const Text("Oturumu sonlandırmak istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Çıkış Yap", style: TextStyle(color: AppTheme.accentColor)),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsSection(title: "Hesap"),
          SettingsTile(
            icon: Icons.person_outline_rounded,
            title: "İsim",
            subtitle: user.name ?? "Belirtilmemiş",
            onTap: () {
              // İsim değiştirme fonksiyonu eklenebilir.
            },
          ),
          SettingsTile(
            icon: Icons.alternate_email_rounded,
            title: "E-posta",
            subtitle: user.email,
          ),
          SettingsTile(
            icon: Icons.shield_outlined,
            title: "Şifreyi Değiştir",
            subtitle: "Güvenliğiniz için şifrenizi güncelleyin",
            onTap: () {
              // Şifre değiştirme ekranı eklenebilir.
            },
          ),
          const SettingsSection(title: "Sınav ve Planlama"),
          SettingsTile(
            icon: Icons.school_outlined,
            title: "Sınavı Değiştir",
            subtitle: "Hazırlandığınız sınavı veya alanı güncelleyin",
            onTap: () => context.push(AppRoutes.examSelection),
          ),
          SettingsTile(
            icon: Icons.edit_calendar_outlined,
            title: "Zaman Haritası",
            subtitle: "Haftalık çalışma takviminizi düzenleyin",
            onTap: () => context.push(AppRoutes.availability),
          ),
          const SettingsSection(title: "Uygulama"),
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: "Bildirimler",
            subtitle: "Anımsatıcıları ve uyarıları yönetin",
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            title: "Uygulama Hakkında",
            subtitle: "Versiyon 1.0.0",
            onTap: () {},
          ),
          const SettingsSection(title: "Oturum"),
          SettingsTile(
            icon: Icons.logout_rounded,
            title: "Çıkış Yap",
            subtitle: "Hesabınızdan güvenle çıkış yapın",
            iconColor: AppTheme.accentColor,
            textColor: AppTheme.accentColor,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }
}