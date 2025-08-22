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
import 'package:bilge_ai/data/models/plan_document.dart';
import 'package:bilge_ai/data/models/performance_summary.dart';
import 'package:bilge_ai/data/models/app_state.dart';
import 'package:bilge_ai/features/arena/models/leaderboard_entry_model.dart'; // YENİ: Leaderboard modeli

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

  // YENİ: Leaderboards kök koleksiyonu
  CollectionReference<Map<String, dynamic>> get _leaderboardsCollection => _firestore.collection('leaderboards');

  CollectionReference<Map<String, dynamic>> get _testsCollection => _firestore.collection('tests');
  CollectionReference<Map<String, dynamic>> get _focusSessionsCollection => _firestore.collection('focusSessions');

  // Alt koleksiyon referans yardımcıları
  DocumentReference<Map<String, dynamic>> _planDoc(String userId) => usersCollection.doc(userId).collection('plans').doc('current_plan');
  DocumentReference<Map<String, dynamic>> _performanceDoc(String userId) => usersCollection.doc(userId).collection('performance').doc('summary');
  DocumentReference<Map<String, dynamic>> _appStateDoc(String userId) => usersCollection.doc(userId).collection('state').doc('app_state');

  // Leaderboard belge referansı
  DocumentReference<Map<String, dynamic>> _leaderboardUserDoc({required String examType, required String userId}) {
    return _leaderboardsCollection.doc(examType).collection('users').doc(userId);
  }

  // Kullanıcının mevcut durumunu okuyarak leaderboards/{examType}/users/{userId} dokümanını günceller
  Future<void> _syncLeaderboardUser(String userId, {String? targetExam}) async {
    final userSnap = await usersCollection.doc(userId).get();
    if (!userSnap.exists) return;
    final data = userSnap.data()!;
    final String? examType = targetExam ?? data['selectedExam'] as String?;
    if (examType == null) return; // sınav seçilmemişse leaderboard'a yazma

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
      // Önce oku
      final snap = await txn.get(userDocRef);
      final data = snap.data();
      final String? examType = data?['selectedExam'];
      // Sonra yaz
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
    // Alt belgeleri başlangıçta oluştur (boş)
    await _appStateDoc(user.uid).set(const AppState().toMap(), SetOptions(merge: true));
    await _planDoc(user.uid).set(PlanDocument().toMap(), SetOptions(merge: true));
    await _performanceDoc(user.uid).set(PerformanceSummary().toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserName({required String userId, required String newName}) async {
    final userDocRef = usersCollection.doc(userId);
    await _firestore.runTransaction((txn) async {
      // Önce oku
      final snap = await txn.get(userDocRef);
      final data = snap.data();
      final String? examType = data?['selectedExam'];
      // Sonra yaz
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
    // Alt koleksiyon: state/app_state
    await _appStateDoc(userId).set({'tutorialCompleted': true}, SetOptions(merge: true));
    // Geri uyumluluk: ana belgeyi de güncelle
    await usersCollection.doc(userId).update({'tutorialCompleted': true});
  }

  Future<void> updateOnboardingData({
    required String userId,
    required String goal,
    required List<String> challenges,
    required double weeklyStudyGoal,
  }) async {
    // Hedef ve ilgili alanlar ana belgede kalabilir
    await usersCollection.doc(userId).update({
      'goal': goal,
      'challenges': challenges,
      'weeklyStudyGoal': weeklyStudyGoal,
    });
    // Onboarding tamamlandı -> alt state belgesine
    await _appStateDoc(userId).set({'onboardingCompleted': true}, SetOptions(merge: true));
    // Geri uyumluluk
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
      // Önce oku
      final userSnapshot = await transaction.get(userDocRef);
      final data = userSnapshot.data();
      final String? examType = data?['selectedExam'];
      // Sonra yaz
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

      // Eski sınavın leaderboards kaydını temizle
      if (prevExam != null && prevExam != examType.name) {
        final oldLbRef = _leaderboardUserDoc(examType: prevExam, userId: userId);
        txn.delete(oldLbRef);
      }

      // Yeni sınav için kayıt/merge
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

  // Yeni Stream'ler
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
    final userDocRef = usersCollection.doc(userId);
    final sanitizedSubject = _sanitizeKey(subject);
    final sanitizedTopic = _sanitizeKey(topic);
    final fieldPath = 'topicPerformances.$sanitizedSubject.$sanitizedTopic';
    // Alt koleksiyon
    await _performanceDoc(userId).set({fieldPath: performance.toMap()}, SetOptions(merge: true));
    // Geri uyumluluk
    await userDocRef.update({fieldPath: performance.toMap()});
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
      final user = UserModel.fromSnapshot(snap);

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

      // Leaderboard: puan artışı/azalışı kullanıcı belgesine yazıldıktan sonra mevcut sınav için güncelle
      final String? examType = user.selectedExam;
      if (examType != null) {
        final lbRef = _leaderboardUserDoc(examType: examType, userId: userId);
        // Tam senkron için mevcut kullanıcı değerleri ile merge et (checksum olarak updatedAt)
        txn.set(lbRef, {
          'userId': userId,
          'userName': user.name,
          // score için toplam delta bilinmiyor; transaction sonrası tam senkron yapılacak
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    // Transaction sonrası kesin senkron (score değerini birebir yansıt)
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
    // Alt koleksiyon: plans/current_plan
    await _planDoc(userId).set({
      'studyPacing': pacing,
      'longTermStrategy': longTermStrategy,
      'weeklyPlan': weeklyPlan,
    }, SetOptions(merge: true));
    // Geri uyumluluk: ana belgeyi de güncelle (geçiş süreci için)
    await usersCollection.doc(userId).update({
      'studyPacing': pacing,
      'longTermStrategy': longTermStrategy,
      'weeklyPlan': weeklyPlan,
    });
    await updateEngagementScore(userId, 100);
  }

  Future<void> markTopicAsMastered({required String userId, required String subject, required String topic}) async {
    final sanitizedSubject = _sanitizeKey(subject);
    final sanitizedTopic = _sanitizeKey(topic);
    final uniqueIdentifier = '$sanitizedSubject-$sanitizedTopic';
    // Alt koleksiyon
    await _performanceDoc(userId).set({
      'masteredTopics': FieldValue.arrayUnion([uniqueIdentifier])
    }, SetOptions(merge: true));
    // Geri uyumluluk
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

  String _weekdayName(int weekday) {
    const list = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return list[(weekday-1).clamp(0,6)];
  }
}
