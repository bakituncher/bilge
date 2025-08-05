// lib/features/strategic_planning/models/strategic_plan_model.dart
import 'dart:convert';

class StrategicPlan {
  final String motto;
  final List<StrategyPhase> phases;

  StrategicPlan({required this.motto, required this.phases});

  factory StrategicPlan.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      var phaseList = (json['phases'] as List<dynamic>?)
          ?.map((phase) => StrategyPhase.fromMap(phase))
          .toList() ?? [];

      return StrategicPlan(
        motto: json['motto'] ?? "Başarıya giden yol, disiplin taşlarıyla döşenmiştir.",
        phases: phaseList,
      );
    } catch (e) {
      // Eğer JSON parse edilemezse, eski formatta düz metin olarak kabul et
      return StrategicPlan(motto: "Genel Strateji", phases: [
        StrategyPhase(phaseNumber: 1, phaseTitle: "Harekat Planı", objective: jsonString, tactic: "", exitCriteria: [])
      ]);
    }
  }
}

class StrategyPhase {
  final int phaseNumber;
  final String phaseTitle;
  final String objective;
  final String tactic;
  final List<String> exitCriteria;

  StrategyPhase({
    required this.phaseNumber,
    required this.phaseTitle,
    required this.objective,
    required this.tactic,
    required this.exitCriteria,
  });

  factory StrategyPhase.fromMap(Map<String, dynamic> map) {
    return StrategyPhase(
      phaseNumber: map['phaseNumber'] ?? 0,
      phaseTitle: map['phaseTitle'] ?? "Bilinmeyen Aşama",
      objective: map['objective'] ?? "Hedef belirtilmemiş.",
      tactic: map['tactic'] ?? "Taktik belirtilmemiş.",
      exitCriteria: List<String>.from(map['exitCriteria'] ?? []),
    );
  }
}