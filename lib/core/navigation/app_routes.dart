// lib/core/navigation/app_routes.dart

// Uygulama genelindeki tüm rota yollarını tutan merkezi harita.
// Bu, yazım hatalarını önler ve rota yönetimini tek bir yerden sağlar.
class AppRoutes {
  // Ana Yollar
  static const String loading = '/loading';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String examSelection = '/exam-selection';
  static const String availability = '/availability';
  static const String library = '/library';

  // Kabuklu (Bottom Nav Bar) Ana Rotalar
  static const String home = '/home';
  static const String coach = '/coach';
  static const String aiHub = '/ai-hub';
  static const String arena = '/arena';
  static const String profile = '/profile';

  // Alt Rotalar (Home)
  static const String addTest = 'add-test'; // home'a bağlı olduğu için '/' yok
  static const String testDetail = 'test-detail';
  static const String testResultSummary = 'test-result-summary';
  static const String pomodoro = 'pomodoro';
  static const String stats = 'stats';

  // Alt Rotalar (Coach)
  static const String updateTopicPerformance = 'update-topic-performance';

  // Alt Rotalar (AI Hub)
  static const String strategicPlanning = 'strategic-planning';
  static const String commandCenter = 'command-center';
  static const String weaknessWorkshop = 'weakness-workshop';
  static const String motivationChat = 'motivation-chat';
}