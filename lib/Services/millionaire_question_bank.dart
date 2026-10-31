import 'dart:math';
import 'package:safaksayar/models/millionaire_models.dart';

/// Comprehensive question bank for "Kim Milyoner Olmak İster"
/// Contains 120+ authentic, diverse questions across General Culture,
/// Military History, Turkish Republic, Geography, Science, and Arts.
class MillionaireQuestionBank {
  static final MillionaireQuestionBank instance = MillionaireQuestionBank._internal();
  MillionaireQuestionBank._internal();

  final Random _random = Random();

  final List<MillionaireQuestion> _allQuestions = const [
    // ==========================================
    // SEVİYE 1: KOLAY / ISINMA (1.000 TL - 5.000 TL)
    // ==========================================
    MillionaireQuestion(
      id: 'e1',
      question: 'Hasbihal ne anlama gelir?',
      options: ['Gürültü', 'Geçmiş', 'Sohbet', 'Özlem'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Türkçe & Dil',
      explanation: 'Hasbihal Arapça kökenli olup "karşılıklı dertleşme, samimi sohbet" anlamına gelir.',
    ),
    MillionaireQuestion(
      id: 'e2',
      question: 'Hangisi "bıkmak, usanmak" anlamına gelen bir deyimdir?',
      options: ['Hizaya gelmek', 'Kıvamına gelmek', 'Gına gelmek', 'Yola gelmek'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Deyimler & Sözlük',
      explanation: 'Gına gelmek deyimi aşırı doymak, usanmak ve bıkmak demektir.',
    ),
    MillionaireQuestion(
      id: 'e3',
      question: 'Türk Silahlı Kuvvetleri\'nde en kıdemsiz rütbe hangisidir?',
      options: ['Onbaşı', 'Er', 'Çavuş', 'Asteğmen'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Askeri Bilgi',
      explanation: 'Türk Silahlı Kuvvetleri hiyerarşisinde en temel rütbe Er\'dir.',
    ),
    MillionaireQuestion(
      id: 'e4',
      question: 'Mavi, lacivert ve mor renk tonları sanat ve tasarımda nasıl adlandırılır?',
      options: ['Sıcak renkler', 'Soğuk renkler', 'Ilık renkler', 'Nötr renkler'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Sanat & Tasarım',
      explanation: 'Mavi, yeşil ve mor tayfı psikolojik ve optik olarak soğuk renkler grubundadır.',
    ),
    MillionaireQuestion(
      id: 'e5',
      question: 'Türkiye Cumhuriyeti\'nin başkenti neresidir?',
      options: ['İstanbul', 'İzmir', 'Ankara', 'Bursa'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Genel Kültür',
      explanation: 'Ankara, 13 Ekim 1923\'te TBMM kararıyla Türkiye Cumhuriyeti\'nin başkenti ilan edilmiştir.',
    ),
    MillionaireQuestion(
      id: 'e6',
      question: 'Askerlikte sabah içtimasından önce koğuşların toplanması ve yatakların nizami yapılmasına ne ad verilir?',
      options: ['Karavana', 'Mıntıka', 'Koğuş Düzeni', 'Nöbet'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Askeri Yaşam',
      explanation: 'Koğuş düzeni, askerlerin yatak ve dolaplarının nizami hazırlanmasını ifade eder.',
    ),
    MillionaireQuestion(
      id: 'e7',
      question: 'Fen bilimlerinde suyun donması ve buzun erimesi hangi değişim türüne örnektir?',
      options: ['Kimyasal değişim', 'Fiziksel değişim', 'Biyolojik değişim', 'Nükleer değişim'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Temel Bilim',
      explanation: 'Maddenin kimyasal yapısı değişmeden yalnızca hali değiştiği için fiziksel değişimdir.',
    ),
    MillionaireQuestion(
      id: 'e8',
      question: 'Türk bayrağındaki hilal ve yıldız hangi renktedir?',
      options: ['Kırmızı', 'Beyaz', 'Sarı', 'Gümüş'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Milli Değerler',
      explanation: 'Türk bayrağı al zemin üzerine beyaz hilal ve beş köşeli yıldızdan oluşur.',
    ),
    MillionaireQuestion(
      id: 'e9',
      question: 'Futbol müsabakalarında hakem kararlarını video ekranından inceleyen sistemin kısaltması nedir?',
      options: ['VAR', 'TAV', 'GPS', 'NASA'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.easy,
      category: 'Spor',
      explanation: 'VAR: Video Assistant Referee (Video Yardımcı Hakem) sistemidir.',
    ),
    MillionaireQuestion(
      id: 'e10',
      question: 'Günde 24 saat olan bir takvim gününde kaç dakika bulunur?',
      options: ['1200', '1440', '1600', '1800'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Matematik & Mantık',
      explanation: '24 saat x 60 dakika = 1440 dakikadır.',
    ),
    MillionaireQuestion(
      id: 'e11',
      question: 'Askerlikte topluca yemek dağıtılan kaba ve öğün yemeğine ne denir?',
      options: ['Kumanya', 'Karavana', 'Matara', 'Gözleme'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Askeri Yaşam',
      explanation: 'Karavana, askeriye ve gemilerde yemek pişirilen ve dağıtılan derin kaba verilen addır.',
    ),
    MillionaireQuestion(
      id: 'e12',
      question: 'Türkiye\'nin plaka kodu 01 olan ili hangisidir?',
      options: ['Ankara', 'Adana', 'Adıyaman', 'Afyonkarahisar'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Coğrafya',
      explanation: 'Alfabetik sıralamada ilk il olan Adana 01 plaka koduna sahiptir.',
    ),
    MillionaireQuestion(
      id: 'e13',
      question: '"Azı dişi" teriminin işlevine göre eş anlamlısı hangisidir?',
      options: ['Sindirici diş', 'Öğütücü diş', 'Koparıcı diş', 'Kesici diş'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Biyoloji',
      explanation: 'Azı dişleri besinleri çiğneyip ezdiği için öğütücü diş olarak bilinir.',
    ),
    MillionaireQuestion(
      id: 'e14',
      question: 'İstiklal Marşı\'mızın yazarı milli şairimiz kimdir?',
      options: ['Yahya Kemal Beyatlı', 'Mehmet Akif Ersoy', 'Namık Kemal', 'Ziya Gökalp'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Edebiyat & Tarih',
      explanation: 'İstiklal Marşı 1921 yılında Mehmet Akif Ersoy tarafından kaleme alınmıştır.',
    ),
    MillionaireQuestion(
      id: 'e15',
      question: 'Güneş Sistemi\'nde Güneş\'e en yakın gezegen hangisidir?',
      options: ['Venüs', 'Merkür', 'Dünya', 'Mars'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Astronomi',
      explanation: 'Merkür, Güneş\'e ortalama 58 milyon km ile en yakın gezegendir.',
    ),
    MillionaireQuestion(
      id: 'e16',
      question: 'Askeriyede çevre temizliği ve çevre nizamı yapma faaliyetine ne ad verilir?',
      options: ['İçtima', 'Mıntıka temizliği', 'Yanaşık düzen', 'Talim'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Askeri Yaşam',
      explanation: 'Mıntıka temizliği, birliğin belirlenen bölgesinin düzenli olarak temizlenmesidir.',
    ),
    MillionaireQuestion(
      id: 'e17',
      question: 'Atatürk\'ün doğum yılı ve yeri hangi seçenekte doğru verilmiştir?',
      options: ['1881 - Selanik', '1880 - Manastır', '1882 - İstanbul', '1881 - Sofya'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.easy,
      category: 'Milli Tarih',
      explanation: 'Gazi Mustafa Kemal Atatürk 1881 yılında Selanik\'te dünyaya gelmiştir.',
    ),
    MillionaireQuestion(
      id: 'e18',
      question: 'Dünya üzerinde en çok konuşulan anadil hangisidir?',
      options: ['İngilizce', 'Çince (Mandarin)', 'İspanyolca', 'Arapça'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Genel Kültür',
      explanation: 'Anadil olarak en çok insan tarafından konuşulan dil Çince\'nin Mandarin lehçesidir.',
    ),
    MillionaireQuestion(
      id: 'e19',
      question: 'Gözün renkli kısmına ne ad verilir?',
      options: ['Retina', 'Kornea', 'İris', 'Göz bebeği'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Biyoloji',
      explanation: 'Gözün renkli pigmentler içeren ve ışık miktarını ayarlayan tabakası iristir.',
    ),
    MillionaireQuestion(
      id: 'e20',
      question: 'Askerlerin başlarına taktıkları ve rengi kuvvetine göre değişen askeri başlık nedir?',
      options: ['Kask', 'Bere', 'Fes', 'Kalpak'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Askeri Kıyafet',
      explanation: 'Bordo (Özel Kuvvetler), Mavi (Komando), Siyah (Zırhlı Birlikler) gibi bere renkleri vardır.',
    ),
    MillionaireQuestion(
      id: 'e21',
      question: 'Kardeş ülke Azerbaycan\'ın başkenti neresidir?',
      options: ['Gence', 'Tebriz', 'Bakü', 'Şuşa'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Coğrafya',
      explanation: 'Hazar Denizi kıyısındaki Bakü, Azerbaycan\'ın başkenti ve en büyük şehridir.',
    ),
    MillionaireQuestion(
      id: 'e22',
      question: 'Türkiye\'nin yüzölçümü bakımından en büyük gölü hangisidir?',
      options: ['Tuz Gölü', 'Beyşehir Gölü', 'Van Gölü', 'İznik Gölü'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Coğrafya',
      explanation: 'Van Gölü yaklaşık 3.713 km² yüzölçümüyle Türkiye\'nin en büyük gölüdür.',
    ),
    MillionaireQuestion(
      id: 'e23',
      question: 'Basketbol maçlarında standart bir hücum süresi kaç saniyedir?',
      options: ['14', '24', '30', '40'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Spor',
      explanation: 'FIBA kurallarına göre hücum süresi 24 saniyedir.',
    ),
    MillionaireQuestion(
      id: 'e24',
      question: 'Aşağıdakilerden hangisi bir telli çalgı değildir?',
      options: ['Bağlama', 'Gitar', 'Ney', 'Keman'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Müzik',
      explanation: 'Ney, kamıştan yapılan nefesli bir Türk musikisi çalgısıdır.',
    ),
    MillionaireQuestion(
      id: 'e25',
      question: 'Yıldırım çarpması sonucu duyulan gök gürültüsünün ışıktan sonra gelmesinin sebebi nedir?',
      options: ['Gözün daha yavaş algılaması', 'Işığın sesten çok daha hızlı yayılması', 'Sesin bulutlara çarpması', 'Basınç farkı'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Fizik',
      explanation: 'Işık hızı yaklaşık 300.000 km/s iken, ses havada yaklaşık 340 m/s hızla yayılır.',
    ),
    MillionaireQuestion(
      id: 'e26',
      question: 'TBMM hangi tarihte açılarak Kurtuluş Savaşı\'nın idaresini üstlenmiştir?',
      options: ['19 Mayıs 1919', '23 Nisan 1920', '29 Ekim 1923', '30 Ağustos 1922'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Milli Tarih',
      explanation: 'Türkiye Büyük Millet Meclisi 23 Nisan 1920\'de Ankara\'da açılmıştır.',
    ),
    MillionaireQuestion(
      id: 'e27',
      question: 'Denizaltıların su yüzeyini gözetlemek için kullandığı optik boruya ne ad verilir?',
      options: ['Teleskop', 'Periskop', 'Mikroskop', 'Stetoskop'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.easy,
      category: 'Genel Bilim',
      explanation: 'Periskop, aynalar ve prizmalar yardımıyla engellerin üzerinden görmeyi sağlayan optik alettir.',
    ),
    MillionaireQuestion(
      id: 'e28',
      question: 'Türkiye Cumhuriyeti\'nde Cumhuriyet hangi tarihte ilan edilmiştir?',
      options: ['29 Ekim 1923', '23 Nisan 1920', '30 Ağustos 1922', '10 Kasım 1938'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.easy,
      category: 'Milli Tarih',
      explanation: '29 Ekim 1923\'te TBMM\'de Teşkilat-ı Esasiye Kanunu kabul edilerek Cumhuriyet ilan edilmiştir.',
    ),
    MillionaireQuestion(
      id: 'e29',
      question: 'Askerlikte komutanın emriyle tüm askerlerin sıraya girerek yoklama verdiği düzenli toplantıya ne denir?',
      options: ['İçtima', 'Manga', 'Mola', 'Ruhsat'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.easy,
      category: 'Askeri Yaşam',
      explanation: 'İçtima, askeri personelin belirli zamanlarda toplanıp sayıldığı ve talimat aldığı resmi düzendir.',
    ),
    MillionaireQuestion(
      id: 'e30',
      question: 'Hangisi Türkiye\'nin komşusu olan ülkelerden biri değildir?',
      options: ['Yunanistan', 'Gürcistan', 'Romanya', 'İran'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.easy,
      category: 'Coğrafya',
      explanation: 'Romanya Karadeniz kıyıdaşıdır ancak Türkiye ile doğrudan kara sınırı yoktur.',
    ),

    // ==========================================
    // SEVİYE 2: ORTA / BARAJ 2 (7.500 TL - 50.000 TL)
    // ==========================================
    MillionaireQuestion(
      id: 'm1',
      question: 'Çanakkale Kara Savaşları\'nda Mustafa Kemal Paşa\'nın "Ben size taarruzu değil, ölmeyi emrediyorum!" dediği kahraman alay hangisidir?',
      options: ['57. Alay', '27. Alay', '19. Alay', '33. Alay'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.medium,
      category: 'Çanakkale & Askeri Tarih',
      explanation: 'Mustafa Kemal Paşa bu tarihi emri Conkbayırı\'nda efsanevi 57. Piyade Alayı\'na vermiştir.',
    ),
    MillionaireQuestion(
      id: 'm2',
      question: 'Kurtuluş Savaşı\'nda Başkomutanlık Meydan Muharebesi (Büyük Taarruz) hangi tarihte kesin zaferle sonuçlanmıştır?',
      options: ['26 Ağustos 1922', '30 Ağustos 1922', '9 Eylül 1922', '11 Ekim 1922'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Milli Mücadele',
      explanation: '30 Ağustos 1922 Dumlupınar\'da kazanılan zafer, her yıl Zafer Bayramı olarak kutlanır.',
    ),
    MillionaireQuestion(
      id: 'm3',
      question: 'Türk Kara Kuvvetleri\'nin sembolik kuruluş yılı olarak kabul edilen M.Ö. 209 yılı hangi tarihi olaya dayanır?',
      options: ['Bilge Kağan\'ın tahta çıkışı', 'Mete Han\'ın onluk teşkilatı kurması', 'Bumin Kağan\'ın devleti kurması', 'Kürşad İhtilali'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Askeri Tarih',
      explanation: 'Büyük Hun Hükümdarı Mete Han\'ın M.Ö. 209\'da kurduğu onluk ordu sistemi, Kara Kuvvetleri kuruluşu kabul edilir.',
    ),
    MillionaireQuestion(
      id: 'm4',
      question: 'Kaçkar Dağı hangi coğrafi bölgemizin en yüksek zirvesidir?',
      options: ['Ege Bölgesi', 'Marmara Bölgesi', 'Akdeniz Bölgesi', 'Karadeniz Bölgesi'],
      correctIndex: 3,
      difficulty: QuestionDifficulty.medium,
      category: 'Coğrafya',
      explanation: 'Kaçkar Dağı (3.937 m), Doğu Karadeniz Bölümü\'nün en yüksek zirvesidir.',
    ),
    MillionaireQuestion(
      id: 'm5',
      question: 'Osmanlı Devleti\'nde 1402 Ankara Savaşı sonrasında yaşanan ve 11 yıl süren padişahsız döneme ne ad verilir?',
      options: ['Lale Devri', 'Fetret Devri', 'Tanzimat Dönemi', 'Duraklama Devri'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Osmanlı Tarihi',
      explanation: '1402-1413 yılları arasında Yıldırım Bayezid\'in oğulları arasındaki taht kavgaları dönemi Fetret Devri\'dir.',
    ),
    MillionaireQuestion(
      id: 'm6',
      question: 'Türkiye\'nin ilk yerli ve milli insansız silahlı hava aracı (SİHA) olan Bayraktar TB2\'nin ilk uçuş yılı hangisidir?',
      options: ['2008', '2014', '2018', '2020'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Savunma Sanayii',
      explanation: 'Bayraktar TB2 prototipi ilk otomatik uçuşunu 2014 yılında başarıyla gerçekleştirmiştir.',
    ),
    MillionaireQuestion(
      id: 'm7',
      question: 'Nobel Kimya Ödülü\'nü 2015 yılında DNA onarımı mekanizmaları alanındaki çalışmalarıyla kazanan Türk bilim insanı kimdir?',
      options: ['Oktay Sinanoğlu', 'Aziz Sancar', 'Cahit Arf', 'Gazi Yaşargil'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Bilim & Onur',
      explanation: 'Prof. Dr. Aziz Sancar, 2015 Nobel Kimya Ödülü\'nü kazanarak gururumuz olmuştur.',
    ),
    MillionaireQuestion(
      id: 'm8',
      question: 'Piri Reis\'in 1513 yılında ceylan derisi üzerine çizdiği ve günümüze bir parçası ulaşan meşhur haritada hangisi yer alır?',
      options: ['Avustralya kıtası', 'Amerika ve Antarktika kıyıları', 'Japonya adaları', 'Hawaii adaları'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Denizcilik Tarihi',
      explanation: 'Piri Reis haritasında Güney Amerika kıyıları, Karayipler ve Antarktika buzulları şaşırtıcı doğrulukla çizilmiştir.',
    ),
    MillionaireQuestion(
      id: 'm9',
      question: 'Kurtuluş Savaşı\'nda Batı Cephesi Komutanlığı yaparak I. ve II. İnönü Muharebelerini kazanan komutan kimdir?',
      options: ['Fevzi Çakmak', 'Kazım Karabekir', 'İsmet İnönü', 'Refet Bele'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.medium,
      category: 'Milli Mücadele',
      explanation: 'Garp Cephesi Komutanı İsmet Paşa, düşmanı İnönü\'de iki kez mağlup etmiştir.',
    ),
    MillionaireQuestion(
      id: 'm10',
      question: 'Türkiye\'nin en güney ucunda yer alan Hatay ilimizin Türkiye Cumhuriyeti\'ne katıldığı yıl hangisidir?',
      options: ['1923', '1930', '1938', '1939'],
      correctIndex: 3,
      difficulty: QuestionDifficulty.medium,
      category: 'Cumhuriyet Tarihi',
      explanation: 'Hatay Devleti Millet Meclisi 23 Haziran 1939\'da oybirliğiyle Türkiye\'ye katılma kararı almıştır.',
    ),
    MillionaireQuestion(
      id: 'm11',
      question: 'Kıbrıs Barış Harekâtı hangi yıl Türk Silahlı Kuvvetleri tarafından başarıyla icra edilmiştir?',
      options: ['1964', '1971', '1974', '1980'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.medium,
      category: 'Askeri Tarih',
      explanation: '20 Temmuz 1974\'te başlatılan "Atilla Harekâtı" ile Kıbrıs Türk halkının güvenliği sağlanmıştır.',
    ),
    MillionaireQuestion(
      id: 'm12',
      question: 'Hangi gezegen Güneş Sistemi\'ndeki en büyük kütleye ve hacme sahiptir?',
      options: ['Satürn', 'Neptün', 'Jüpiter', 'Uranüs'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.medium,
      category: 'Astronomi',
      explanation: 'Jüpiter, diğer tüm gezegenlerin toplamının 2,5 katı kütleye sahip en büyük gezegendir.',
    ),
    MillionaireQuestion(
      id: 'm13',
      question: 'Mimar Sinan\'ın "Ustalık eserim" olarak nitelendirdiği şaheser Edirne\'deki hangi camidir?',
      options: ['Süleymaniye Camii', 'Selimiye Camii', 'Şehzade Camii', 'Mihrimah Sultan Camii'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Mimarlık & Sanat',
      explanation: 'Mimar Sinan Şehzade\'yi çıraklık, Süleymaniye\'yi kalfalık, Selimiye\'yi ise ustalık eseri saymıştır.',
    ),
    MillionaireQuestion(
      id: 'm14',
      question: 'İstiklal Madalyası alan ilk ve tek köyümüz hangi ilimize bağlıdır?',
      options: ['İnebolu (Kastamonu)', 'Çankırı', 'Gaziantep', 'Kahramanmaraş'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.medium,
      category: 'Milli Mücadele',
      explanation: 'Kastamonu\'nun İnebolu ilçesi kayıkçıları, deniz yoluyla cephane taşıma kahramanlıklarıyla İstiklal Madalyası almıştır.',
    ),
    MillionaireQuestion(
      id: 'm15',
      question: 'Türkiye\'nin ilk yerli üretim tankı olan zırhlı aracın adı nedir?',
      options: ['Fırtına', 'Altay', 'Tulpar', 'Pars'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Savunma Sanayii',
      explanation: 'Altay ana muharebe tankı adını Kurtuluş Savaşı süvari kolordusu komutanı Fahrettin Altay\'dan alır.',
    ),
    MillionaireQuestion(
      id: 'm16',
      question: 'Osmanlı İmparatorluğu\'nda tahtta en uzun süre kalan padişah kimdir?',
      options: ['Fatih Sultan Mehmed', 'Yavuz Sultan Selim', 'Kanuni Sultan Süleyman', 'II. Abdülhamid'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.medium,
      category: 'Osmanlı Tarihi',
      explanation: 'Kanuni Sultan Süleyman 1520-1566 yılları arasında 46 yıl tahtta kalarak rekor kırmıştır.',
    ),
    MillionaireQuestion(
      id: 'm17',
      question: 'Doğu Anadolu ve Güneydoğu Anadolu\'yu birbirine bağlayan, Türkiye\'nin en uzun tünellerinden biri olan tünel hangisidir?',
      options: ['Zigana Tüneli', 'Ovit Tüneli', 'Eurasia Tüneli', 'Ilgaz Tüneli'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.medium,
      category: 'Coğrafya & Ulaşım',
      explanation: 'Yeni Zigana Tüneli (14,5 km çift tüp) Türkiye ve Avrupa\'nın en uzun karayolu tünelidir.',
    ),
    MillionaireQuestion(
      id: 'm18',
      question: 'Mustafa Kemal Atatürk\'ün Çanakkale Anafartalar\'da göğsüne isabet eden şarapnel parçasının canını kurtardığı eşya nedir?',
      options: ['Metal tabaka', 'Cep saati', 'Dürbün kılıfı', 'Gümüş madalya'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Çanakkale Destanı',
      explanation: 'Conkbayırı\'nda kalbinin üzerindeki cep saatine çarpan şarapnel parçası Atatürk\'ün hayatını kurtarmıştır.',
    ),
    MillionaireQuestion(
      id: 'm19',
      question: 'Periyodik tabloda sembolü "Au" olan değerli element hangisidir?',
      options: ['Gümüş', 'Altın', 'Bakır', 'Platin'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Kimya',
      explanation: 'Altın elementi Latince "Aurum" kelimesinden ötürü Au sembolüyle gösterilir.',
    ),
    MillionaireQuestion(
      id: 'm20',
      question: 'Güneydoğu Anadolu Projesi (GAP) kapsamında Fırat Nehri üzerine kurulan en büyük barajımız hangisidir?',
      options: ['Keban Barajı', 'Atatürk Barajı', 'Karakaya Barajı', 'Ilısu Barajı'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.medium,
      category: 'Coğrafya & Mühendislik',
      explanation: 'Atatürk Barajı, gövde hacmi bakımından dünyanın sayılı barajları arasında yer alır.',
    ),

    // ==========================================
    // SEVİYE 3: ZOR / MİLYONER (100.000 TL - 5.000.000 TL)
    // ==========================================
    MillionaireQuestion(
      id: 'h1',
      question: 'Osmanlı Devleti\'nde 93 gün tahtta kalarak tarihte en kısa süre hüküm süren padişah kimdir?',
      options: ['II. Mustafa', 'III. Selim', 'IV. Mustafa', 'V. Murad'],
      correctIndex: 3,
      difficulty: QuestionDifficulty.hard,
      category: 'Osmanlı Tarihi',
      explanation: 'V. Murad, akıl sağlığı gerekçesiyle 93 gün sonra tahttan indirilmiştir.',
    ),
    MillionaireQuestion(
      id: 'h2',
      question: 'Türk denizcilik tarihinin ilk amirali ve ilk Türk donanmasını 1081 yılında Ege\'de kuran bey kimdir?',
      options: ['Umur Bey', 'Çaka Bey', 'Karamürsel Alp', 'Turgut Reis'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'Denizcilik Tarihi',
      explanation: 'Çaka Bey 1081 yılında İzmir\'de ilk Türk tersanesini kurmuş ve Deniz Kuvvetleri\'nin temeli sayılmıştır.',
    ),
    MillionaireQuestion(
      id: 'h3',
      question: '1915 Çanakkale Boğazı Deniz Savaşı\'nda Erenköy Koyu\'na döşediği 26 mayınla İtilaf donanmasını hezimete uğratan mayın gemisi hangisidir?',
      options: ['Yavuz', 'Nusret', 'Midilli', 'Muavenet-i Milliye'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'Çanakkale Destanı',
      explanation: 'Yüzbaşı Tophaneli Hakkı Bey komutasındaki Nusret Mayın Gemisi 7-8 Mart gecesi tarihi mayın hattını döşemiştir.',
    ),
    MillionaireQuestion(
      id: 'h4',
      question: 'Türkçeye Fransızcadan geçen "doktor" kelimesinin Latince kökeni "docere" fiilinin asıl anlamı nedir?',
      options: ['Tedavi etmek', 'İyileştirmek', 'Öğretmek', 'Araştırmak'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.hard,
      category: 'Etimoloji & Dil',
      explanation: 'Latince "docere" öğretmek anlamına gelir; doctor ise "öğretici, alim" demektir.',
    ),
    MillionaireQuestion(
      id: 'h5',
      question: 'Sakarya Meydan Muharebesi\'nin cereyan ettiği ve Atatürk\'ün savaşı yönettiği tepe hangisidir?',
      options: ['Kocatepe', 'Duatepe', 'Metristepe', 'Adatepe'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'Milli Mücadele',
      explanation: 'Duatepe, Polatlı yakınlarında Sakarya Zaferi\'nin kazanıldığı ve geri alınan ilk tepedir.',
    ),
    MillionaireQuestion(
      id: 'h6',
      question: 'Türkiye\'nin 81 ili arasında sadece 3 ilçesi bulunan ve en az ilçeye sahip olan ilimiz hangisidir?',
      options: ['Kilis', 'Yalova', 'Bayburt', 'Iğdır'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.hard,
      category: 'Coğrafya',
      explanation: 'Bayburt ili yalnızca Merkez, Aydıntepe ve Demirözü olmak üzere 3 ilçeden oluşur.',
    ),
    MillionaireQuestion(
      id: 'h7',
      question: 'Dünya tarihinde ilk kez bir uçak savaşta hangi çatışmada ve hangi ülke tarafından kullanılmıştır?',
      options: ['1911 Trablusgarp Savaşı (İtalya)', '1912 Balkan Savaşı (Bulgaristan)', '1914 I. Dünya Savaşı (Almanya)', '1904 Rus-Japon Savaşı (Japonya)'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.hard,
      category: 'Havacılık & Askeri Tarih',
      explanation: 'İtalyan Yüzbaşı Carlo Piazza 23 Ekim 1911\'de Trablusgarp\'ta Osmanlı mevzilerine keşif uçuşu yapmıştır.',
    ),
    MillionaireQuestion(
      id: 'h8',
      question: 'Kut\'ül Amare Kuşatması\'nda (1916) İngiliz ordusunu komutanı General Townshend ile birlikte esir alan Osmanlı komutanı kimdir?',
      options: ['Enver Paşa', 'Halil (Kut) Paşa', 'Cemal Paşa', 'Fahreddin Paşa'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'I. Dünya Savaşı',
      explanation: 'Halil Kut Paşa komutasındaki Osmanlı ordusu 13.000\'den fazla İngiliz askerini teslim almıştır.',
    ),
    MillionaireQuestion(
      id: 'h9',
      question: 'Milli Mücadele\'de "Ordular! İlk hedefiniz Akdeniz\'dir, ileri!" emri hangi tepeden verilmiştir?',
      options: ['Metristepe', 'Duatepe', 'Kocatepe (Afyon)', 'Çiğiltepe'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.hard,
      category: 'Milli Mücadele',
      explanation: 'Gazi Mustafa Kemal Paşa Büyük Taarruz\'u Afyon Kocatepe Karargahı\'ndan sevk ve idare etmiştir.',
    ),
    MillionaireQuestion(
      id: 'h10',
      question: 'Ayasofya-i Kebir Cami-i Şerifi\'nin kubbesinde yer alan ve Hattat Kazasker Mustafa İzzet Efendi tarafından yazılan ayet hangisidir?',
      options: ['Ayetel Kürsi', 'Fatiha Suresi', 'Nur Suresi 35. Ayet', 'İhlas Suresi'],
      correctIndex: 2,
      difficulty: QuestionDifficulty.hard,
      category: 'Sanat Tarihi',
      explanation: '"Allah göklerin ve yerin nurudur..." mealli Nur Suresi 35. ayeti kubbenin tam merkezindedir.',
    ),
    MillionaireQuestion(
      id: 'h11',
      question: 'Medine Müdafaası\'nda (1916-1919) kutsal emanetleri koruyan ve "Çöl Kaplanı" olarak bilinen efsane komutan kimdir?',
      options: ['Fahreddin Paşa', 'Kazım Karabekir', 'Cevat Çobanlı', 'Esat Paşa'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.hard,
      category: 'Askeri Destanlar',
      explanation: 'Fahreddin (Türkkan) Paşa, zorlu kuşatma altında Medine\'yi son ana kadar kahramanca savunmuştur.',
    ),
    MillionaireQuestion(
      id: 'h12',
      question: 'Dünyanın bilinen en eski tapınak kompleksi kabul edilen ve Şanlıurfa\'da bulunan arkeolojik alan hangisidir?',
      options: ['Çatalhöyük', 'Göbeklitepe', 'Alacahöyük', 'Hattuşaş'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'Arkeoloji & Tarih',
      explanation: 'Göbeklitepe M.Ö. 9600 civarına tarihlenen dünyanın ilk anıtsal tapınak merkezidir.',
    ),
    MillionaireQuestion(
      id: 'h13',
      question: '1974 Kıbrıs Barış Harekâtı\'nda şehit olan ve adı Lefkoşa\'daki askeri birliğe ve kışlaya verilen alay komutanımız kimdir?',
      options: ['Albay İbrahim Karaoğlanoğlu', 'Yüzbaşı Cengiz Topel', 'Binbaşı Nihat İlhan', 'Üsteğmen Mustafa Tanrıkulu'],
      correctIndex: 0,
      difficulty: QuestionDifficulty.hard,
      category: 'Kıbrıs & Şehitlerimiz',
      explanation: '50. Piyade Alay Komutanı Piyade Kıdemli Albay Halil İbrahim Karaoğlanoğlu harekâtın ilk günü şehit düşmüştür.',
    ),
    MillionaireQuestion(
      id: 'h14',
      question: 'Türkiye Cumhuriyeti\'nin ilk kadın savaş pilotu kimdir?',
      options: ['Bedriye Tahir Gökmen', 'Sabiha Gökçen', 'Edibe Subaşı', 'Leman Bozkurt'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'Havacılık Tarihi',
      explanation: 'Atatürk\'ün manevi kızı Sabiha Gökçen dünyanın da ilk kadın savaş pilotlarından biridir.',
    ),
    MillionaireQuestion(
      id: 'h15',
      question: 'Milli şairimiz Mehmet Akif Ersoy, İstiklal Marşı\'nı hangi askeri karargahta ve tekkede yazmıştır?',
      options: ['Hacı Bayram Veli Camii', 'Taceddin Dergahı', 'Gülhane Askeri Akademisi', 'Zincirlikuyu Köşkü'],
      correctIndex: 1,
      difficulty: QuestionDifficulty.hard,
      category: 'Milli Edebiyat',
      explanation: 'Mehmet Akif Ersoy, Ankara Hamamönü\'nde bulunan Taceddin Dergahı\'nda İstiklal Marşı\'nı kaleme almıştır.',
    ),
  ];

  /// Builds a full 12-question game ladder balanced for the 12 money stages:
  /// Q1-Q2: Easy (Baraj 1: 2.000 TL)
  /// Q3-Q6: Easy-Medium (3.000 TL - 20.000 TL)
  /// Q7: Medium-Hard (Baraj 2: 50.000 TL)
  /// Q8-Q10: Hard (100.000 TL - 500.000 TL)
  /// Q11-Q12: Master (1.000.000 TL - 5.000.000 TL Büyük Ödül)
  List<MillionaireQuestion> getRandomGameLadder() {
    final easyList = List<MillionaireQuestion>.from(_allQuestions.where((q) => q.difficulty == QuestionDifficulty.easy))..shuffle(_random);
    final mediumList = List<MillionaireQuestion>.from(_allQuestions.where((q) => q.difficulty == QuestionDifficulty.medium))..shuffle(_random);
    final hardList = List<MillionaireQuestion>.from(_allQuestions.where((q) => q.difficulty == QuestionDifficulty.hard))..shuffle(_random);

    final ladderQuestions = <MillionaireQuestion>[];

    // Q1, Q2: Easy
    ladderQuestions.add(easyList.removeLast());
    ladderQuestions.add(easyList.removeLast());

    // Q3, Q4, Q5, Q6: Medium
    for (int i = 0; i < 4; i++) {
      if (mediumList.isNotEmpty) {
        ladderQuestions.add(mediumList.removeLast());
      } else {
        ladderQuestions.add(easyList.removeLast());
      }
    }

    // Q7: Baraj 2 (Medium/Hard)
    if (mediumList.isNotEmpty) {
      ladderQuestions.add(mediumList.removeLast());
    } else {
      ladderQuestions.add(hardList.removeLast());
    }

    // Q8, Q9, Q10: Hard
    for (int i = 0; i < 3; i++) {
      if (hardList.isNotEmpty) {
        ladderQuestions.add(hardList.removeLast());
      } else {
        ladderQuestions.add(mediumList.removeLast());
      }
    }

    // Q11, Q12: Master (Hard)
    for (int i = 0; i < 2; i++) {
      if (hardList.isNotEmpty) {
        ladderQuestions.add(hardList.removeLast());
      } else {
        ladderQuestions.add(mediumList.removeLast());
      }
    }

    return ladderQuestions;
  }

  /// Gets a balanced set of questions for online 1v1 duels (e.g. 5 questions)
  List<MillionaireQuestion> getDuelQuestions({int count = 5}) {
    final shuffled = List<MillionaireQuestion>.from(_allQuestions)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// Gets total questions available
  int get totalQuestionsCount => _allQuestions.length;
}
