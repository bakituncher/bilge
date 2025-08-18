// lib/features/quests/screens/quests_screen.dart
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart'; // issue banner provider
import 'package:bilge_ai/features/quests/logic/optimized_quests_provider.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});
  // Yardım içeriği
  static const Map<QuestCategory,String> categoryHelp = {
    QuestCategory.practice: 'Practice: Soru çözme / hız çalışmaları. İlerleme: çözdüğün soru sayısı.',
    QuestCategory.study: 'Study: Konu hakimiyeti / plan görevi tamamlamak. İlerleme: tamamlanan konu veya plan maddesi.',
    QuestCategory.engagement: 'Engagement: Uygulama içi etkileşim (istatistik inceleme, pomodoro vb.).',
    QuestCategory.consistency: 'Consistency: Düzen ve süreklilik (gün içi tekrar ziyaret, seri koruma).',
    QuestCategory.test_submission: 'Test: Deneme ekleme ve sonuç raporlama.',
  };
  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadAsync = ref.watch(dailyQuestsProvider); // sadece ilk yükleme / force refresh durum göstergesi
    final quests = ref.watch(optimizedDailyQuestsProvider);
    final user = ref.watch(userProfileProvider).value;

    // Confetti dinleyici: optimized liste farkı
    ref.listen<List<Quest>>(optimizedDailyQuestsProvider, (previous, next) {
      if (previous == null || previous.isEmpty) return;
      final prevCompleted = previous.where((q)=>q.isCompleted).length;
      final nextCompleted = next.where((q)=>q.isCompleted).length;
      if (nextCompleted > prevCompleted) {
        _confettiController.play();
      }
    });

    final isLoading = loadAsync.isLoading && quests.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fetih Kütüğü"),
        actions: [
          IconButton(
            tooltip: 'Görev Rehberi',
            icon: const Icon(Icons.help_center_outlined),
            onPressed: () => _showHelp(context),
          ),
          IconButton(
            tooltip: 'Görevleri Yenile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: user == null ? null : () async {
              final service = ref.read(questServiceProvider);
              await service.refreshDailyQuestsForUser(user, force: true);
              ref.invalidate(dailyQuestsProvider); // yeni yükleme göstergesi
            },
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
          else if (quests.isEmpty)
            _buildEmptyState(context)
          else
            _buildQuestList(context, quests, user),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppTheme.secondaryColor, AppTheme.successColor, Colors.white],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestList(BuildContext context, List<Quest> quests, user) {
    final issue = ref.watch(questGenerationIssueProvider);
    final weeklyCampaigns = quests.where((q) => q.type == QuestType.weekly).toList();
    final completedQuests = quests.where((q) => q.isCompleted && q.type == QuestType.daily).toList();
    final activeQuests = quests.where((q) => !q.isCompleted && q.type == QuestType.daily).toList();

    final listChild = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _SummaryBar(quests: quests, user: user),
        if (issue) _IssueBanner(onClose: ()=> ref.read(questGenerationIssueProvider.notifier).state = false),
        _buildBannerIfNeeded(context, activeQuests, completedQuests),
        if (weeklyCampaigns.isNotEmpty) ...[
          const _SectionHeader(title: "Haftalık Sefer"),
          ...weeklyCampaigns.map((quest) => QuestCard(quest: quest)),
          const SizedBox(height: 16),
        ],
        if (activeQuests.isNotEmpty) ...[
          const _SectionHeader(title: "Günlük Emirler"),
          ...activeQuests.map((quest) => QuestCard(quest: quest)),
        ],
        if (completedQuests.isNotEmpty) ...[
          _SectionHeader(title: "Fethedilenler (${completedQuests.length})"),
          ...completedQuests.map((quest) => QuestCard(quest: quest)),
        ],
        const SizedBox(height: 24),
      ],
    ).animate() // interval param kaldırıldı
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.15);

    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await ref.read(questServiceProvider).refreshDailyQuestsForUser(user, force: true);
          ref.invalidate(dailyQuestsProvider);
        }
      },
      child: listChild,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_moon_rounded, size: 80, color: AppTheme.secondaryTextColor),
          const SizedBox(height: 16),
          Text('Bugünün Fetihleri Tamamlandı!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Yarın yeni hedeflerle görüşmek üzere, komutanım.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildBannerIfNeeded(BuildContext context, List<Quest> active, List<Quest> completed) {
    if (active.isEmpty) return const SizedBox.shrink();
    // Eğer kullanıcı ilk defa 2+ kategori görüyorsa bilgi banner'ı göster
    final categories = active.map((e) => e.category).toSet();
    if (categories.length < 2) return const SizedBox.shrink();
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Birden fazla kategori açıldı. Her kategori farklı bir gelişim alanını temsil eder. Karttaki kısa ipuçlarını oku ve ilgili ekrana gitmek için dokun.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20, color: AppTheme.secondaryTextColor),
              onPressed: () => _showHelp(context),
              tooltip: 'Kategori Açıklamaları',
            )
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.cardColor,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Görev Rehberi', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      ...QuestsScreen.categoryHelp.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.label_important_outline, size: 18, color: AppTheme.secondaryColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value, style: Theme.of(context).textTheme.bodyMedium)),
                          ],
                        ),
                      )),
                      const Divider(),
                      Text('İlerleme Mantığı', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _helpBullet('Soru / dakika içeren görevler: Hedef sayıya ulaştığında otomatik tamamlanır.'),
                      _helpBullet('Plan görevleri: Haftalık plan ekranında ilgili maddeyi bitir.'),
                      _helpBullet('Deneme görevleri: Deneme ekle ekranından yeni sonuç kaydet.'),
                      _helpBullet('Ziyaret / seri görevleri: Uygulamayı gün içinde tekrar açarak ilerlet.'),
                      _helpBullet('Pomodoro odak görevleri: Odak seansları tamamla.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Anladım'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _helpBullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppTheme.secondaryColor)),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class QuestCard extends StatelessWidget {
  final Quest quest;
  const QuestCard({super.key, required this.quest});

  IconData _getIconForCategory(QuestCategory category) {
    switch (category) {
      case QuestCategory.study: return Icons.book_rounded;
      case QuestCategory.practice: return Icons.edit_note_rounded;
      case QuestCategory.engagement: return Icons.auto_awesome;
      case QuestCategory.consistency: return Icons.event_repeat_rounded;
      case QuestCategory.test_submission: return Icons.add_chart_rounded;
      default: return Icons.shield_moon_rounded; // Beklenmedik durumlara karşı
    }
  }

  List<Widget> _buildPriorityBadges(Quest quest) {
    final List<Widget> chips = [];
    bool isHighValue = quest.reward >= 90 || quest.tags.contains('high_value');
    if (isHighValue) chips.add(_badge('Öncelik', Icons.flash_on, Colors.amber));
    if (quest.tags.contains('weakness')) chips.add(_badge('Zayıf Nokta', Icons.warning_amber, Colors.redAccent));
    if (quest.tags.contains('adaptive')) chips.add(_badge('Adaptif', Icons.auto_fix_high, Colors.lightBlueAccent));
    if (quest.tags.contains('chain')) chips.add(_badge('Zincir', Icons.link, Colors.tealAccent));
    if (quest.tags.contains('retention')) chips.add(_badge('Geri Dönüş', Icons.refresh, Colors.orangeAccent));
    if (quest.tags.contains('focus')) chips.add(_badge('Odak', Icons.center_focus_strong, Colors.cyanAccent));
    return chips;
  }

  Widget _badge(String text, IconData icon, Color color) {
    return Chip(
      label: Text(text),
      avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
      backgroundColor: color.withOpacity(0.85),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildChainSegments(Quest quest) {
    if (!quest.id.startsWith('chain_focus_')) return const SizedBox.shrink();
    final steps = ['chain_focus_1','chain_focus_2','chain_focus_3'];
    int currentIndex = steps.indexOf(quest.id);
    return Padding(
      padding: const EdgeInsets.only(top:6.0),
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i <= currentIndex && quest.isCompleted ? true : i < currentIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: 300.ms,
              margin: EdgeInsets.symmetric(horizontal: i==1?4:2),
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.secondaryColor : AppTheme.lightSurfaceColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final progress = quest.goalValue > 0 ? (quest.currentProgress / quest.goalValue).clamp(0.0, 1.0) : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      color: isCompleted ? AppTheme.cardColor.withOpacity(0.5) : AppTheme.cardColor,
      child: InkWell(
        // Kullanıcıyı görevi tamamlayabileceği ekrana yönlendir.
        onTap: isCompleted ? null : () => context.go(quest.actionRoute),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isCompleted ? AppTheme.successColor.withOpacity(0.2) : AppTheme.secondaryColor.withOpacity(0.2),
                    child: Icon(
                      _getIconForCategory(quest.category),
                      color: isCompleted ? AppTheme.successColor : AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quest.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: isCompleted ? AppTheme.secondaryTextColor : Colors.white)),
                        const SizedBox(height: 4),
                        Text(quest.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ..._buildPriorityBadges(quest),
                  if (quest.id.startsWith('schedule_')) Chip(
                    label: const Text('Plan'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.blueGrey.withOpacity(0.3),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                  Chip(
                    avatar: const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    label: Text('+${quest.reward} BP'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isCompleted)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("${quest.currentProgress} / ${quest.goalValue}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCompleted)
                    Row(
                      children: const [
                        Text("Fethedildi!", style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 20)
                      ],
                    ).animate().fadeIn().scale(delay: 150.ms, curve: Curves.easeOutBack),
                  if (!isCompleted)
                    const Row(
                      children: [
                        Text("Yola Koyul", style: TextStyle(color: AppTheme.secondaryTextColor)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: AppTheme.secondaryTextColor, size: 16),
                      ],
                    )
                ],
              ),
              const SizedBox(height: 4),
              _QuestHintLine(quest: quest),
              _buildChainSegments(quest),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  final VoidCallback onClose;
  const _IssueBanner({required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.accentColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.accentColor),
            const SizedBox(width: 12),
            Expanded(child: Text('Görev üretimi bağlantı sorunları nedeniyle önbellekten gösteriliyor.', style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12))),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18, color: AppTheme.secondaryTextColor))
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends ConsumerWidget {
  final List<Quest> quests; final dynamic user; // user model tipine gerek yok burada
  const _SummaryBar({required this.quests, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = quests.where((q)=>q.type==QuestType.daily).length;
    final done = quests.where((q)=>q.type==QuestType.daily && q.isCompleted).length;
    int focusMinutes = 0; // tahmini: focus kategori completed progress toplamı
    focusMinutes = quests.where((q)=>q.category==QuestCategory.focus).fold(0,(s,q)=> s + q.currentProgress);
    final practiceSolved = quests.where((q)=>q.category==QuestCategory.practice).fold(0,(s,q)=> s + q.currentProgress);
    double planRatio = 0;
    try {
      if(user?.weeklyPlan != null) {
        final today = DateTime.now();
        final dateKey = '${today.year.toString().padLeft(4,'0')}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
        final completed = (user.completedDailyTasks[dateKey]??[]).length;
        // plan uzunluğu hesaplamak için questService _computeTodayPlanSignature benzeri parse gerekmeden schedule_ quest sayısını kullan
        final int planTotalRaw = quests.where((q)=>q.id.startsWith('schedule_')).length;
        final int planTotal = planTotalRaw == 0 ? 1 : planTotalRaw;
        planRatio = completed / planTotal;
      }
    } catch(_){}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children:[
              Expanded(child: _summaryMetric(label: 'Görev', value: '$done/$total')), 
              Expanded(child: _summaryMetric(label: 'Plan %', value: '${(planRatio*100).round()}%')), 
              Expanded(child: _summaryMetric(label: 'Odak dk', value: focusMinutes.toString())),
              Expanded(child: _summaryMetric(label: 'Soru', value: practiceSolved.toString())),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total==0?0: done/total,
              minHeight: 6,
              backgroundColor: AppTheme.lightSurfaceColor.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(AppTheme.secondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.secondaryTextColor)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Eksik kalmış yardımcı sınıflar tekrar eklendi
class _QuestHintLine extends StatelessWidget {
  final Quest quest;
  const _QuestHintLine({required this.quest});
  String _buildHint() {
    switch (quest.category) {
      case QuestCategory.practice:
        if (quest.goalValue <= 5) return 'Mini başla: birkaç soru tetikler.';
        return '${quest.goalValue} soru hedefi. Bilgi Galaksisi ekranından soru çöz.';
      case QuestCategory.study:
        return 'Plan / konu hakimiyeti. İlgili maddeyi haftalık plandan bitir.';
      case QuestCategory.engagement:
        if (quest.actionRoute.contains('pomodoro')) return 'Pomodoro ekranında odak seansı başlat.';
        if (quest.actionRoute.contains('stats')) return 'Performans Kalesi ekranını aç.';
        return 'İlgili özelliği ziyaret et ve etkileşimi tamamla.';
      case QuestCategory.consistency:
        return 'Gün içi düzen. Uygulamayı farklı zamanlarda aç / seri koru.';
      case QuestCategory.test_submission:
        return 'Yeni bir deneme sonucu ekle.';
      case QuestCategory.focus:
        return 'Odak turları biriktir. Seansları tamamla.';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Text(
      _buildHint(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.secondaryTextColor,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.lightSurfaceColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(title, style: const TextStyle(color: AppTheme.secondaryTextColor, fontWeight: FontWeight.bold)),
          ),
          const Expanded(child: Divider(color: AppTheme.lightSurfaceColor)),
        ],
      ),
    );
  }
}
