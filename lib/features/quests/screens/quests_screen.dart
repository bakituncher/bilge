// lib/features/quests/screens/quests_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:bilge_ai/core/analytics/analytics_logger.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/logic/quest_service.dart';
import 'package:bilge_ai/features/quests/logic/optimized_quests_provider.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

// ===================== HELPER WIDGETS ÖNE ALINDI =====================
class QuestCard extends StatelessWidget {
  final Quest quest; final Set<String> completedIds; final String? userId; final Map<String,Quest> allQuestsMap; final WidgetRef ref;
  const QuestCard({super.key, required this.quest, required this.completedIds, this.userId, required this.allQuestsMap, required this.ref});
  IconData _getIconForCategory(QuestCategory category){
    switch(category){
      case QuestCategory.study: return Icons.book_rounded;
      case QuestCategory.practice: return Icons.edit_note_rounded;
      case QuestCategory.engagement: return Icons.auto_awesome;
      case QuestCategory.consistency: return Icons.event_repeat_rounded;
      case QuestCategory.test_submission: return Icons.add_chart_rounded;
      case QuestCategory.focus: return Icons.center_focus_strong;
    }
  }
  Widget _pill(String label, {IconData? icon, String? emoji, Color? color}){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.lightSurfaceColor).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (color ?? AppTheme.secondaryColor).withValues(alpha: 0.35), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children:[
        if(emoji!=null) Text(emoji),
        if(icon!=null) Icon(icon, size: 14, color: Colors.white),
        if(emoji!=null||icon!=null) const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]),
    );
  }
  List<Widget> _buildPills(Quest q, {required bool locked}){
    final pills=<Widget>[];
    if(locked){
      pills.add(_pill('Önkoşul', icon: Icons.lock_rounded, color: Colors.deepPurpleAccent));
    }
    // Etiket önceliği
    final tags=q.tags;
    if(tags.contains('high_value')) pills.add(_pill('Öncelik', emoji: '⚡', color: Colors.amber));
    if(tags.contains('weakness') && pills.length<2) pills.add(_pill('Zayıf', emoji:'⚠️', color: Colors.redAccent));
    if(tags.contains('focus') && pills.length<2) pills.add(_pill('Odak', emoji:'🎯', color: Colors.cyanAccent));
    if(tags.contains('adaptive') && pills.length<2) pills.add(_pill('Adaptif', emoji:'✨', color: Colors.lightBlueAccent));
    if(tags.contains('chain') && pills.length<2) pills.add(_pill('Zincir', emoji:'🔗', color: Colors.tealAccent));
    if(tags.contains('plan') && pills.length<2) pills.add(_pill('Plan', emoji:'🗓️', color: Colors.blueGrey));
    return pills.take(2).toList();
  }
  Widget _badge(String text,IconData icon,Color color)=>Chip(label:Text(text),avatar:Icon(icon,size:16,color:AppTheme.primaryColor),backgroundColor:color.withValues(alpha:0.85),labelStyle:const TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:AppTheme.primaryColor),materialTapTargetSize:MaterialTapTargetSize.shrinkWrap,visualDensity:VisualDensity.compact,);
  Widget _buildChainSegments(Quest q){ if(q.chainId==null||q.chainStep==null||q.chainLength==null) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top:6), child: Row(children: List.generate(q.chainLength!, (i){final active=i<q.chainStep!; return Expanded(child: AnimatedContainer(duration:300.ms, margin: EdgeInsets.symmetric(horizontal:i==1?4:2), height:6, decoration:BoxDecoration(color: active?AppTheme.secondaryColor:AppTheme.lightSurfaceColor.withValues(alpha:0.3), borderRadius: BorderRadius.circular(4)),));}))); }
  @override Widget build(BuildContext context){
    final isCompleted=quest.isCompleted; final progress=quest.goalValue>0?((quest.currentProgress/quest.goalValue).clamp(0.0,1.0)):1.0; final locked=!isCompleted && quest.prerequisiteIds.isNotEmpty && !quest.prerequisiteIds.every((id)=>completedIds.contains(id));
    // Cam efektli, gradient hatlı yeni kart
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.cardColor.withValues(alpha: isCompleted?0.45:0.6),
                AppTheme.cardColor.withValues(alpha: isCompleted?0.35:0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0,6)),
            ],
          ),
          child: InkWell(
            onTap: (isCompleted||locked)?(){ if(locked){
              final names = quest.prerequisiteIds.map((id)=> allQuestsMap[id]?.title ?? id).toList();
              final msg = names.isEmpty? 'Önce önkoşul görev(ler)ini tamamla' : 'Önkoşul: '+names.join(', ');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }
            }:(){ if(userId!=null){ref.read(analyticsLoggerProvider).logQuestEvent(userId: userId!, event:'quest_tap', data:{'questId':quest.id,'category':quest.category.name});}
              String target=quest.actionRoute; if(target=='/coach'){ final subjectTag=quest.tags.firstWhere((t)=>t.startsWith('subject:'), orElse:()=>'' ); if(subjectTag.isNotEmpty){ final subj=subjectTag.split(':').sublist(1).join(':'); target=Uri(path:'/coach', queryParameters:{'subject':subj}).toString(); }} context.go(target); },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14,14,14,10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  // Gradient avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors:[
                        isCompleted? AppTheme.successColor.withValues(alpha:0.8): AppTheme.secondaryColor,
                        AppTheme.secondaryColor.withValues(alpha:0.6),
                      ]),
                    ),
                    child: Center(child: Icon(_getIconForCategory(quest.category), color: AppTheme.primaryColor, size: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    Text(quest.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(quest.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
                    const SizedBox(height: 6),
                    Row(children:[
                      ..._buildPills(quest, locked: locked),
                      const Spacer(),
                      Chip(
                        label: Text('+${quest.reward} BP', style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.35),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ])
                  ])),
                ]),
                const SizedBox(height: 10),
                if(!isCompleted) Row(children:[
                  Expanded(child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(colors:[
                        AppTheme.secondaryColor,
                        AppTheme.secondaryColor.withValues(alpha: 0.4),
                      ]),
                    ),
                    child: LayoutBuilder(builder: (ctx, c){
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: 400.ms, curve: Curves.easeOutCubic,
                          width: c.maxWidth * progress,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  )),
                  const SizedBox(width: 10),
                  Text('${quest.currentProgress}/${quest.goalValue}', style: const TextStyle(fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 10),
                Row(children:[
                  if(isCompleted && quest.rewardClaimed) ...[
                    const Icon(Icons.check_circle_rounded,color:AppTheme.successColor,size:20),
                    const SizedBox(width:6),
                    const Text('Fethedildi!', style: TextStyle(color: AppTheme.successColor,fontWeight: FontWeight.bold)),
                  ] else if(isCompleted && !quest.rewardClaimed) ...[
                    // Ödül butonu (mevcut attention animasyonları korunuyor)
                    Expanded(child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppTheme.secondaryColor.withValues(alpha:0.55), blurRadius: 18, spreadRadius: 1),
                          BoxShadow(color: AppTheme.secondaryColor.withValues(alpha:0.25), blurRadius: 28, spreadRadius: 6),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: userId==null? null : () async {
                          await ref.read(firestoreServiceProvider).claimQuestReward(userId!, quest);
                          ref.invalidate(dailyQuestsProvider);
                          if(context.mounted){
                            await HapticFeedback.mediumImpact();
                            showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              backgroundColor: AppTheme.cardColor,
                              builder: (ctx){
                                return SafeArea(child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20,16,20,24),
                                  child: Column(mainAxisSize: MainAxisSize.min, children:[
                                    const Icon(Icons.celebration_rounded, color: AppTheme.successColor, size: 44),
                                    const SizedBox(height: 8),
                                    const Text('Ödül tahsil edildi!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 6),
                                    Text('+${quest.reward} BP', style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w700, fontSize: 16)),
                                    const SizedBox(height: 12),
                                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: ()=>Navigator.pop(ctx), icon: const Icon(Icons.check_circle_outline), label: const Text('Tamam'))),
                                  ]),
                                ));
                              }
                            );
                          }
                        },
                        icon: const Icon(Icons.card_giftcard_rounded),
                        label: const Text('Ödülü Al!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ).animate(onPlay: (c)=>c.repeat(reverse:true))
                       .scaleXY(begin: 0.98, end: 1.02, duration: 800.ms, curve: Curves.easeInOut)
                       .shimmer(duration: 1200.ms, color: AppTheme.primaryColor.withValues(alpha:0.15)),
                    )),
                  ] else ...[
                    Text('Başla', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                    const SizedBox(width:6),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.secondaryTextColor)
                  ]
                ])
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
class _SummaryBar extends ConsumerWidget { final List<Quest> quests; final dynamic user; const _SummaryBar({required this.quests, required this.user}); @override Widget build(BuildContext context, WidgetRef ref){ final total=quests.where((q)=>q.type==QuestType.daily).length; final done=quests.where((q)=>q.type==QuestType.daily && q.isCompleted).length; final focusMinutes=quests.where((q)=>q.category==QuestCategory.focus).fold<int>(0,(s,q)=>s+q.currentProgress); final practiceSolved=quests.where((q)=>q.category==QuestCategory.practice).fold<int>(0,(s,q)=>s+q.currentProgress); double planRatio=0; try{ final today=DateTime.now(); final completed=ref.watch(completedTasksForDateProvider(today)).maybeWhen(data:(list)=>list.length, orElse: ()=>0); final planTotalRaw=quests.where((q)=>q.id.startsWith('schedule_')).length; final planTotal=planTotalRaw==0?1:planTotalRaw; planRatio=completed/planTotal; }catch(_){ }
    return Card(margin: const EdgeInsets.only(bottom:12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Row(children:[ Expanded(child:_metric('Görev','$done/$total')), Expanded(child:_metric('Plan %','${(planRatio*100).round()}%')), Expanded(child:_metric('Odak dk',focusMinutes.toString())), Expanded(child:_metric('Soru',practiceSolved.toString())), ]), const SizedBox(height:8), LinearProgressIndicator(value: total==0?0.0:done/total, minHeight:6, backgroundColor: AppTheme.lightSurfaceColor.withValues(alpha:0.25), valueColor: const AlwaysStoppedAnimation(AppTheme.secondaryColor)), ]))); }
  Widget _metric(String l,String v)=>Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text(l, style: const TextStyle(fontSize:11,color:AppTheme.secondaryTextColor)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold)), ]);
}
class _QuestHintLine extends StatelessWidget { final Quest quest; const _QuestHintLine({required this.quest}); String _hint(){ switch(quest.category){ case QuestCategory.practice: return quest.goalValue<=5?'Mini başla: birkaç soru tetikler.':'${quest.goalValue} soru hedefi. Bilgi Galaksisi ekranından soru çöz.'; case QuestCategory.study: return 'Plan / konu hakimiyeti. İlgili maddeyi haftalık plandan bitir.'; case QuestCategory.engagement: if(quest.actionRoute.contains('pomodoro')) return 'Pomodoro ekranında odak seansı başlat.'; if(quest.actionRoute.contains('stats')) return 'Performans Kalesi ekranını aç.'; return 'İlgili özelliği ziyaret et ve etkileşimi tamamla.'; case QuestCategory.consistency: return 'Gün içi düzen. Uygulamayı farklı zamanlarda aç / seri koru.'; case QuestCategory.test_submission: return 'Yeni bir deneme sonucu ekle.'; case QuestCategory.focus: return 'Odak turları biriktir. Seansları tamamla.'; } }
  @override Widget build(BuildContext context)=> Text(_hint(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor, fontStyle: FontStyle.italic)); }
class _SectionHeader extends StatelessWidget { final String title; const _SectionHeader({required this.title}); @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(top:16,bottom:16), child: Row(children:[ const Expanded(child: Divider(color: AppTheme.lightSurfaceColor)), Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Text(title, style: const TextStyle(color: AppTheme.secondaryTextColor,fontWeight: FontWeight.bold))), const Expanded(child: Divider(color: AppTheme.lightSurfaceColor)), ])); }
// ===================== ANA EKRAN =====================
class QuestsScreen extends ConsumerStatefulWidget { const QuestsScreen({super.key}); static const Map<QuestCategory,String> categoryHelp={
  QuestCategory.practice:'Practice: Soru çözme / hız çalışmaları. İlerleme: çözdüğün soru sayısı.',
  QuestCategory.study:'Study: Konu hakimiyeti / plan görevi tamamlamak. İlerleme: tamamlanan konu veya plan maddesi.',
  QuestCategory.engagement:'Engagement: Uygulama içi etkileşim (istatistik inceleme, pomodoro vb.).',
  QuestCategory.consistency:'Consistency: Düzen ve süreklilik (gün içi tekrar ziyaret, seri koruma).',
  QuestCategory.test_submission:'Test: Deneme ekleme ve sonuç raporlama.',
  QuestCategory.focus:'Focus: Odak seansı dakikaları biriktirme / zincir ilerletme.',}; @override ConsumerState<QuestsScreen> createState()=>_QuestsScreenState(); }
class _QuestsScreenState extends ConsumerState<QuestsScreen>{
  late ConfettiController _confettiController; final _loggedViews=<String>{};
  bool _bulkClaiming=false;

  Future<void> _handleBulkClaim(List<Quest> claimable, String userId) async {
    if (_bulkClaiming || claimable.isEmpty) return;
    setState(()=>_bulkClaiming=true);
    final snapshot = List<Quest>.from(claimable);
    final totalBp = snapshot.fold<int>(0,(s,q)=>s+q.reward);
    try{
      await HapticFeedback.selectionClick();
      for(final q in snapshot){
        await ref.read(firestoreServiceProvider).claimQuestReward(userId, q);
      }
      ref.invalidate(dailyQuestsProvider);
      await HapticFeedback.heavyImpact();
      if(mounted){
        _confettiController.play();
        // ignore: use_build_context_synchronously
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          backgroundColor: AppTheme.cardColor,
          builder: (ctx){
            return SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20,16,20,24),
              child: Column(mainAxisSize: MainAxisSize.min, children:[
                const Icon(Icons.emoji_events_rounded, color: AppTheme.successColor, size: 48),
                const SizedBox(height: 8),
                Text('${snapshot.length} ödül tahsil edildi!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text('+$totalBp BP', style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: ()=>Navigator.pop(ctx), icon: const Icon(Icons.check_circle_outline), label: const Text('Harika'))),
              ]),
            ));
          }
        );
      }
    } catch (_) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toplu tahsil sırasında bir sorun oluştu.')));
      }
    } finally {
      if(mounted) setState(()=>_bulkClaiming=false);
    }
  }
  @override void initState(){ super.initState(); _confettiController=ConfettiController(duration: const Duration(seconds:1)); }
  @override void dispose(){ _confettiController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    final loadAsync=ref.watch(dailyQuestsProvider);
    final quests=ref.watch(optimizedDailyQuestsProvider);
    final user=ref.watch(userProfileProvider).value;
    ref.listen<List<Quest>>(optimizedDailyQuestsProvider,(prev,next){ if(prev==null||prev.isEmpty) return; if(next.where((q)=>q.isCompleted).length>prev.where((q)=>q.isCompleted).length){ _confettiController.play(); }});
    final isLoading=loadAsync.isLoading && quests.isEmpty;

    // Kümeler ve haritalar
    final weeklyAll=quests.where((q)=>q.type==QuestType.weekly).toList();
    final dailyAll=quests.where((q)=>q.type==QuestType.daily).toList();
    final dailyActive=dailyAll.where((q)=>!q.isCompleted).toList();
    final dailyCompleted=dailyAll.where((q)=>q.isCompleted).toList();
    final claimable=quests.where((q)=>q.isCompleted && !q.rewardClaimed).toList();
    final completedIds=quests.where((q)=>q.isCompleted).map((q)=>q.id).toSet();
    final allMap={for(final q in quests) q.id:q};

    // Analitik görüntüleme logları
    final analytics=ref.read(analyticsLoggerProvider);
    for(final q in quests){ if(!_loggedViews.contains(q.id)){ _loggedViews.add(q.id); if(user!=null){ analytics.logQuestEvent(userId:user.id, event:'quest_view', data:{'questId':q.id,'category':q.category.name,'difficulty':q.difficulty.name}); } }}

    final initialIndex = claimable.isNotEmpty ? 0 : 1; // Ödül varsa önce onu göster

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fetih Kütüğü'),
          actions:[
            IconButton(tooltip:'Görev Rehberi', icon: const Icon(Icons.help_center_outlined), onPressed: ()=>_showHelp(context)),
            IconButton(tooltip:'Görevleri Yenile', icon: const Icon(Icons.refresh_rounded), onPressed: user==null?null:() async { await ref.read(questServiceProvider).refreshDailyQuestsForUser(user, force:true); ref.invalidate(dailyQuestsProvider);} )
          ],
          bottom: TabBar(
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.secondaryColor.withValues(alpha:0.35), AppTheme.successColor.withValues(alpha:0.30)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: [
              Tab(icon: const Icon(Icons.card_giftcard_rounded), text: 'Ödüller (${claimable.length})'),
              const Tab(icon: Icon(Icons.today_rounded), text: 'Günlük'),
              const Tab(icon: Icon(Icons.event_note_rounded), text: 'Haftalık'),
            ],
          ),
        ),
        body: Stack(alignment: Alignment.topCenter, children:[
          // Arka plan gradienti
          Positioned.fill(child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.55),
                  AppTheme.cardColor,
                ],
              ),
            ),
          )),
          // Hafif parçacık efekti
          const Positioned.fill(child: IgnorePointer(child: _SubtleParticles())),
          if(isLoading) const Center(child:CircularProgressIndicator(color: AppTheme.secondaryColor))
          else TabBarView(children: [
            // Sekme 1: Ödüller (tamamlanmış ve tahsil bekleyenler)
            Builder(builder: (ctx){
              final hasClaim = claimable.isNotEmpty;
              if(!hasClaim){
                return RefreshIndicator(
                  onRefresh: () async { if(user!=null){ await ref.read(questServiceProvider).refreshDailyQuestsForUser(user, force:true); ref.invalidate(dailyQuestsProvider);} },
                  child: _buildEmptyClaimable(context),
                );
              }
              return Stack(children:[
                RefreshIndicator(
                  onRefresh: () async { if(user!=null){ await ref.read(questServiceProvider).refreshDailyQuestsForUser(user, force:true); ref.invalidate(dailyQuestsProvider);} },
                  child: ListView(padding: const EdgeInsets.fromLTRB(16,16,16,160), children:[
                    _SectionHeader(title: 'Tahsil Bekleyenler (${claimable.length})'),
                    ...claimable.map((q)=>QuestCard(quest:q,completedIds:completedIds,userId:user?.id,allQuestsMap:allMap,ref:ref)),
                    const SizedBox(height: 80),
                  ]),
                ),
                // Yapışkan alt eylem çubuğu
                Positioned(
                  left: 12, right: 12, bottom: 16,
                  child: SafeArea(child: SizedBox(
                    height: 64,
                    child: Material(
                      color: AppTheme.cardColor.withValues(alpha: 0.9),
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(children:[
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[
                            Text('${claimable.length} ödül hazır', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Toplam +${claimable.fold<int>(0,(s,q)=>s+q.reward)} BP', style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                          ])),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: (user==null || _bulkClaiming)? null : () => _handleBulkClaim(claimable, user!.id),
                            icon: _bulkClaiming? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.flash_on_rounded),
                            label: Text(_bulkClaiming? 'İşleniyor' : 'Hepsini Al'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor, foregroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          )
                        ]),
                      ),
                    ),
                  )),
                )
              ]);
            }),
            // Sekme 2: Günlük
            RefreshIndicator(
              onRefresh: () async { if(user!=null){ await ref.read(questServiceProvider).refreshDailyQuestsForUser(user, force:true); ref.invalidate(dailyQuestsProvider);} },
              child: ListView(padding: const EdgeInsets.fromLTRB(16,16,16,120), children:[
                _TopCarouselMetrics(quests:quests,user:user),
                const SizedBox(height: 12),
                if(dailyActive.isNotEmpty)...[
                  const _SectionHeader(title:'Aktif Görevler'),
                  ...dailyActive.map((q)=>QuestCard(quest:q,completedIds:completedIds,userId:user?.id,allQuestsMap:allMap,ref:ref)),
                ],
                if(dailyCompleted.isNotEmpty)...[
                  _SectionHeader(title:'Tamamlananlar (${dailyCompleted.length})'),
                  ...dailyCompleted.map((q)=>QuestCard(quest:q,completedIds:completedIds,userId:user?.id,allQuestsMap:allMap,ref:ref)),
                ],
                if(dailyActive.isEmpty && dailyCompleted.isEmpty) _buildEmptyState(context),
              ]).animate().fadeIn(duration:400.ms).slideY(begin:0.08),
            ),
            // Sekme 3: Haftalık
            RefreshIndicator(
              onRefresh: () async { if(user!=null){ await ref.read(questServiceProvider).refreshDailyQuestsForUser(user, force:true); ref.invalidate(dailyQuestsProvider);} },
              child: weeklyAll.isEmpty
                ? _buildEmptyWeekly(context)
                : ListView(padding: const EdgeInsets.fromLTRB(16,16,16,120), children:[
                    const _SectionHeader(title:'Haftalık Sefer'),
                    ...weeklyAll.map((q)=>QuestCard(quest:q,completedIds:completedIds,userId:user?.id,allQuestsMap:allMap,ref:ref)),
                  ]),
            ),
          ]),
          ConfettiWidget(confettiController:_confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop:false, colors: const [AppTheme.secondaryColor, AppTheme.successColor, Colors.white]),
        ]),
        floatingActionButton: claimable.isNotEmpty ? Builder(builder: (ctx){
          return FloatingActionButton.extended(
            onPressed: (){
              final controller = DefaultTabController.of(ctx);
              controller?.animateTo(0);
            },
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.card_giftcard_rounded),
            label: const Text('Ödül Var'),
          ).animate(onPlay: (c)=>c.repeat(reverse:true))
           .scaleXY(begin: 0.96, end: 1.04, duration: 900.ms, curve: Curves.easeInOut)
           .shimmer(duration: 1400.ms, color: AppTheme.primaryColor.withValues(alpha:0.2));
        }) : null,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context)=> Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ const Icon(Icons.shield_moon_rounded,size:80,color:AppTheme.secondaryTextColor), const SizedBox(height:16), Text('Bugünün Fetihleri Tamamlandı!', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height:8), Padding(padding: const EdgeInsets.symmetric(horizontal:32), child: Text('Yarın yeni hedeflerle görüşmek üzere, komutanım.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor))), ])).animate().fadeIn(duration:500.ms);

  Widget _buildEmptyClaimable(BuildContext context)=> Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ const Icon(Icons.card_giftcard_rounded,size:80,color:AppTheme.secondaryTextColor), const SizedBox(height:16), Text('Tahsil bekleyen ödül yok.', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height:8), const Text('Görevleri tamamlayınca ödüller burada parlayacak.'), ])).animate().fadeIn(duration:400.ms);

  Widget _buildEmptyWeekly(BuildContext context)=> Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ const Icon(Icons.event_note_rounded,size:80,color:AppTheme.secondaryTextColor), const SizedBox(height:16), Text('Bu hafta için görev bulunamadı.', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height:8), const Text('Planını oluştur ve haftalık seferi başlat.'), ])).animate().fadeIn(duration:400.ms);

  void _showHelp(BuildContext context){ showModalBottomSheet(context: context, showDragHandle:true, backgroundColor: AppTheme.cardColor, builder: (ctx){ return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20,12,20,24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('Görev Rehberi', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height:12), Expanded(child: ListView(children:[ ...QuestsScreen.categoryHelp.entries.map((e)=> Padding(padding: const EdgeInsets.only(bottom:12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[ const Icon(Icons.label_important_outline,size:18,color:AppTheme.secondaryColor), const SizedBox(width:8), Expanded(child: Text(e.value, style: Theme.of(context).textTheme.bodyMedium)), ]))), const Divider(), Text('İlerleme Mantığı', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height:8), _helpBullet('Soru / dakika içeren görevler: Hedef sayıya ulaştığında otomatik tamamlanır.'), _helpBullet('Plan görevleri: Haftalık plan ekranında ilgili maddeyi bitir.'), _helpBullet('Deneme görevleri: Deneme ekle ekranından yeni sonuç kaydet.'), _helpBullet('Ziyaret / seri görevleri: Uygulamayı gün içinde tekrar açarak ilerlet.'), _helpBullet('Pomodoro odak görevleri: Odak seansları tamamla.'), ])), const SizedBox(height:12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: ()=>Navigator.pop(ctx), icon: const Icon(Icons.check_circle_outline), label: const Text('Anladım')) ) ]))); }); }
  Widget _helpBullet(String text)=> Padding(padding: const EdgeInsets.only(bottom:6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[ const Text('• ', style: TextStyle(color: AppTheme.secondaryColor)), Expanded(child: Text(text)), ]));
}

// Hafif parçacık efekti için widget ve painter
class _SubtleParticles extends StatefulWidget {
  const _SubtleParticles();
  @override State<_SubtleParticles> createState() => _SubtleParticlesState();
}
class _SubtleParticlesState extends State<_SubtleParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rand = math.Random();
  late final List<_Particle> _particles;
  @override void initState(){
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _particles = List.generate(18, (i)=> _Particle(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      r: 1.2 + _rand.nextDouble()*2.2,
      amp: 0.02 + _rand.nextDouble()*0.06,
      phase: _rand.nextDouble()*math.pi*2,
      speed: 0.5 + _rand.nextDouble()*1.2,
    ));
  }
  @override void dispose(){ _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __){
        return CustomPaint(painter: _ParticlesPainter(_particles, _ctrl.value));
      },
    );
  }
}
class _Particle { double x; double y; double r; double amp; double phase; double speed; _Particle({required this.x,required this.y,required this.r,required this.amp,required this.phase,required this.speed}); }
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> ps; final double t;
  _ParticlesPainter(this.ps,this.t);
  @override void paint(Canvas canvas, Size size){
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08)..isAntiAlias=true;
    for(final p in ps){
      final dx = math.sin((t*2*math.pi*p.speed)+p.phase)*p.amp*size.width;
      final dy = math.cos((t*2*math.pi*p.speed)+p.phase)*p.amp*size.height;
      final off = Offset(p.x*size.width + dx, p.y*size.height + dy);
      canvas.drawCircle(off, p.r, paint);
    }
  }
  @override bool shouldRepaint(covariant _ParticlesPainter old)=> old.t!=t || old.ps!=ps;
}

// Genç odaklı yatay metrik carousel
class _TopCarouselMetrics extends ConsumerStatefulWidget{
  final List<Quest> quests; final dynamic user;
  const _TopCarouselMetrics({required this.quests, required this.user});
  @override ConsumerState<_TopCarouselMetrics> createState()=>_TopCarouselMetricsState();
}
class _TopCarouselMetricsState extends ConsumerState<_TopCarouselMetrics>{
  final PageController _pc = PageController(viewportFraction: 0.88);
  @override void dispose(){ _pc.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    final quests=widget.quests; double planRatio=0; int focusMinutes=0; int practiceSolved=0; int total=0; int done=0;
    try{
      final today=DateTime.now();
      final completed=ref.watch(completedTasksForDateProvider(today)).maybeWhen(data:(list)=>list.length, orElse: ()=>0);
      final planTotalRaw=quests.where((q)=>q.id.startsWith('schedule_')).length; final planTotal=planTotalRaw==0?1:planTotalRaw; planRatio=completed/planTotal;
    }catch(_){ planRatio=0; }
    focusMinutes=quests.where((q)=>q.category==QuestCategory.focus).fold<int>(0,(s,q)=>s+q.currentProgress);
    practiceSolved=quests.where((q)=>q.category==QuestCategory.practice).fold<int>(0,(s,q)=>s+q.currentProgress);
    total=quests.where((q)=>q.type==QuestType.daily).length;
    done=quests.where((q)=>q.type==QuestType.daily && q.isCompleted).length;

    final items = [
      _metricCard(context, title:'Görev', subtitle: '$done/$total', emoji:'🛡️', colors:[AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha:0.5)]),
      _metricCard(context, title:'Plan', subtitle: '${(planRatio*100).round()}%', emoji:'📅', colors:[Colors.blueAccent, Colors.lightBlueAccent]),
      _metricCard(context, title:'Odak', subtitle: '${focusMinutes}dk', emoji:'⏱️', colors:[Colors.purpleAccent, Colors.deepPurpleAccent]),
      _metricCard(context, title:'Soru', subtitle: '$practiceSolved', emoji:'🧠', colors:[Colors.orangeAccent, Colors.deepOrangeAccent]),
    ];
    return Column(children:[
      SizedBox(
        height: 120,
        child: PageView.builder(
          controller: _pc,
          itemCount: items.length,
          itemBuilder: (_,i){ return Padding(padding: const EdgeInsets.only(right: 8), child: items[i]); },
        ),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(items.length, (i){
        return AnimatedBuilder(
          animation: _pc,
          builder: (_, __){
            final page = _pc.hasClients && _pc.page!=null ? _pc.page! : 0.0;
            final selected = (page.round()==i);
            return Container(
              width: selected? 16: 8, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: selected? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(999)),
            );
          },
        );
      }))
    ]);
  }
  Widget _metricCard(BuildContext context,{required String title, required String subtitle, required String emoji, required List<Color> colors}){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children:[
        Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ])
      ]),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}
