// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/core/navigation/app_routes.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/auth/application/auth_controller.dart';
import 'package:bilge_ai/features/settings/logic/settings_notifier.dart';
import 'package:bilge_ai/features/settings/widgets/settings_section.dart';
import 'package:bilge_ai/features/settings/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // ONAY AKIŞINI YÖNETEN FONKSİYONLAR

  void _showExamChangeFlow(BuildContext context, WidgetRef ref) {
    // 1. Onay Diyaloğu
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentColor),
            SizedBox(width: 10),
            Text("Çok Önemli Uyarı"),
          ],
        ),
        content: const Text(
            "Sınav türünü değiştirmek, mevcut ilerlemenizi tamamen sıfırlayacaktır.\n\n"
                "• Tüm deneme sonuçlarınız\n"
                "• Haftalık planlarınız ve stratejileriniz\n"
                "• Konu analizleriniz ve istatistikleriniz\n\n"
                "kalıcı olarak silinecektir. Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("İptal Et"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            onPressed: () {
              Navigator.of(context).pop();
              _showFinalConfirmationDialog(context, ref); // 2. Onay Diyaloğuna geç
            },
            child: const Text("Anladım, Devam Et"),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmationDialog(BuildContext context, WidgetRef ref) {
    final confirmationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    const confirmationText = "SİL";

    showDialog(
      context: context,
      barrierDismissible: false, // İşlem sırasında kapatılmasını engelle
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text("Son Onay"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Bu son adımdır. Devam etmek için lütfen aşağıdaki alana büyük harflerle 'SİL' yazın."),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: confirmationController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Onay Metni",
                        hintText: confirmationText,
                      ),
                      onChanged: (value) => setState(() {}), // Buton durumunu güncellemek için
                      validator: (value) {
                        if (value != confirmationText) {
                          return "Lütfen 'SİL' yazın.";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Vazgeç"),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final isLoading = ref.watch(settingsNotifierProvider).isLoading;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                      onPressed: (confirmationController.text == confirmationText && !isLoading)
                          ? () {
                        if (formKey.currentState!.validate()) {
                          // SADECE İŞLEMİ TETİKLE VE DİYALOĞU KAPAT.
                          // NAVİGASYON YAPMA! GoRouter halledecek.
                          Navigator.of(dialogContext).pop();
                          ref.read(settingsNotifierProvider.notifier).resetAccountForNewExam();
                        }
                      }
                          : null, // Butonu pasif yap
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Tüm Verileri Sil ve Değiştir"),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // İsim değiştirme diyalogunu gösteren fonksiyon
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
    // TODO: URL açma işlevi eklenecek
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bağlantı açılamadı: $url')),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    // TODO: E-posta açma işlevi eklenecek
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-posta uygulaması bulunamadı.')),
    );
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
    // Sadece hata durumunda kullanıcıya mesaj göstermek için dinle
    ref.listen<SettingsState>(settingsNotifierProvider, (previous, next) {
      if (next.resetStatus == ResetStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veriler sıfırlanırken bir hata oluştu. Lütfen tekrar deneyin."),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        ref.read(settingsNotifierProvider.notifier).resetOperationStatus();
      }
    });

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
            subtitle: "Tüm ilerlemeniz sıfırlanacak",
            onTap: () => _showExamChangeFlow(context, ref),
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