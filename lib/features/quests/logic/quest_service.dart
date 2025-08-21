// lib/features/quests/logic/quest_service.dart
import 'dart:math';
import 'dart:async'; // TimeoutException için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';
import 'package:bilge_ai/features/quests/quest_armory.dart'; // YENİ CEPHANELİK
import 'package:bilge_ai/features/stats/logic/stats_analysis.dart';
import 'package:uuid/uuid.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/plan_model.dart'; // WeeklyPlan parsing için
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/features/quests/logic/quest_templates.dart';

final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService(ref);
});
final questGenerationIssueProvider = StateProvider<bool>((_) => false);

// "Strateji Masası" - Görev Atama Motoru
class QuestService {
  final Ref _ref;
  QuestService(this._ref);

  bool _inProgress = false; // yeniden giriş kilidi

  Future<List<Quest>> refreshDailyQuestsForUser(UserModel user, {bool force = false}) async {
    if (_inProgress) {
      return user.activeDailyQuests;
    }
    _inProgress = true;
    try {
      final today = DateTime.now();
      await _maybeGenerateWeeklyReport(user, today); // yeni
      final lastRefresh = user.lastQuestRefreshDate?.toDate();
      final currentPlanSignature = _computeTodayPlanSignature(user);
      final planChanged = currentPlanSignature != null && currentPlanSignature != user.dailyQuestPlanSignature;
      final shouldBypassSameDayCache = planChanged;
      if (!force && !shouldBypassSameDayCache && lastRefresh != null && lastRefresh.year == today.year && lastRefresh.month == today.month && lastRefresh.day == today.day) {
        return user.activeDailyQuests;
      }
      List<Quest> newQuests = [];
      try {
        newQuests = await _generateQuestsForUser(user).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        if (kDebugMode) debugPrint('[QuestService] Görev üretimi timeout -> eski görevler dönüyor');
        _ref.read(questGenerationIssueProvider.notifier).state = true; // banner tetik
        return user.activeDailyQuests;
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[QuestService] Görev üretimi hata: $e');
          debugPrint(st.toString());
        }
        _ref.read(questGenerationIssueProvider.notifier).state = true; // banner tetik
        return user.activeDailyQuests;
      }
      await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({
        'activeDailyQuests': newQuests.map((q) => q.toMap()).toList(),
        'lastQuestRefreshDate': Timestamp.now(),
        if (currentPlanSignature != null) 'dailyQuestPlanSignature': currentPlanSignature,
        if (_lastDifficultyFactor != null) 'dynamicDifficultyFactorToday': _lastDifficultyFactor,
      });
      _ref.read(questGenerationIssueProvider.notifier).state = false; // başarıyla temizle
      return newQuests;
    } finally {
      _inProgress = false;
    }
  }

  double? _lastDifficultyFactor; // güncel zorluk çarpanı cache

  // === MİLYON DOLARLIK OTOMASYONUN KALBİ: GÖREV ÜRETİM MOTORU ===
  Future<List<Quest>> _generateQuestsForUser(UserModel user) async {
    final List<Quest> generatedQuests = [];
    final random = Random();

    // 1. VERİ TOPLAMA (streams -> valueOrNull ile non-blocking)
    List<TestModel> tests = [];
    try {
      final testsAsync = _ref.read(testsProvider);
      tests = testsAsync.valueOrNull ?? [];
    } catch (_) {
      // yoksay
    }
    final examData = user.selectedExam != null
        ? await ExamData.getExamByType(ExamType.values.byName(user.selectedExam!))
        : null;

    StatsAnalysis? analysis;
    if (tests.isNotEmpty && examData != null) {
      analysis = StatsAnalysis(tests, user.topicPerformances, examData, user: user);
    }

    // 2. ŞABLONLARI HAZIRLA (modüler)
    List<QuestTemplate> templates = questArmory.map((m) => QuestTemplateFactory.fromMap(m)).toList();
    templates.shuffle();
    templates.removeWhere((t) => user.activeDailyQuests.any((q) => q.id == t.id));

    // Gün içi plan tamamlama ve kategori bilgisi
    final todayKey = _dateKey(DateTime.now());
    final todayCompletedPlanTasks = user.completedDailyTasks[todayKey]?.length ?? 0;

    // Önceki gün plan oranı ve inaktiflik
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayRatio = user.lastScheduleCompletionRatio ?? 0.0;
    final wasInactiveYesterday = !(user.dailyVisits.any((ts) {
      final d = ts.toDate();
      return d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;
    }));

    // Mevcut tamamlanan quest kategorileri (günün) -> sadece çeşitlilik sayımı için adlar
    final completedCategoriesNames = user.activeDailyQuests
        .where((q) => q.isCompleted)
        .map((q) => q.category.name)
        .toSet();

    final ctx = QuestContext(
      tests: tests,
      yesterdayPlanRatio: yesterdayRatio,
      wasInactiveYesterday: wasInactiveYesterday,
      todayCompletedPlanTasks: todayCompletedPlanTasks,
      completedCategoriesToday: completedCategoriesNames,
    );

    // 3. PUANLAMA (modüler)
    final List<({QuestTemplate template, int score, Map<String, String> variables})> scoredQuests = [];
    for (final t in templates) {
      if (!t.isEligible(user, analysis, ctx)) continue;
      final score = t.calculateScore(user, analysis, ctx);
      if (score <= 0) continue;
      final vars = t.resolveVariables(user, analysis, ctx);
      scoredQuests.add((template: t, score: score, variables: vars));
    }
    scoredQuests.sort((a, b) => b.score.compareTo(a.score));

    // 4. SEÇİM (kategori çeşitliliğini koru)
    final Set<QuestCategory> selectedCategories = {};
    while (generatedQuests.length < 5 && scoredQuests.isNotEmpty) {
      final candidate = scoredQuests.removeAt(0);
      final catName = candidate.template.category;
      final catEnum = QuestCategory.values.byName(catName);
      if (selectedCategories.contains(catEnum)) {
        if (random.nextDouble() > 0.6) continue;
      }
      generatedQuests.add(_createQuestFromTemplate(candidate.template.data, variables: candidate.variables));
      selectedCategories.add(catEnum);
    }

    // 5. HAFTALIK PLAN ENTEGRASYONU (KALE GÜÇLENDİRME)
    _injectScheduleBasedQuests(user, generatedQuests, tests: tests);

    // Günlük ödül dengesini (özellikle programdan gelen görevler) normalize et.
    _normalizeDailyRewards(generatedQuests);

    // 6. KİŞİSELLEŞTİRME Katmanı
    for (var i = 0; i < generatedQuests.length; i++) {
      generatedQuests[i] = _personalizeQuest(generatedQuests[i], user, analysis);
    }

    // 7. İHMAL EDİLEN DERS GÖREVİ (Recovery)
    _maybeInjectNeglectedSubjectQuest(user, generatedQuests, analysis);

    // 8. PLATO KIRICI GÖREV
    _maybeInjectPlateauBreaker(user, generatedQuests, analysis, tests);

    // 9. MASTERy CHAIN (strong subject)
    _maybeInjectMasteryChain(user, generatedQuests, analysis);

    return generatedQuests;
  }

  void _maybeInjectPlateauBreaker(UserModel user, List<Quest> quests, StatsAnalysis? analysis, List<TestModel> tests){
    if (tests.length < 3) return;
    final last3 = tests.take(3).toList(); // tests zaten tarih sıralı (generate sırasında ilk eleman en yeni test kabul)
    // Güvenli: en yeni başta değilse sıralayalım (desc)
    last3.sort((a,b)=> b.date.compareTo(a.date));
    final nets = last3.map((t)=> t.totalNet).toList();
    final avg = nets.fold<double>(0,(s,e)=>s+e)/nets.length;
    final variance = nets.map((n)=> (n-avg)*(n-avg)).fold<double>(0,(s,e)=>s+e)/nets.length;
    final trendNearbyFlat = (analysis?.trend.abs() ?? 0) < 0.5;
    if (variance < 2.0 && trendNearbyFlat) {
      final exists = quests.any((q)=> q.id=='plateau_breaker_1');
      if(!exists){
        quests.add(_personalizeQuest(Quest(
          id: 'plateau_breaker_1',
          title: 'Net Sıçratma Hamlesi',
            description: 'Son denemelerde ilerleme plato yaptı. 3 farklı dersten toplam 30 hız odaklı soru çöz (10+10+10).',
            type: QuestType.daily,
            category: QuestCategory.practice,
            progressType: QuestProgressType.increment,
            reward: 85,
            goalValue: 30,
            actionRoute: '/coach',
            route: questRouteFromPath('/coach'),
            tags: ['variety','plateau','personal']
        ), user, analysis));
      }
    }
  }

  void _maybeInjectMasteryChain(UserModel user, List<Quest> quests, StatsAnalysis? analysis){
    final strong = analysis?.strongestSubjectByNet;
    if (strong==null || strong=='Belirlenemedi') return;
    final hasChain = quests.any((q)=> q.id.startsWith('chain_mastery_')); // basit kontrol
    if (hasChain) return;
    final idBase = 'chain_mastery_${strong.hashCode}';
    // İlk adımı ekle
    quests.add(_personalizeQuest(Quest(
      id: '${idBase}_1',
      title: 'Ustalık Zinciri I: $strong Temel Tarama',
      description: '$strong kalesinde 20 seçilmiş soru ile ritmi kur. Hız değil doğruluk öncelik. ',
      type: QuestType.daily,
      category: QuestCategory.practice,
      progressType: QuestProgressType.increment,
      reward: 60,
      goalValue: 20,
      actionRoute: '/coach',
      route: questRouteFromPath('/coach'),
      tags: ['chain','strength','subject:$strong','mastery_chain']
    ), user, analysis));
  }

  Quest _personalizeQuest(Quest q, UserModel user, StatsAnalysis? analysis) {
    String reason = '';
    int rewardDelta = 0;
    int? newGoal;

    final weak = analysis?.weakestSubjectByNet;
    final strong = analysis?.strongestSubjectByNet;
    final streak = user.streak;
    final planRatio = user.lastScheduleCompletionRatio ?? 0.0;
    final recentPracticeAvg = _computeRecentPracticeAverage(user); // günlük ortalama soru hacmi

    // Weakness görevleri – ekstra bağlam
    if (q.tags.contains('weakness')) {
      if (weak != null && weak != 'Belirlenemedi' && !q.title.contains(weak)) {
        q = q.copyWith(title: q.title.replaceAll('{subject}', weak));
      }
      reason = 'Zayıf noktanı güçlendirmek için seçildi.';
      rewardDelta += 10;
      if (q.category == QuestCategory.practice && q.goalValue >= 40) {
        newGoal = (q.goalValue * 0.8).round().clamp(1, q.goalValue);
      }
    }
    else if (q.tags.contains('strength')) {
      if (strong != null && strong != 'Belirlenemedi' && !q.title.contains(strong)) {
        q = q.copyWith(title: q.title.replaceAll('{subject}', strong));
      }
      reason = 'Güçlü yanını hız ve doğrulukla pekiştirmek için.';
      rewardDelta += 5;
      if (q.category == QuestCategory.practice && q.goalValue >= 25) {
        // Güçlü alanda hedefi hafif artır (challenge)
        newGoal = (q.goalValue * 1.1).round();
      }
    }
    else if (q.tags.contains('neglected')) {
      reason = 'Uzun süredir ihmal edilen cepheyi yeniden aktive et.';
      rewardDelta += 12;
    }
    else if (q.tags.contains('plateau')) {
      reason = 'Net eğrisi yatay. Çeşitlilik ile sıçrama hedefleniyor.';
      rewardDelta += 10;
    }
    else if (q.tags.contains('mastery_chain')) {
      reason = 'Güçlü kalede derinlemesine ustalık inşası.';
      rewardDelta += 8;
    }
    else if (q.id.startsWith('schedule_')) {
      if (planRatio < 0.5) {
        reason = 'Program ritmini yeniden ayağa kaldırman için önceliklendirildi.';
        rewardDelta += 8;
      } else if (planRatio >= 0.85) {
        reason = 'Yüksek plan uyumunu sürdürmek için ritmi koru.';
      }
    }

    if (reason.isEmpty && streak >= 3) {
      reason = 'Serini (streak: $streak) canlı tutan yapıtaşı.';
    }
    if (reason.isEmpty) {
      if (q.category == QuestCategory.practice) reason = 'Günlük soru ritmini desteklemek için.'; else if (q.category == QuestCategory.focus) reason = 'Odak kasını sistemli geliştirmek için.'; else reason = 'Gelişim dengesini korumak için.';
    }

    if (!q.description.contains('Kişisel Not:')) {
      final personalizedDescription = q.description + '\n---\nKişisel Not: ' + reason;
      q = q.copyWith(description: personalizedDescription);
    }

    // Adaptif hedef (genel) – plan oranı düşükse hedefi küçült, yüksekse hafif büyüt
    if (q.category == QuestCategory.practice && newGoal == null) {
      if (planRatio < 0.5 && q.goalValue >= 20) newGoal = (q.goalValue * 0.85).round();
      else if (planRatio >= 0.85 && q.goalValue >= 15) newGoal = (q.goalValue * 1.05).round();
      // Son 7 gün ortalama soru hacmine göre ince ayar – aşırı yükseltmemek için clamp
      if (recentPracticeAvg > 0) {
        final target = (recentPracticeAvg * 1.12).round();
        // Sadece anlamlı fark varsa (±%10) uygula ve weakness/neglected hedeflerini küçültme kuralına dokunma
        if (target > 5 && (target - q.goalValue).abs() / q.goalValue > 0.1) {
          // Önceki newGoal ayarlanmış olabilir – ona göre güncelle
          final baseGoal = newGoal ?? q.goalValue;
          int adaptiveGoal;
          if (target > baseGoal) {
            adaptiveGoal = min(target, (baseGoal * 1.25).round());
          } else {
            adaptiveGoal = max(target, (baseGoal * 0.75).round());
          }
          newGoal = adaptiveGoal.clamp(1, 400);
        }
      }
    }

    int newReward = (q.reward + rewardDelta).clamp(1, 999);
    if (newGoal != null && newGoal != q.goalValue) {
      q = q.copyWith(goalValue: newGoal);
    }
    if (newReward != q.reward) q = q.copyWith(reward: newReward);

    final updatedTags = Set<String>.from(q.tags);
    if (q.tags.contains('weakness')) updatedTags.add('personal');
    if (planRatio < 0.5 && q.id.startsWith('schedule_')) updatedTags.add('plan_recovery');
    if (streak >= 3) updatedTags.add('streak');
    if (updatedTags.length != q.tags.length) q = q.copyWith(tags: updatedTags.toList());

    return q;
  }

  void _maybeInjectNeglectedSubjectQuest(UserModel user, List<Quest> quests, StatsAnalysis? analysis) {
    if (quests.length >= 6) return; // üst sınır
    final neglected = _detectNeglectedSubjects(user);
    if (neglected.isEmpty) return;
    final subject = neglected.first;
    final exists = quests.any((q)=> q.tags.contains('neglected') && q.tags.any((t)=> t == 'subject:$subject'));
    if (exists) return;
    final id = 'reengage_${subject.hashCode}';
    if (quests.any((q)=> q.id == id)) return;
    final quest = Quest(
      id: id,
      title: 'Geri Dönüş Operasyonu: $subject',
      description: '$subject cephesini yeniden aktive et. 15 odaklı soru çöz ve temelini tazele.',
      type: QuestType.daily,
      category: QuestCategory.practice,
      progressType: QuestProgressType.increment,
      reward: 55,
      goalValue: 15,
      actionRoute: '/coach',
      route: questRouteFromPath('/coach'),
      tags: ['neglected','subject:$subject','weakness','personal'],
    );
    quests.add(_personalizeQuest(quest, user, analysis));
  }

  List<String> _detectNeglectedSubjects(UserModel user) {
    if (user.topicPerformances.isEmpty) return [];
    final Map<String,int> totals = {};
    user.topicPerformances.forEach((subject, topics) {
      int sum = 0;
      topics.forEach((_, perf) { sum += (perf.correctCount + perf.wrongCount + perf.blankCount); });
      totals[subject] = sum;
    });
    if (totals.isEmpty) return [];
    final maxVal = totals.values.fold<int>(0,(m,v)=> v>m? v:m);
    if (maxVal <= 0) return [];
    final threshold = (maxVal * 0.3).ceil();
    final neglected = totals.entries.where((e)=> e.value>0 && e.value < threshold).map((e)=> e.key).toList();
    neglected.sort((a,b)=> totals[a]!.compareTo(totals[b]!));
    return neglected;
  }

  double _computeRecentPracticeAverage(UserModel user,{int days=7}) {
    if (user.recentPracticeVolumes.isEmpty) return 0;
    final now = DateTime.now();
    int sum = 0; int count = 0;
    user.recentPracticeVolumes.forEach((dateKey, value) {
      final dt = DateTime.tryParse(dateKey);
      if (dt != null) {
        final diff = now.difference(dt).inDays;
        if (diff >=0 && diff < days) {
          sum += value; count++;
        }
      }
    });
    if (sum==0 || count==0) return 0;
    return sum / count;
  }

  // Bugünkü haftalık plan görevlerinden dinamik görev üretici
  void _injectScheduleBasedQuests(UserModel user, List<Quest> quests, {required List<TestModel> tests}) {
    if (user.weeklyPlan == null) return;
    try {
      final weekly = WeeklyPlan.fromJson(user.weeklyPlan!);
      final today = DateTime.now();
      final weekdayIndex = today.weekday - 1; // 0-6
      if (weekdayIndex < 0 || weekdayIndex >= weekly.plan.length) return;
      final todayPlan = weekly.plan[weekdayIndex];
      final dateKey = _dateKey(today);
      final completedIds = user.completedDailyTasks[dateKey] ?? [];

      bool hasTestQuestAlready = quests.any((q) => q.category == QuestCategory.test_submission);

      // Dinlenme günü ise kullanıcıyı yine de etkileşime sokacak hafif bir görev enjekte et
      if (todayPlan.schedule.isEmpty) {
        if (!quests.any((q) => q.id == 'schedule_${dateKey}_rest')) {
          quests.add(_autoTagQuest(Quest(
            id: 'schedule_${dateKey}_rest',
            title: 'Zihinsel Bakım Ritüeli',
            description: 'Dinlenme gününde 10 dakikalık kısa bir odak/plan gözden geçirme seansı yap.',
            type: QuestType.daily,
            category: QuestCategory.engagement,
            progressType: QuestProgressType.increment,
            reward: 35,
            goalValue: 1,
            actionRoute: '/home/pomodoro',
            route: questRouteFromPath('/home/pomodoro'),
          )));
        }
        return; // Dinlenme gününde ekstra program görevi yok.
      }

      for (final item in todayPlan.schedule) {
        final identifier = '${item.time}-${item.activity}';
        if (completedIds.contains(identifier)) continue; // Zaten yapılmış
        // Zaten aynı aktivite için dinamik görev oluşturulmuş mu?
        final questId = 'schedule_${dateKey}_${identifier.hashCode}';
        if (quests.any((q) => q.id == questId)) continue;

        final lower = item.activity.toLowerCase();
        bool isTestLike = lower.contains('deneme') || lower.contains('test') || lower.contains('sim��lasyon');

        if (isTestLike && !hasTestQuestAlready) {
          quests.add(_autoTagQuest(Quest(
            id: questId,
            title: 'Fetih: Günün Denemesi',
            description: 'Programındaki denemeyi çöz ve sonucunu ekleyerek kaleyi raporla.',
            type: QuestType.daily,
            category: QuestCategory.test_submission,
            progressType: QuestProgressType.increment,
            reward: 160,
            goalValue: 1,
            actionRoute: '/home/add-test',
            route: questRouteFromPath('/home/add-test'),
          )));
          hasTestQuestAlready = true;
          continue;
        }

        final category = _mapScheduleTypeToCategory(item.type);
        final reward = _estimateReward(item, category);
        final inferred = _inferRoute(item, isTestLike: isTestLike);
        quests.add(_autoTagQuest(Quest(
          id: questId,
          title: _buildDynamicTitle(item),
          description: 'Bugünkü planındaki "${item.activity}" görevini tamamla.',
          type: QuestType.daily,
          category: category,
          progressType: QuestProgressType.increment,
          reward: reward,
          goalValue: 1,
          actionRoute: inferred,
          route: questRouteFromPath(inferred),
        )));
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[QuestService] Haftalık plan parse hatası: $e');
        debugPrint(st.toString());
      }
    }
  }

  void _normalizeDailyRewards(List<Quest> quests) {
    final user = _ref.read(userProfileProvider).value;
    double difficultyFactor = 1.0;
    if (user != null) {
      final ratio = user.lastScheduleCompletionRatio ?? 0.0;
      if (ratio >= 0.85) difficultyFactor = 0.9; else if (ratio < 0.5) difficultyFactor = 1.15;
      if (user.dailyScheduleStreak >= 6) difficultyFactor *= 1.05;
    }
    _lastDifficultyFactor = difficultyFactor;
    for (var i=0;i<quests.length;i++) {
      final q = quests[i];
      if (q.id.startsWith('schedule_')) {
        final scaled = (q.reward * difficultyFactor).round();
        final newReward = scaled.clamp(10, 999);
        quests[i] = Quest(
          id: q.id,
          title: q.title,
          description: q.description,
          type: q.type,
          category: q.category,
          progressType: q.progressType,
          reward: newReward,
          goalValue: q.goalValue,
          currentProgress: q.currentProgress,
          isCompleted: q.isCompleted,
          actionRoute: q.actionRoute,
          route: q.route,
          completionDate: q.completionDate,
          tags: q.tags,
          difficulty: q.difficulty,
          estimatedMinutes: q.estimatedMinutes,
          prerequisiteIds: q.prerequisiteIds,
          conceptTags: q.conceptTags,
          learningObjectiveId: q.learningObjectiveId,
          chainId: q.chainId,
          chainStep: q.chainStep,
          chainLength: q.chainLength,
        );
      }
    }
    // Programdan gelen görevler id prefix: schedule_
    final scheduleQuests = quests.where((q) => q.id.startsWith('schedule_')).toList();
    if (scheduleQuests.isEmpty) return;
    const int scheduleRewardCap = 300; // Günlük program görevleri toplam tavan
    final int currentSum = scheduleQuests.fold(0, (s, q) => s + q.reward);
    if (currentSum <= scheduleRewardCap) return;
    final double scale = scheduleRewardCap / currentSum;
    for (var i = 0; i < quests.length; i++) {
      final q = quests[i];
      if (q.id.startsWith('schedule_')) {
        // Yeni reward hesaplanıp kopya ile güncellenir.
        final newReward = (q.reward * scale).floor().clamp(10, q.reward); // asgari 10
        quests[i] = Quest(
          id: q.id,
          title: q.title,
          description: q.description,
          type: q.type,
          category: q.category,
          progressType: q.progressType,
          reward: newReward,
          goalValue: q.goalValue,
          currentProgress: q.currentProgress,
          isCompleted: q.isCompleted,
          actionRoute: q.actionRoute,
          route: q.route,
          completionDate: q.completionDate,
          tags: q.tags,
          difficulty: q.difficulty,
          estimatedMinutes: q.estimatedMinutes,
          prerequisiteIds: q.prerequisiteIds,
          conceptTags: q.conceptTags,
          learningObjectiveId: q.learningObjectiveId,
          chainId: q.chainId,
          chainStep: q.chainStep,
          chainLength: q.chainLength,
        );
      }
    }
  }

  // Şablondan görev oluşturucu (eksik olduğu için geri eklendi)
  Quest _createQuestFromTemplate(Map<String, dynamic> template, {Map<String, String>? variables}) {
    String title = template['title'] ?? 'İsimsiz Görev';
    String description = template['description'] ?? 'Açıklama bulunamadı.';
    String actionRoute = template['actionRoute'] ?? '/home';

    if (variables != null) {
      variables.forEach((key, value) {
        title = title.replaceAll(key, value);
        description = description.replaceAll(key, value);
      });
    }

    final rawTags = template['tags'];
    // DEĞİŞTİ: final kaldırıldı ki dinamik subject etiketi eklenebilsin
    List<String> tagList = rawTags is List
        ? rawTags.map((e) => e.toString().split('.').last).toList()
        : <String>[];

    // Yeni: subject değişkeni varsa subject:<Ad> etiketi ekle
    if (variables != null && variables.containsKey('{subject}')) {
      final subj = variables['{subject}'];
      if (subj != null && subj.isNotEmpty) {
        tagList.add('subject:$subj');
      }
    }

    final quest = Quest(
      id: template['id'] ?? const Uuid().v4(),
      title: title,
      description: description,
      type: QuestType.values.byName(template['type'] ?? 'daily'),
      category: QuestCategory.values.byName(template['category'] ?? 'engagement'),
      progressType: QuestProgressType.values.byName(template['progressType'] ?? 'increment'),
      reward: template['reward'] ?? 10,
      goalValue: template['goalValue'] ?? 1,
      actionRoute: actionRoute,
      route: questRouteFromPath(actionRoute),
      tags: tagList,
    );
    return _autoTagQuest(quest);
  }

  QuestCategory _mapScheduleTypeToCategory(String type) {
    switch (type.toLowerCase()) {
      case 'practice':
      case 'soru':
        return QuestCategory.practice;
      case 'test':
      case 'exam':
        return QuestCategory.test_submission;
      case 'focus':
        return QuestCategory.focus;
      case 'analysis': // ayrı enum yok, etkileşim olarak değerlendir
        return QuestCategory.engagement;
      default:
        return QuestCategory.study;
    }
  }

  int _estimateReward(ScheduleItem item, QuestCategory cat) {
    int base;
    switch (cat) {
      case QuestCategory.test_submission: base = 150; break;
      case QuestCategory.practice: base = 60; break;
      case QuestCategory.focus: base = 50; break;
      case QuestCategory.study: base = 45; break;
      case QuestCategory.engagement: base = 40; break;
      case QuestCategory.consistency: base = 35; break;
      default: base = 40; break;
    }
    if (item.activity.length > 25) base += 10;
    return base;
  }

  String _buildDynamicTitle(ScheduleItem item) {
    final lower = item.activity.toLowerCase();
    if (lower.contains('tekrar')) return 'Tekrar Görevi';
    if (lower.contains('deneme')) return 'Planlı Deneme';
    if (lower.contains('test')) return 'Planlı Test';
    if (lower.contains('soru')) return 'Soru Serisi';
    return 'Plan Görevi';
  }

  String _inferRoute(ScheduleItem item, {required bool isTestLike}) {
    if (isTestLike) return '/home/add-test';
    final lower = item.activity.toLowerCase();
    if (lower.contains('pomodoro') || lower.contains('odak')) return '/home/pomodoro';
    if (lower.contains('konu') || lower.contains('soru') || lower.contains('tekrar')) return '/coach';
    return '/home';
  }

  String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // (Önceki sürümden korunmuş yardımcı fonksiyon)
  List<ExamSection> _getRelevantSectionsForUser(UserModel user, Exam exam) {
    if (user.selectedExam == ExamType.lgs.name) {
      return exam.sections;
    } else if (user.selectedExam == ExamType.yks.name) {
      final tytSection = exam.sections.firstWhere((s) => s.name == 'TYT');
      final userAytSection = exam.sections.firstWhere(
        (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      if (tytSection.name == userAytSection.name) return [tytSection];
      return [tytSection, userAytSection];
    } else {
      final relevantSection = exam.sections.firstWhere(
        (s) => s.name == user.selectedExamSection,
        orElse: () => exam.sections.first,
      );
      return [relevantSection];
    }
  }

  String? _computeTodayPlanSignature(UserModel user) {
    if (user.weeklyPlan == null) return null;
    try {
      final weekly = WeeklyPlan.fromJson(user.weeklyPlan!);
      final today = DateTime.now();
      final weekdayIndex = today.weekday - 1; // 0-6
      if (weekdayIndex < 0 || weekdayIndex >= weekly.plan.length) return null;
      final dayName = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'][weekdayIndex];
      final daily = weekly.plan.firstWhere((d) => d.day == dayName, orElse: () => DailyPlan(day: dayName, schedule: []));
      final buffer = StringBuffer();
      for (final s in daily.schedule) {
        buffer.write('${s.time}|${s.activity}|${s.type}||');
      }
      final bytes = utf8.encode(buffer.toString());
      return md5.convert(bytes).toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _maybeGenerateWeeklyReport(UserModel user, DateTime now) async {
    if (user.weeklyPlan == null) return;
    // Haftanın pazartesi başlangıcı
    DateTime startOfWeek(DateTime d){return d.subtract(Duration(days: d.weekday-1));}
    final thisWeekStart = startOfWeek(now);
    final lastReport = user.lastWeeklyReport;
    if (lastReport != null) {
      final lastWeekStartStr = lastReport['weekStart'] as String?;
      if (lastWeekStartStr != null) {
        final lastWeekStart = DateTime.tryParse(lastWeekStartStr);
        if (lastWeekStart != null && lastWeekStart.isAtSameMomentAs(thisWeekStart)) return; // aynı hafta
      }
    }
    // Sadece haftanın ilk günü (Pazartesi) veya ilk girişte üret
    if (now.weekday != DateTime.monday && lastReport != null) return;

    try {
      final weekly = WeeklyPlan.fromJson(user.weeklyPlan!);
      int planned = 0; int completed = 0; Map<String,int> dayPlanned = {}; Map<String,int> dayCompleted = {};
      for (int i=0;i<weekly.plan.length;i++) {
        final dp = weekly.plan[i];
        planned += dp.schedule.length;
        dayPlanned[dp.day] = dp.schedule.length;
        // Tarih hesapla
        final date = thisWeekStart.add(Duration(days: i));
        final key = _dateKey(date);
        final compList = user.completedDailyTasks[key] ?? [];
        completed += compList.length;
        dayCompleted[dp.day] = compList.length;
      }
      double overallRate = planned>0? completed/planned : 0.0;
      String topDay = '';
      String lowDay = '';
      double bestRate = -1; double worstRate = 2;
      dayPlanned.forEach((day, p){
        final c = dayCompleted[day] ?? 0;
        final r = p>0? c/p:0.0;
        if (r>bestRate){bestRate=r; topDay=day;}
        if (r<worstRate){worstRate=r; lowDay=day;}
      });
      final report = {
        'weekStart': _dateKey(thisWeekStart),
        'planned': planned,
        'completed': completed,
        'overallRate': overallRate,
        'topDay': topDay,
        'topRate': bestRate,
        'lowDay': lowDay,
        'lowRate': worstRate,
        'generatedAt': DateTime.now().toIso8601String(),
      };
      await _ref.read(firestoreServiceProvider).usersCollection.doc(user.id).update({'lastWeeklyReport': report});
    } catch(_) {}
  }

  Quest _autoTagQuest(Quest q) {
    final newTags = Set<String>.from(q.tags);
    if (q.reward >= 120) newTags.add('high_value');
    if (q.difficulty == QuestDifficulty.hard || q.difficulty == QuestDifficulty.epic) newTags.add('high_value');
    if (q.reward < 30 && q.goalValue <= 2) newTags.add('quick_win');
    if ((q.estimatedMinutes != null && q.estimatedMinutes! <= 5) || (q.goalValue == 1 && q.reward <= 25)) newTags.add('micro');
    if (q.category == QuestCategory.focus) newTags.add('focus');
    // plan programı görevleri
    if (q.id.startsWith('schedule_')) newTags.add('plan');
    if (newTags.difference(q.tags.toSet()).isEmpty) return q; // değişiklik yok
    return q.copyWith(tags: newTags.toList());
  }
}

final dailyQuestsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];
  final questService = ref.read(questServiceProvider);
  final result = await questService.refreshDailyQuestsForUser(user).catchError((e){
    if (kDebugMode) debugPrint('[dailyQuestsProvider] hata: $e');
    return user.activeDailyQuests; // fallback
  });
  return result;
});
