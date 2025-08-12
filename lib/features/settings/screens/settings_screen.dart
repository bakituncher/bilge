// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/features/settings/logic/settings_notifier.dart'; // YENİ: Notifier import edildi
import 'package:bilge_ai/features/settings/widgets/settings_section.dart';
import 'package:bilge_ai/features/settings/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // YENİ: İsim değiştirme diyalogunu gösteren fonksiyon
  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final settingsState = ref.watch(settingsNotifierProvider);
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text("İsmini Güncelle"),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "Yeni İsim"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "İsim boş bırakılamaz.";
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: settingsState.isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      final success = await ref
                          .read(settingsNotifierProvider.notifier)
                          .updateUserName(nameController.text.trim());
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? "İsmin başarıyla güncellendi!"
                                : "Bir hata oluştu."),
                            backgroundColor: success
                                ? AppTheme.successColor
                                : AppTheme.accentColor,
                          ),
                        );
                      }
                    }
                  },
                  child: settingsState.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Kaydet"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı açılamadı: $url')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=BilgeAI Geri Bildirim',
    );
    if (!await launchUrl(emailUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-posta uygulaması bulunamadı.')),
      );
    }
  }

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
            onTap: () => _showEditNameDialog(context, ref, user.name ?? ""),
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
              // TODO: Şifre değiştirme ekranı eklenecek.
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
            icon: Icons.description_outlined,
            title: "Kullanım Sözleşmesi",
            subtitle: "Hizmet şartlarımızı okuyun",
            onTap: () => _launchURL(context, "https://codenzi.com"),
          ),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: "Gizlilik Politikası",
            subtitle: "Verilerinizi nasıl koruduğumuzu öğrenin",
            onTap: () => _launchURL(context, "https://codenzi.com"),
          ),
          SettingsTile(
            icon: Icons.contact_support_outlined,
            title: "Bize Ulaşın",
            subtitle: "Görüş ve önerileriniz için",
            onTap: () => _launchEmail(context, "info@codenzi.com"),
          ),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            title: "Uygulama Hakkında",
            subtitle: "Versiyon 1.0.0",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BilgeAI',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Codenzi. Tüm hakları saklıdır.',
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Text('BilgeAI, kişisel yapay zeka destekli sınav koçunuzdur.'),
                  )
                ],
              );
            },
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