// lib/data/repositories/test_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilge_ai/data/models/test_model.dart';

class TestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test sonucu ekle
  Future<void> addTestResult(TestModel test) async {
    await _firestore.collection('tests').add(test.toJson());
  }

  // Kullanıcının testlerini getir
  Future<List<TestModel>> getUserTests(String userId) async {
    final snapshot = await _firestore
        .collection('tests')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TestModel.fromSnapshot(doc))
        .toList();
  }

  // Test güncelle
  Future<void> updateTest(String testId, Map<String, dynamic> data) async {
    await _firestore.collection('tests').doc(testId).update(data);
  }

  // Test sil
  Future<void> deleteTest(String testId) async {
    await _firestore.collection('tests').doc(testId).delete();
  }
}