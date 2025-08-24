// lib/data/repositories/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/features/weakness_workshop/models/saved_workshop_model.dart';
import 'package:bilge_ai/data/models/plan_model.dart';
import 'package:bilge_ai/data/models/plan_document.dart';
import 'package:bilge_ai/data/models/performance_summary.dart';
import 'package:bilge_ai/data/models/app_state.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart';
import 'package:bilge_ai/features/quests/models/quest_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  FirestoreService(this._firestore);

  String sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[.\s\(\)]'), '_');
  }

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  CollectionReference<Map<String, dynamic>> get usersCollection => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _leaderboardsCollection => _firestore.collection('leaderboards');
  CollectionReference<Map<String, dynamic>> get _testsCollection => _firestore.collection('tests');
  CollectionReference<Map<String, dynamic>> get _focusSessionsCollection => _firestore.collection('focusSessions');

  // YENI: Kullanıcı aktivite alt koleksiyonu
  CollectionReference<Map<String, dynamic>> _userActivityCollection(String userId) => usersCollection.doc(userId).collection('user_activity');
  DocumentReference<Map<String, dynamic>> _userActivityMonthlyDoc(String userId, DateTime date) {
    final id = '${date.year.toString().padLeft(4, '0')}_${date.month.toString().padLeft(2, '0')}';
    return _userActivityCollection(userId).doc(id);
  }

  String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> getActivityMonth(String userId, DateTime date) async {
    final snap = await _userActivityMonthlyDoc(userId, date).get();
    return snap.data() ?? <String, dynamic>{};
  }

  Future<List<String>> getCompletedTasksForDate(String userId, DateTime date) async {
    final data = await getActivityMonth(userId, date);
    final String dk = _dateKey(date);
    final completedTasks = data['completedTasks'] as Map<String, dynamic>?;
    if (completedTasks == null) return const [];
    final v = completedTasks[dk];
    if (v is List) return List<String>.from(v);
    return const [];
  }

  Future<List<Timestamp>> getVisitsForMonth(String userId, DateTime date) async {
    final data = await getActivityMonth(userId, date);
    final v = data['visits'];
    if (v is List) {
      return v.whereType<Timestamp>().toList();
    }
    return const [];
  }

  Future<Map<String, int>> getPracticeVolumesForMonth(String userId, DateTime date) async {
    final data = await getActivityMonth(userId, date);
    final mv = data['practiceVolumes'];
    if (mv is Map<String, dynamic>) {
      return mv.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    }
    return const {};
  }

  Future<void> incrementPracticeVolume(String userId, {required DateTime date, required int delta}) async {
    final monthRef = _userActivityMonthlyDoc(userId, date);
    final key = _dateKey(date);
    await monthRef.set({
      'practiceVolumes.$key': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordUserVisit(String userId, {Timestamp? at}) async {
    final nowTs = at ?? Timestamp.now();
    final now = nowTs.toDate();
    final monthRef = _userActivityMonthlyDoc(userId, now);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(monthRef);
      final data = snap.data() ?? <String, dynamic>{};
      final List<dynamic> visitsRaw = List<dynamic>.from(data['visits'] ?? const []);
      // Sadece bugünkü ziyaretleri koru, 1 saat kuralını uygula
      DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
      final todayStart = startOfDay(now);
      final filtered = visitsRaw.whereType<Timestamp>().where((ts) {
        final d = ts.toDate();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList()
        ..sort((a, b) => a.compareTo(b));
      if (filtered.isEmpty || now.difference(filtered.last.toDate()).inHours >= 1) {
        filtered.add(nowTs);
      }
      // Ay içindeki eski günlere ait ziyaretleri de tutmak serbest; sadece bugünkü listeyi güncelliyoruz
      // Tüm ziyaret listesini yeniden oluştur: bugünkü filtreli + bugun dışı eski kayıtlar
      final others = visitsRaw.whereType<Timestamp>().where((ts) {
        final d = ts.toDate();
        return d.isBefore(todayStart) || d.isAfter(todayStart.add(const Duration(days: 1)));
      }).toList();
      final updated = <Timestamp>[...others, ...filtered];
      txn.set(monthRef, {
        'visits': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  DocumentReference<Map<String, dynamic>> _planDoc(String userId) => usersCollection.doc(userId).collection('plans').doc('current_plan');
  DocumentReference<Map<String, dynamic>> _performanceDoc(String userId) => usersCollection.doc(userId).collection('performance').doc('summary');
  DocumentReference<Map<String, dynamic>> _appStateDoc(String userId) => usersCollection.doc(userId).collection('state').doc('app_state');
  DocumentReference<Map<String, dynamic>> _leaderboardUserDoc({required String examType, required String userId}) => _leaderboardsCollection.doc(examType).collection('users').doc(userId);

  Future<void> _syncLeaderboardUser(String userId, {String? targetExam}) async {
    final userSnap = await usersCollection.doc(userId).get();
    if (!userSnap.exists) return;
    final data = userSnap.data()!;
    final String? examType = targetExam ?? data['selectedExam'] as String?;
    if (examType == null) return;

    final docRef = _leaderboardUserDoc(examType: examType, userId: userId);
    await docRef.set({
      'userId': userId,
      'userName': data['name'],
      'score': data['engagementScore'] ?? 0,
      'testCount': data['testCount'] ?? 0,
      'avatarStyle': data['avatarStyle'],
      'avatarSeed': data['avatarSeed'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserAvatar({
    required String userId,
    required String style,
    required String seed,
  }) async {
    final userDocRef = usersCollection.doc(userId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(userDocRef);
      final data = snap.data();
      final String? examType = data?['selectedExam'];
      txn.update(userDocRef, {
        'avatarStyle': style,
        'avatarSeed': seed,
      });
      if (examType != null) {
        final lbRef = _leaderboardUserDoc(examType: examType, userId: userId);
        txn.set(lbRef, {
          'avatarStyle': style,
          'avatarSeed': seed,
          'userId': userId,
          'userName': data?['name'],
          'score': data?['engagementScore'] ?? 0,
          'testCount': data?['testCount'] ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> saveWorkshopForUser(String userId, SavedWorkshopModel workshop) async {
    final userDocRef = usersCollection.doc(userId);
    final workshopCollectionRef = userDocRef.collection('savedWorkshops');
    await workshopCollectionRef.doc(workshop.id).set(workshop.toMap());
  }

  Stream<List<SavedWorkshopModel>> getSavedWorkshops(String userId) {
    return usersCollection
        .doc(userId)
        .collection('savedWorkshops')
        .orderBy('savedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SavedWorkshopModel.fromSnapshot(doc)).toList());
  }

  Future<void> createUserProfile(User user, String name) async {
    final userProfile = UserModel(id: user.uid, email: user.email!, name: name, tutorialCompleted: false);
    await usersCollection.doc(user.uid).set(userProfile.toJson());
    await _appStateDoc(user.uid).set(AppState().toMap(), SetOptions(merge: true));
    await _planDoc(user.uid).set(PlanDocument().toMap(), SetOptions(merge: true));
    await _performanceDoc(user.uid).set(const PerformanceSummary().toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserName({required String userId, required String newName}) async {
    final userDocRef = usersCollection.doc(userId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(userDocRef);
      final data = snap.data();
      final String? examType = data?['selectedExam'];
      txn.update(userDocRef, {'name': newName});
      if (examType != null) {
        final lbRef = _leaderboardUserDoc(examType: examType, userId: userId);
        txn.set(lbRef, {
          'userId': userId,
          'userName': newName,
          'score': data?['engagementScore'] ?? 0,
          'testCount': data?['testCount'] ?? 0,
          'avatarStyle': data?['avatarStyle'],
          'avatarSeed': data?['avatarSeed'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> markTutorialAsCompleted(String userId) async {
    await _appStateDoc(userId).set({'tutorialCompleted': true}, SetOptions(merge: true));
    await usersCollection.doc(userId).update({'tutorialCompleted': true});
  }

  Future<void> updateOnboardingData({
    required String userId,
    required String goal,
    required List<String> challenges,
    required double weeklyStudyGoal,
  }) async {
    await usersCollection.doc(userId).update({
      'goal': goal,
      'challenges': challenges,
      'weeklyStudyGoal': weeklyStudyGoal,
    });
    await _appStateDoc(userId).set({'onboardingCompleted': true}, SetOptions(merge: true));
    await usersCollection.doc(userId).update({'onboardingCompleted': true});
  }

  Stream<UserModel> getUserProfile(String userId) {
    return usersCollection.doc(userId).snapshots().map((doc) => UserModel.fromSnapshot(doc));
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await usersCollection.doc(userId).get();
    if(doc.exists) {
      return UserModel.fromSnapshot(doc);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await usersCollection.get();
    return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
  }

  Future<void> updateEngagementScore(String userId, int pointsToAdd) async {
    final userDocRef = usersCollection.doc(userId);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDocRef);
      final data = userSnapshot.data();
      final String? examType = data?['selectedExam'];
      transaction.update(userDocRef, {'engagementScore': FieldValue.increment(pointsToAdd)});
      if (examType != null) {
        final lbRef = _leaderboardUserDoc(examType: examType, userId: userId);
        transaction.set(lbRef, {
          'userId': userId,
          'userName': data?['name'],
          'score': FieldValue.increment(pointsToAdd),
          'testCount': data?['testCount'] ?? 0,
          'avatarStyle': data?['avatarStyle'],
          'avatarSeed': data?['avatarSeed'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> addTestResult(TestModel test) async {
    final userDocRef = usersCollection.doc(test.userId);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDocRef);
      if (!userSnapshot.exists) throw Exception("Kullanıcı bulunamadı!");
      final user = UserModel.fromSnapshot(userSnapshot);
      final newTestRef = _testsCollection.doc();
      transaction.set(newTestRef, test.toJson());
      transaction.update(userDocRef, {
        'testCount': FieldValue.increment(1),
        'totalNetSum': FieldValue.increment(test.totalNet),
      });
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastUpdate = user.lastStreakUpdate;
      if (lastUpdate == null) {
        transaction.update(userDocRef, {'streak': 1, 'lastStreakUpdate': Timestamp.fromDate(today)});
      } else {
        final lastUpdateDate = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
        if (!today.isAtSameMomentAs(lastUpdateDate)) {
          final yesterday = today.subtract(const Duration(days: 1));
          if (lastUpdateDate.isAtSameMomentAs(yesterday)) {
            transaction.update(userDocRef, {'streak': FieldValue.increment(1), 'lastStreakUpdate': Timestamp.fromDate(today)});
          } else {
            transaction.update(userDocRef, {'streak': 1, 'lastStreakUpdate': Timestamp.fromDate(today)});
          }
        }
      }
    });
    await updateEngagementScore(test.userId, 50);
  }

  Stream<List<TestModel>> getTestResults(String userId) {
    return _testsCollection.where('userId', isEqualTo: userId).orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => TestModel.fromSnapshot(doc)).toList());
  }

  Future<List<TestModel>> getTestResultsOnce(String userId) async {
    final qs = await _testsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return qs.docs.map((d) => TestModel.fromSnapshot(d)).toList();
  }

  Future<void> saveExamSelection({
    required String userId,
    required ExamType examType,
    required String sectionName,
  }) async {
    final userDocRef = usersCollection.doc(userId);
    await _firestore.runTransaction((txn) async {
      final prevSnap = await txn.get(userDocRef);
      final prevData = prevSnap.data();
      final String? prevExam = prevData?['selectedExam'];

      txn.update(userDocRef, {
        'selectedExam': examType.name,
        'selectedExamSection': sectionName,
      });

      if (prevExam != null && prevExam != examType.name) {
        final oldLbRef = _leaderboardUserDoc(examType: prevExam, userId: userId);
        txn.delete(oldLbRef);
      }

      final newLbRef = _leaderboardUserDoc(examType: examType.name, userId: userId);
      txn.set(newLbRef, {
        'userId': userId,
        'userName': prevData?['name'],
        'score': prevData?['engagementScore'] ?? 0,
        'testCount': prevData?['testCount'] ?? 0,
        'avatarStyle': prevData?['avatarStyle'],
        'avatarSeed': prevData?['avatarSeed'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<PlanDocument?> getPlansStream(String userId) {
    return _planDoc(userId).snapshots().map((doc) => doc.exists ? PlanDocument.fromSnapshot(doc) : null);
  }

  Stream<PerformanceSummary?> getPerformanceStream(String userId) {
    return _performanceDoc(userId).snapshots().map((doc) => doc.exists ? PerformanceSummary.fromSnapshot(doc) : null);
  }

  Stream<AppState?> getAppStateStream(String userId) {
    return _appStateDoc(userId).snapshots().map((doc) => doc.exists ? AppState.fromSnapshot(doc) : null);
  }

  Future<void> updateTopicPerformance({
    required String userId,
    required String subject,
    required String topic,
    required TopicPerformanceModel performance,
  }) async {
    final sanitizedSubject = sanitizeKey(subject);
    final sanitizedTopic = sanitizeKey(topic);
    // Önce update ile iç içe alanı doğrudan güncelle (nokta notasyonu destekli)
    try {
      await _performanceDoc(userId).update({
        'topicPerformances.$sanitizedSubject.$sanitizedTopic': performance.toMap(),
      });
    } on FirebaseException catch (e) {
      // Eğer özet dokümanı yoksa, merge set ile oluşturup ilgili alanı yaz
      if (e.code == 'not-found') {
        await _performanceDoc(userId).set({
          'topicPerformances': {
            sanitizedSubject: {
              sanitizedTopic: performance.toMap(),
            }
          }
        }, SetOptions(merge: true));
      } else {
        rethrow;
      }
    }
  }

  Future<void> addFocusSession(FocusSessionModel session) async {
    await _focusSessionsCollection.add(session.toMap());
    await updateEngagementScore(session.userId, 25);
  }

  Future<void> updateDailyTaskCompletion({
    required String userId,
    required String dateKey,
    required String task,
    required bool isCompleted,
  }) async {
    final userDocRef = usersCollection.doc(userId);
    final date = DateTime.parse(dateKey);
    final monthDocRef = _userActivityMonthlyDoc(userId, date);
    final fieldPath = 'completedTasks.$dateKey';

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(userDocRef);
      if(!snap.exists) return;
      final user = UserModel.fromSnapshot(snap);
      final planDoc = await txn.get(_planDoc(userId));
      final planData = planDoc.data();

      // Aylık aktivite dokümanından o güne ait mevcut tamamlananlar
      final monthSnap = await txn.get(monthDocRef);
      final monthData = monthSnap.data() ?? <String, dynamic>{};
      final Map<String, dynamic> completedMap = Map<String, dynamic>.from(monthData['completedTasks'] ?? {});
      final List<String> completedList = List<String>.from(completedMap[dateKey] ?? const <String>[]);

      final updates = <String,dynamic>{};
      // Kullanıcı kök dokümanında skor ve diğer anlık metaları koruyoruz
      if(isCompleted) {
        txn.set(monthDocRef, { fieldPath: FieldValue.arrayUnion([task]) }, SetOptions(merge: true));
        updates['engagementScore'] = FieldValue.increment(10);
      } else {
        txn.set(monthDocRef, { fieldPath: FieldValue.arrayRemove([task]) }, SetOptions(merge: true));
        updates['engagementScore'] = FieldValue.increment(-10);
      }

      final today = DateTime.now();
      final todayKey = _dateKey(today);

      if(dateKey != todayKey && isCompleted) {
        updates['dailyScheduleStreak'] = 0;
      }

      if(isCompleted) {
        int currentStreak = user.dailyScheduleStreak;
        currentStreak += 1;
        updates['dailyScheduleStreak'] = currentStreak;

        const momentumThresholds = [3,6,9];
        if(momentumThresholds.contains(currentStreak)) {
          final bonus = 15;
          updates['engagementScore'] = FieldValue.increment(bonus);
        }

        final projectedCompleted = {...completedList}.length + 1;

        int totalForDay = 0;
        if(planData != null && planData['weeklyPlan'] != null) {
          try {
            final weekly = WeeklyPlan.fromJson(planData['weeklyPlan']);
            final dp = weekly.plan.firstWhere((d) => d.day == _weekdayName(DateTime.parse(dateKey).weekday), orElse: () => DailyPlan(day: '', schedule: []));
            totalForDay = dp.schedule.length;
          } catch(_){ totalForDay = 0; }
        }
        if(totalForDay > 0) {
          final ratio = projectedCompleted / totalForDay;
          final thresholds = [0.6,0.8,1.0];
          final givenList = List<int>.from((snap.data()?['dailyPlanBonuses'] ?? const {})[dateKey] ?? const <int>[]);
          for(int i=0;i<thresholds.length;i++) {
            if(ratio >= thresholds[i] && !givenList.contains(i)) {
              int extra = (i==0?25:(i==1?35:60));
              updates['engagementScore'] = FieldValue.increment(extra);
              givenList.add(i);
            }
          }
          updates['dailyPlanBonuses.$dateKey'] = givenList;
        }
      }

      if(isCompleted && dateKey == todayKey) {
        final yesterday = today.subtract(const Duration(days:1));
        final yKey = _dateKey(yesterday);
        // Dünkü tamamlananları aylık aktiviteden al
        final yMonthSnap = await txn.get(_userActivityMonthlyDoc(userId, yesterday));
        final yData = yMonthSnap.data() ?? <String, dynamic>{};
        final yMap = Map<String, dynamic>.from(yData['completedTasks'] ?? {});
        if(user.lastScheduleCompletionRatio == null || (List.from(yMap[yKey] ?? const <String>[])).isNotEmpty) {
          if(planData != null && planData['weeklyPlan'] != null) {
            try {
              final weekly = WeeklyPlan.fromJson(planData['weeklyPlan']);
              final dpY = weekly.plan.firstWhere((d) => d.day == _weekdayName(yesterday.weekday), orElse: () => DailyPlan(day: '', schedule: []));
              final totalY = dpY.schedule.length;
              if(totalY>0) {
                final compY = (List.from(yMap[yKey] ?? const <String>[])).length;
                final ratioY = compY/totalY;
                updates['lastScheduleCompletionRatio'] = ratioY;
              }
            } catch(_){ }
          }
        }
      }

      txn.update(userDocRef, updates);

      final String? examType = user.selectedExam;
      if (examType != null) {
        final lbRef = _leaderboardUserDoc(examType: examType, userId: userId);
        txn.set(lbRef, {
          'userId': userId,
          'userName': user.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    await _syncLeaderboardUser(userId);
  }

  Future<void> updateWeeklyAvailability({
    required String userId,
    required Map<String, List<String>> availability,
  }) async {
    await usersCollection.doc(userId).update({
      'weeklyAvailability': availability,
    });
  }

  Future<void> updateStrategicPlan({
    required String userId,
    required String pacing,
    required String longTermStrategy,
    required Map<String, dynamic> weeklyPlan,
  }) async {
    await _planDoc(userId).set({
      'studyPacing': pacing,
      'longTermStrategy': longTermStrategy,
      'weeklyPlan': weeklyPlan,
    }, SetOptions(merge: true));
    await updateEngagementScore(userId, 100);
  }

  Future<void> markTopicAsMastered({required String userId, required String subject, required String topic}) async {
    final sanitizedSubject = sanitizeKey(subject);
    final sanitizedTopic = sanitizeKey(topic);
    final uniqueIdentifier = '$sanitizedSubject-$sanitizedTopic';
    await _performanceDoc(userId).set({
      'masteredTopics': FieldValue.arrayUnion([uniqueIdentifier])
    }, SetOptions(merge: true));
  }

  Future<void> resetUserDataForNewExam(String userId) async {
    final WriteBatch batch = _firestore.batch();
    final userDocRef = usersCollection.doc(userId);
    batch.update(userDocRef, {
      'onboardingCompleted': false,
      'tutorialCompleted': false,
      'selectedExam': null,
      'selectedExamSection': null,
      'testCount': 0,
      'totalNetSum': 0.0,
      'engagementScore': 0,
      'completedDailyTasks': {},
      'weeklyAvailability': {},
      'goal': null,
      'challenges': [],
      'weeklyStudyGoal': null,
      'streak': 0,
      'lastStreakUpdate': null,
    });
    batch.set(_performanceDoc(userId), const PerformanceSummary().toMap());
    batch.set(_planDoc(userId), PlanDocument().toMap());

    final testsSnapshot = await _testsCollection.where('userId', isEqualTo: userId).get();
    for (final doc in testsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final focusSnapshot = await _focusSessionsCollection.where('userId', isEqualTo: userId).get();
    for (final doc in focusSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // YENI: user_activity alt koleksiyonunu temizle
    final activitySnap = await _userActivityCollection(userId).get();
    for (final doc in activitySnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<LeaderboardEntry>> getLeaderboardUsers(String examType) async {
    final snapshot = await _leaderboardsCollection
        .doc(examType)
        .collection('users')
        .orderBy('score', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return LeaderboardEntry(
        userId: data['userId'] ?? doc.id,
        userName: (data['userName'] ?? '') as String,
        score: (data['score'] ?? 0) as int,
        testCount: (data['testCount'] ?? 0) as int,
        avatarStyle: data['avatarStyle'] as String?,
        avatarSeed: data['avatarSeed'] as String?,
      );
    }).where((e) => e.userName.isNotEmpty).toList();
  }

  CollectionReference<Map<String, dynamic>> dailyQuestsCollection(String userId) => usersCollection.doc(userId).collection('daily_quests');

  Stream<List<Quest>> streamDailyQuests(String userId) {
    return dailyQuestsCollection(userId)
        .orderBy('qid')
        .snapshots()
        .map((qs) => qs.docs.map((d) => Quest.fromMap(d.data(), d.id)).toList());
  }

  Future<List<Quest>> getDailyQuestsOnce(String userId) async {
    final qs = await dailyQuestsCollection(userId).orderBy('qid').get();
    return qs.docs.map((d) => Quest.fromMap(d.data(), d.id)).toList();
  }

  Future<void> replaceAllDailyQuests(String userId, List<Quest> quests) async {
    final col = dailyQuestsCollection(userId);
    final batch = _firestore.batch();
    final existing = await col.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final q in quests) {
      batch.set(col.doc(q.id), q.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> upsertQuest(String userId, Quest quest) async {
    await dailyQuestsCollection(userId).doc(quest.id).set(quest.toMap(), SetOptions(merge: true));
  }

  Future<void> updateQuestFields(String userId, String questId, Map<String, dynamic> fields) async {
    await dailyQuestsCollection(userId).doc(questId).update(fields);
  }

  Future<void> batchUpdateQuestFields(String userId, Map<String, Map<String, dynamic>> updates, {int? engagementDelta}) async {
    final batch = _firestore.batch();
    final userDocRef = usersCollection.doc(userId);
    updates.forEach((questId, fields) {
      batch.update(dailyQuestsCollection(userId).doc(questId), fields);
    });
    if (engagementDelta != null && engagementDelta != 0) {
      batch.update(userDocRef, {'engagementScore': FieldValue.increment(engagementDelta)});
    }
    await batch.commit();
  }

  // ISTEGE BAGLI: Tek kullanımlık migrate yardımcısı. Client tarafında sadece tek kullanıcı için güvenli.
  Future<void> migrateActiveDailyQuestsForUser(String userId) async {
    final userDoc = await usersCollection.doc(userId).get();
    if (!userDoc.exists) return;
    final data = userDoc.data()!;
    if (data['activeDailyQuests'] is! List) return;
    final List active = data['activeDailyQuests'];
    final List<Quest> quests = [];
    for (final e in active) {
      if (e is Map<String, dynamic>) {
        final dynamic rawId = e['qid'] ?? e['id'];
        if (rawId != null) {
          quests.add(Quest.fromMap(e, rawId.toString()));
        }
      }
    }
    if (quests.isEmpty) return;
    await replaceAllDailyQuests(userId, quests);
    // Alanı temizle
    await usersCollection.doc(userId).update({'activeDailyQuests': FieldValue.delete()});
  }

  String _weekdayName(int weekday) {
    const list = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return list[(weekday-1).clamp(0,6)];
  }
}