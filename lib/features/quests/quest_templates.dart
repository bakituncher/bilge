// lib/features/quests/quest_templates.dart

final List<Map<String, dynamic>> questTemplates = [
  // --- TUTARLILIK GÖREVLERİ (Her Gün Kontrol Edilir) ---
  {
    'id': 'consistency_01',
    'title': 'Savaşçı Yemini',
    'description': '3 gün üst üste uygulamaya giriş yaparak kararlılığını kanıtla.',
    'category': 'consistency',
    'reward': 75,
    'goalValue': 3,
    'actionRoute': '/home',
    'progressType': 'set_to_value', // HATA GİDERİLDİ: 'userStreak' -> 'set_to_value'
  },
  {
    'id': 'consistency_02',
    'title': 'Demir İrade',
    'description': 'Tam 7 gün boyunca Fetih Kütüğü\'nü kontrol et ve serini devam ettir.',
    'category': 'consistency',
    'reward': 150,
    'goalValue': 7,
    'actionRoute': '/home/quests',
    'progressType': 'set_to_value', // HATA GİDERİLDİ: 'userStreak' -> 'set_to_value'
  },

  // ... (diğer görevler aynı kalacak, onlarda bir hata yoktu) ...

  // --- ETKİLEŞİM GÖREVLERİ (Uygulama Kullanımı) ---
  {
    'id': 'engagement_01',
    'title': 'Zihinsel Gözlemevi',
    'description': 'Odaklanma Mabedi\'nde 25 dakikalık bir Pomodoro seansı tamamla.',
    'category': 'engagement',
    'reward': 40,
    'goalValue': 1,
    'actionRoute': '/home/pomodoro',
  },
  {
    'id': 'engagement_02',
    'title': 'Stratejist',
    'description': 'BilgeAI ile haftalık stratejini oluştur veya mevcut stratejini gözden geçir.',
    'category': 'engagement',
    'reward': 100,
    'goalValue': 1,
    'actionRoute': '/ai-hub/strategic-planning',
  },
  {
    'id': 'engagement_03',
    'title': 'Cevher Avcısı',
    'description': 'Cevher Atölyesi\'ni ziyaret ederek zayıf bir konunun üzerine git.',
    'category': 'engagement',
    'reward': 120,
    'goalValue': 1,
    'actionRoute': '/ai-hub/weakness-workshop',
  },
  {
    'id': 'engagement_04',
    'title': 'Komutanın Raporu',
    'description': 'Performans Kalesi\'ni ziyaret ederek genel durumunu analiz et.',
    'category': 'engagement',
    'reward': 50,
    'goalValue': 1,
    'actionRoute': '/home/stats',
  },

  // --- PRATİK GÖREVLERİ (Soru Çözme, Deneme vb.) ---
  {
    'id': 'practice_01',
    'title': 'Kale Kuşatması: {subject}',
    'description': '{subject} dersinden 50 soru çözerek kalenin surlarını zorla.',
    'category': 'practice',
    'reward': 75,
    'goalValue': 50,
    'actionRoute': '/coach',
    'variables': ['weakest_subject'], // Bu görev en zayıf derse göre atanacak
  },
  {
    'id': 'practice_02',
    'title': 'Paragraf Canavarı',
    'description': 'Hız ve anlama gücünü artırmak için 20 paragraf sorusu çöz.',
    'category': 'practice',
    'reward': 30,
    'goalValue': 20,
    'actionRoute': '/coach',
  },
  {
    'id': 'practice_03',
    'title': 'Savaş Tatbikatı',
    'description': 'Yeni bir deneme sonucunu sisteme ekleyerek genel durumunu raporla.',
    'category': 'practice',
    'reward': 150,
    'goalValue': 1,
    'actionRoute': '/home/add-test',
  },
  {
    'id': 'practice_04',
    'title': 'Hücum Taktiği: {subject}',
    'description': 'En güçlü olduğun {subject} dersinden 30 soru çözerek hızını test et.',
    'category': 'practice',
    'reward': 60,
    'goalValue': 30,
    'actionRoute': '/coach',
    'variables': ['strongest_subject'],
  },

  // --- ÇALIŞMA GÖREVLERİ (Konu Tekrarı vb.) ---
  {
    'id': 'study_01',
    'title': 'Tozlu Raflar: {subject}',
    'description': '{subject} dersinden eski bir konuyu hızlıca tekrar et.',
    'category': 'study',
    'reward': 60,
    'goalValue': 1,
    'actionRoute': '/coach',
    'variables': ['random_subject_not_weakest'], // Rastgele ama en zayıf olmayan bir ders
  },
  {
    'id': 'study_02',
    'title': 'Bilgi Taraması',
    'description': 'Bilgi Galaksisi\'nde bir konunun hakimiyetini güncelle.',
    'category': 'study',
    'reward': 25,
    'goalValue': 1,
    'actionRoute': '/coach',
  },
];