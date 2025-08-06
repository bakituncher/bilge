// lib/features/profile/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';
import 'package:bilge_ai/data/repositories/firestore_service.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';

// Rozet modelimiz
class Badge {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  Badge({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
  });
}

// Odaklanma Ustası rozeti için bu provider'ı ekliyoruz
final focusSessionsProvider = StreamProvider.autoDispose<List<FocusSessionModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user != null) {
    return FirebaseFirestore.instance
        .collection('focusSessions')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FocusSessionModel.fromSnapshot(doc)).toList());
  }
  return Stream.value([]);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Çıkış yapma onayı
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Çıkış Yap"),
          content: const Text("Oturumu sonlandırmak istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal", style: TextStyle(color: AppTheme.secondaryTextColor)),
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

  String _getWarriorTitle(int testCount, double avgNet) {
    if (testCount < 5) return "Acemi Kâşif";
    if (avgNet > 90 && testCount > 20) return "Efsanevi Komutan";
    if (avgNet > 70) return "Usta Stratejist";
    if (testCount > 15) return "Kıdemli Savaşçı";
    return "Azimli Savaşçı";
  }

  // Kullanıcı verilerine göre rozet listesini oluşturan devrimci fonksiyon
  List<Badge> _generateBadges(UserModel user, int testCount, double avgNet, List<FocusSessionModel> focusSessions) {
    return [
      Badge(name: 'İlk Adım', description: 'İlk denemeni ekle.', icon: Icons.flag, color: Colors.green, isUnlocked: testCount >= 1),
      Badge(name: 'Acemi Savaşçı', description: '5 deneme ekle.', icon: Icons.shield_outlined, color: Colors.green, isUnlocked: testCount >= 5),
      Badge(name: 'Deneyimli Savaşçı', description: '15 deneme ekle.', icon: Icons.shield, color: Colors.green, isUnlocked: testCount >= 15),
      Badge(name: 'Usta Savaşçı', description: '30 deneme ekle.', icon: Icons.military_tech_outlined, color: Colors.green, isUnlocked: testCount >= 30),
      Badge(name: 'Deneme Fatihi', description: '50 deneme ekle.', icon: Icons.military_tech, color: Colors.green, isUnlocked: testCount >= 50),
      Badge(name: 'Kıvılcım', description: '3 günlük seri yakala.', icon: Icons.whatshot_outlined, color: Colors.orange, isUnlocked: user.streak >= 3),
      Badge(name: 'Ateşleyici', description: '7 günlük seri yakala.', icon: Icons.local_fire_department_outlined, color: Colors.orange, isUnlocked: user.streak >= 7),
      Badge(name: 'Alev Ustası', description: '14 günlük seri yakala.', icon: Icons.local_fire_department, color: Colors.orange, isUnlocked: user.streak >= 14),
      Badge(name: 'Durdurulamaz', description: '30 günlük seri yakala.', icon: Icons.wb_sunny, color: Colors.orange, isUnlocked: user.streak >= 30),
      Badge(name: 'Yükseliş', description: '50 Net ortalamasını geç.', icon: Icons.trending_up, color: Colors.blue, isUnlocked: avgNet > 50),
      Badge(name: 'Nişancı', description: '70 Net ortalamasını geç.', icon: Icons.gps_fixed, color: Colors.blue, isUnlocked: avgNet > 70),
      Badge(name: 'Usta Nişancı', description: '90 Net ortalamasını geç.', icon: Icons.gps_not_fixed, color: Colors.blue, isUnlocked: avgNet > 90),
      Badge(name: 'Bilge Nişancı', description: '100 Net ortalamasını geç.', icon: Icons.gps_fixed, color: Colors.blue, isUnlocked: avgNet > 100),
      Badge(name: 'Stratejist', description: 'İlk stratejini oluştur.', icon: Icons.insights, color: AppTheme.successColor, isUnlocked: user.longTermStrategy != null),
      Badge(name: 'Planlayıcı', description: 'Haftalık planındaki 10 görevi tamamla.', icon: Icons.checklist, color: AppTheme.successColor, isUnlocked: (user.completedDailyTasks.values.expand((e) => e).length) >= 10),
      Badge(name: 'Odaklanma Ustası', description: 'İlk Pomodoro seansını tamamla.', icon: Icons.timer, color: AppTheme.successColor, isUnlocked: focusSessions.isNotEmpty),
      Badge(name: 'Kâşif', description: 'İlk zayıf konunu işle.', icon: Icons.construction, color: Colors.purple, isUnlocked: user.topicPerformances.isNotEmpty),
      Badge(name: 'Lider', description: 'Liderlik tablosuna gir.', icon: Icons.leaderboard, color: Colors.purple, isUnlocked: user.engagementScore > 0),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);
    final focusSessionsAsync = ref.watch(focusSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komuta Merkezi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
            tooltip: 'Güvenli Çıkış',
          )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Komutan bulunamadı.'));

          final tests = testsAsync.valueOrNull ?? [];
          final focusSessions = focusSessionsAsync.valueOrNull ?? [];
          final testCount = tests.length;
          final avgNet = testCount > 0 ? user.totalNetSum / testCount : 0.0;
          final badges = _generateBadges(user, testCount, avgNet, focusSessions);
          final unlockedBadges = badges.where((b) => b.isUnlocked).toList();
          final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _WarriorIDCard(user: user, title: _getWarriorTitle(testCount, avgNet)),
              const SizedBox(height: 24),
              _WarStats(testCount: testCount, avgNet: avgNet, streak: user.streak),
              const SizedBox(height: 24),
              _TimeManagementActions(),
              const SizedBox(height: 12),
              _StrategicActions(user: user),
              const SizedBox(height: 32),
              _HonorWall(unlockedBadges: unlockedBadges),
              const SizedBox(height: 24),
              _FutureVictories(lockedBadges: lockedBadges),
              const SizedBox(height: 24),
            ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
        error: (e, s) => Center(child: Text('Karargâh Yüklenemedi: $e')),
      ),
    );
  }
}

// Savaşçı Kimlik Kartı (GÜNCELLENDİ: Bilgelik Puanı eklendi)
class _WarriorIDCard extends StatelessWidget {
  final UserModel user;
  final String title;
  const _WarriorIDCard({required this.user, required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.secondaryColor,
              child: Text(
                user.name?.substring(0, 1).toUpperCase() ?? 'B',
                style: textTheme.displaySmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name ?? 'İsimsiz Savaşçı', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title, style: textTheme.titleMedium?.copyWith(color: AppTheme.secondaryColor, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8), // YENİ EKLENDİ
                  // YENİ WIDGET: Bilgelik Puanı Göstergesi
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${user.engagementScore} Bilgelik Puanı',
                        style: textTheme.titleMedium?.copyWith(color: Colors.amber),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Savaş İstatistikleri
class _WarStats extends StatelessWidget {
  final int testCount;
  final double avgNet;
  final int streak;
  const _WarStats({required this.testCount, required this.avgNet, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: testCount.toString(),
            label: 'Toplam Deneme',
            icon: Icons.library_books_rounded,
            onTap: () => context.go('/library'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: avgNet.toStringAsFixed(2),
            label: 'Ortalama Net',
            icon: Icons.track_changes_rounded,
            onTap: () => context.go('/home/stats'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: streak.toString(),
            label: 'Günlük Seri',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
      ],
    );
  }
}

// İstatistik Kartı Stili
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _StatCard({required this.value, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppTheme.secondaryTextColor),
              const SizedBox(height: 8),
              Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// Zaman Haritası Düzenleme Kartı
class _TimeManagementActions extends StatelessWidget {
  const _TimeManagementActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/availability'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: AppTheme.successColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Zaman Haritanı Düzenle", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Haftalık müsaitlik durumunu güncelle.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

// Stratejik Eylemler Kartı
class _StrategicActions extends StatelessWidget {
  final UserModel user;
  const _StrategicActions({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.secondaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.secondaryColor, width: 1)
      ),
      child: InkWell(
        onTap: () {
          if (user.weeklyAvailability.isEmpty || user.weeklyAvailability.values.every((list) => list.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Lütfen önce "Zaman Haritanı Düzenle" bölümünden müsaitlik durumunuzu belirtin.'),
                backgroundColor: AppTheme.accentColor,
                action: SnackBarAction(
                  label: 'DÜZENLE',
                  textColor: Colors.white,
                  onPressed: () => context.push('/availability'),
                ),
              ),
            );
          } else {
            if(user.longTermStrategy != null && user.weeklyPlan != null) {
              context.push('/ai-hub/command-center', extra: user);
            } else {
              context.push('/ai-hub/strategic-planning');
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Icon(Icons.map_rounded, color: AppTheme.secondaryColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Zafer Planı", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text("Kişisel zafer planını oluştur veya görüntüle.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                    ],
                  )
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

// Şeref Duvarı
class _HonorWall extends StatelessWidget {
  final List<Badge> unlockedBadges;
  const _HonorWall({required this.unlockedBadges});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Şeref Duvarı", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (unlockedBadges.isEmpty)
          const Center(child: Text("Henüz madalya kazanılmadı. Savaşmaya devam et!", style: TextStyle(color: AppTheme.secondaryTextColor))),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: unlockedBadges.map((badge) {
            return Tooltip(
              message: "${badge.name}\n${badge.description}",
              child: Chip(
                avatar: Icon(badge.icon, color: badge.color, size: 18),
                label: Text(badge.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: badge.color.withOpacity(0.2),
                side: BorderSide(color: badge.color),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Gelecek Zaferler
class _FutureVictories extends StatelessWidget {
  final List<Badge> lockedBadges;
  const _FutureVictories({required this.lockedBadges});

  @override
  Widget build(BuildContext context) {
    if (lockedBadges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Gelecek Zaferler", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: lockedBadges.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final badge = lockedBadges[index];
            return Tooltip(
              message: "${badge.name}\n${badge.description}",
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                      color: AppTheme.cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.lightSurfaceColor.withOpacity(0.3), width: 1.5)
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                          badge.icon,
                          color: AppTheme.secondaryTextColor.withOpacity(0.2),
                          size: 30
                      ),
                      Icon(
                          Icons.lock,
                          color: AppTheme.secondaryTextColor.withOpacity(0.8),
                          size: 20
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}