import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a curated military & dawn quote.
class SafakQuote {
  final String id;
  final String text;
  final String category; // 'vatan', 'safak', 'ozlem', 'komando', 'mizah', 'dogan_gunes'
  final String categoryLabel;
  final IconData categoryIcon;
  final Color accentColor;
  final String? author;

  const SafakQuote({
    required this.id,
    required this.text,
    required this.category,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.accentColor,
    this.author,
  });
}

class SafakSozleri extends StatefulWidget {
  final String? backgroundImage;
  const SafakSozleri({super.key, this.backgroundImage});

  // Backward-compatible static list for any external callers
  static List<Map<String, dynamic>> get cardData => allQuotes.map((q) => {
    'id': q.id,
    'title': q.text,
    'category': q.categoryLabel,
  }).toList();

  static const List<SafakQuote> allQuotes = [
    // ==========================================
    // 1. VATAN & BAYRAK (🇹🇷)
    // ==========================================
    SafakQuote(
      id: 'vatan_1',
      text: 'Biz Türk askeriyiz; dosta güven, düşmana korku salarız. Vatan bize emanet, canımız Allah’a.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_2',
      text: 'Bayrakları bayrak yapan üstündeki kandır; toprak, eğer uğrunda ölen varsa vatandır!',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mithat Cemal Kuntay',
    ),
    SafakQuote(
      id: 'vatan_3',
      text: 'Ezanla geldik selayla gideriz. Bu vatan için kanımızı şerbet diye içeriz.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_4',
      text: 'Kapımıza dayanıyorsa zulüm; başka yol yok: Ya istiklal ya ölüm!',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Gazi Mustafa Kemal Atatürk',
    ),
    SafakQuote(
      id: 'vatan_5',
      text: 'Bize "Vatan delisi" diyorlar; çok şükür kafamız bozuk, kanımız değil!',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Bir Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_6',
      text: 'Biz seve seve can veririz lakin bir karış vatan toprağı vermeyiz.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Türk Askeri',
    ),
    SafakQuote(
      id: 'vatan_7',
      text: 'Uğrunda ölmeyeceğin bayrağın gölgesine sığınma. Ya sahip ol ya da defol!',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_8',
      text: 'Ülkümüz göklerde dalgalanan şanlı sancak; biz yalnızca Allah’ın huzurunda eğiliriz.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_9',
      text: 'Vatan diye bir sevdaya tutulduk; Allah şifa mifa vermesin!',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_10',
      text: 'Şehitler tepesi boş değil; toprağı sıksan şüheda fışkırır. Biz bu nöbeti namus bildik.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmet Akif Ersoy',
    ),
    SafakQuote(
      id: 'vatan_11',
      text: 'Eğer bir gün şafağım için doğacak güneş, dağdaki hainin sırtını ısıtacaksa; bırakın o güneş hiç doğmasın!',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Nöbetçi Asker',
    ),
    SafakQuote(
      id: 'vatan_12',
      text: 'Bu vatan toprağın kara bağrında, sıradağlar gibi duran Mehmetçiklerindir.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Orhan Şaik Gökyay',
    ),
    SafakQuote(
      id: 'vatan_13',
      text: 'Herkes bilsin ki; çakalların hükmü bozkurt ayağa kalkana kadardır.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_14',
      text: 'Bizler Atatürk’ün askerleriyiz, ayık olun! Vatan bize, hudut Mehmetçiğe emanet.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'vatan_15',
      text: 'Bil ki kanım vatana toprak olur, bil ki ruhum cennete bekçi olur, bil ki canım bayrağa feda olur.',
      category: 'vatan',
      categoryLabel: 'Vatan & Bayrak',
      categoryIcon: Icons.flag_rounded,
      accentColor: Color(0xFFEF4444),
      author: 'Mehmetçik',
    ),

    // ==========================================
    // 2. ŞAFAK & TESKERE (⏳)
    // ==========================================
    SafakQuote(
      id: 'safak_1',
      text: 'Ömründen gün gitmesini isteyen tek varlık askerdir paşam; şafak erir, ömür tükenir, teskere gelir.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'safak_2',
      text: 'Şafak ne kadar zengin olursa olsun, bir gün fakirleşmeye mahkûmdur!',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Tertip',
    ),
    SafakQuote(
      id: 'safak_3',
      text: 'Doğan her güneş gençliğimin kaybıysa, batan her güneş şafağımın kazancıdır.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'safak_4',
      text: 'Bir insan günleri bu kadar hevesle sayıyorsa; ya mahkûmdur ya asker!',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Kışla Hatırası',
    ),
    SafakQuote(
      id: 'safak_5',
      text: 'İlk başlarda kaç gün kaldı yerine kaç gün geçti diye sayarsan senin için daha kolay olur. Sabret tertip!',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Kıdemli Asker',
    ),
    SafakQuote(
      id: 'safak_6',
      text: 'Plakalara düştük be gülüm! Artık şafak geriye değil, memlekete doğru koşuyor.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Plaka Şafağı',
    ),
    SafakQuote(
      id: 'safak_7',
      text: 'Gel teskere gel, gönlümüz seninle; geride bıraktığımız günler hatıra, önümüzdeki günler zafer olsun.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'safak_8',
      text: 'Göz açıp kapayıncaya kadar geçer dediler; gözümüz açık kaldı be şafak!',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Nöbetçi',
    ),
    SafakQuote(
      id: 'safak_9',
      text: 'Ağaç kırılır gövdesi kalır; dedeniz Mehmetçik gider, kışlada namı kalır!',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Torununa Nasihat',
    ),
    SafakQuote(
      id: 'safak_10',
      text: 'Bugün de battı güneş, bir gün daha eksildi hasretten. Şafak sıkıştırsa da biz çeliğiz!',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'safak_11',
      text: 'Şafak 81 olunca memleket kokusu başlar, şafak doğan güneş olunca bayram olur.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Plaka Sevinci',
    ),
    SafakQuote(
      id: 'safak_12',
      text: 'Dün bir hayaldi, bugün sabır, yarın teskere! Az kaldı kavuşmaya.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'safak_13',
      text: 'Ne albay ne yarbay; alayına bay bay! Teskere çantası hazır, bekle beni sivil hayat.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Terhisçi',
    ),
    SafakQuote(
      id: 'safak_14',
      text: 'Biz bu şafağı takvimden değil, yüreğimizden birer birer sildik.',
      category: 'safak',
      categoryLabel: 'Şafak & Teskere',
      categoryIcon: Icons.hourglass_bottom_rounded,
      accentColor: Color(0xFFF59E0B),
      author: 'Mehmetçik',
    ),

    // ==========================================
    // 3. HASRET & ASKER YARİ (💌)
    // ==========================================
    SafakQuote(
      id: 'ozlem_1',
      text: 'Şafak sayar gelin evde, asker eşini hayal eder nöbetinde; biter bu hasret dayan askerim, bu vatan senin eserin.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Asker Yari',
    ),
    SafakQuote(
      id: 'ozlem_2',
      text: 'Aşkım yatağın, sevgim yorganın, yüreğim yastığın olsun; asker ocağında rahat uyu bir tanem.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Asker Sevgilisi',
    ),
    SafakQuote(
      id: 'ozlem_3',
      text: 'Gecenin ayazında nöbetteyken içimi ısıtan tek şey; gözlerinin hayali ve memleket hasretidir.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Nöbetteki Asker',
    ),
    SafakQuote(
      id: 'ozlem_4',
      text: 'Sen orada vatana nöbet tutarsın yiğidim, ben burada sana dua bekçisiyim.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Asker Eşi',
    ),
    SafakQuote(
      id: 'ozlem_5',
      text: 'Hasret kurşundan ağır gelse de, kavuşacağımız o kutlu gün için her nöbete değer sevgilim.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'ozlem_6',
      text: 'Vedalar zor olsa da bazen gitmek gerekir; arkada bekleyenin duası, önde vatanın sevdası varsa yol tükenir.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Gurbetteki Asker',
    ),
    SafakQuote(
      id: 'ozlem_7',
      text: 'Yalnızlıklardan yoruldum usandım; ama bilirim ki o sımsıcak bakan gözler nöbetimin en güzel mükafatıdır.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'ozlem_8',
      text: 'Her gece yıldızlara bakıp aynı gökyüzünün altında kavuşacağımız günü fısıldıyorum rüzgara.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Asker Sevgilisi',
    ),
    SafakQuote(
      id: 'ozlem_9',
      text: 'Bir gün gelecek o nizamiye kapısında boynuna sarılıp "Hoş geldin şampiyonum" diyeceğim.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Bekleyen Yürek',
    ),
    SafakQuote(
      id: 'ozlem_10',
      text: 'Hakkını helal et anam; vatan için göğsümüzü siper ettik, duanla dimdik ayaktayız.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Kınalı Kuzu',
    ),
    SafakQuote(
      id: 'ozlem_11',
      text: 'Asker yolu beklemek sabır işidir derler; doğru, ama beklediğin vatana siper bir koca yürekse gururdur.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Asker Yari',
    ),
    SafakQuote(
      id: 'ozlem_12',
      text: 'Sol yanımda atan kalbin her zaman benimle; aramızdaki yollar şafakla erir gider.',
      category: 'ozlem',
      categoryLabel: 'Hasret & Özlem',
      categoryIcon: Icons.favorite_rounded,
      accentColor: Color(0xFFEC4899),
      author: 'Mehmetçik',
    ),

    // ==========================================
    // 4. KOMANDO & HUDUT (🦅)
    // ==========================================
    SafakQuote(
      id: 'komando_1',
      text: 'Dağlara çizmişler resmimi, komando koymuşlar ismimi; belki bir gün geri dönemem diye göndermişler sana sevgimi.',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Mavi Bereli',
    ),
    SafakQuote(
      id: 'komando_2',
      text: 'Biz denizci değiliz ki her limanda bir sevgilimiz olsun; biz komandoyuz, dağlar sağ olsun!',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Dağ Komandosu',
    ),
    SafakQuote(
      id: 'komando_3',
      text: 'Korku nedir bilmeyiz biz dağların erleri; yuva yaptık göklere, baş döndüren yerlere!',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Komando Marşı',
    ),
    SafakQuote(
      id: 'komando_4',
      text: 'Fırtına bizim nefesimiz, karlı dağlar bizim meskenimiz. Mavi bere düşmez, komando pes etmez!',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Komando',
    ),
    SafakQuote(
      id: 'komando_5',
      text: 'Gecenin zifiri karanlığında tek bir parola vardır kulaklarımızda: Hudut namustur!',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Hudut Kartalı',
    ),
    SafakQuote(
      id: 'komando_6',
      text: 'Dağların tepesine, eşkıyanın alnına, vatanın bağrına ölümsüz Mehmetçik yazacağız.',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'komando_7',
      text: 'Zor bizim günlük işimizdir, imkansız ise sadece biraz zamanımızı alır.',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Özel Kuvvetler',
    ),
    SafakQuote(
      id: 'komando_8',
      text: 'Bordo bereli yürürse dağlar titrer, komando durursa cihan susar!',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Bordo Bereli',
    ),
    SafakQuote(
      id: 'komando_9',
      text: 'Görünmeziz, duyulmazız; geldiğimizde sadece zaferin ayak sesi duyulur.',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Komando',
    ),
    SafakQuote(
      id: 'komando_10',
      text: 'Vatanımda gözün varsa eğer, mezarın derin olur bunu sakın unutma!',
      category: 'komando',
      categoryLabel: 'Komando & Hudut',
      categoryIcon: Icons.military_tech_rounded,
      accentColor: Color(0xFF10B981),
      author: 'Hudut Muhafızı',
    ),

    // ==========================================
    // 5. KIŞLA MİZAHI & NÖBET MATRAKLARI (😄)
    // ==========================================
    SafakQuote(
      id: 'mizah_1',
      text: 'Aradığınız kişiye şu anda ulaşılamıyor; lütfen 460 gün sonra tekrar deneyiniz!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Acemi Asker',
    ),
    SafakQuote(
      id: 'mizah_2',
      text: 'Her sabah mercimek yemeyi, çatalla hoşaf içmeyi, elbise yerine kamuflaj giymeyi asker ol da gör arkadaş!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Karavanacı',
    ),
    SafakQuote(
      id: 'mizah_3',
      text: 'Spora gidememekten yakınıyordun ya; al işte spor ayağına geldi, hem de 5 kilo piyade tüfeğiyle!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Çavuş Nasihati',
    ),
    SafakQuote(
      id: 'mizah_4',
      text: 'Gece nöbetlerinde beni aklına getirmemeye çalış; gülerken komutana yakalanmanı istemem!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Asker Sevgilisi',
    ),
    SafakQuote(
      id: 'mizah_5',
      text: 'Hayat bir zulümse, tak kamuflajı gülümse be şafak!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Kıdemli Er',
    ),
    SafakQuote(
      id: 'mizah_6',
      text: 'Bot boyamaktan parmak izim silindi; terhis olunca e-Devlet beni tanımayacak diye korkuyorum.',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Nöbetçi Er',
    ),
    SafakQuote(
      id: 'mizah_7',
      text: 'Vatan bize, kozan size, çarşıdaki kızlar Allah’a emanet!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Tertip',
    ),
    SafakQuote(
      id: 'mizah_8',
      text: 'Koğuş kalk dediğinde tavana 5 dakika boş boş bakıp "Ben neredeyim" demeyen asker asker sayılmaz.',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Koğuş Kıdemlisi',
    ),
    SafakQuote(
      id: 'mizah_9',
      text: 'Teskereyi alınca ilk işim sabah saat 06:00 alarmını telefonun kökünden silmek olacak!',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Şafakzede',
    ),
    SafakQuote(
      id: 'mizah_10',
      text: 'Nöbet kulübesine destan yazan şair askerler derneği onursal başkanıyım.',
      category: 'mizah',
      categoryLabel: 'Kışla Mizahı',
      categoryIcon: Icons.sentiment_very_satisfied_rounded,
      accentColor: Color(0xFF38BDF8),
      author: 'Nöbet Şairi',
    ),

    // ==========================================
    // 6. DOĞAN GÜNEŞ & PLAKALAR (🌟)
    // ==========================================
    SafakQuote(
      id: 'dogan_1',
      text: 'Şafak Doğan Güneş! Bitti be askerlik, yol ver karlı dağlar memleketime gidiyorum!',
      category: 'dogan_gunes',
      categoryLabel: 'Doğan Güneş',
      categoryIcon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24),
      author: 'Terhis Belgesi',
    ),
    SafakQuote(
      id: 'dogan_2',
      text: 'Doğan güneş şafağım, batan güneş kışladaki son nefesimdir. Elveda nizamiye!',
      category: 'dogan_gunes',
      categoryLabel: 'Doğan Güneş',
      categoryIcon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24),
      author: 'Mehmetçik',
    ),
    SafakQuote(
      id: 'dogan_3',
      text: 'Plakalar bitti, son gün geldi. Arkama bakmadan yürüyorum; doğan her güneş artık hürriyetime doğsun!',
      category: 'dogan_gunes',
      categoryLabel: 'Doğan Güneş',
      categoryIcon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24),
      author: 'Sivil Hayat',
    ),
    SafakQuote(
      id: 'dogan_4',
      text: 'Son nöbet, son içtima, son karavana... Vatan borcu ödendi, başımız dik memlekete selam!',
      category: 'dogan_gunes',
      categoryLabel: 'Doğan Güneş',
      categoryIcon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24),
      author: 'Eski Asker',
    ),
    SafakQuote(
      id: 'dogan_5',
      text: 'O güneş nihayet doğdu! Şafak sıfırlandı, hasret son buldu. Merhaba sevdiklerim, merhaba canım ailem!',
      category: 'dogan_gunes',
      categoryLabel: 'Doğan Güneş',
      categoryIcon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24),
      author: 'Kavuşan Mehmetçik',
    ),
  ];

  @override
  State<SafakSozleri> createState() => _SafakSozleriState();
}

class _SafakSozleriState extends State<SafakSozleri> {
  late String _backgroundImage;
  String _selectedCategory = 'all'; // 'all' or category key
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _favoriteIds = {};
  int _randomHeroIndex = 0;

  final List<Map<String, dynamic>> _categories = const [
    {'key': 'all', 'label': 'Tümü', 'icon': Icons.apps_rounded, 'color': Color(0xFF94A3B8)},
    {'key': 'vatan', 'label': 'Vatan & Bayrak', 'icon': Icons.flag_rounded, 'color': Color(0xFFEF4444)},
    {'key': 'safak', 'label': 'Şafak & Teskere', 'icon': Icons.hourglass_bottom_rounded, 'color': Color(0xFFF59E0B)},
    {'key': 'ozlem', 'label': 'Hasret & Özlem', 'icon': Icons.favorite_rounded, 'color': Color(0xFFEC4899)},
    {'key': 'komando', 'label': 'Komando & Hudut', 'icon': Icons.military_tech_rounded, 'color': Color(0xFF10B981)},
    {'key': 'mizah', 'label': 'Kışla Mizahı', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': Color(0xFF38BDF8)},
    {'key': 'dogan_gunes', 'label': 'Doğan Güneş', 'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFFBBF24)},
    {'key': 'favorites', 'label': 'Favorilerim', 'icon': Icons.star_rounded, 'color': Color(0xFFEAB308)},
  ];

  @override
  void initState() {
    super.initState();
    _backgroundImage = widget.backgroundImage ?? 'assets/images/img0.webp';
    _loadTheme();
    _loadFavorites();
    _pickDailyQuoteIndex();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickDailyQuoteIndex() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _randomHeroIndex = dayOfYear % SafakSozleri.allQuotes.length;
  }

  void _shuffleHeroQuote() {
    HapticFeedback.mediumImpact();
    setState(() {
      _randomHeroIndex = (_randomHeroIndex + 7) % SafakSozleri.allQuotes.length;
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
    if (mounted) {
      setState(() {
        _backgroundImage = imagePath;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_safak_quotes') ?? [];
    if (mounted) {
      setState(() {
        _favoriteIds = favList.toSet();
      });
    }
  }

  Future<void> _toggleFavorite(String quoteId) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(quoteId)) {
        _favoriteIds.remove(quoteId);
      } else {
        _favoriteIds.add(quoteId);
      }
    });
    await prefs.setStringList('favorite_safak_quotes', _favoriteIds.toList());
  }

  List<SafakQuote> get _filteredQuotes {
    return SafakSozleri.allQuotes.where((q) {
      // Category filter
      if (_selectedCategory == 'favorites') {
        if (!_favoriteIds.contains(q.id)) return false;
      } else if (_selectedCategory != 'all' && q.category != _selectedCategory) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesText = q.text.toLowerCase().contains(query);
        final matchesCategory = q.categoryLabel.toLowerCase().contains(query);
        final matchesAuthor = q.author?.toLowerCase().contains(query) ?? false;
        if (!matchesText && !matchesCategory && !matchesAuthor) return false;
      }

      return true;
    }).toList();
  }

  void _shareQuote(BuildContext btnContext, SafakQuote quote) {
    HapticFeedback.lightImpact();
    final box = btnContext.findRenderObject() as RenderBox?;
    Rect? origin;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final size = MediaQuery.sizeOf(btnContext);
      origin = Rect.fromLTWH(size.width / 2 - 100, size.height / 2 - 100, 200, 200);
    }

    final shareText = "«${quote.text}»\n\n🇹🇷 ${quote.categoryLabel} • Şafak Sayar";
    try {
      Share.share(
        shareText,
        subject: "Şafak Sözü",
        sharePositionOrigin: origin,
      );
    } catch (e) {
      Clipboard.setData(ClipboardData(text: quote.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📋 Söz panoya kopyalandı!"),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyQuote(SafakQuote quote) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: quote.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Söz panoya kopyalandı!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDefaultBg = _backgroundImage == 'assets/images/img0.webp';
    final Color textColor = isDefaultBg ? Colors.black87 : Colors.white;
    final quotes = _filteredQuotes;
    final heroQuote = SafakSozleri.allQuotes[_randomHeroIndex];

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: isDefaultBg ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Şafak Sözleri',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDefaultBg ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Text(
                      '${SafakSozleri.allQuotes.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar & Filter Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildSearchBar(isDefaultBg),
            ),

            // Horizontal Category Chips
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['key'];
                  final Color catColor = cat['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : (isDefaultBg ? Colors.black87 : Colors.white70),
                      ),
                      label: Text(
                        cat['key'] == 'favorites' ? '${cat['label']} (${_favoriteIds.length})' : cat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? Colors.white : (isDefaultBg ? Colors.black87 : Colors.white),
                        ),
                      ),
                      backgroundColor: isDefaultBg
                          ? Colors.white.withValues(alpha: 0.75)
                          : Colors.black.withValues(alpha: 0.35),
                      selectedColor: catColor,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? catColor
                              : (isDefaultBg ? Colors.black12 : Colors.white12),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = cat['key'] as String;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Quotes List View
            Expanded(
              child: quotes.isEmpty
                  ? _buildEmptyState(isDefaultBg)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: quotes.length + (_selectedCategory == 'all' && _searchQuery.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Position 0: Hero "Günün Şafak Sözü" when on 'all' view with no search
                        if (_selectedCategory == 'all' && _searchQuery.isEmpty) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildHeroDailyQuote(heroQuote, isDefaultBg),
                            );
                          }
                          final quote = quotes[index - 1];
                          return _buildModernQuoteCard(
                            quote: quote,
                            index: index - 1,
                            total: quotes.length,
                            isDefaultBg: isDefaultBg,
                          );
                        }

                        final quote = quotes[index];
                        return _buildModernQuoteCard(
                          quote: quote,
                          index: index,
                          total: quotes.length,
                          isDefaultBg: isDefaultBg,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SEARCH BAR
  // ==========================================
  Widget _buildSearchBar(bool isDefaultBg) {
    final Color bgColor = isDefaultBg
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.45);
    final Color textColor = isDefaultBg ? Colors.black87 : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDefaultBg ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textColor, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Şafak sözü veya kategori ara...',
              hintStyle: TextStyle(
                color: isDefaultBg ? Colors.black45 : Colors.white38,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDefaultBg ? Colors.black54 : Colors.white54,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: isDefaultBg ? Colors.black54 : Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // GÜNÜN ŞAFAK SÖZÜ HERO BANNER
  // ==========================================
  Widget _buildHeroDailyQuote(SafakQuote quote, bool isDefaultBg) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF881337), Color(0xFF4C0519), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'GÜNÜN ŞAFAK SÖZÜ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFBBF24),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.shuffle_rounded, size: 14),
                  label: const Text('Değiştir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _shuffleHeroQuote,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFFF43F5E),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (quote.author != null)
                  Text(
                    '— ${quote.author}',
                    style: const TextStyle(
                      color: Color(0xFFFDA4AF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const Spacer(),
                Builder(
                  builder: (btnCtx) => IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white70, size: 18),
                    onPressed: () => _shareQuote(btnCtx, quote),
                    tooltip: 'Paylaş',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                  onPressed: () => _copyQuote(quote),
                  tooltip: 'Kopyala',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODERN QUOTE CARD WIDGET
  // ==========================================
  Widget _buildModernQuoteCard({
    required SafakQuote quote,
    required int index,
    required int total,
    required bool isDefaultBg,
  }) {
    final bool isFav = _favoriteIds.contains(quote.id);
    final Color cardColor = isDefaultBg
        ? Colors.white.withValues(alpha: 0.90)
        : const Color(0xFF0F172A).withValues(alpha: 0.85);
    final Color borderColor = isDefaultBg
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.12);
    final Color textColor = isDefaultBg ? Colors.black87 : Colors.white;
    final Color subColor = isDefaultBg ? Colors.black54 : Colors.white60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFav
                    ? const Color(0xFFEC4899).withValues(alpha: 0.5)
                    : borderColor,
                width: isFav ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDefaultBg ? 0.04 : 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category Badge & Favorite Star
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: quote.accentColor.withValues(alpha: isDefaultBg ? 0.12 : 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: quote.accentColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(quote.categoryIcon, size: 14, color: quote.accentColor),
                            const SizedBox(width: 5),
                            Text(
                              quote.categoryLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: quote.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFEC4899) : subColor,
                          size: 20,
                        ),
                        onPressed: () => _toggleFavorite(quote.id),
                        tooltip: isFav ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quote Text with Quote Marks
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: quote.accentColor.withValues(alpha: 0.7),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          quote.text,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.45,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (quote.author != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        '— ${quote.author}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: subColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Divider(
                    color: isDefaultBg
                        ? Colors.black.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),

                  const SizedBox(height: 10),

                  // Bottom Action Row (Copy, Share, Index Counter)
                  Row(
                    children: [
                      _buildSmallButton(
                        icon: Icons.copy_rounded,
                        label: 'Kopyala',
                        onTap: () => _copyQuote(quote),
                        isDefaultBg: isDefaultBg,
                        textColor: subColor,
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (btnCtx) => _buildSmallButton(
                          icon: Icons.share_rounded,
                          label: 'Paylaş',
                          onTap: () => _shareQuote(btnCtx, quote),
                          isDefaultBg: isDefaultBg,
                          textColor: subColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDefaultBg
                              ? Colors.black.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${index + 1} / $total',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDefaultBg,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDefaultBg
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDefaultBg
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE WIDGET
  // ==========================================
  Widget _buildEmptyState(bool isDefaultBg) {
    final bool isFav = _selectedCategory == 'favorites';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDefaultBg
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                isFav ? Icons.favorite_border_rounded : Icons.search_off_rounded,
                size: 42,
                color: isDefaultBg ? Colors.black45 : Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFav ? 'Henüz Favori Sözünüz Yok' : 'Sonuç Bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDefaultBg ? Colors.black87 : Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFav
                  ? 'Beğendiğiniz şafak sözlerinin yanındaki kalp simgesine dokunarak buraya kaydedebilirsiniz.'
                  : 'Farklı bir arama terimi deneyin veya diğer kategorilere göz atın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDefaultBg ? Colors.black54 : Colors.white54,
                height: 1.4,
              ),
            ),
            if (isFav || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Tüm Sözleri Göster'),
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'all';
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
