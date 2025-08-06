// lib/data/models/exam_model.dart

// Sınav türlerini tanımlayan enum
enum ExamType {
  yks,
  lgs,
  kpssLisans,
  kpssOnlisans,
  kpssOrtaogretim,
}

extension ExamTypeExtension on ExamType {
  String get displayName {
    switch (this) {
      case ExamType.yks:
        return 'YKS';
      case ExamType.lgs:
        return 'LGS';
      case ExamType.kpssLisans:
        return 'KPSS Lisans';
      case ExamType.kpssOnlisans:
        return 'KPSS Önlisans';
      case ExamType.kpssOrtaogretim:
        return 'KPSS Ortaöğretim';
    }
  }
}

// Bir dersin içindeki tek bir konuyu temsil eder.
class SubjectTopic {
  final String name;
  SubjectTopic({required this.name});
}

// Bir dersin soru sayısı ve konu listesi gibi detaylarını tutar.
class SubjectDetails {
  final int questionCount;
  final List<SubjectTopic> topics;
  SubjectDetails({required this.questionCount, required this.topics});
}

// Bir sınavın bölümünü (örn: TYT, Sayısal Bölüm) temsil eder
class ExamSection {
  final String name;
  final Map<String, SubjectDetails> subjects; // Ders Adı -> SubjectDetails
  final double penaltyCoefficient;

  ExamSection({
    required this.name,
    required this.subjects,
    this.penaltyCoefficient = 0.25, // 4 yanlış 1 doğruyu götürür (varsayılan)
  });
}

// Ana sınav yapısını temsil eder (örn: YKS)
class Exam {
  final ExamType type;
  final String name;
  final List<ExamSection> sections;

  Exam({
    required this.type,
    required this.name,
    required this.sections,
  });
}

// Sınav verilerinin merkezi (TÜM SINAVLAR VE GÜNCEL KONULAR EKLENDİ)
class ExamData {
  // KPSS için ortak ders ve konu yapısı
  static final Map<String, SubjectDetails> _kpssGyGkSubjects = {
    'Türkçe (Genel Yetenek)': SubjectDetails(questionCount: 30, topics: [
      SubjectTopic(name: 'Sözcükte Anlam'),
      SubjectTopic(name: 'Cümlede Anlam'),
      SubjectTopic(name: 'Paragrafta Anlam'),
      SubjectTopic(name: 'Sözel Mantık'),
      SubjectTopic(name: 'Ses Bilgisi'),
      SubjectTopic(name: 'Yazım Kuralları'),
      SubjectTopic(name: 'Noktalama İşaretleri'),
      SubjectTopic(name: 'Yapı Bilgisi'),
      SubjectTopic(name: 'Sözcük Türleri'),
      SubjectTopic(name: 'Cümlenin Öğeleri'),
      SubjectTopic(name: 'Cümle Türleri'),
      SubjectTopic(name: 'Anlatım Bozuklukları'),
    ]),
    'Matematik (Genel Yetenek)':
    SubjectDetails(questionCount: 30, topics: [
      SubjectTopic(name: 'Temel Kavramlar ve Sayılar'),
      SubjectTopic(name: 'Bölme-Bölünebilme, Asal Çarpanlar'),
      SubjectTopic(name: 'EBOB-EKOK'),
      SubjectTopic(name: 'Rasyonel ve Ondalıklı Sayılar'),
      SubjectTopic(name: 'Basit Eşitsizlikler ve Mutlak Değer'),
      SubjectTopic(name: 'Üslü ve Köklü İfadeler'),
      SubjectTopic(name: 'Çarpanlara Ayırma ve Özdeşlikler'),
      SubjectTopic(name: 'Denklem Çözme ve Oran-Orantı'),
      SubjectTopic(name: 'Sayı, Kesir, Yaş Problemleri'),
      SubjectTopic(name: 'İşçi, Havuz, Hız Problemleri'),
      SubjectTopic(name: 'Yüzde, Kâr-Zarar, Faiz, Karışım Problemleri'),
      SubjectTopic(name: 'Kümeler, Fonksiyonlar, İşlem, Modüler Aritmetik'),
      SubjectTopic(name: 'Permütasyon, Kombinasyon, Olasılık'),
      SubjectTopic(name: 'Tablo ve Grafik Yorumlama'),
      SubjectTopic(name: 'Sayısal Mantık'),
      SubjectTopic(name: 'Geometri (Açılar, Üçgenler, Dörtgenler, Çember, Analitik, Katı Cisimler)'),
    ]),
    'Tarih (Genel Kültür)': SubjectDetails(questionCount: 27, topics: [
      SubjectTopic(name: 'İslamiyet Öncesi Türk Tarihi'),
      SubjectTopic(name: 'İlk Müslüman Türk Devletleri ve Beylikleri'),
      SubjectTopic(name: 'Osmanlı Devleti Siyasi Tarihi'),
      SubjectTopic(name: 'Osmanlı Devleti Kültür ve Medeniyeti'),
      SubjectTopic(name: '20. Yüzyılda Osmanlı Devleti'),
      SubjectTopic(name: 'Milli Mücadele Hazırlık Dönemi'),
      SubjectTopic(name: 'Kurtuluş Savaşı (Cepheler)'),
      SubjectTopic(name: 'Atatürk İlke ve İnkılapları'),
      SubjectTopic(name: 'Atatürk Dönemi İç Politika'),
      SubjectTopic(name: 'Atatürk Dönemi Dış Politika'),
      SubjectTopic(name: 'Çağdaş Türk ve Dünya Tarihi'),
    ]),
    'Coğrafya (Genel Kültür)':
    SubjectDetails(questionCount: 18, topics: [
      SubjectTopic(name: 'Türkiye\'nin Coğrafi Konumu'),
      SubjectTopic(name: 'Türkiye\'nin Yer Şekilleri'),
      SubjectTopic(name: 'Türkiye\'nin İklimi ve Bitki Örtüsü'),
      SubjectTopic(name: 'Türkiye\'de Nüfus, Yerleşme ve Göç'),
      SubjectTopic(name: 'Türkiye\'de Tarım'),
      SubjectTopic(name: 'Türkiye\'de Hayvancılık'),
      SubjectTopic(name: 'Türkiye\'de Madenler ve Enerji Kaynakları'),
      SubjectTopic(name: 'Türkiye\'de Sanayi'),
      SubjectTopic(name: 'Türkiye\'de Ticaret'),
      SubjectTopic(name: 'Türkiye\'de Ulaşım'),
      SubjectTopic(name: 'Türkiye\'de Turizm'),
      SubjectTopic(name: 'Türkiye\'nin Coğrafi Bölgeleri'),
    ]),
    'Vatandaşlık (Genel Kültür)':
    SubjectDetails(questionCount: 9, topics: [
      SubjectTopic(name: 'Temel Hukuk Kavramları'),
      SubjectTopic(name: 'Anayasa Hukukuna Giriş'),
      SubjectTopic(name: '1982 Anayasası (Temel İlkeler, Hak ve Hürriyetler)'),
      SubjectTopic(name: 'Yasama'),
      SubjectTopic(name: 'Yürütme'),
      SubjectTopic(name: 'Yargı'),
      SubjectTopic(name: 'İdare Hukuku'),
      SubjectTopic(name: 'İnsan Hakları Hukuku'),
    ]),
    'Güncel Bilgiler (Genel Kültür)':
    SubjectDetails(questionCount: 6, topics: [
      SubjectTopic(name: 'Türkiye ve Dünya ile İlgili Genel, Kültürel ve Güncel Sosyoekonomik Konular'),
      SubjectTopic(name: 'Bilimsel ve Teknolojik Gelişmeler'),
      SubjectTopic(name: 'Uluslararası Kuruluşlar ve Anlaşmalar'),
      SubjectTopic(name: 'Sanat ve Spor Alanındaki Gelişmeler'),
    ]),
  };


  static final List<Exam> exams = [
    // LGS Tanımı
    Exam(
      type: ExamType.lgs,
      name: 'Liselere Geçiş Sistemi',
      sections: [
        ExamSection(
            name: 'Sözel Bölüm',
            penaltyCoefficient: 1 / 3, // 3 yanlış 1 doğruyu götürür
            subjects: {
              'Türkçe': SubjectDetails(questionCount: 20, topics: [
                SubjectTopic(name: 'Sözcükte Anlam'),
                SubjectTopic(name: 'Cümlede Anlam'),
                SubjectTopic(name: 'Paragrafta Anlam'),
                SubjectTopic(name: 'Metin Karşılaştırma'),
                SubjectTopic(name: 'Görsel ve Grafik Yorumlama'),
                SubjectTopic(name: 'Sözel Mantık ve Muhakeme'),
                SubjectTopic(name: 'Fiilimsiler'),
                SubjectTopic(name: 'Cümlenin Öğeleri'),
                SubjectTopic(name: 'Fiilde Çatı'),
                SubjectTopic(name: 'Cümle Türleri'),
                SubjectTopic(name: 'Anlatım Bozuklukları'),
                SubjectTopic(name: 'Yazım Kuralları'),
                SubjectTopic(name: 'Noktalama İşaretleri'),
                SubjectTopic(name: 'Metin Türleri'),
                SubjectTopic(name: 'Söz Sanatları'),
              ]),
              'T.C. İnkılap Tarihi ve Atatürkçülük':
              SubjectDetails(questionCount: 10, topics: [
                SubjectTopic(name: 'Bir Kahraman Doğuyor'),
                SubjectTopic(name: 'Milli Uyanış: Bağımsızlık Yolunda Atılan Adımlar'),
                SubjectTopic(name: 'Milli Bir Destan: Ya İstiklal Ya Ölüm!'),
                SubjectTopic(name: 'Atatürkçülük ve Çağdaşlaşan Türkiye'),
                SubjectTopic(name: 'Demokratikleşme Çabaları'),
                SubjectTopic(name: 'Atatürk Dönemi Dış Politika'),
                SubjectTopic(name: 'Atatürk\'ün Ölümü ve Sonrası'),
              ]),
              'Din Kültürü ve Ahlak Bilgisi':
              SubjectDetails(questionCount: 10, topics: [
                SubjectTopic(name: 'Kader İnancı'),
                SubjectTopic(name: 'Zekat ve Sadaka'),
                SubjectTopic(name: 'Din ve Hayat'),
                SubjectTopic(name: 'Hz. Muhammed\'in Örnekliği'),
                SubjectTopic(name: 'Kur\'an-ı Kerim ve Özellikleri'),
              ]),
              'İngilizce': SubjectDetails(questionCount: 10, topics: [
                SubjectTopic(name: 'Friendship'),
                SubjectTopic(name: 'Teen Life'),
                SubjectTopic(name: 'In the Kitchen'),
                SubjectTopic(name: 'On the Phone'),
                SubjectTopic(name: 'The Internet'),
                SubjectTopic(name: 'Adventures'),
                SubjectTopic(name: 'Tourism'),
                SubjectTopic(name: 'Chores'),
                SubjectTopic(name: 'Science'),
                SubjectTopic(name: 'Natural Forces'),
              ]),
            }),
        ExamSection(
            name: 'Sayısal Bölüm',
            penaltyCoefficient: 1 / 3,
            subjects: {
              'Matematik': SubjectDetails(questionCount: 20, topics: [
                SubjectTopic(name: 'Çarpanlar ve Katlar'),
                SubjectTopic(name: 'Üslü İfadeler'),
                SubjectTopic(name: 'Kareköklü İfadeler'),
                SubjectTopic(name: 'Veri Analizi'),
                SubjectTopic(name: 'Basit Olayların Olma Olasılığı'),
                SubjectTopic(name: 'Cebirsel İfadeler ve Özdeşlikler'),
                SubjectTopic(name: 'Doğrusal Denklemler'),
                SubjectTopic(name: 'Eşitsizlikler'),
                SubjectTopic(name: 'Üçgenler'),
                SubjectTopic(name: 'Eşlik ve Benzerlik'),
                SubjectTopic(name: 'Dönüşüm Geometrisi'),
                SubjectTopic(name: 'Geometrik Cisimler'),
              ]),
              'Fen Bilimleri': SubjectDetails(questionCount: 20, topics: [
                SubjectTopic(name: 'Mevsimler ve İklim'),
                SubjectTopic(name: 'DNA ve Genetik Kod'),
                SubjectTopic(name: 'Basınç'),
                SubjectTopic(name: 'Madde ve Endüstri'),
                SubjectTopic(name: 'Basit Makineler'),
                SubjectTopic(name: 'Canlılar ve Enerji İlişkileri'),
                SubjectTopic(name: 'Madde Döngüleri ve Çevre Sorunları'),
                SubjectTopic(name: 'Elektrik Yükleri ve Elektrik Enerjisi'),
              ]),
            }),
      ],
    ),
    // YKS Tanımı
    Exam(
      type: ExamType.yks,
      name: 'Yükseköğretim Kurumları Sınavı',
      sections: [
        ExamSection(name: 'TYT', subjects: {
          'Türkçe': SubjectDetails(questionCount: 40, topics: [
            SubjectTopic(name: 'Sözcükte Anlam'),
            SubjectTopic(name: 'Cümlede Anlam'),
            SubjectTopic(name: 'Paragrafta Anlam'),
            SubjectTopic(name: 'Ses Bilgisi'),
            SubjectTopic(name: 'Yazım Kuralları'),
            SubjectTopic(name: 'Noktalama İşaretleri'),
            SubjectTopic(name: 'Sözcük Yapısı'),
            SubjectTopic(name: 'Sözcük Türleri'),
            SubjectTopic(name: 'Fiiller (Eylemler)'),
            SubjectTopic(name: 'Fiilimsiler'),
            SubjectTopic(name: 'Fiilde Çatı'),
            SubjectTopic(name: 'Cümlenin Öğeleri'),
            SubjectTopic(name: 'Cümle Türleri'),
            SubjectTopic(name: 'Anlatım Bozuklukları'),
          ]),
          'Tarih (Sosyal Bilimler)':
          SubjectDetails(questionCount: 5, topics: [
            SubjectTopic(name: 'Tarih ve Zaman'),
            SubjectTopic(name: 'İnsanlığın İlk Dönemleri'),
            SubjectTopic(name: 'Orta Çağ\'da Dünya'),
            SubjectTopic(name: 'İlk ve Orta Çağlarda Türk Dünyası'),
            SubjectTopic(name: 'İslam Medeniyetinin Doğuşu'),
            SubjectTopic(name: 'Türklerin İslamiyet\'i Kabulü ve İlk Türk İslam Devletleri'),
            SubjectTopic(name: 'Yerleşme ve Devletleşme Sürecinde Selçuklu Türkiyesi'),
            SubjectTopic(name: 'Beylikten Devlete Osmanlı Siyaseti (1302-1453)'),
            SubjectTopic(name: 'Dünya Gücü Osmanlı Devleti (1453-1600)'),
            SubjectTopic(name: 'Değişen Dünya Dengeleri Karşısında Osmanlı Siyaseti (1595-1774)'),
            SubjectTopic(name: 'Uluslararası İlişkilerde Denge Stratejisi (1774-1914)'),
            SubjectTopic(name: 'Milli Mücadele'),
            SubjectTopic(name: 'Atatürkçülük ve Türk İnkılabı'),
          ]),
          'Coğrafya (Sosyal Bilimler)':
          SubjectDetails(questionCount: 5, topics: [
            SubjectTopic(name: 'Doğa, İnsan ve Coğrafya'),
            SubjectTopic(name: 'Dünya\'nın Şekli ve Hareketleri'),
            SubjectTopic(name: 'Harita Bilgisi'),
            SubjectTopic(name: 'İklim Bilgisi'),
            SubjectTopic(name: 'Yer\'in Şekillenmesi (İç ve Dış Kuvvetler)'),
            SubjectTopic(name: 'Su, Toprak ve Bitki Varlığı'),
            SubjectTopic(name: 'Nüfus ve Yerleşme'),
            SubjectTopic(name: 'Ekonomik Faaliyetler'),
            SubjectTopic(name: 'Ulaşım Yolları'),
            SubjectTopic(name: 'Bölgeler ve Ülkeler'),
            SubjectTopic(name: 'Doğal Afetler ve Toplum'),
          ]),
          'Felsefe (Sosyal Bilimler)':
          SubjectDetails(questionCount: 5, topics: [
            SubjectTopic(name: 'Felsefeye Giriş'),
            SubjectTopic(name: 'Felsefe ile Düşünme'),
            SubjectTopic(name: 'Bilgi Felsefesi (Epistemoloji)'),
            SubjectTopic(name: 'Varlık Felsefesi (Ontoloji)'),
            SubjectTopic(name: 'Ahlak Felsefesi (Etik)'),
            SubjectTopic(name: 'Sanat Felsefesi (Estetik)'),
            SubjectTopic(name: 'Din Felsefesi'),
            SubjectTopic(name: 'Siyaset Felsefesi'),
            SubjectTopic(name: 'Bilim Felsefesi'),
            SubjectTopic(name: 'MÖ 6. Yüzyıl - MS 2. Yüzyıl Felsefesi'),
            SubjectTopic(name: 'MS 2. Yüzyıl - MS 15. Yüzyıl Felsefesi'),
          ]),
          'Din Kültürü ve Ahlak Bilgisi (Sosyal Bilimler)':
          SubjectDetails(questionCount: 5, topics: [
            SubjectTopic(name: 'Bilgi ve İnanç'),
            SubjectTopic(name: 'Din ve İslam'),
            SubjectTopic(name: 'İnsan ve Din'),
            SubjectTopic(name: 'Kur\'an\'a Göre Hz. Muhammed'),
            SubjectTopic(name: 'İnançla İlgili Meseleler'),
            SubjectTopic(name: 'İbadet'),
            SubjectTopic(name: 'Ahlaki Tutum ve Davranışlar'),
            SubjectTopic(name: 'İslam Düşüncesinde Yorumlar'),
          ]),
          'Temel Matematik': SubjectDetails(questionCount: 40, topics: [
            SubjectTopic(name: 'Temel Kavramlar'),
            SubjectTopic(name: 'Sayı Basamakları'),
            SubjectTopic(name: 'Bölme ve Bölünebilme'),
            SubjectTopic(name: 'EBOB-EKOK'),
            SubjectTopic(name: 'Rasyonel Sayılar'),
            SubjectTopic(name: 'Basit Eşitsizlikler'),
            SubjectTopic(name: 'Mutlak Değer'),
            SubjectTopic(name: 'Üslü Sayılar'),
            SubjectTopic(name: 'Köklü Sayılar'),
            SubjectTopic(name: 'Çarpanlara Ayırma'),
            SubjectTopic(name: 'Oran-Orantı'),
            SubjectTopic(name: 'Denklem Çözme'),
            SubjectTopic(name: 'Problemler'),
            SubjectTopic(name: 'Kümeler ve Kartezyen Çarpım'),
            SubjectTopic(name: 'Mantık'),
            SubjectTopic(name: 'Fonksiyonlar'),
            SubjectTopic(name: 'Polinomlar'),
            SubjectTopic(name: 'Permütasyon-Kombinasyon-Binom-Olasılık'),
            SubjectTopic(name: 'Veri ve İstatistik'),
            SubjectTopic(name: 'Doğruda ve Üçgende Açılar'),
            SubjectTopic(name: 'Özel Üçgenler'),
            SubjectTopic(name: 'Üçgende Alan, Açıortay, Kenarortay'),
            SubjectTopic(name: 'Üçgende Benzerlik ve Açı-Kenar Bağıntıları'),
            SubjectTopic(name: 'Çokgenler ve Dörtgenler'),
            SubjectTopic(name: 'Çember ve Daire'),
            SubjectTopic(name: 'Katı Cisimler'),
            SubjectTopic(name: 'Analitik Geometri'),
          ]),
          'Fizik (Fen Bilimleri)': SubjectDetails(questionCount: 7, topics: [
            SubjectTopic(name: 'Fizik Bilimine Giriş'),
            SubjectTopic(name: 'Madde ve Özellikleri'),
            SubjectTopic(name: 'Hareket ve Kuvvet'),
            SubjectTopic(name: 'İş, Güç ve Enerji'),
            SubjectTopic(name: 'Isı, Sıcaklık ve Genleşme'),
            SubjectTopic(name: 'Basınç ve Kaldırma Kuvveti'),
            SubjectTopic(name: 'Elektrik'),
            SubjectTopic(name: 'Manyetizma'),
            SubjectTopic(name: 'Dalgalar'),
            SubjectTopic(name: 'Optik'),
          ]),
          'Kimya (Fen Bilimleri)': SubjectDetails(questionCount: 7, topics: [
            SubjectTopic(name: 'Kimya Bilimi'),
            SubjectTopic(name: 'Atom ve Periyodik Sistem'),
            SubjectTopic(name: 'Kimyasal Türler Arası Etkileşimler'),
            SubjectTopic(name: 'Maddenin Halleri'),
            SubjectTopic(name: 'Doğa ve Kimya'),
            SubjectTopic(name: 'Kimyanın Temel Kanunları ve Hesaplamalar'),
            SubjectTopic(name: 'Karışımlar'),
            SubjectTopic(name: 'Asitler, Bazlar ve Tuzlar'),
            SubjectTopic(name: 'Kimya Her Yerde'),
          ]),
          'Biyoloji (Fen Bilimleri)': SubjectDetails(questionCount: 6, topics: [
            SubjectTopic(name: 'Canlıların Ortak Özellikleri'),
            SubjectTopic(name: 'Canlıların Temel Bileşenleri'),
            SubjectTopic(name: 'Hücre ve Organelleri'),
            SubjectTopic(name: 'Hücre Zarından Madde Geçişleri'),
            SubjectTopic(name: 'Canlıların Sınıflandırılması'),
            SubjectTopic(name: 'Hücre Bölünmeleri (Mitoz ve Mayoz)'),
            SubjectTopic(name: 'Kalıtımın Genel İlkeleri'),
            SubjectTopic(name: 'Ekosistem Ekolojisi ve Güncel Çevre Sorunları'),
          ]),
        }),
        ExamSection(name: 'AYT - Sayısal', subjects: {
          'Matematik': SubjectDetails(questionCount: 40, topics: [
            SubjectTopic(name: 'Temel Kavramlar'),
            SubjectTopic(name: 'Sayı Basamakları'),
            SubjectTopic(name: 'Bölme ve Bölünebilme'),
            SubjectTopic(name: 'EBOB-EKOK'),
            SubjectTopic(name: 'Rasyonel Sayılar'),
            SubjectTopic(name: 'Basit Eşitsizlikler'),
            SubjectTopic(name: 'Mutlak Değer'),
            SubjectTopic(name: 'Üslü Sayılar'),
            SubjectTopic(name: 'Köklü Sayılar'),
            SubjectTopic(name: 'Çarpanlara Ayırma'),
            SubjectTopic(name: 'Oran-Orantı'),
            SubjectTopic(name: 'Denklem Çözme'),
            SubjectTopic(name: 'Problemler'),
            SubjectTopic(name: 'Kümeler ve Kartezyen Çarpım'),
            SubjectTopic(name: 'Mantık'),
            SubjectTopic(name: 'Fonksiyonlar'),
            SubjectTopic(name: 'Polinomlar'),
            SubjectTopic(name: 'İkinci Dereceden Denklemler'),
            SubjectTopic(name: 'Parabol'),
            SubjectTopic(name: 'Eşitsizlikler'),
            SubjectTopic(name: 'Trigonometri'),
            SubjectTopic(name: 'Logaritma'),
            SubjectTopic(name: 'Diziler'),
            SubjectTopic(name: 'Permütasyon-Kombinasyon-Binom-Olasılık'),
            SubjectTopic(name: 'Limit ve Süreklilik'),
            SubjectTopic(name: 'Türev ve Uygulamaları'),
            SubjectTopic(name: 'İntegral ve Uygulamaları'),
            SubjectTopic(name: 'Çember ve Daire'),
            SubjectTopic(name: 'Analitik Geometri'),
            SubjectTopic(name: 'Çemberin Analitik İncelenmesi'),
            SubjectTopic(name: 'Katı Cisimler'),
            SubjectTopic(name: 'Dönüşümlerle Geometri'),
          ]),
          'Fizik': SubjectDetails(questionCount: 14, topics: [
            SubjectTopic(name: 'Vektörler ve Kuvvet-Denge'),
            SubjectTopic(name: 'Tork ve Denge'),
            SubjectTopic(name: 'Kütle Merkezi'),
            SubjectTopic(name: 'Basit Makineler'),
            SubjectTopic(name: 'Hareket (Doğrusal, Bağıl)'),
            SubjectTopic(name: 'Dinamik (Newton\'un Hareket Yasaları)'),
            SubjectTopic(name: 'İş, Güç ve Enerji'),
            SubjectTopic(name: 'Atışlar'),
            SubjectTopic(name: 'İtme ve Çizgisel Momentum'),
            SubjectTopic(name: 'Çembersel Hareket'),
            SubjectTopic(name: 'Basit Harmonik Hareket'),
            SubjectTopic(name: 'Dönme, Yuvarlanma ve Açısal Momentum'),
            SubjectTopic(name: 'Kütle Çekim ve Kepler Kanunları'),
            SubjectTopic(name: 'Elektriksel Kuvvet ve Alan'),
            SubjectTopic(name: 'Elektriksel Potansiyel ve Enerji'),
            SubjectTopic(name: 'Düzgün Elektrik Alan ve Sığa'),
            SubjectTopic(name: 'Manyetizma ve Elektromanyetik İndüksiyon'),
            SubjectTopic(name: 'Alternatif Akım ve Transformatörler'),
            SubjectTopic(name: 'Dalga Mekaniği (Su ve Işık Dalgaları)'),
            SubjectTopic(name: 'Atom Fiziğine Giriş ve Radyoaktivite'),
            SubjectTopic(name: 'Modern Fizik'),
            SubjectTopic(name: 'Modern Fiziğin Teknolojideki Uygulamaları'),
          ]),
          'Kimya': SubjectDetails(questionCount: 13, topics: [
            SubjectTopic(name: 'Modern Atom Teorisi'),
            SubjectTopic(name: 'Gazlar'),
            SubjectTopic(name: 'Sıvı Çözeltiler ve Çözünürlük'),
            SubjectTopic(name: 'Kimyasal Tepkimelerde Enerji (Entalpi)'),
            SubjectTopic(name: 'Kimyasal Tepkimelerde Hız'),
            SubjectTopic(name: 'Kimyasal Tepkimelerde Denge'),
            SubjectTopic(name: 'Asit-Baz Dengesi'),
            SubjectTopic(name: 'Çözünürlük Dengesi (KÇÇ)'),
            SubjectTopic(name: 'Kimya ve Elektrik (Redoks, Piller)'),
            SubjectTopic(name: 'Karbon Kimyasına Giriş'),
            SubjectTopic(name: 'Organik Bileşikler'),
            SubjectTopic(name: 'Enerji Kaynakları ve Bilimsel Gelişmeler'),
          ]),
          'Biyoloji': SubjectDetails(questionCount: 13, topics: [
            SubjectTopic(name: 'Sinir Sistemi'),
            SubjectTopic(name: 'Endokrin Sistem'),
            SubjectTopic(name: 'Duyu Organları'),
            SubjectTopic(name: 'Destek ve Hareket Sistemi'),
            SubjectTopic(name: 'Sindirim Sistemi'),
            SubjectTopic(name: 'Dolaşım ve Bağışıklık Sistemi'),
            SubjectTopic(name: 'Solunum Sistemi'),
            SubjectTopic(name: 'Boşaltım Sistemi (Üriner Sistem)'),
            SubjectTopic(name: 'Üreme Sistemi ve Embriyonik Gelişim'),
            SubjectTopic(name: 'Komünite ve Popülasyon Ekolojisi'),
            SubjectTopic(name: 'Genden Proteine'),
            SubjectTopic(name: 'Canlılarda Enerji Dönüşümleri'),
            SubjectTopic(name: 'Bitki Biyolojisi'),
            SubjectTopic(name: 'Canlılar ve Çevre'),
          ]),
        }),
        ExamSection(name: 'AYT - Eşit Ağırlık', subjects: {
          'Matematik': SubjectDetails(questionCount: 40, topics: [
            SubjectTopic(name: 'Temel Kavramlar'),
            SubjectTopic(name: 'Sayı Basamakları'),
            SubjectTopic(name: 'Bölme ve Bölünebilme'),
            SubjectTopic(name: 'EBOB-EKOK'),
            SubjectTopic(name: 'Rasyonel Sayılar'),
            SubjectTopic(name: 'Basit Eşitsizlikler'),
            SubjectTopic(name: 'Mutlak Değer'),
            SubjectTopic(name: 'Üslü Sayılar'),
            SubjectTopic(name: 'Köklü Sayılar'),
            SubjectTopic(name: 'Çarpanlara Ayırma'),
            SubjectTopic(name: 'Oran-Orantı'),
            SubjectTopic(name: 'Denklem Çözme'),
            SubjectTopic(name: 'Problemler'),
            SubjectTopic(name: 'Kümeler ve Kartezyen Çarpım'),
            SubjectTopic(name: 'Mantık'),
            SubjectTopic(name: 'Fonksiyonlar'),
            SubjectTopic(name: 'Polinomlar'),
            SubjectTopic(name: 'İkinci Dereceden Denklemler'),
            SubjectTopic(name: 'Parabol'),
            SubjectTopic(name: 'Eşitsizlikler'),
            SubjectTopic(name: 'Trigonometri'),
            SubjectTopic(name: 'Logaritma'),
            SubjectTopic(name: 'Diziler'),
            SubjectTopic(name: 'Permütasyon-Kombinasyon-Binom-Olasılık'),
            SubjectTopic(name: 'Limit ve Süreklilik'),
            SubjectTopic(name: 'Türev ve Uygulamaları'),
            SubjectTopic(name: 'İntegral ve Uygulamaları'),
            SubjectTopic(name: 'Çember ve Daire'),
            SubjectTopic(name: 'Analitik Geometri'),
            SubjectTopic(name: 'Çemberin Analitik İncelenmesi'),
            SubjectTopic(name: 'Katı Cisimler'),
            SubjectTopic(name: 'Dönüşümlerle Geometri'),
          ]),
          'Türk Dili ve Edebiyatı':
          SubjectDetails(questionCount: 24, topics: [
            SubjectTopic(name: 'Anlam Bilgisi (Sözcük, Cümle, Paragraf)'),
            SubjectTopic(name: 'Güzel Sanatlar ve Edebiyat'),
            SubjectTopic(name: 'Metinlerin Sınıflandırılması'),
            SubjectTopic(name: 'Şiir Bilgisi'),
            SubjectTopic(name: 'Edebi Sanatlar'),
            SubjectTopic(name: 'İslamiyet Öncesi Türk Edebiyatı'),
            SubjectTopic(name: 'İslam Uygarlığı Çevresinde Gelişen Türk Edebiyatı'),
            SubjectTopic(name: 'Halk Edebiyatı'),
            SubjectTopic(name: 'Divan Edebiyatı'),
            SubjectTopic(name: 'Batı Etkisindeki Türk Edebiyatı'),
            SubjectTopic(name: 'Tanzimat Edebiyatı'),
            SubjectTopic(name: 'Servet-i Fünun Edebiyatı'),
            SubjectTopic(name: 'Fecr-i Ati Edebiyatı'),
            SubjectTopic(name: 'Milli Edebiyat'),
            SubjectTopic(name: 'Cumhuriyet Dönemi Türk Edebiyatı'),
            SubjectTopic(name: 'Edebi Akımlar'),
            SubjectTopic(name: 'Dünya Edebiyatı'),
          ]),
          'Tarih-1': SubjectDetails(questionCount: 10, topics: [
            SubjectTopic(name: 'Tarih ve Zaman'),
            SubjectTopic(name: 'İnsanlığın İlk Dönemleri'),
            SubjectTopic(name: 'Orta Çağ\'da Dünya'),
            SubjectTopic(name: 'İlk ve Orta Çağlarda Türk Dünyası'),
            SubjectTopic(name: 'İslam Medeniyetinin Doğuşu'),
            SubjectTopic(name: 'Türklerin İslamiyet\'i Kabulü ve İlk Türk İslam Devletleri'),
            SubjectTopic(name: 'Yerleşme ve Devletleşme Sürecinde Selçuklu Türkiyesi'),
            SubjectTopic(name: 'Beylikten Devlete Osmanlı Siyaseti (1302-1453)'),
            SubjectTopic(name: 'Dünya Gücü Osmanlı Devleti (1453-1600)'),
            SubjectTopic(name: 'Sultan ve Osmanlı Merkez Teşkilatı'),
            SubjectTopic(name: 'Klasik Çağda Osmanlı Toplum Düzeni'),
            SubjectTopic(name: 'Değişen Dünya Dengeleri Karşısında Osmanlı Siyaseti (1595-1774)'),
            SubjectTopic(name: 'Uluslararası İlişkilerde Denge Stratejisi (1774-1914)'),
            SubjectTopic(name: 'Osmanlı Devleti\'nde Demokratikleşme Hareketleri'),
            SubjectTopic(name: 'Milli Mücadele'),
            SubjectTopic(name: 'Atatürkçülük ve Türk İnkılabı'),
          ]),
          'Coğrafya-1': SubjectDetails(questionCount: 6, topics: [
            SubjectTopic(name: 'Ekosistem, Madde Döngüsü ve Enerji Akışı'),
            SubjectTopic(name: 'Biyoçeşitlilik'),
            SubjectTopic(name: 'Nüfus Politikaları ve Şehirleşme'),
            SubjectTopic(name: 'Ekonomik Faaliyetler ve Doğal Kaynaklar'),
            SubjectTopic(name: 'Türkiye\'de Nüfus, Yerleşme ve Göç'),
            SubjectTopic(name: 'Türkiye Ekonomisi'),
            SubjectTopic(name: 'Türkiye\'nin Jeopolitik Konumu'),
            SubjectTopic(name: 'Bölgeler ve Ülkeler (Kültür Bölgeleri)'),
            SubjectTopic(name: 'Uluslararası Ulaşım Hatları'),
            SubjectTopic(name: 'Çevre Sorunları ve Sürdürülebilirlik'),
          ]),
        }),
        ExamSection(name: 'AYT - Sözel', subjects: {
          'Türk Dili ve Edebiyatı':
          SubjectDetails(questionCount: 24, topics: [
            SubjectTopic(name: 'Anlam Bilgisi (Sözcük, Cümle, Paragraf)'),
            SubjectTopic(name: 'Güzel Sanatlar ve Edebiyat'),
            SubjectTopic(name: 'Metinlerin Sınıflandırılması'),
            SubjectTopic(name: 'Şiir Bilgisi'),
            SubjectTopic(name: 'Edebi Sanatlar'),
            SubjectTopic(name: 'İslamiyet Öncesi Türk Edebiyatı'),
            SubjectTopic(name: 'İslam Uygarlığı Çevresinde Gelişen Türk Edebiyatı'),
            SubjectTopic(name: 'Halk Edebiyatı'),
            SubjectTopic(name: 'Divan Edebiyatı'),
            SubjectTopic(name: 'Batı Etkisindeki Türk Edebiyatı'),
            SubjectTopic(name: 'Tanzimat Edebiyatı'),
            SubjectTopic(name: 'Servet-i Fünun Edebiyatı'),
            SubjectTopic(name: 'Fecr-i Ati Edebiyatı'),
            SubjectTopic(name: 'Milli Edebiyat'),
            SubjectTopic(name: 'Cumhuriyet Dönemi Türk Edebiyatı'),
            SubjectTopic(name: 'Edebi Akımlar'),
            SubjectTopic(name: 'Dünya Edebiyatı'),
          ]),
          'Tarih-1': SubjectDetails(questionCount: 10, topics: [
            SubjectTopic(name: 'Tarih ve Zaman'),
            SubjectTopic(name: 'İnsanlığın İlk Dönemleri'),
            SubjectTopic(name: 'Orta Çağ\'da Dünya'),
            SubjectTopic(name: 'İlk ve Orta Çağlarda Türk Dünyası'),
            SubjectTopic(name: 'İslam Medeniyetinin Doğuşu'),
            SubjectTopic(name: 'Türklerin İslamiyet\'i Kabulü ve İlk Türk İslam Devletleri'),
            SubjectTopic(name: 'Yerleşme ve Devletleşme Sürecinde Selçuklu Türkiyesi'),
            SubjectTopic(name: 'Beylikten Devlete Osmanlı Siyaseti (1302-1453)'),
            SubjectTopic(name: 'Dünya Gücü Osmanlı Devleti (1453-1600)'),
            SubjectTopic(name: 'Sultan ve Osmanlı Merkez Teşkilatı'),
            SubjectTopic(name: 'Klasik Çağda Osmanlı Toplum Düzeni'),
            SubjectTopic(name: 'Değişen Dünya Dengeleri Karşısında Osmanlı Siyaseti (1595-1774)'),
            SubjectTopic(name: 'Uluslararası İlişkilerde Denge Stratejisi (1774-1914)'),
            SubjectTopic(name: 'Osmanlı Devleti\'nde Demokratikleşme Hareketleri'),
            SubjectTopic(name: 'Milli Mücadele'),
            SubjectTopic(name: 'Atatürkçülük ve Türk İnkılabı'),
          ]),
          'Coğrafya-1': SubjectDetails(questionCount: 6, topics: [
            SubjectTopic(name: 'Ekosistem, Madde Döngüsü ve Enerji Akışı'),
            SubjectTopic(name: 'Biyoçeşitlilik'),
            SubjectTopic(name: 'Nüfus Politikaları ve Şehirleşme'),
            SubjectTopic(name: 'Ekonomik Faaliyetler ve Doğal Kaynaklar'),
            SubjectTopic(name: 'Türkiye\'de Nüfus, Yerleşme ve Göç'),
            SubjectTopic(name: 'Türkiye Ekonomisi'),
            SubjectTopic(name: 'Türkiye\'nin Jeopolitik Konumu'),
            SubjectTopic(name: 'Bölgeler ve Ülkeler (Kültür Bölgeleri)'),
            SubjectTopic(name: 'Uluslararası Ulaşım Hatları'),
            SubjectTopic(name: 'Çevre Sorunları ve Sürdürülebilirlik'),
          ]),
          'Tarih-2': SubjectDetails(questionCount: 11, topics: [
            SubjectTopic(name: 'İlk Çağ Medeniyetleri'),
            SubjectTopic(name: 'Türklerin Anayurdu ve İlk Türk Devletleri'),
            SubjectTopic(name: 'İslam Tarihi ve Uygarlığı'),
            SubjectTopic(name: 'Avrupa Tarihi (Orta Çağ, Yeni Çağ, Yakın Çağ)'),
            SubjectTopic(name: 'Osmanlı Devleti (Kuruluş, Yükselme, Kültür Medeniyet)'),
            SubjectTopic(name: 'Osmanlı Devleti (Duraklama, Gerileme, Dağılma)'),
            SubjectTopic(name: '20. Yüzyıl Başlarında Osmanlı ve Dünya'),
            SubjectTopic(name: 'I. Dünya Savaşı ve Sonrası'),
            SubjectTopic(name: 'İkinci Dünya Savaşı'),
            SubjectTopic(name: 'Soğuk Savaş Dönemi'),
            SubjectTopic(name: 'Yumuşama Dönemi ve Sonrası'),
            SubjectTopic(name: 'Küreselleşen Dünya'),
            SubjectTopic(name: 'Türklerde Devlet Teşkilatı'),
          ]),
          'Coğrafya-2': SubjectDetails(questionCount: 11, topics: [
            SubjectTopic(name: 'Şehirlerin Fonksiyonları ve Etki Alanları'),
            SubjectTopic(name: 'Türkiye\'de Arazi Kullanımı ve Kır Yerleşmeleri'),
            SubjectTopic(name: 'Türkiye\'de Enerji Kaynakları, Sanayi ve Ticaret'),
            SubjectTopic(name: 'Küresel Ticaret ve Turizm'),
            SubjectTopic(name: 'Jeopolitik Konum ve Ülkelerin Gelişmişliği'),
            SubjectTopic(name: 'Kültür Bölgeleri ve Medeniyetler'),
            SubjectTopic(name: 'Çevre Politikaları ve Ülkeler Arası Sorunlar'),
            SubjectTopic(name: 'Doğal Kaynaklar ve Sürdürülebilir Kalkınma'),
            SubjectTopic(name: 'Bölgesel Kalkınma Projeleri'),
          ]),
          'Felsefe Grubu': SubjectDetails(questionCount: 12, topics: [
            SubjectTopic(name: '15. Yüzyıl - 17. Yüzyıl Felsefesi'),
            SubjectTopic(name: '18. Yüzyıl - 19. Yüzyıl Felsefesi'),
            SubjectTopic(name: '20. Yüzyıl Felsefesi'),
            SubjectTopic(name: 'Psikoloji Bilimini Tanıyalım'),
            SubjectTopic(name: 'Psikolojinin Temel Süreçleri'),
            SubjectTopic(name: 'Öğrenme, Bellek, Düşünme'),
            SubjectTopic(name: 'Ruh Sağlığının Temelleri'),
            SubjectTopic(name: 'Sosyolojiye Giriş'),
            SubjectTopic(name: 'Birey ve Toplum'),
            SubjectTopic(name: 'Toplumsal Yapı'),
            SubjectTopic(name: 'Toplumsal Değişme ve Gelişme'),
            SubjectTopic(name: 'Toplum ve Kültür'),
            SubjectTopic(name: 'Toplumsal Kurumlar'),
            SubjectTopic(name: 'Mantığa Giriş'),
            SubjectTopic(name: 'Klasik Mantık'),
            SubjectTopic(name: 'Mantık ve Dil'),
            SubjectTopic(name: 'Sembolik (Modern) Mantık'),
          ]),
          'Din Kültürü ve Ahlak Bilgisi':
          SubjectDetails(questionCount: 6, topics: [
            SubjectTopic(name: 'İslam ve Bilim, Estetik, Ekonomi'),
            SubjectTopic(name: 'Anadolu\'da İslam'),
            SubjectTopic(name: 'Tasavvufi Düşünce ve Yorumlar'),
            SubjectTopic(name: 'Güncel Dini Meseleler'),
            SubjectTopic(name: 'Yaşayan Dinler (Yahudilik, Hristiyanlık)'),
            SubjectTopic(name: 'Hint ve Çin Dinleri (Hinduizm, Budizm, Konfüçyanizm, Taoizm)'),
          ]),
        }),
      ],
    ),
    // KPSS Lisans
    Exam(
      type: ExamType.kpssLisans,
      name: 'Kamu Personel Seçme Sınavı (Lisans)',
      sections: [
        ExamSection(
          name: 'Genel Yetenek - Genel Kültür',
          subjects: _kpssGyGkSubjects,
        ),
      ],
    ),
    // KPSS Önlisans (YENİ EKLENDİ)
    Exam(
      type: ExamType.kpssOnlisans,
      name: 'Kamu Personel Seçme Sınavı (Önlisans)',
      sections: [
        ExamSection(
          name: 'Genel Yetenek - Genel Kültür',
          subjects: _kpssGyGkSubjects,
        ),
      ],
    ),
    // KPSS Ortaöğretim (YENİ EKLENDİ)
    Exam(
      type: ExamType.kpssOrtaogretim,
      name: 'Kamu Personel Seçme Sınavı (Ortaöğretim)',
      sections: [
        ExamSection(
          name: 'Genel Yetenek - Genel Kültür',
          subjects: _kpssGyGkSubjects,
        ),
      ],
    ),
  ];

  static Exam getExamByType(ExamType type) {
    return exams.firstWhere((exam) => exam.type == type);
  }

  static List<SubjectTopic> getAllTopicsForSubject(String subjectName) {
    for (var exam in exams) {
      for (var section in exam.sections) {
        if (section.subjects.containsKey(subjectName)) {
          return section.subjects[subjectName]!.topics;
        }
      }
    }
    return [];
  }
}
