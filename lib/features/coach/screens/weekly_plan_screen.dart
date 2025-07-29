// lib/features/coach/screens/weekly_plan_screen.dart
// Bu dosya artık doğrudan bir ekran olarak kullanılmıyor,
// ancak içerisindeki modeller AiCoachScreen tarafından kullanılıyor.

// Model Sınıfları
class WeeklyPlan {
  final String planTitle;
  final String strategyFocus;
  final List<DailyPlan> plan;
  WeeklyPlan({required this.planTitle, required this.strategyFocus, required this.plan});

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    var list = (json['plan'] as List?) ?? [];
    List<DailyPlan> dailyPlans = list.map((i) => DailyPlan.fromJson(i)).toList();
    return WeeklyPlan(
      planTitle: json['planTitle'] ?? "Haftalık Stratejik Plan",
      strategyFocus: json['strategyFocus'] ?? "Strateji belirlenemedi.",
      plan: dailyPlans,
    );
  }
}

class DailyPlan {
  final String day;
  final List<String> tasks;
  DailyPlan({required this.day, required this.tasks});

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    var tasksFromJson = (json['tasks'] as List?) ?? [];
    List<String> taskList = tasksFromJson.cast<String>();
    return DailyPlan(day: json['day'], tasks: taskList);
  }
}