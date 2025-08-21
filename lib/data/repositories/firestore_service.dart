// lib/data/repositories/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/models/exam_model.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';
import 'package:bilge_ai/data/models/focus_session_model.dart';
import 'package:bilge_ai/features/weakness_workshop/models/saved_workshop_model.dart';
import 'package:bilge_ai/data/models/plan_model.dart'; // WeeklyPlan & DailyPlan için eklendi

class FirestoreService {
  final FirebaseFirestore _firestore;
  FirestoreService(this._firestore);

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[.\s\(\)]'), '_');
  }

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // --- HATA DÜZELTMESİ: GÖREV MOTORUNUN ERİŞEBİLMESİ İÇİN PUBLIC HALE GETİRİLDİ ---
  CollectionReference<Map<String, dynamic>> get usersCollection => _firestore.collection('users');
  // ------------------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _testsCollection => _firestore.collection('tests');
  CollectionReference<Map<String, dynamic>> get _focusSessionsCollection => _firestore.collection('focusSessions');

  // YENİ EKLENEN FONKSİYONLAR: CEVHER ATÖLYESİ İÇİN
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
  //---------------------------------------------------------

  Future<void> createUserProfile(User user, String name) async {
    final userProfile = UserModel(id: user.uid, email: user.email!, name: name, tutorialCompleted: false);
    await usersCollection.doc(user.uid).set(userProfile.toJson());
  }

  Future<void> updateUserName({required String userId, required String newName}) async {
    await usersCollection.doc(userId).update({'name': newName});
  }

  Future<void> markTutorialAsCompleted(String userId) async {
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
      'onboardingCompleted': true,
    });
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
    await userDocRef.update({'engagementScore': FieldValue.increment(pointsToAdd)});
  }

  Future<void> addTestResult(TestModel test) async {
    final userDocRef = usersCollection.doc(test.userId);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDocRef);
      if (!userSnapshot.exists) throw Exception("Kullanıcı bulunamadı!");
      final user = UserModel.fromSnapshot(userSnapshot as DocumentSnapshot<Map<String, dynamic>>);
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

  Future<void> saveExamSelection({
    required String userId,
    required ExamType examType,
    required String sectionName,
  }) async {
    await usersCollection.doc(userId).update({
      'selectedExam': examType.name,
      'selectedExamSection': sectionName,
    });
  }

  Future<void> updateTopicPerformance({
    required String userId,
    required String subject,
    required String topic,
    required TopicPerformanceModel performance,
  }) async {
    final userDocRef = usersCollection.doc(userId);
    final sanitizedSubject = _sanitizeKey(subject);
    final sanitizedTopic = _sanitizeKey(topic);
    final fieldPath = 'topicPerformances.$sanitizedSubject.$sanitizedTopic';
    await userDocRef.update({
      fieldPath: performance.toMap(),
    });
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
    final fieldPath = 'completedDailyTasks.$dateKey';

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(userDocRef);
      if(!snap.exists) return;
      final user = UserModel.fromSnapshot(snap as DocumentSnapshot<Map<String,dynamic>>);

      // Temel tamamlama / geri alma
      final updates = <String,dynamic>{};
      if(isCompleted) {
        updates[fieldPath] = FieldValue.arrayUnion([task]);
        updates['engagementScore'] = FieldValue.increment(10);
      } else {
        updates[fieldPath] = FieldValue.arrayRemove([task]);
        updates['engagementScore'] = FieldValue.increment(-10);
      }

      // Tarih hesapları
      final today = DateTime.now();
      final todayKey = '${today.year.toString().padLeft(4,'0')}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      // Gün değiştiyse momentum sıfırla
      if(dateKey != todayKey && isCompleted) {
        updates['dailyScheduleStreak'] = 0;
      }

      // Momentum ve bonuslar sadece tamamlanırken
      if(isCompleted) {
        // Günlük momentum
        int currentStreak = user.dailyScheduleStreak;
        currentStreak += 1;
        updates['dailyScheduleStreak'] = currentStreak;

        // Momentum eşikleri (3,6,9)
        const momentumThresholds = [3,6,9];
        if(momentumThresholds.contains(currentStreak)) {
          final bonus = 15; // sabit mini bonus
          updates['engagementScore'] = FieldValue.increment(bonus);
        }

        // Gün içi plan görevi sayıları
        final completedList = List<String>.from(user.completedDailyTasks[dateKey] ?? []);
        final projectedCompleted = {...completedList}.length + 1; // bu görev ekleniyor

        // Günün toplam plan görevi sayısı -> weeklyPlan üzerinden bulunur
        int totalForDay = 0;
        if(user.weeklyPlan != null) {
          try {
            final weekly = WeeklyPlan.fromJson(user.weeklyPlan!);
            final dp = weekly.plan.firstWhere((d) => d.day == _weekdayName(DateTime.parse(dateKey).weekday), orElse: () => DailyPlan(day: '', schedule: []));
            totalForDay = dp.schedule.length;
          } catch(_){ totalForDay = 0; }
        }
        if(totalForDay > 0) {
          final ratio = projectedCompleted / totalForDay;
          // Bonus eşikleri %60 %80 %100
            final thresholds = [0.6,0.8,1.0];
            final givenMap = Map<String,List<int>>.from(user.dailyPlanBonuses);
            final givenList = List<int>.from(givenMap[dateKey] ?? []);
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

      // Önceki gün oranını hesaplarken (günün ilk tamamlamasıysa) dünün durumu finalize et
      if(isCompleted && dateKey == todayKey) {
        final yesterday = today.subtract(const Duration(days:1));
        final yKey = '${yesterday.year.toString().padLeft(4,'0')}-${yesterday.month.toString().padLeft(2,'0')}-${yesterday.day.toString().padLeft(2,'0')}';
        if(user.lastScheduleCompletionRatio == null || (user.completedDailyTasks[yKey]??[]).isNotEmpty) {
          // hesapla
          if(user.weeklyPlan != null) {
            try {
              final weekly = WeeklyPlan.fromJson(user.weeklyPlan!);
              final dpY = weekly.plan.firstWhere((d) => d.day == _weekdayName(yesterday.weekday), orElse: () => DailyPlan(day: '', schedule: []));
              final totalY = dpY.schedule.length;
              if(totalY>0) {
                final compY = (user.completedDailyTasks[yKey]??[]).length;
                final ratioY = compY/totalY;
                updates['lastScheduleCompletionRatio'] = ratioY;
              }
            } catch(_){ }
          }
        }
      }

      txn.update(userDocRef, updates);
    });
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
    await usersCollection.doc(userId).update({
      'studyPacing': pacing,
      'longTermStrategy': longTermStrategy,
      'weeklyPlan': weeklyPlan,
    });
    await updateEngagementScore(userId, 100);
  }

  Future<void> markTopicAsMastered(
      {required String userId,
        required String subject,
        required String topic}) async {
    final sanitizedSubject = _sanitizeKey(subject);
    final sanitizedTopic = _sanitizeKey(topic);
    final uniqueIdentifier = '$sanitizedSubject-$sanitizedTopic';
    await usersCollection.doc(userId).update({
      'masteredTopics': FieldValue.arrayUnion([uniqueIdentifier])
    });
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
      'topicPerformances': {},
      'completedDailyTasks': {},
      'studyPacing': null,
      'longTermStrategy': null,
      'weeklyPlan': null,
      'weeklyAvailability': {},
      'masteredTopics': [],
      'goal': null,
      'challenges': [],
      'weeklyStudyGoal': null,
      'streak': 0,
      'lastStreakUpdate': null,
    });

    final testsSnapshot = await _testsCollection.where('userId', isEqualTo: userId).get();
    for (final doc in testsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final focusSnapshot = await _focusSessionsCollection.where('userId', isEqualTo: userId).get();
    for (final doc in focusSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<UserModel>> getLeaderboardUsers(String examType) async {
    final snapshot = await usersCollection
        .where('selectedExam', isEqualTo: examType)
        .where('engagementScore', isGreaterThan: 0)
        .orderBy('engagementScore', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
  }

  String _weekdayName(int weekday) {
    const list = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return list[(weekday-1).clamp(0,6)];
  }
}
