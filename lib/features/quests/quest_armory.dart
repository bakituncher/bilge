// lib/features/quests/quest_armory.dart

// Bu dosya, uygulamamızın görev cephaneliğidir.
// Yapay zeka yerine, bu devasa ve çeşitli liste üzerinden,
// kurallara dayalı akıllı bir görev atama sistemi kuracağız.

enum QuestTag {
  core, // Her zaman atanabilecek temel görevler
  consistency, // Seri ve düzenlilik odaklı
  weakness, // Zayıf nokta tespiti gerektiren
  strength, // Güçlü yanı pekiştiren
  exploration, // Yeni özellik keşfi
  high_value, // Yüksek ödüllü, zorlayıcı
  quick_win, // Hızlı ve kolay tamamlanabilen
  special, // Özel durumlar için
  variety, // Çeşitlilik sunan
  focus, // Odaklanma gerektiren
  analysis, // Analiz ve raporlama odaklı
}

final List<Map<String, dynamic>> questArmory = [
  // =======================================================================
  // TUTARLILIK (CONSISTENCY) GÖREVLERİ (10+)
  // =======================================================================
  {
    'id': 'consistency_01',
    'title': 'Savaşçı Yemini',
    'description': 'Günün farklı zamanlarında (en az 1 saat arayla) 3 kez uygulamayı ziyaret ederek kararlılığını kanıtla.',
    'category': 'consistency', 'reward': 15, 'goalValue': 3, 'actionRoute': '/home', 'progressType': 'set_to_value',
    'tags': [QuestTag.core, QuestTag.consistency],
  },
  {
    'id': 'consistency_02',
    'title': 'Şafak Nöbeti',
    'description': 'Sabah 09:00\'dan önce uygulamaya giriş yaparak güne bir adım önde başla.',
    'category': 'consistency', 'reward': 20, 'goalValue': 1, 'actionRoute': '/home',
    'tags': [QuestTag.consistency, QuestTag.quick_win], 'triggerConditions': {'timeOfDay': 'morning'}
  },
  {
    'id': 'consistency_03',
    'title': 'Gece Kartalı',
    'description': 'Akşam 22:00\'dan sonra günün son tekrarını yaparak günü tamamla.',
    'category': 'consistency', 'reward': 20, 'goalValue': 1, 'actionRoute': '/home',
    'tags': [QuestTag.consistency], 'triggerConditions': {'timeOfDay': 'night'}
  },
  {
    'id': 'consistency_04',
    'title': 'Hafta Sonu Nöbeti',
    'description': 'Hafta sonu da disiplini elden bırakma! Cumartesi veya Pazar günü en az bir görev tamamla.',
    'category': 'consistency', 'reward': 50, 'goalValue': 1,
    'actionRoute': '/home/quests',
    'tags': [QuestTag.consistency], 'triggerConditions': {'dayOfWeek': ['saturday', 'sunday']}
  },

  // =======================================================================
  // ETKİLEŞİM (ENGAGEMENT) GÖREVLERİ (15+)
  // =======================================================================
  {
    'id': 'engagement_01a',
    'title': 'Zihinsel Gözlemevi',
    'description': 'Odaklanma Mabedi\'nde 25 dakikalık bir Pomodoro seansı tamamla.',
    'category': 'engagement', 'reward': 40, 'goalValue': 1, 'actionRoute': '/home/pomodoro',
    'tags': [QuestTag.exploration, QuestTag.focus], 'triggerConditions': {'notUsedFeature': 'pomodoro'}
  },
  {
    'id': 'engagement_01b',
    'title': 'Odaklanma Maratonu',
    'description': 'Odaklanma Mabedi\'nde 2 tam Pomodoro turu (2x25dk çalışma) tamamla.',
    'category': 'engagement', 'reward': 75, 'goalValue': 2, 'actionRoute': '/home/pomodoro',
    'tags': [QuestTag.focus, QuestTag.high_value], 'triggerConditions': {'usedFeatureRecently': 'pomodoro'}
  },
  {
    'id': 'engagement_02',
    'title': 'Strateji Dehası',
    'description': 'Mevcut stratejini gözden geçir veya yeni bir haftalık strateji oluştur.',
    'category': 'engagement', 'reward': 100, 'goalValue': 1, 'actionRoute': '/ai-hub/strategic-planning',
    'tags': [QuestTag.high_value, QuestTag.exploration], 'triggerConditions': {'notUsedFeature': 'strategy'}
  },
  {
    'id': 'engagement_03',
    'title': 'Cevher Avcısı',
    'description': 'Cevher Atölyesi\'ni ziyaret ederek zayıf bir konunun üzerine git.',
    'category': 'engagement', 'reward': 120, 'goalValue': 1, 'actionRoute': '/ai-hub/weakness-workshop',
    'tags': [QuestTag.high_value, QuestTag.weakness], 'triggerConditions': {'hasWeakTopic': true, 'notUsedFeature': 'workshop'}
  },
  {
    'id': 'engagement_04',
    'title': 'Komutanın Raporu',
    'description': 'Performans Kalesi\'ni ziyaret ederek genel durumunu analiz et.',
    'category': 'engagement', 'reward': 50, 'goalValue': 1, 'actionRoute': '/home/stats',
    'tags': [QuestTag.exploration, QuestTag.core, QuestTag.analysis],
  },
  {
    'id': 'engagement_05',
    'title': 'Arena Savaşçısı',
    'description': 'Zafer Panteonu\'nu ziyaret ederek diğer savaşçılar arasındaki yerini gör.',
    'category': 'engagement', 'reward': 30, 'goalValue': 1, 'actionRoute': '/arena',
    'tags': [QuestTag.exploration],
  },
  {
    'id': 'engagement_06',
    'title': 'Kütüphane Ziyareti',
    'description': 'Performans Arşivi\'ni ziyaret ederek eski bir denemeni incele.',
    'category': 'engagement', 'reward': 25, 'goalValue': 1, 'actionRoute': '/library',
    'tags': [QuestTag.quick_win, QuestTag.analysis],
  },
  {
    'id': 'engagement_07',
    'title': 'Moral Takviyesi',
    'description': 'Zihinsel Harbiye\'de BilgeAI ile sohbet ederek motivasyonunu tazele.',
    'category': 'engagement', 'reward': 35, 'goalValue': 1, 'actionRoute': '/ai-hub/motivation-chat',
    'tags': [QuestTag.exploration],
  },
  {
    'id': 'engagement_08',
    'title': 'Avatarını Kişiselleştir',
    'description': 'Profilindeki avatar atölyesini ziyaret ederek kendini ifade et.',
    'category': 'engagement', 'reward': 20, 'goalValue': 1, 'actionRoute': '/profile/avatar-selection',
    'tags': [QuestTag.quick_win],
  },
  {
    'id': 'engagement_09',
    'title': 'Zaman Haritası Güncellemesi',
    'description': 'Bu haftaki programın değişti mi? Zaman Haritanı güncelleyerek planını taze tut.',
    'category': 'engagement', 'reward': 40, 'goalValue': 1, 'actionRoute': '/availability',
    'tags': [QuestTag.core],
  },

  // =======================================================================
  // PRATİK (PRACTICE) GÖREVLERİ (20+)
  // =======================================================================
  {
    'id': 'practice_01a',
    'title': 'Gedik Kapatma: {subject}',
    'description': 'En zayıf dersin olan {subject} cephesinden 20 soru çözerek gedikleri kapatmaya başla.',
    'category': 'practice', 'reward': 40, 'goalValue': 20, 'actionRoute': '/coach',
    'tags': [QuestTag.weakness], 'triggerConditions': {'hasWeakSubject': true}
  },
  {
    'id': 'practice_01b',
    'title': 'Kale Kuşatması: {subject}',
    'description': 'En zayıf halkan olan {subject} dersinden 50 soru çözerek kalenin surlarını zorla.',
    'category': 'practice', 'reward': 75, 'goalValue': 50, 'actionRoute': '/coach',
    'tags': [QuestTag.weakness, QuestTag.high_value], 'triggerConditions': {'hasWeakSubject': true}
  },
  {
    'id': 'practice_02a',
    'title': 'Güç Gösterisi: {subject}',
    'description': 'En güçlü olduğun {subject} kalesinde 25 soru çözerek hakimiyetini pekiştir.',
    'category': 'practice', 'reward': 50, 'goalValue': 25, 'actionRoute': '/coach',
    'tags': [QuestTag.strength], 'triggerConditions': {'hasStrongSubject': true}
  },
  {
    'id': 'practice_02b',
    'title': 'Hücum Taktiği: {subject}',
    'description': 'En güçlü olduğun {subject} dersinde 40 soru çözerek hızını ve doğruluğunu sına.',
    'category': 'practice', 'reward': 65, 'goalValue': 40, 'actionRoute': '/coach',
    'tags': [QuestTag.strength], 'triggerConditions': {'hasStrongSubject': true}
  },
  {
    'id': 'practice_03',
    'title': 'Savaş Tatbikatı',
    'description': 'Yeni bir deneme sonucunu sisteme ekleyerek genel durumunu raporla.',
    'category': 'test_submission', 'reward': 150, 'goalValue': 1, 'actionRoute': '/home/add-test',
    'tags': [QuestTag.high_value, QuestTag.analysis], 'triggerConditions': {'noRecentTest': true}
  },
  {
    'id': 'practice_04',
    'title': 'Paragraf Canavarı',
    'description': 'Hız ve anlama gücünü artırmak için 20 paragraf sorusu çöz.',
    'category': 'practice', 'reward': 30, 'goalValue': 20, 'actionRoute': '/coach',
    'tags': [QuestTag.core, QuestTag.variety], 'triggerConditions': {'examType': ['yks', 'kpss']}
  },
  {
    'id': 'practice_05',
    'title': 'Problem Avcısı',
    'description': 'Analitik düşünme yeteneğini geliştirmek için 15 problem sorusu çöz.',
    'category': 'practice', 'reward': 30, 'goalValue': 15, 'actionRoute': '/coach',
    'tags': [QuestTag.core, QuestTag.variety], 'triggerConditions': {'examType': ['yks', 'kpss', 'lgs']}
  },
  {
    'id': 'practice_06',
    'title': 'Karma Antrenman',
    'description': '3 farklı dersten 10\'ar soru çözerek zihnini zinde tut.',
    'category': 'practice', 'reward': 50, 'goalValue': 30, 'actionRoute': '/coach',
    'tags': [QuestTag.variety],
  },
  {
    'id': 'practice_07',
    'title': 'Hız Testi: 15 Dakika',
    'description': '15 dakika içinde çözebildiğin kadar çok soru çözerek zaman yönetimi pratiği yap.',
    'category': 'practice', 'reward': 40, 'goalValue': 15, // dakika
    'actionRoute': '/home/pomodoro',
    'tags': [QuestTag.focus],
  },
  {
    'id': 'practice_08',
    'title': 'Sayısal Mantık Meydan Okuması',
    'description': '10 Sayısal Mantık sorusu çözerek beyninin sınırlarını zorla.',
    'category': 'practice', 'reward': 45, 'goalValue': 10, 'actionRoute': '/coach',
    'tags': [QuestTag.variety], 'triggerConditions': {'examType': ['yks', 'kpss', 'lgs']}
  },
  {
    'id': 'practice_09',
    'title': 'Sözel Mantık Atölyesi',
    'description': '10 Sözel Mantık sorusu çözerek muhakeme yeteneğini geliştir.',
    'category': 'practice', 'reward': 45, 'goalValue': 10, 'actionRoute': '/coach',
    'tags': [QuestTag.variety], 'triggerConditions': {'examType': ['yks', 'kpss']}
  },

  // =======================================================================
  // ÇALIŞMA (STUDY) GÖREVLERİ (10+)
  // =======================================================================
  {
    'id': 'study_01',
    'title': 'Tozlu Raflar: {subject}',
    'description': 'Uzun zamandır tekrar etmediğin {subject} dersinden bir konunun hakimiyetini Bilgi Galaksisi\'nde güncelle.',
    'category': 'study', 'reward': 60, 'goalValue': 1, 'actionRoute': '/coach',
    'tags': [QuestTag.core, QuestTag.analysis], 'triggerConditions': {'hasStaleSubject': true}
  },
  {
    'id': 'study_02',
    'title': 'Bilgi Taraması',
    'description': 'Bilgi Galaksisi\'nde herhangi bir konunun hakimiyetini güncelle.',
    'category': 'study', 'reward': 25, 'goalValue': 1, 'actionRoute': '/coach',
    'tags': [QuestTag.quick_win, QuestTag.analysis],
  },
  {
    'id': 'study_03',
    'title': 'Galaksi Hakimiyeti',
    'description': 'Bilgi Galaksisi\'nde 3 farklı konunun hakimiyetini güncelle.',
    'category': 'study', 'reward': 70, 'goalValue': 3, 'actionRoute': '/coach',
    'tags': [QuestTag.analysis, QuestTag.high_value],
  },
  {
    'id': 'study_04',
    'title': 'Zayıf Gezegen Fethi',
    'description': 'Bilgi Galaksisi\'nde kırmızı renkte (zayıf) olan bir gezegenin bilgilerini güncelle.',
    'category': 'study', 'reward': 50, 'goalValue': 1, 'actionRoute': '/coach',
    'tags': [QuestTag.weakness], 'triggerConditions': {'hasWeakTopicInGalaxy': true}
  },
  {
    'id': 'study_05',
    'title': 'Planlı Harekât',
    'description': 'Haftalık planında bugün için atanmış bir görevi tamamla.',
    'category': 'study', 'reward': 30, 'goalValue': 1, 'actionRoute': '/home/weekly-plan',
    'tags': [QuestTag.core], 'triggerConditions': {'hasWeeklyPlan': true}
  },

  // =======================================================================
  // HAFTALIK SEFERLER (WEEKLY CAMPAIGNS)
  // =======================================================================
  {
    'id': 'weekly_01',
    'title': 'Haftalık Sefer: Kale Fethi',
    'description': 'Bu hafta en zayıf dersin olan {subject} üzerine yoğunlaşarak ortalama netini en az 2 puan artır.',
    'category': 'practice', 'type': 'weekly', 'reward': 500, 'goalValue': 2, 'actionRoute': '/coach',
    'tags': [QuestTag.high_value, QuestTag.weakness], 'triggerConditions': {'hasWeakSubject': true}
  },
  {
    'id': 'weekly_02',
    'title': 'Haftalık Sefer: Demir İrade',
    'description': 'Bu hafta boyunca her gün uygulamaya giriş yaparak 7 günlük seriyi tamamla ve iradeni kanıtla.',
    'category': 'consistency', 'type': 'weekly', 'reward': 300, 'goalValue': 7, 'actionRoute': '/home',
    'tags': [QuestTag.high_value, QuestTag.consistency],
  },
  {
    'id': 'weekly_03',
    'title': 'Haftalık Sefer: Soru İmparatoru',
    'description': 'Bu hafta toplam 500 soru çözerek soru çözme limitlerini zorla.',
    'category': 'practice', 'type': 'weekly', 'reward': 400, 'goalValue': 500, 'actionRoute': '/coach',
    'tags': [QuestTag.high_value],
  },
  {
    'id': 'weekly_04',
    'title': 'Haftalık Sefer: Odaklanma Ustası',
    'description': 'Bu hafta toplam 5 saat (300 dakika) Pomodoro tekniği ile odaklanarak zihnini eğit.',
    'category': 'engagement', 'type': 'weekly', 'reward': 350, 'goalValue': 300,
    'actionRoute': '/home/pomodoro', 'tags': [QuestTag.high_value, QuestTag.focus],
  },
];