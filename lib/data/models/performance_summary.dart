// lib/data/models/performance_summary.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilge_ai/data/models/topic_performance_model.dart';

class PerformanceSummary {
  final Map<String, Map<String, TopicPerformanceModel>> topicPerformances;
  final List<String> masteredTopics;

  const PerformanceSummary({
    this.topicPerformances = const {},
    this.masteredTopics = const [],
  });

  factory PerformanceSummary.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final Map<String, Map<String, TopicPerformanceModel>> safeTopicPerformances = {};
    if (data['topicPerformances'] is Map<String, dynamic>) {
      final topicsMap = data['topicPerformances'] as Map<String, dynamic>;
      topicsMap.forEach((subjectKey, subjectValue) {
        if (subjectValue is Map<String, dynamic>) {
          final newSubjectMap = <String, TopicPerformanceModel>{};
          subjectValue.forEach((topicKey, topicValue) {
            if (topicValue is Map<String, dynamic>) {
              newSubjectMap[topicKey] = TopicPerformanceModel.fromMap(topicValue);
            }
          });
          safeTopicPerformances[subjectKey] = newSubjectMap;
        }
      });
    }

    return PerformanceSummary(
      topicPerformances: safeTopicPerformances,
      masteredTopics: List<String>.from(data['masteredTopics'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'topicPerformances': topicPerformances.map((k, v) => MapEntry(k, v.map((tk, tv) => MapEntry(tk, tv.toMap())))),
    'masteredTopics': masteredTopics,
  };
}
