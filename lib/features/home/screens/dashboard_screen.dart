// lib/features/home/screens/dashboard_screen.dart
// Gerekli importlar (temizlenmiş)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/features/home/widgets/todays_plan.dart';
import 'package:bilge_ai/features/onboarding/providers/tutorial_provider.dart';
import 'package:bilge_ai/features/home/widgets/hero_header.dart';
import 'package:bilge_ai/features/home/widgets/performance_cluster.dart';
import 'package:bilge_ai/features/home/widgets/adaptive_action_center.dart';
import 'package:bilge_ai/features/home/widgets/resume_cta.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/shared/constants/highlight_keys.dart';
import 'package:bilge_ai/features/home/providers/home_providers.dart';

// Widget'ları vurgulamak için GlobalKey'ler artik highlight_keys.dart'tan geliyor, burada TANIM YOK.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    // Ekran yüklendiğinde öğreticiyi kontrol et ve başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider).value;
      if (user != null && !user.tutorialCompleted) {
        ref.read(tutorialProvider.notifier).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final testsAsync = ref.watch(testsProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Kullanıcı verisi yüklenemedi.'));
        }
        final tests = testsAsync.valueOrNull ?? [];
        // rankInfo (unvan) artık ekran üstünde HeroHeader içinde hesaplanıyor, burada gerek yok.

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(child: HeroHeader()),
              ),
              // DEVAM ET (RESUME) BÖLÜMÜ
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: const SliverToBoxAdapter(child: ResumeCta()),
              ),
              // HIZLI EYLEMLER ÜSTE TAŞINDI
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(child: Container(key: addTestKey, child: const AdaptiveActionCenter())),
              ),
              // GÜNÜN PLANI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(key: todaysPlanKey, child: const TodaysPlan()),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              // GÜNLÜK GÖREVLER
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _DailyQuestsCard()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // PERFORMANS KÜMESİ (YENİ TASARIM DOSYASI AYNI İSİM)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: PerformanceCluster(tests: tests, user: user)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 64)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
      error: (e, s) => Center(child: Text('Bir hata oluştu: $e')),
    );
  }
}

// --- YENİ WIDGET: GÜNLÜK GÖREVLER KARTI ---
class _DailyQuestsCard extends ConsumerWidget {
  _DailyQuestsCard();

  static final Set<String> _celebratedDates = {};

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}dk';
    return '${h}sa ${m}dk';
  }

  Color _progressColor(double p) {
    if (p >= .999) return Colors.greenAccent;
    if (p >= .85) return Colors.greenAccent.withValues(alpha: .9);
    if (p >= .5) return AppTheme.secondaryColor;
    return AppTheme.lightSurfaceColor.withValues(alpha: .9);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null) return const SizedBox.shrink();

    final questProg = ref.watch(dailyQuestsProgressProvider);
    final total = questProg.total;
    final completed = questProg.completed;
    final progress = questProg.progress;
    final remaining = questProg.remaining;

    // Günlük tamamlanma kutlaması (günde bir kez)
    if (progress >= 1.0) {
      final todayKey = DateTime.now().toIso8601String().substring(0,10);
      if (!_celebratedDates.contains(todayKey)) {
        _celebratedDates.add(todayKey);
        WidgetsBinding.instance.addPostFrameCallback((_){
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.celebration_rounded, color: Colors.greenAccent),
                    SizedBox(width: 8),
                    Expanded(child: Text('Tüm günlük fetihler tamamlandı! 🔥')),
                  ],
                ),
              ),
            );
          }
        });
      }
    }

    final showShimmer = progress < 1.0;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _progressColor(progress), width: 2),
      ),
      child: InkWell(
        onTap: () => context.go('/home/quests'),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _progressColor(progress).withValues(alpha: 0.18),
                AppTheme.cardColor.withValues(alpha: 0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      value: progress == 0 ? null : progress,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.lightSurfaceColor.withValues(alpha: .25),
                      valueColor: AlwaysStoppedAnimation(_progressColor(progress)),
                    ),
                  ),
                  Icon(progress >=1 ? Icons.emoji_events_rounded : Icons.shield_moon_rounded, size: 28, color: _progressColor(progress)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress >=1 ? "Zafer!" : "Günlük Fetihler",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0 ? 'Bugün görev yok' : '$completed / $total tamamlandı • Kalan ${_formatRemaining(remaining)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0,1),
                        minHeight: 6,
                        backgroundColor: AppTheme.lightSurfaceColor.withValues(alpha: .25),
                        valueColor: AlwaysStoppedAnimation(_progressColor(progress)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondaryTextColor, size: 18),
            ],
          ),
        ),
      ),
    );

    if (!showShimmer) return card;

    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [
        ShimmerEffect(
          duration: 2500.ms,
          color: AppTheme.secondaryColor.withValues(alpha: 0.35),
        ),
      ],
      child: card,
    );
  }
}
// ------------------------------------------
