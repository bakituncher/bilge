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

    // 2. ŞABLONLARI HAZIRLA
    List<Map<String, dynamic>> availableQuestTemplates = List.from(questArmory);
    availableQuestTemplates.shuffle();
    availableQuestTemplates.removeWhere((template) => user.activeDailyQuests.any((q) => q.id == template['id']));

    // Gün içi plan tamamlama ve kategori bilgisi
    final todayKey = _dateKey(DateTime.now());
    final todayCompletedPlanTasks = user.completedDailyTasks[todayKey]?.length ?? 0;

    // Önceki gün plan oranı
    final yesterday = DateTime.now().subtract(const Duration(days:1));
    final yesterdayRatio = user.lastScheduleCompletionRatio ?? 0.0;
    final wasInactiveYesterday = !(user.dailyVisits.any((ts){ final d=ts.toDate(); return d.year==yesterday.year && d.month==yesterday.month && d.day==yesterday.day; }));

    // Mevcut tamamlanan quest kategorileri (günün)
    final completedCategories = user.activeDailyQuests.where((q) => q.isCompleted).map((q) => q.category).toSet();

    // 3. PUANLAMA
    final List<({Map<String, dynamic> template, int score, Map<String, String> variables})> scoredQuests = [];
    for (var template in availableQuestTemplates) {
      int score = 100;
      Map<String, String> variables = {};
      final triggers = (template['triggerConditions'] as Map<String,dynamic>?) ?? {};

      // Özel yeni tetikleyiciler
      if (triggers.containsKey('wasInactiveYesterday') && triggers['wasInactiveYesterday']==true && !wasInactiveYesterday) { score = 0; }
      if (triggers.containsKey('lowYesterdayPlanRatio') && triggers['lowYesterdayPlanRatio']==true && !(yesterdayRatio < 0.5)) { score = 0; }
      if (triggers.containsKey('highYesterdayPlanRatio') && triggers['highYesterdayPlanRatio']==true && !(yesterdayRatio >= 0.85)) { score = 0; }
      if (triggers.containsKey('afterQuest')) {
        final prevId = triggers['afterQuest'];
        final prevQuest = user.activeDailyQuests.firstWhere((q)=>q.id==prevId, orElse: ()=>Quest(id:'',title:'',description:'',type:QuestType.daily,category:QuestCategory.engagement,progressType:QuestProgressType.increment,reward:0,goalValue:1,actionRoute:'/', route: QuestRoute.unknown));
        if (prevQuest.id.isEmpty || !prevQuest.isCompleted) { score = 0; }
      }
      if (triggers.containsKey('comboEligible') && triggers['comboEligible']==true && !(todayCompletedPlanTasks >= 2)) { score = 0; }
      if (triggers.containsKey('multiCategoryDay') && triggers['multiCategoryDay']==true && !(completedCategories.length >=2 && completedCategories.length <4)) { score = 0; }
      if (triggers.containsKey('streakAtRisk') && triggers['streakAtRisk']==true) {
        // risk: streak var (>0) ve bugün henüz plan görevi yapılmamış
        final risk = user.dailyScheduleStreak>0 && todayCompletedPlanTasks==0;
        if(!risk) score = 0;
      }
      if (triggers.containsKey('reflectionNotDone') && triggers['reflectionNotDone']==true) {
        // Şimdilik her zaman uygun varsay (ileride not kaydı ile değiştirilebilir)
      }

      // Eski tetikleyiciler (zayıf/güçlü/deneme vb.) zaten önceki mantıkta işleniyor
      if (template['triggerConditions'] is Map) {
        final conditions = template['triggerConditions'] as Map<String, dynamic>;
        if (conditions['hasWeakSubject'] == true) {
          if (analysis?.weakestSubjectByNet != null && analysis!.weakestSubjectByNet != "Belirlenemedi") {
            score += 250; variables['{subject}'] = analysis.weakestSubjectByNet;
          } else { score = 0; }
        }
        if (conditions['hasStrongSubject'] == true) {
          if (analysis?.strongestSubjectByNet != null && analysis!.strongestSubjectByNet != "Belirlenemedi") {
            score += 100; variables['{subject}'] = analysis.strongestSubjectByNet;
          } else { score = 0; }
        }
        if (conditions['noRecentTest'] == true) {
          final lastTestDate = tests.isNotEmpty ? tests.first.date : null;
            if (lastTestDate == null || DateTime.now().difference(lastTestDate).inDays > 3) {
              score += 200;
            } else { score = 0; }
        }
      }

      if (score > 0) {
        scoredQuests.add((template: template, score: score, variables: variables));
      }
    }
    scoredQuests.sort((a, b) => b.score.compareTo(a.score));

    // 4. SEÇİM
    final Set<QuestCategory> selectedCategories = {};
    while (generatedQuests.length < 5 && scoredQuests.isNotEmpty) {
      final candidate = scoredQuests.removeAt(0);
      if (selectedCategories.contains(QuestCategory.values.byName(candidate.template['category']))) {
        if (random.nextDouble() > 0.6) continue;
      }
      generatedQuests.add(_createQuestFromTemplate(candidate.template, variables: candidate.variables));
      selectedCategories.add(QuestCategory.values.byName(candidate.template['category']));
    }

    // 5. HAFTALIK PLAN ENTEGRASYONU (KALE GÜÇLENDİRME)
    _injectScheduleBasedQuests(user, generatedQuests, tests: tests);

    // Günlük ödül dengesini (özellikle programdan gelen görevler) normalize et.
    _normalizeDailyRewards(generatedQuests);

    return generatedQuests;
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
