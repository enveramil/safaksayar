import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:safaksayar/pages/safak_cizelgesi_page.dart';
import 'package:safaksayar/pages/ani_defteri_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/Services/calendar_capsule_service.dart';
import 'package:safaksayar/Services/notification_service.dart';
import 'package:safaksayar/widgets/calendar_capsule_dialogs.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/pages/custom_photo_preview_page.dart';
import 'package:safaksayar/pages/live_share_simulation_page.dart';

class HomeScreen extends StatefulWidget {
  final String backgroundImage;
  const HomeScreen({super.key, required this.backgroundImage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Duration remainingDuration = Duration.zero;

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool get _isDefaultTheme => widget.backgroundImage == 'assets/images/img0.webp';

  Color _getTextColor() {
    return _isDefaultTheme ? Colors.black : Colors.white;
  }

  Color _getCardColor() {
    return _isDefaultTheme
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.45);
  }

  Color _getBorderColor() {
    return _isDefaultTheme
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.15);
  }

  Color _getSubtitleColor() {
    return _isDefaultTheme ? Colors.black54 : Colors.white70;
  }

  ValueNotifier<Map<DateTime, bool>> _selectedDaysNotifier = ValueNotifier({});
  DateTime _focusedDay = DateTime.now(); // focusedDay için bir değişken
  Timer? countdownTimer;
  Duration elapsedDuration = Duration.zero; // For elapsed time
  int? durationMonths; // Declare durationMonths as a member variable
  ValueNotifier<bool> isKalanBlurred =
      ValueNotifier<bool>(false); // Blur state for KALAN SÜRE
  ValueNotifier<bool> isGecenBlurred =
      ValueNotifier<bool>(false); // Blur state for GEÇEN SÜRE

  String displayedInfo = '';
  String displayGununSozu = '';
  int _currentInfoIndex = 0;
  late Future<Map<String, String?>> _profileDataFuture;

  String? sulusTarihi;
  String? terhisTarihi;
  final Set<String> _knownCapsuleIds = {};
  bool _initialCapsulesLoaded = false;
  final GlobalKey _calendarSectionKey = GlobalKey();

  final List<String> infoList = [
    "Giyotin tarihte “damla kılıç” ya da “kafa kesme makinesi” olarak da adlandırılır. Ölüm cezası almışlar için uygulanan bir yöntemdir. Giyotini tasarlayan Fransiz doktor Joseph-Ignace Guillotin’dir.",
    "Orta ve Güney Amerika’da yaşayan ve günün 18 saatini uykuda geçiren tembel hayvanlar, yediklerini sindirebilmek için iki hafta ile bir ay arası zamana ihtiyaç duyar.",
    "Bir renkli kurşun kalemin bitebilmesi için 56 kilometrelik çizgi çizmek gerekir.",
    "Her yıl sadece Londra’nın metro istasyonlarında unutulan şemsiye sayısı 75 bindir.",
    "İspanya milli marşı sadece melodiden oluşur, sözleri yoktur.",
    "Hareket hâlindeki insanın ayak baş parmakları vücut ağırlığının yaklaşık %40’ını taşır.",
    "Eski Mısır rahipleri vücutlarındaki bütün kılları tıraş etmek zorundaydı. Kaşlar, kirpikler de dâhil.",
    "Uzaktan kumanda, ilk defa 1948 yılında Amerika’da kullanıldı. Televizyonlara kablo ile bağlı olan kumandanın görevi sadece ekran görüntüsünü büyütüp küçültmekti.",
    "Dünyada yazımı en uzun sürmüş kitap, Johann Wolfgang von Goethe’nin yazdığı Faust’tur. Yazmaya 21 yaşında başlamış ve 36 yıl sonra bitirmiştir.",
    "Guinness Rekorlar Kitabı, insanların rekorlarının yazılı olduğu bir kitaptır. İlk defa kendi rekorunu da kitaba yazmıştır. Bu kitabın kendi rekoru ise dünyada en çok çalınan kitap olmasıdır.",
    "Basketbolcu Michael Jordan’ın Nike reklamlarından kazandığı para, Malezya’daki Nike fabrikasında çalışan bütün işçilerin toplam kazancından fazladır.",
    "Yüzme Olimpiyatları’nda altın madalya sahibi Mark Spitz, bir keresinde Rus eğitmenine espri olsun diye başarısında bıyıklarının çok faydası olduğunu, hızlı yüzdürdüğünü ve mermi gibi hızlandırdığını söylemiştir. Ertesi yıl ise Rus yüzücülerin tamamı bıyıklı bir şekilde yarışmaya katılmıştır.",
    "1 milyar saniye 32 yıla, 1 milyon saniye ise 11 güne tekabül eder",
    "Eğer arabanızla uzaya gidebilecek bir yol olsaydı, sadece 1 saatlik yolculukla uzaya çıkabilirdiniz.",
    "Tarihte ismi Jane olan çoğu kraliçe ya öldürüldü, hapse atıldı, tahtan indirildi, genç yaşta öldü ya da delirdi.",
    "Mercedes ve Porsche’nin ana merkez büroları ve fabrikaları Stuttgart Almanya’dadır ve ikisinin de burada ayrı ayrı müzesi bulunmaktadır.",
    "Dünyada 3600 den fazla yılan türü vardır",
    "Bilimsel bir araştırmaya göre kadınların uyku kalitesi yalnız uyuduğunda daha yüksektir. Erkeklerin uyku kalitesi ise partneri ile birlikte uyuduğunda fazladır.",
    "Bütün dünyada yaklaşık 9 milyon insan hapishanelerde tutulur. Bu sayının %25’i sadece Amerika Birleşik Devletleri’ndedir.",
    "Penguenlerin 18 farklı türü vardır. Bu türler 30 santimetre ile bir metre arasında boylara sahiptir.",
    "Dünya’dan Ay’a gönderilen ışığın ulaşma süresi yaklaşık 1,3 saniyedir.",
    "Gökyüzünün mavi görünmesinin nedeni, güneş ışığının atmosferdeki gazlar tarafından saçılmasıdır. Mavi ışık diğer renklere göre daha fazla saçılır.",
    "Dünyanın en derin noktası olan Mariana Çukuru, yaklaşık 11.000 metre derinliğindedir. Bu derinlik Everest Dağı'nın yüksekliğinden bile fazladır.",
    "Kutup ayılarının derileri aslında siyahtır ve kürkleri beyaz değil, şeffaftır. Işığı yansıttıkları için beyaz görünürler.",
    "Gözlerimiz doğumdan itibaren neredeyse hiç büyümezken, kulaklarımız ve burnumuz yaşam boyu büyümeye devam eder.",
    "Dünyadaki en uzun ağaç, Kaliforniya'da bulunan ve boyu 115,92 metre olan Hyperion adındaki bir sahil sekoyasıdır.",
    "Bal hiç bozulmayan tek besindir. Arkeologlar, antik Mısır mezarlarında binlerce yıllık bozulmamış yenilebilir bal kavanozları bulmuşlardır.",
    "Ahtapotların üç kalbi ve mavi kanı vardır. Ayrıca beyinleri kollarının arasına dağılmıştır.",
    "Kelebekler tat alma duyularını ayaklarında bulunan özel alıcılar sayesinde hissederler.",
    "Bir salyangoz hiçbir zarar görmeden bir jiletin keskin kenarı üzerinde sürünebilir, çünkü vücudu koruyucu kalın bir mukus üretir.",
    "Mona Lisa tablosunun kaşları yoktur. O dönemde kadınların kaşlarını tamamen tıraş etmesi modaydı.",
    "Muzlar hafifçe radyoaktiftir çünkü yüksek oranda potasyum içerirler, ancak sağlığa herhangi bir zararı yoktur.",
    "Dünyanın en uzun trafik sıkışıklığı 2010 yılında Çin'in Pekin kentinde yaşandı ve tam 12 gün sürdü, araçlar günde sadece 1 km ilerleyebildi.",
    "Kargalar, kendilerine haksızlık yapan ya da zarar veren insanların yüzlerini unutmazlar ve bunu diğer kargalara da öğretebilirler.",
    "Güneş sistemindeki en yüksek yanardağ, Mars'ta bulunan ve yüksekliği yaklaşık 22 kilometre olan Olympus Mons'tur.",
    "İnsan vücudundaki en güçlü kas, çene kası olan çiğneme (masseter) kasıdır.",
    "Gökyüzündeki yıldızların sayısı, dünyadaki tüm plajlardaki kum tanelerinin sayısından daha fazladır.",
    "Arılar, birbirleriyle iletişim kurmak ve çiçeklerin yerini tarif etmek için özel bir dans yaparlar.",
    "Denizatı, ömür boyu tek eşli yaşayan tek balık türüdür ve yavruları erkek denizatı taşır.",
    "Bir bulutun ağırlığı ortalama 500 ton civarındadır, bu da yaklaşık 100 filin ağırlığına eşittir.",
    "Flamingolar sadece kafaları baş alkali durduğunda yemek yiyebilirler.",
    "Dünya üzerindeki tüm karıncaların toplam ağırlığı, tüm insanların toplam ağırlığına yaklaşık olarak eşittir.",
    "İnternet üzerindeki ilk alan adı (domain) 'symbolics.com'dur ve 15 Mart 1985'te tescil edilmiştir.",
    "Bukalemunların dilleri, kendi vücut uzunluklarının yaklaşık iki katı kadar uzayabilir.",
    "İnsan gözü yaklaşık 10 milyon farklı renk tonunu ayırt edebilir.",
    "Ketçap, 1830'lu yıllarda Amerika'da ilaç olarak satılıyordu ve ishal ile hazımsızlığa iyi geldiği iddia ediliyordu.",
    "Dünyadaki tatlı suyun yaklaşık %70'i kutuplardaki buzullarda donmuş halde bulunmaktadır.",
    "Bir salyangoz hiç durmadan ve uyanmadan 3 yıl boyunca uyuyabilir.",
    "Japonya'da her yıl meydana gelen deprem sayısı ortalama 1.500 civarındadır.",
    "İnsanlar ve muzlar, DNA'larının yaklaşık %50'sini paylaşırlar.",
    "Gözlerimizi kırptığımızda, gün boyunca yaklaşık 30 dakika karanlıkta kalmış oluruz.",
    "İskambil kartlarındaki kupa papazı, bıyığı olmayan tek papazdır.",
    "Bir su bardağı dolusu suyun içindeki atom sayısı, dünyadaki tüm okyanuslardaki su bardağı dolusu su sayısından fazladır.",
    "Dünyanın en soğuk yeri olan Antarktika'da hiçbir sürüngen veya amfibi türü yaşamaz.",
    "Güneş, dünyadaki tüm kum tanelerinden daha fazla sayıda atom içerir.",
    "İnsan DNA'sı ile şempanze DNA'sı yaklaşık %98,8 oranında aynıdır.",
    "Gökyüzündeki bulutlar beyazdır çünkü güneş ışığını oluşturan tüm renkleri eşit şekilde yansıtırlar.",
    "Bir insanın yaşamı boyunca ürettiği tükürük miktarı, yaklaşık iki yüzme havuzunu doldurabilir.",
    "Köpeklerin burun izleri, insanların parmak izleri gibi benzersizdir ve kimlik tespitinde kullanılabilir.",
    "Bir sinekkuşu, havada asılı kalabilen ve geriye doğru uçabilen tek kuş türüdür.",
    "Satürn gezegeni sudan daha az yoğundur; eğer devasa bir okyanusa koyulabilseydi, suyun üzerinde yüzerdi.",
    "Dünya tarihindeki en büyük deprem, 1960 yılında Şili'de meydana gelen 9.5 büyüklüğündeki depremdir.",
    "Kar taneleri altı köşelidir çünkü su molekülleri donarken altıgen kristal yapılar oluşturur.",
    "Kivi meyvesi, ismini Yeni Zelanda'nın uçamayan milli kuşu olan kivi kuşundan almıştır.",
    "İnternetteki verilerin %90'ı sadece son iki yıl içinde üretilmiştir.",
    "Ahtapotların kolları kesildiğinde yeniden büyüyebilir ve bu kollarda bağımsız küçük beyinler bulunur.",
    "Dünya'nın çekirdeğindeki altın miktarı, tüm gezegenin yüzeyini 1,5 metre kalınlığında kaplayacak kadardır.",
    "Kelebekler, sıvı gıdaları tüketmek için pipete benzeyen hortum şeklinde bir ağıza sahiptirler.",
    "Venüs günü, Venüs yılından daha uzundur; yani kendi etrafında dönmesi, Güneş etrafında dönmesinden uzun sürer.",
    "İnsan beyni, uyanıkken küçük bir ampulü yakmaya yetecek kadar elektrik üretebilir.",
    "Dünyadaki en büyük çöl Sahra değil, Antarktika Kutup Çölü'dür; çünkü çöller yağış miktarına göre belirlenir.",
    "Timsahlar dillerini ağızlarının dışına çıkaramazlar çünkü dilleri ağız tabanına sabittir.",
    "Su, donduğunda hacmi genişleyen ender maddelerden biridir; bu yüzden buz suyun üstünde yüzer.",
    "Zürafaların ses telleri yoktur, bu yüzden birbirleriyle düşük frekanslı sesler veya homurtularla iletişim kurarlar.",
    "Sıcak su, belirli koşullar altında soğuk sudan daha hızlı donabilir; buna Mpemba etkisi denir.",
    "Kediler, hayatlarının yaklaşık üçte ikisini uyuyarak geçirirler.",
    "Dünya üzerindeki en eski ağaç, İsveç'te bulunan ve yaklaşık 9.500 yaşında olan bir çam ağacıdır.",
    "İnsanlar esnediğinde kulaklarındaki geçici tıkanıklık, östaki borusunun açılıp kapanmasından kaynaklanır.",
    "Kutup ışıkları (Aurora), Güneş'ten gelen yüklü parçacıkların Dünya'nın atmosferindeki gazlarla çarpışmasıyla oluşur.",
    "İlk bilgisayar faresi 1964 yılında Douglas Engelbart tarafından ahşaptan yapılmıştır.",
    "Köpekbalıkları dünyada dinozorlardan daha uzun süredir varlığını sürdmektedir.",
    "Dünyanın en küçük ülkesi, Roma şehrinin içinde yer alan ve yüzölçümü sadece 0.44 km² olan Vatikan'dır.",
    "Ay'daki ayak izleri, orada rüzgar veya su olmadığı için milyonlarca yıl boyunca bozulmadan kalacaktır.",
    "Papatya çayı, sinir sistemini yatıştırarak uykuya geçişi kolaylaştıran doğal bileşenler içerir.",
    "Eiffel Kulesi, yaz aylarında metalin genleşmesi nedeniyle yaklaşık 15 santimetre daha uzun olabilir.",
    "Karıncalar uyumazlar; gün boyunca kısa süreli güç şekerlemeleri yaparak dinlenirler.",
    "Denizanalarının %95'i sudan oluşur, beyinleri, kalpleri ve kemikleri yoktur.",
    "Dünya yüzeyinin yaklaşık %71'i suyla kaplıdır, ancak bu suyun sadece %2,5'i tatlı sudur.",
    "Koalalar, günün yaklaşık 20 ila 22 saatini dinlenerek ve uyuyarak geçirirler.",
    "İnsan vücudundaki kemiklerin dörtte biri ayaklarda bulunur.",
    "Işık, saniyede yaklaşık 300.000 kilometre hızla hareket eder; bu hızla Dünya'nın etrafını bir saniyede 7.5 kez dönebilir.",
    "Dünyanın en yüksek şelalesi, Venezuela'da bulunan ve yüksekliği 979 metre olan Angel Şelalesi'dir.",
    "Kaju fıstığı aslında kaju elması adı verilen bir meyvenin altında yetişen tek bir tohumdur.",
    "İnsan kalbi, günde ortalama 100.000 kez atar ve vücuda kan pompalar.",
    "Yunuslar, olası tehlikelere karşı tetikte kalabilmek için bir gözleri açık uyurlar.",
    "Dünya üzerindeki tüm altınların sadece %1'i kadarı bugüne kadar madenlerden çıkarılabilmiştir.",
    "İnsan burnu, yaklaşık bir trilyon farklı kokuyu ayırt etme yeteneğine sahiptir.",
    "Jüpiter o kadar büyüktür ki, Güneş sistemindeki diğer tüm gezegenler onun içine rahatça sığabilir.",
    "Kutup ayıları beyaz görünmelerine rağmen aslında şeffaf tüylere ve tamamen siyah bir deriye sahiptirler.",
    "Bir çay kaşığı nötron yıldızı maddesi, yaklaşık 6 milyar ton ağırlığındadır.",
    "Ketçap, 1830'lu yıllarda Amerika'da ilaç olarak satılıyordu ve ishal ile hazımsızlığa iyi geldiği iddia ediliyordu.",
    "Dünyadaki tatlı suyun yaklaşık %70'i kutuplardaki buzullarda donmuş halde bulunmaktadır.",
    "Bir salyangoz hiç durmadan ve uyanmadan 3 yıl boyunca uyuyabilir.",
    "Japonya'da her yıl meydana gelen deprem sayısı ortalama 1.500 civarındadır.",
    "İnsanlar ve muzlar, DNA'larının yaklaşık %50'sini paylaşırlar.",
    "Gözlerimizi kırptığımızda, gün boyunca yaklaşık 30 dakika karanlıkta kalmış oluruz."
  ];

  List<String> askeriSozler = [
    "Disiplin, bir askerin en büyük silahıdır.",
    "Cesaret, korkunun ötesine geçmektir.",
    "Zafer, inanç ve fedakarlıkla kazanılır.",
    "Vatan için atılan her adım kutsaldır.",
    "Bir asker, görev bitti demeden yorulmaz.",
    "Birlikte mücadele edenler, birlikte kazanır.",
    "Bir askerin onuru, bayrağıdır.",
    "Zafer, hazırlıklı olanlarındır.",
    "Sabır ve dayanıklılık, askerliğin temelidir.",
    "Görev kutsaldır, asla yarıda bırakılmaz.",
    "Siper arkadaşlığı, hayattaki en güçlü bağdır.",
    "Savaşta en büyük cesaret, doğru karar vermektir.",
    "Bir asker, düşmanı kadar kendi korkusunu da yenmelidir.",
    "Yemin edilen vatan, can pahasına korunur.",
    "Barış için savaşa hazır ol.",
    "Vatan sevgisi, bir askerin kalbindeki ateştir.",
    "Bir asker, zorlukları yene yene güçlenir.",
    "Hedef, her zaman ileriye gitmektir.",
    "Cesaret, sadece tehlike anında değil, her an gereklidir.",
    "Birlik ruhu, savaşı kazandırır.",
    "Zafer, disiplin ve azmin sonucudur.",
    "Bir asker, düşmana korku, dosta güven verir.",
    "Komutlar kalpten gelmez, ama onurlu bir görevdir.",
    "Bir bayrağın dalgalanması, binlerce yüreğin fedakarlığıdır.",
    "Bir asker için vazgeçmek, seçenek değildir.",
    "Birlik, gücün en büyük kaynağıdır.",
    "Zafer, sabırla ve azimle gelir.",
    "Bir asker, zorluklardan şikayet etmez; çözüm üretir.",
    "Korku, cesaretin test edildiği yerdir.",
    "Bir askerin en büyük ödülü, görevini başarıyla tamamlamaktır.",
    "Tetikte kal, çünkü tehlike sessiz gelir.",
    "Savaş alanında zaman, en değerli kaynaktır.",
    "Siper dostluğu, hayatta bir kez yaşanır.",
    "Bir asker için başarısızlık, seçenek değildir.",
    "Gökyüzündeki her yıldız, bir şehidin ışığıdır.",
    "Sabır, savaşı kazananların anahtarıdır.",
    "Bir askerin gücü, sadece kaslarında değil, yüreğindedir.",
    "Vatan için yapılan fedakarlık, en yüce erdemdir.",
    "Kendini koru ki vatanı koruyabilesin.",
    "Bir asker için dinlenmek, bir sonraki mücadeleye hazırlanmaktır.",
    "Görev, kişisel ihtiyaçlardan önce gelir.",
    "Birlikte hareket edenler, zaferi paylaşır.",
    "Disiplin olmadan kaos kazanır.",
    "Bir askerin en büyük silahı, iradesidir.",
    "Hayat bir savaştır, askerlik bunu öğretir.",
    "Vatanı korumak, cesur yüreklerin işidir.",
    "Zafer, hazırlık ve kararlılığın sonucudur.",
    "Bir asker, her zaman tetikte olmalıdır.",
    "Düşman, sadece dışarıda değil, bazen içerideki korkulardadır.",
    "Bir asker, kendine olan güveniyle savaşır.",
    "Fedakarlık, askerliğin temel taşlarından biridir.",
    "Birlikte yürüyenler, birlikte başarır.",
    "Görev, her zaman onurla yapılır.",
    "Bir asker, zafere inanmadan zafer kazanamaz.",
    "Bir milletin gücü, askerlerinin fedakarlığında saklıdır.",
    "Her siper, bir hikaye taşır.",
    "Bir asker için en büyük ödül, huzur içinde dönebilmek.",
    "Birlik ve beraberlik, savaş alanının en büyük silahıdır.",
    "Cesaret, savaşı kazandıran en güçlü duygudur.",
    "Zafer için önce kendine inanmalısın.",
    "Bir asker, düşmanı kadar kendi zayıflığını da yenmelidir.",
    "Korku, cesaretin sınandığı yerdir.",
    "Bayrağa sadakat, bir askerin yemininin özüdür.",
    "Sabır, bir askerin en önemli erdemidir.",
    "Zafer, her zaman hazırlıklı olanındır.",
    "Vatan savunması, hayatın en kutsal görevidir.",
    "Bir asker, asla pes etmez.",
    "Birlik, gücün simgesidir.",
    "Görev, her şeyden önce gelir.",
    "Bir asker, düşmana korku, dosta umut verir.",
    "Sabır, askerin en önemli silahıdır.",
    "Kazanmak için önce inanç gerekir.",
    "Vatanı savunmak, bir askerin şerefidir.",
    "Görev, asla yarım bırakılmaz.",
    "Bir asker için cesaret, en güçlü zırhtır.",
    "Düşman, asla uyumaz; sen de uyuma.",
    "Bir askerin kalbi, vatan sevgisiyle atar.",
    "Zafer, ancak inananlara gelir.",
    "Bir asker, disiplinsiz başarıya ulaşamaz.",
    "Korku, zaferin düşmanıdır.",
    "Bir asker, onurunu asla kaybetmez.",
    "Birlikte güç doğar.",
    "Görev kutsaldır, asla unutulmaz.",
    "Her savaş, bir ders taşır.",
    "Bir askerin en büyük düşmanı, kendi korkusudur.",
    "Zafer, cesaretle kazanılır.",
    "Bir asker, önce kendine inanmalıdır.",
    "Birlik ruhu, savaş alanındaki en güçlü bağdır.",
    "Görev bitmeden, savaş bitmez.",
    "Bir asker için her yeni gün, yeni bir mücadeledir.",
    "Vatan sevgisi, bir askerin en büyük motivasyonudur.",
    "Disiplin, zaferin anahtarıdır.",
    "Her zafer, sabır ve inançla gelir.",
    "Bir asker, zorluklara göğüs gerendir.",
    "Görev, cesaretin test edildiği yerdir.",
    "Bir asker, asla pes etmez; her zaman devam eder.",
    "Zafer, sadece kazanmayı değil, öğrenmeyi de içerir.",
    "Vatan için dökülen ter, en kutsal fedakarlıktır.",
    "Görev aşkı, bir askerin yolunu aydınlatır.",
    "Bir asker, düşman karşısında asla eğilmez.",
    "Askerim, vatana borcumu ödeyeceğim, her şey vatan için!",
    "Bir canım var, vatanıma feda olsun!",
    "Asker oldum, şeref doldum; vatanıma canım feda!",
    "Askerlik şereftir, biz de bu şerefli yoldan geçeceğiz!",
    "Bu vatanın neferiyim; anam, babam, kardeşim, sevgilim… vatanımdır!",
    "Vatan! Sensin vazgeçilmez sevgili, sensin kalbimde yatan!",
    "Vatan bugün benden görev bekliyor! Şerefli göreve gidiyorum!",
    "Ülkem için verilecek bir can varsa onu ben taşıyorum!",
    "Vatan demek namus demek, ülkem için şanlı göreve gidiyorum.",
    "Her Türk’ün öncelikli görevi askerliktir; biz 6 ay değil, bir ömür askeriz.",
    "Vatan borç beklemez, zamanı gelince gider borcunu ödersin.",
    "Türk devleti var olsun, bu can ülkeme yar olsun!",
    "Her Türk erkeğinin en kutsal görevi askerliktir, ben de bu kutsal görevi icraya gidiyorum.",
    "Bugün vatan bizden görev bekliyor, geç kalmadan gitmeli; alnının akıyla görevi icra etmeli!",
    "Gazilik ya da şehitlik, vatan bizden hangi mertebeyi isterse oraya erişiriz!",
    "Her Türk asker doğar, yaşar ve ölür; Türk, bir ömür askerdir; vatana emanet!",
    "Vatan bölünmez, bayrak inmez, ezan dinmez! Türk askerinin olduğu yerde kutsallarımıza kimse dokunamaz!",
    "Türk devleti var olsun, bu can ülkeme feda olsun!",
    "Askerlik, yüce bir görevdir. Bu yüce görevi tam not alarak geçmek gerekir. Atalarımızdan bize yadigâr bu vatanı beklemek namus görevimizdir.",
    "Kim bükebilir Türk’ün bileğini? Vatan için fedadır tüm varlığımız!",
    "Her Türk asker doğar, vatanı için yaşar ve vatanı için ölür.",
    "Şafak ne kadar karanlık olursa olsun, güneşin doğuşu o kadar muhteşem olacaktır.",
    "Vatan sevgisi maya gibidir, sütü bozuk olanlarda tutmaz.",
    "Gözlerinizdeki cesaret, düşmanın kalbindeki korkuyu besler.",
    "Bayrakları bayrak yapan üstündeki kandır; toprak, eğer uğrunda ölen varsa vatandır.",
    "Şafak kartları bir bir azalırken, vatan sevgisi kalbimizde bir çınar gibi büyür.",
    "Bir avuç yiğit, koca bir orduya bedeldir; yeter ki yüreklerinde vatan inancı olsun.",
    "Askerin adımları toprağı titretir, dosta huzur düşmana korku verir.",
    "Sınırda bekleyen her Mehmetçik, bu milletin bağımsızlık ufkudur.",
    "Bizim yolumuz vatan yolu, bizim sevdamız bayrak sevdasıdır.",
    "Zorluklar askerin gücünü sınar, sabır ise şafağı aydınlatır.",
    "Şafak kaç olursa olsun, vatan görevi bizim için en büyük onurdur."
  ];

  Map<String, String?>? _cachedProfileData;

  @override
  void initState() {
    super.initState();
    SoldierMatchService.instance.dataSyncVersion.addListener(_onExternalDataSync);
    final prewarmedPrefs = SoldierMatchService.instance.cachedPrefs;
    if (prewarmedPrefs != null) {
      _cachedProfileData = _extractProfileDataSync(prewarmedPrefs);
      _hydrateCountdownSync(prewarmedPrefs);
    }
    _profileDataFuture = _loadData();
    loadCountdown();
    pickRandomInfo(); // Pick random info when the app starts
    gununSozu();
    loadSelectedDays().then((loadedDays) {
      if (mounted) {
        _selectedDaysNotifier.value = loadedDays;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoldierMatchService.instance.syncSoldierFCMToken();
      AdManager.instance.loadAndShowAppOpenAd();
    });
  }

  void _onExternalDataSync() {
    if (!mounted) return;
    _hasInitializedForceIndex = false;
    setState(() {
      _profileDataFuture = _loadData();
    });
    loadCountdown();
    gununSozu();
    loadSelectedDays().then((loadedDays) {
      if (mounted) {
        _selectedDaysNotifier.value = loadedDays;
      }
    });
  }

  // Function to randomly select an info
  void pickRandomInfo() {
    final random = Random();

    // Check if infoList is not empty to prevent null value
    if (infoList.isNotEmpty) {
      setState(() {
        _currentInfoIndex = random.nextInt(infoList.length);
        displayedInfo = infoList[_currentInfoIndex];
      });
    } else {
      setState(() {
        displayedInfo = 'Bilgi bulunamadı'; // Fallback if list is empty
      });
    }
  }

  void _nextInfo() {
    if (infoList.isNotEmpty) {
      setState(() {
        _currentInfoIndex = (_currentInfoIndex + 1) % infoList.length;
        displayedInfo = infoList[_currentInfoIndex];
      });
    }
  }

  void _prevInfo() {
    if (infoList.isNotEmpty) {
      setState(() {
        _currentInfoIndex = (_currentInfoIndex - 1 + infoList.length) % infoList.length;
        displayedInfo = infoList[_currentInfoIndex];
      });
    }
  }

  List<String> yakinSozleri = [
    "Hasretin boynumuza borç, vuslatımız vatan kadar kutsal olsun.",
    "Sabret sevdiğim; her batan güneş, sarılacağımız güne bir adım daha yakın.",
    "Gözüm yolda, gönlüm duada askerim. Vatan sana, sen Allah'a emanetsin.",
    "Vatani görevinde gururumuz, kalbimizde dinmeyen hasretimizsin.",
    "Bir gün gelecek, bir gün kalacak ve o gün kollarımda olacaksın.",
    "Sabrın sonu selamet, hasretin sonu sarılmak olsun canım askerim.",
    "Dualarım kalkanın, sevgim yoldaşın olsun. Sağ salim dön vatan bekçim.",
    "Uzaklarda olsan da her nefeste aklımdasın, kavuşacağımız günü iple çekiyorum.",
    "Sen orada vatanı bekliyorsun, ben burada bir ömür seni bekliyorum.",
    "Şafak ne kadar karanlık olursa olsun, güneş seninle doğacak.",
  ];

  Future<void> gununSozu() async {
    final random = Random();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'asker';
    final targetList = role == 'yakin' ? yakinSozleri : askeriSozler;

    if (targetList.isNotEmpty) {
      setState(() {
        displayGununSozu = targetList[random.nextInt(targetList.length)];
      });
    } else {
      setState(() {
        displayGununSozu = 'Bilgi bulunamadı'; // Fallback if list is empty
      });
    }
  }

  int? izin;
  int? ceza;
  String? yolIzni;
  int? yolIzniDisplay;
  int _selectedRankForceIndex = 0;
  bool _hasInitializedForceIndex = false;

  Future<void> updateHomeWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? 'Asker';
      final endDateStr = prefs.getString('end_date') ?? '';
      final sulusStr = prefs.getString('sulus_tarihi') ?? '';
      final remainingDays = remainingDuration.inDays;

      await HomeWidget.setAppGroupId('group.com.bayesa.ios.safaksayar2026');

      await HomeWidget.saveWidgetData<String>('name', name);
      await HomeWidget.saveWidgetData<String>('end_date', endDateStr);
      await HomeWidget.saveWidgetData<String>('sulus_tarihi', sulusStr);
      await HomeWidget.saveWidgetData<int>('remainingDays', remainingDays);

      await HomeWidget.updateWidget(
        name: 'SafakWidgetProvider',
        androidName: 'SafakWidgetProvider',
        qualifiedAndroidName: 'com.bayesa.safaksayar.SafakWidgetProvider',
        iOSName: 'SafakWidget',
      );
      print('HomeWidget updated successfully.');
    } catch (e) {
      print('Failed to update HomeWidget: $e');
    }
  }

  Future<void> loadCountdown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime endDate = DateTime.now();
    isKalanBlurred.value = prefs.getBool('isKalanBlurred') ?? false;
    isGecenBlurred.value = prefs.getBool('isGecenBlurred') ?? false;

    String? dueDateStr = prefs.getString('sulus_tarihi');
    durationMonths = prefs.getInt('duration') ?? 0;

    izin = prefs.getInt('izin') ?? 0;
    ceza = prefs.getInt('ceza') ?? 0;
    yolIzni = prefs.getString('yolIzni');
    yolIzniDisplay = yolIzni == '1 (Terhis)'
        ? 0
        : yolIzni == '1+1 (İzin)'
            ? 1
            : yolIzni == '2 (Terhis)'
                ? -1
                : yolIzni == '2+2 (İzin)'
                    ? 1
                    : yolIzni == '3 (Terhis)'
                        ? -2
                        : yolIzni == '3+3 (İzin)'
                            ? 1
                            : 0;

    final String? savedEndStr = prefs.getString('end_date');

    if (dueDateStr != null && dueDateStr.isNotEmpty && durationMonths! > 0) {
      DateTime dueDate = DateTime.parse(dueDateStr); // Sulus Tarihi
      if (durationMonths == 1) {
        endDate = DateTime(
          dueDate.year,
          dueDate.month + durationMonths!,
          dueDate.day,
        )
            .add(Duration(days: izin!)) // 0
            .add(Duration(days: ceza!)) // 0
            .subtract(Duration(days: yolIzniDisplay!)); // 0
      } else if (durationMonths == 6) {
        endDate = DateTime(
          dueDate.year,
          dueDate.month + durationMonths!,
          dueDate.day,
        )
            .add(Duration(days: izin!)) // 0
            .add(Duration(days: ceza!)) // 0
            .subtract(Duration(days: yolIzniDisplay!))
            .subtract(Duration(days: 6)); // 0
      } else if (durationMonths == 12) {
        endDate = DateTime(
          dueDate.year,
          dueDate.month + durationMonths!,
          dueDate.day,
        )
            .add(Duration(days: izin!)) // 0
            .add(Duration(days: ceza!)) // 0
            .subtract(Duration(days: yolIzniDisplay!))
            .subtract(Duration(days: 12)); // 0
      } else if (savedEndStr != null && savedEndStr.isNotEmpty) {
        endDate = DateTime.tryParse(savedEndStr) ??
            DateTime(dueDate.year, dueDate.month + durationMonths!, dueDate.day);
      } else {
        endDate = DateTime(dueDate.year, dueDate.month + durationMonths!, dueDate.day);
      }

      DateTime now = DateTime.now();

      if (mounted) {
        setState(() {
          remainingDuration =
              endDate.isAfter(now) ? endDate.difference(now) : Duration.zero;
          elapsedDuration =
              now.isAfter(dueDate) ? now.difference(dueDate) : Duration.zero;
        });
      }

      prefs.setInt('remainingDays', remainingDuration.inDays);
      await prefs.setString('end_date', endDate.toIso8601String());
      print('Remaining Days: ${remainingDuration.inDays}');
      updateHomeWidget();
    } else if (savedEndStr != null && savedEndStr.isNotEmpty) {
      final parsedEnd = DateTime.tryParse(savedEndStr);
      if (parsedEnd != null) {
        final now = DateTime.now();
        final parsedStart = (dueDateStr != null && dueDateStr.isNotEmpty)
            ? DateTime.tryParse(dueDateStr)
            : null;
        if (mounted) {
          setState(() {
            remainingDuration =
                parsedEnd.isAfter(now) ? parsedEnd.difference(now) : Duration.zero;
            elapsedDuration = (parsedStart != null && now.isAfter(parsedStart))
                ? now.difference(parsedStart)
                : Duration.zero;
          });
        }
        prefs.setInt('remainingDays', remainingDuration.inDays);
        updateHomeWidget();
      }
    } else {
      if (mounted) {
        setState(() {
          remainingDuration = Duration.zero;
          elapsedDuration = Duration.zero;
        });
      }
      print('Error: Missing or invalid dueDateStr or durationMonths');
    }
  }

  void startTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (countdownTimer != null && countdownTimer!.isActive) return;

    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingDuration.inSeconds > 0) {
        setState(() {
          remainingDuration -= Duration(seconds: 1);
          int previousRemainingDays = prefs.getInt('remainingDays') ?? 0;
          if (previousRemainingDays != remainingDuration.inDays) {
            prefs.setInt('remainingDays', remainingDuration.inDays);
            updateHomeWidget();
          }
        });
      } else {
        timer.cancel();
        final sulusStr = prefs.getString('sulus_tarihi');
        final parsedSulus = sulusStr != null ? DateTime.tryParse(sulusStr) : null;
        if (parsedSulus != null) {
          elapsedDuration = DateTime.now().difference(parsedSulus);
        }
      }
    });
  }

  @override
  void dispose() {
    SoldierMatchService.instance.dataSyncVersion.removeListener(_onExternalDataSync);
    _scrollController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  double calculatePercentage() {
    if (remainingDuration <= Duration.zero) {
      return 1.0;
    }
    if (elapsedDuration <= Duration.zero) {
      return 0.0;
    }
    final int months = durationMonths ?? 0;
    final int totalDurationInSeconds = months > 0
        ? (months * 30 * 24 * 60 * 60) +
            ((izin ?? 0) * 24 * 60 * 60) +
            ((ceza ?? 0) * 24 * 60 * 60) -
            ((yolIzniDisplay ?? 0) * 24 * 60 * 60)
        : (elapsedDuration.inSeconds + remainingDuration.inSeconds);

    // Elapsed duration in seconds
    final elapsedDurationInSeconds = elapsedDuration.inSeconds;

    // Calculate percentage
    if (totalDurationInSeconds > 0) {
      return (elapsedDurationInSeconds / totalDurationInSeconds)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$days Gün $hours Saat $minutes Dakika";
  }

  void _hydrateCountdownSync(SharedPreferences prefs) {
    isKalanBlurred.value = prefs.getBool('isKalanBlurred') ?? false;
    isGecenBlurred.value = prefs.getBool('isGecenBlurred') ?? false;
    durationMonths = prefs.getInt('duration') ?? 0;
    izin = prefs.getInt('izin') ?? 0;
    ceza = prefs.getInt('ceza') ?? 0;
    yolIzni = prefs.getString('yolIzni');
    yolIzniDisplay = yolIzni == '1 (Terhis)'
        ? 0
        : yolIzni == '1+1 (İzin)'
            ? 1
            : yolIzni == '2 (Terhis)'
                ? -1
                : yolIzni == '2+2 (İzin)'
                    ? 1
                    : yolIzni == '3 (Terhis)'
                        ? -2
                        : yolIzni == '3+3 (İzin)'
                            ? 1
                            : 0;

    final role = prefs.getString('user_role') ?? 'asker';
    final targetQuotes = role == 'yakin' ? yakinSozleri : askeriSozler;
    if (displayGununSozu.isEmpty && targetQuotes.isNotEmpty) {
      displayGununSozu = targetQuotes[Random().nextInt(targetQuotes.length)];
    }

    final String? savedEndStr = prefs.getString('end_date');
    final String? dueDateStr = prefs.getString('sulus_tarihi');
    final DateTime now = DateTime.now();
    if (savedEndStr != null && savedEndStr.isNotEmpty) {
      final parsedEnd = DateTime.tryParse(savedEndStr);
      if (parsedEnd != null) {
        remainingDuration =
            parsedEnd.isAfter(now) ? parsedEnd.difference(now) : Duration.zero;
      }
    }
    if (dueDateStr != null && dueDateStr.isNotEmpty) {
      final parsedDue = DateTime.tryParse(dueDateStr);
      if (parsedDue != null) {
        elapsedDuration =
            now.isAfter(parsedDue) ? now.difference(parsedDue) : Duration.zero;
      }
    }
  }

  Map<String, String?> _extractProfileDataSync(SharedPreferences prefs) {
    String? name = prefs.getString('name');
    String? surname = prefs.getString('surname');
    String? askerlikYeri = prefs.getString('askerlik_yeri');
    String? memleket = prefs.getString('memleket');
    sulusTarihi = prefs.getString('sulus_tarihi');
    terhisTarihi = prefs.getString('end_date');
    String? kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi');
    String? rutbe = prefs.getString('rutbe');
    String? themeColor = prefs.getString('themeColor');
    String? userRole = prefs.getString('user_role') ?? 'asker';
    String? relationship = prefs.getString('relationship');
    String? followerName = prefs.getString('follower_name');
    String? trackingCode = prefs.getString('tracking_code');
    String? pairedCode = prefs.getString('paired_code');
    bool isPaired = prefs.getBool('is_paired') ?? false;

    String? kanGrubu = prefs.getString('kan_grubu');
    String? babaAdi = prefs.getString('baba_adi');
    String? dini = prefs.getString('dini');
    String? tertip = prefs.getString('tertip');

    if ((tertip == null || tertip.isEmpty) &&
        sulusTarihi != null &&
        sulusTarihi!.isNotEmpty) {
      try {
        final sulusDt = DateTime.parse(sulusTarihi!);
        final termNumber = ((sulusDt.month - 1) ~/ 3) + 1;
        tertip = '${sulusDt.year}/$termNumber';
      } catch (_) {
        tertip = '2024/1';
      }
    }

    String? customHeaderPhoto = prefs.getString('custom_header_photo_path');
    if (customHeaderPhoto != null && !File(customHeaderPhoto).existsSync()) {
      customHeaderPhoto = null;
    }
    double customHeaderPhotoY = prefs.getDouble('custom_header_photo_y') ?? 0.0;
    double customHeaderPhotoX = prefs.getDouble('custom_header_photo_x') ?? 0.0;

    return {
      'name': name,
      'surname': surname,
      'askerlikYeri': askerlikYeri,
      'memleket': memleket,
      'sulusTarihi': sulusTarihi,
      'terhisTarihi': terhisTarihi,
      'kuvvetKomutanligi': kuvvetKomutanligi,
      'rutbe': rutbe,
      'themeColor': themeColor,
      'userRole': userRole,
      'relationship': relationship,
      'followerName': followerName,
      'trackingCode': trackingCode,
      'pairedCode': pairedCode,
      'isPaired': isPaired.toString(),
      'userId': prefs.getString('userId'),
      'kanGrubu': (kanGrubu != null && kanGrubu.isNotEmpty) ? kanGrubu : 'A Rh (+)',
      'babaAdi': babaAdi ?? '',
      'dini': (dini != null && dini.isNotEmpty) ? dini : 'İSLAM',
      'tertip': tertip ?? '2024/1',
      'customHeaderPhoto': customHeaderPhoto,
      'customHeaderPhotoY': customHeaderPhotoY.toString(),
      'customHeaderPhotoX': customHeaderPhotoX.toString(),
    };
  }

  Future<Map<String, String?>> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    SoldierMatchService.instance.cachedPrefs = prefs;
    final map = _extractProfileDataSync(prefs);
    final String userRole = map['userRole'] ?? 'asker';
    String? trackingCode = map['trackingCode'];

    if (userRole == 'asker' && (trackingCode == null || trackingCode.isEmpty)) {
      trackingCode = await SoldierMatchService.instance.generateOrGetTrackingCode();
      await prefs.setString('tracking_code', trackingCode);
      map['trackingCode'] = trackingCode;
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _profileDataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _cachedProfileData;
        if (data == null) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }
          return const SizedBox.shrink();
        }
        _cachedProfileData = data;
        {
          final bool isRelative = data['userRole'] == 'yakin';
          final double customPhotoY = double.tryParse(data['customHeaderPhotoY'] ?? '0.0') ?? 0.0;
          final double customPhotoX = double.tryParse(data['customHeaderPhotoX'] ?? '0.0') ?? 0.0;

          return SingleChildScrollView(
            controller: _scrollController,
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            child: Column(
              children: [
                // 1. Edge-to-Edge Hero Header (Status Bar Integrated & Full-bleed)
                buildHeaderSection(
                  name: data['name'],
                  surname: data['surname'],
                  kuvvetKomutanligi: data['kuvvetKomutanligi'],
                  rutbe: data['rutbe'],
                  userRole: data['userRole'],
                  relationship: data['relationship'],
                  trackingCode: data['trackingCode'],
                  pairedCode: data['pairedCode'],
                  isPaired: data['isPaired'] == 'true',
                  customPhotoPath: data['customHeaderPhoto'],
                  customPhotoY: customPhotoY,
                  customPhotoX: customPhotoX,
                ),

                // 2. Page Content with standard 16px horizontal margins
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 12.0,
                    bottom: 120.0,
                  ),
                  child: Column(
                    children: [
                      // 1A. Sleek Single-Row Live Capsule Strip
                      buildTopTimeCapsuleSpotlight(data),

                      // 1B. Soldier Share Code or Relative Sync banner (has top: 10 margin)
                      if (data['userRole'] == 'asker')
                        buildSoldierShareCodeCard(data['trackingCode'] ?? '')
                      else if (data['userRole'] == 'yakin')
                        buildRelativeSyncBanner(data),

                      const SizedBox(height: 10),

                      // 2. Dual Tactical Mission Timeline (Kalan & Geçen Süre - Birleşik Taktik Sayaç)
                      buildDualTimeSection(isRelative: isRelative),

                      const SizedBox(height: 10),

                      // 3. Tactical Mission Progress HUD
                      buildProgressBar(isRelative: isRelative),

                      const SizedBox(height: 10),

                      // 4. Tactical Quick Actions (Anı Defteri & Şafak Çizelgesi)
                      buildActionCardsSection(),

                      const SizedBox(height: 10),

                      // 5. Military Dossier (2x2 Askeri Künye Grid)
                      buildUserInfoPanel(data),

                      const SizedBox(height: 10),

                      // 6. Operation Calendar (Askerlik Takvimi - Sürpriz Zaman Kapsüllü)
                      Container(
                        key: _calendarSectionKey,
                        child: buildCalendarCard(data),
                      ),

                      const SizedBox(height: 10),

                      // 7. Tactical Intel & Quotes
                      buildShortInfoContainer(),
                      const SizedBox(height: 10),
                      buildGununSozu(),

                      const SizedBox(height: 10),

                      // 8. TSK Askeri Rütbe Hiyerarşisi (Askeri Rütbeler)
                      buildInfoContainer(data['rutbe'], data['kuvvetKomutanligi']),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _saveBlurState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKalanBlurred', isKalanBlurred.value);
    await prefs.setBool('isGecenBlurred', isGecenBlurred.value);
  }

  // ==========================================
  // CUSTOM HEADER PHOTO & LIVE PREVIEW (PRO AYRICALIĞI)
  // ==========================================
  Future<void> _openCustomPhotoLivePreview({
    required String photoPath,
    required Map<String, String?> profileData,
    double initialX = 0.0,
    double initialY = 0.0,
    bool isEditingExisting = false,
  }) async {
    HapticFeedback.lightImpact();
    final bool? applied = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        settings: const RouteSettings(name: 'CustomPhotoPreviewPage'),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CustomPhotoPreviewPage(
              initialPhotoPath: photoPath,
              initialPhotoX: initialX,
              initialPhotoY: initialY,
              isEditingExisting: isEditingExisting,
              backgroundImage: widget.backgroundImage,
              profileData: profileData,
              remainingDays:
                  remainingDuration.inDays > 0 ? remainingDuration.inDays : 0,
              elapsedDays:
                  elapsedDuration.inDays > 0 ? elapsedDuration.inDays : 0,
              progressPercent: calculatePercentage(),
            ),
          );
        },
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        _profileDataFuture = _loadData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEditingExisting
                    ? 'Fotoğraf kadrajı güncellendi! 💕'
                    : 'Özel şafak fotoğrafın uygulandı! 💕',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _showCustomPhotoBottomSheet({
    required Map<String, String?> profileData,
    required String? currentPhotoPath,
    double currentPhotoY = 0.0,
    double currentPhotoX = 0.0,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ValueListenableBuilder<bool>(
          valueListenable: RevenueCatService.instance.isPremiumNotifier,
          builder: (context, isPremium, _) {
            final bool hasActivePhoto = isPremium &&
                currentPhotoPath != null &&
                File(currentPhotoPath).existsSync();

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.pinkAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Şafak Kartını Özelleştir',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPremium
                                          ? const [
                                              Color(0xFF10B981),
                                              Color(0xFF059669),
                                            ]
                                          : const [
                                              Color(0xFFFFD700),
                                              Color(0xFFF59E0B),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPremium
                                            ? Icons.verified_rounded
                                            : Icons.workspace_premium_rounded,
                                        size: 11,
                                        color: isPremium
                                            ? Colors.white
                                            : const Color(0xFF1F1600),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: isPremium
                                              ? Colors.white
                                              : const Color(0xFF1F1600),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Arka plana sevdiğinin veya ikinizin fotoğrafını yerleştir',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (!isPremium) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            color: Color(0xFFFBBF24),
                            size: 19,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Galeriden fotoğrafını seçerek şafak kartında canlı önizleyebilir ve kadrajını ayarlayabilirsin. Uygulama özelliği PRO\'ya dahildir.',
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11.5,
                                height: 1.38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (hasActivePhoto) ...[
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: FileImage(File(currentPhotoPath)),
                          fit: BoxFit.cover,
                          alignment: Alignment(
                            currentPhotoX.clamp(-1.0, 1.0),
                            currentPhotoY.clamp(-1.0, 1.0),
                          ),
                        ),
                        border: Border.all(
                          color: Colors.pinkAccent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.greenAccent,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Aktif Şafak Fotoğrafı',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openCustomPhotoLivePreview(
                            photoPath: currentPhotoPath,
                            profileData: profileData,
                            initialX: currentPhotoX,
                            initialY: currentPhotoY,
                            isEditingExisting: true,
                          );
                        },
                        icon: const Icon(
                          Icons.crop_free_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '📐 Kadrajı / Konumu Ayarla',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: hasActivePhoto
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await _pickAndPreviewHeaderPhoto(profileData);
                            },
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                            label: const Text(
                              'Galeriden Başka Fotoğraf Seç',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await _pickAndPreviewHeaderPhoto(profileData);
                            },
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              isPremium
                                  ? 'Galeriden Fotoğraf Seç'
                                  : 'Galeriden Seç & Canlı Önizle',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ),

                  if (hasActivePhoto) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _removeHeaderPhoto(currentPhotoPath);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Fotoğrafı Kaldır (Varsayılan Temaya Dön)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndPreviewHeaderPhoto(
    Map<String, String?> profileData,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final tempFileName =
          'preview_header_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile =
          await File(pickedFile.path).copy('${appDir.path}/$tempFileName');

      if (mounted) {
        await _openCustomPhotoLivePreview(
          photoPath: tempFile.path,
          profileData: profileData,
          initialX: 0.0,
          initialY: 0.0,
          isEditingExisting: false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fotoğraf seçilirken bir hata oluştu: $e"),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeHeaderPhoto(String? currentPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_header_photo_path');
      await prefs.remove('custom_header_photo_y');
      await prefs.remove('custom_header_photo_x');

      if (currentPath != null) {
        final file = File(currentPath);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      if (mounted) {
        setState(() {
          _profileDataFuture = _loadData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Özel fotoğraf kaldırıldı. Varsayılan tema devrede."),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error removing photo: $e");
    }
  }

  // ==========================================
  // 1. TACTICAL COMMANDER HEADER & MAIN HUD (EDGE-TO-EDGE & STATUS BAR MERGED)
  // ==========================================
  Widget buildHeaderSection({
    required String? name,
    required String? surname,
    required String? kuvvetKomutanligi,
    required String? rutbe,
    String? userRole,
    String? relationship,
    String? trackingCode,
    String? pairedCode,
    bool isPaired = false,
    String? customPhotoPath,
    double customPhotoY = 0.0,
    double customPhotoX = 0.0,
  }) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final bool isRelative = userRole == 'yakin';
    final String fullName = name != null && name.isNotEmpty
        ? '${name.toUpperCase()} ${surname?.toUpperCase() ?? ""}'
        : (isRelative ? 'ASKERİM' : 'ŞAFAK SAYAR');
    final Map<String, String?> headerProfileMap = {
      'name': name,
      'surname': surname,
      'kuvvetKomutanligi': kuvvetKomutanligi,
      'rutbe': rutbe,
      'userRole': userRole,
      'relationship': relationship,
    };

    String relativeCategoryTitle = '🌟 ASKERİMİN ŞAFAĞI';
    if (relationship == 'es' || relationship == 'sevgili') {
      relativeCategoryTitle = '💕 SEVGİLİMİN ŞAFAĞI';
    } else if (relationship == 'aile') {
      relativeCategoryTitle = '👨‍👩‍👧 EVLADIMIN / CANIMIN ŞAFAĞI';
    } else if (relationship == 'arkadas') {
      relativeCategoryTitle = '🤝 DOSTUMUN ŞAFAĞI';
    }

    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        final bool hasCustomPhoto = isPremium &&
            customPhotoPath != null &&
            File(customPhotoPath).existsSync();
        final bool isDark = !_isDefaultTheme || hasCustomPhoto;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _getCardColor(),
              image: hasCustomPhoto
                  ? DecorationImage(
                      image: FileImage(File(customPhotoPath)),
                      fit: BoxFit.cover,
                      alignment: Alignment(
                        customPhotoX.clamp(-1.0, 1.0),
                        customPhotoY.clamp(-1.0, 1.0),
                      ),
                    )
                  : null,
              gradient: hasCustomPhoto
                  ? null
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFF1E293B), const Color(0xFF334155)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              border: Border(
                bottom: BorderSide(
                  color: hasCustomPhoto
                      ? (isRelative
                          ? Colors.pinkAccent.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.18))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
        child: Stack(
          children: [
            // Cinematic Dark Scrim for photo contrast (deep dark at top for status bar, clear in middle, dark at bottom for numbers)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.only(
                top: (statusBarHeight > 0 ? statusBarHeight : 24) + 8,
                left: 16,
                right: 16,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP STATUS BAR ACTION ROW (Title Badge + VIP/PRO + Fotoğraf Butonu)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Brand Title (Logo + ŞAFAK SAYAR 2026 - Flat / No Card Container)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "ŞAFAK SAYAR 2026",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Right Action Buttons (VIP/PRO Badge + Fotoğraf Değiştir)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // VIP / PRO Badge
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              PremiumPaywallPage.show(context, source: 'home_hero_header');
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: RevenueCatService.instance.isPremiumNotifier,
                              builder: (context, isPremium, _) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPremium
                                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                          : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isPremium ? const Color(0xFF10B981) : const Color(0xFFFFD700))
                                            .withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                                        size: 13,
                                        color: isPremium ? Colors.white : const Color(0xFF1F1600),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPremium ? 'VIP' : 'PRO',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: isPremium ? Colors.white : const Color(0xFF1F1600),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Fotoğraf Özelleştirme Butonu (PRO Önizleme + Uygulama)
                          GestureDetector(
                            onTap: () => _showCustomPhotoBottomSheet(
                              profileData: headerProfileMap,
                              currentPhotoPath: customPhotoPath,
                              currentPhotoY: customPhotoY,
                              currentPhotoX: customPhotoX,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasCustomPhoto
                                      ? (isRelative ? Colors.pinkAccent.withValues(alpha: 0.6) : Colors.white38)
                                      : (!isPremium
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                                          : Colors.white24),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasCustomPhoto ? Icons.photo_camera_rounded : Icons.add_a_photo_rounded,
                                    size: 13,
                                    color: hasCustomPhoto
                                        ? Colors.pinkAccent.shade100
                                        : (!isPremium ? const Color(0xFFFBBF24) : Colors.white),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasCustomPhoto ? "DEĞİŞTİR" : "+ FOTO",
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. COMMANDER / RELATIVE PROFILE LINE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRelative) ...[
                        Text(
                          relativeCategoryTitle,
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isRelative) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.pinkAccent.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    SoldierMatchService.getRelationshipIcon(relationship),
                                    size: 12,
                                    color: Colors.pinkAccent.shade100,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    SoldierMatchService.getRelationshipLabel(relationship).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.pink.shade100,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: (isPaired ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isPaired ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isPaired ? const Color(0xFF10B981) : Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPaired ? "CANLI EŞLEŞME" : "MANUEL",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isPaired ? const Color(0xFF34D399) : Colors.amber.shade200,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blueAccent.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    size: 12,
                                    color: Colors.blueAccent.shade100,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (rutbe != null && rutbe.isNotEmpty ? rutbe : "ER").toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blue.shade100,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. TACTICAL DUAL HUD METRICS: ŞAFAK & ATARSA
                  Row(
                    children: [
                      // ŞAFAK HUD CARD
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (isRelative ? const Color(0xFF831843) : const Color(0xFF1E3A8A)).withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: (isRelative ? Colors.pinkAccent : Colors.blueAccent).withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isRelative ? Colors.pinkAccent : Colors.blueAccent).withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Icon(
                                  isRelative ? Icons.favorite_rounded : Icons.flag_rounded,
                                  size: 58,
                                  color: (isRelative ? Colors.pink.shade300 : Colors.blue.shade300)
                                      .withValues(alpha: 0.08),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isRelative ? Icons.favorite_rounded : Icons.flag_rounded,
                                        size: 13,
                                        color: isRelative ? Colors.pink.shade200 : Colors.blue.shade200,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isRelative ? "KAVUŞMAYA" : "ŞAFAK",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isRelative ? Colors.pink.shade200 : Colors.blue.shade200,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      remainingDuration.inDays > 0
                                          ? "${remainingDuration.inDays}"
                                          : (isRelative ? "Kavuşuldu!" : "Bitti :)"),
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    remainingDuration.inDays > 0
                                        ? (isRelative ? "GÜN KALDI 💕" : "GÜN KALDI")
                                        : (isRelative ? "KAVUŞTUNUZ 🎉" : "TERHİS OLDUN"),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ATARSA HUD CARD
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7C2D12).withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orangeAccent.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  size: 58,
                                  color: Colors.orange.shade200.withValues(alpha: 0.08),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.wb_sunny_rounded,
                                        size: 13,
                                        color: Colors.orange.shade200,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isRelative ? "YARIN ŞAFAK" : "ATARSA",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.orange.shade200,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      remainingDuration.inDays - 1 == 0
                                          ? "Doğan Güneş"
                                          : remainingDuration.inDays < 1
                                              ? "Atmıyor :)"
                                              : "${remainingDuration.inDays - 1}",
                                      style: TextStyle(
                                        fontSize: remainingDuration.inDays - 1 == 0 ? 24 : 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    remainingDuration.inDays - 1 == 0
                                        ? "SON GÜN"
                                        : remainingDuration.inDays < 1
                                            ? "GÖREV BİTTİ"
                                            : "BİR SONRAKİ GÜN",
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  // ==========================================
  // SOLDIER SHARE CODE CARD
  // ==========================================
  Widget buildSoldierShareCodeCard(String trackingCode) {
    if (trackingCode.isEmpty) return const SizedBox.shrink();
    final bool isDark = !_isDefaultTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        if (!isPremium) {
          return _buildSoldierTrackingLockedCard(isDark);
        }
        return _buildSoldierTrackingUnlockedCard(trackingCode, isDark);
      },
    );
  }

  // PRO Kilitli Şafak Takip Kartı (Teaser & Kısıtlama Tasarımı)
  Widget _buildSoldierTrackingLockedCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B).withValues(alpha: 0.95), const Color(0xFF0F172A).withValues(alpha: 0.98)]
              : [Colors.white, const Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Satırı & PRO Rozeti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Color(0xFF1F1600), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ŞAFAK TAKİP KODU',
                        style: TextStyle(
                          color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Sevdiklerinle Canlı Paylaşım',
                        style: TextStyle(
                          color: _getTextColor(),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 12, color: Color(0xFF1F1600)),
                    SizedBox(width: 3),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F1600),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Maskeli / Kilitli Kod Alanı (Tıklanınca Simülasyon Önizleme Açılır)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              LiveShareSimulationPage.show(context, initialTab: 0);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'TR-••••••',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill_rounded, size: 12, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          'DEMO ÖNİZLE',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bilgilendirme Açıklaması
          Text(
            'Sevgilin, eşin veya ailen bu özel kod ile kendi telefonundan şafağını canlı izler ve takvimine sürpriz Zaman Kapsülü bırakabilir.',
            style: TextStyle(
              color: _getSubtitleColor(),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Simülasyon Önizleme + Kilidi Açma Butonları
          Row(
            children: [
              Expanded(
                flex: 11,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    LiveShareSimulationPage.show(context, initialTab: 0);
                  },
                  icon: Icon(
                    Icons.slideshow_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                  ),
                  label: Text(
                    'Simülasyonu Gör',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFFFFBEB),
                    side: BorderSide(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 12,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    PremiumPaywallPage.show(context, source: 'soldier_tracking_code');
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFF1F1600)),
                  label: const Text(
                    "KİLİDİ AÇ • PRO",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F1600),
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1F1600),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PRO Aktif Açık Şafak Takip Kartı
  Widget _buildSoldierTrackingUnlockedCard(String trackingCode, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_location_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ŞAFAK TAKİP KODUNUZ',
                          style: TextStyle(
                            color: _getSubtitleColor(),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO AKTİF',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trackingCode,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Eşiniz, sevgiliniz veya aileniz bu kodu girerek şafağınızı canlı takip edebilir.',
            style: TextStyle(
              color: _getSubtitleColor(),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Kopyala
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: trackingCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Takip kodu kopyalandı: $trackingCode'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Paylaş
              Expanded(
                child: Builder(
                  builder: (btnContext) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final shareText = '🇹🇷 Selam! Şafak Sayar uygulamasında şafağımı ve terhis günümü anlık takip edebilirsin.\n\nTakip Kodum: $trackingCode\n\nUygulamayı açıp "Asker Yakınıyım" seçeneğinden bu kodu girerek şafağımı canlı izleyebilirsin! 🇹🇷';
                        
                        RenderBox? box = btnContext.findRenderObject() as RenderBox?;
                        Rect? origin;
                        if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
                          origin = box.localToGlobal(Offset.zero) & box.size;
                        } else {
                          final size = MediaQuery.sizeOf(btnContext);
                          origin = Rect.fromLTWH(size.width / 2 - 100, size.height / 2 - 100, 200, 200);
                        }

                        Share.share(
                          shareText,
                          subject: 'Şafak Takip Kodu: $trackingCode',
                          sharePositionOrigin: origin,
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Paylaş', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Takipçilerim
              IconButton(
                onPressed: () => _showFollowersModal(trackingCode),
                tooltip: 'Seni Takip Edenler',
                icon: const Icon(Icons.group_rounded, color: Color(0xFF2563EB), size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RELATIVE LIVE SYNC BANNER
  // ==========================================
  Widget buildRelativeSyncBanner(Map<String, String?> data) {
    final bool isDark = !_isDefaultTheme;
    final bool isPaired = data['isPaired'] == 'true';
    final String pairedCode = data['pairedCode'] ?? '';
    final String soldierName = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFFFF1F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.pinkAccent.withValues(alpha: 0.35) : Colors.pink.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TAKİP EDİLEN ASKER',
                      style: TextStyle(
                        color: _getSubtitleColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      soldierName.isNotEmpty
                          ? '${soldierName.toUpperCase()}${isPaired && pairedCode.isNotEmpty ? ' ($pairedCode)' : ''}'
                          : 'ASKERİNİZ',
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPaired ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isPaired ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isPaired ? const Color(0xFF10B981) : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPaired ? 'Canlı Takip' : 'Manuel',
                      style: TextStyle(
                        color: isPaired ? const Color(0xFF10B981) : Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPaired) ...[
            Text(
              'Askerinizin güncellediği tüm sülüs, izin ve ceza değişiklikleri buraya canlı yansır.',
              style: TextStyle(
                color: _getSubtitleColor(),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final synced = await SoldierMatchService.instance.syncPairedSoldierData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(synced
                                ? 'Şafak verileri güncellendi! 🇹🇷'
                                : 'Zaten en güncel şafak verilerini görüntülüyorsunuz.'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Senkronize Et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmHomeUnpair(),
                    icon: const Icon(Icons.link_off_rounded, size: 16),
                    label: const Text('Eşleşmeyi Kaldır', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showHomePairingDialog(data['relationship']),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: const Text('Takip Kodu ile Eşleş', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.pinkAccent,
                      side: const BorderSide(color: Colors.pinkAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmHomeUnpair() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eşleşmeyi Kaldır?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Asker takip kodunuz silinecek ve verileriniz manuel moda geçecektir. Onaylıyor musunuz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eşleşmeyi Kaldır', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SoldierMatchService.instance.unpairSoldier();
      NotificationService().scheduleAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eşleşme kaldırıldı. Manuel moddasınız.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showHomePairingDialog(String? relationship) {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: Colors.pinkAccent),
                  SizedBox(width: 8),
                  Text('Asker Kodu ile Eşleş', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Askerinizin size verdiği takip kodunu (örn: SFK-1234) giriniz:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      hintText: 'SFK-XXXX',
                      hintStyle: const TextStyle(color: Colors.white30),
                      errorText: errorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        Navigator.push(
                          this.context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeRolePage(isSwitchingRole: true),
                          ),
                        ).then((_) {
                          SoldierMatchService.instance.notifyDataChanged(pairingChanged: true);
                        });
                      },
                      child: const Text(
                        'Rolü Değiştir',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('İptal', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) {
                            setDialogState(() => errorText = 'Lütfen bir kod girin');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            errorText = null;
                          });
                          final soldier = await SoldierMatchService.instance.getSoldierByTrackingCode(code);
                          if (soldier == null) {
                            setDialogState(() {
                              isLoading = false;
                              errorText = 'Asker bulunamadı. Kodu kontrol edin.';
                            });
                            return;
                          }
                          final prefs = await SharedPreferences.getInstance();
                          await SoldierMatchService.instance.pairWithSoldier(
                            code: code,
                            relationship: (relationship != null && relationship.isNotEmpty)
                                ? relationship
                                : (prefs.getString('relationship') ?? 'es'),
                            followerName: prefs.getString('follower_name') ?? 'Yakını',
                          );
                          NotificationService().scheduleAllNotifications();
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('${soldier['name']} ${soldier['surname']} ile başarıyla eşleşildi! 💕'),
                                backgroundColor: Colors.pinkAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Eşleş', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFollowersModal(String trackingCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: SoldierMatchService.instance.getFollowers(trackingCode),
          builder: (context, snapshot) {
            final followers = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Şafağını Takip Edenler (${followers.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (followers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.person_add_rounded, color: Colors.white.withValues(alpha: 0.3), size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Henüz seni takip eden kimse yok.\nTakip kodunu eşine, sevgiline veya ailene vererek anlık takip ettirebilirsin!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: followers.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final f = followers[index];
                          final name = f['name'] ?? 'Yakını';
                          final rel = f['relationship'] ?? '';
                          final relLabel = SoldierMatchService.getRelationshipLabel(rel);
                          final icon = SoldierMatchService.getRelationshipIcon(rel);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                              child: Icon(icon, color: Colors.pinkAccent, size: 20),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              relLabel,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Bağlandı',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 2. DUAL TACTICAL TIMELINE (KALAN & GEÇEN SÜRE)
  // ==========================================
  Widget buildDualTimeSection({bool isRelative = false}) {
    final bool isDark = !_isDefaultTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRelative ? Icons.favorite_border_rounded : Icons.access_time_rounded,
                    size: 14,
                    color: isDark ? (isRelative ? Colors.pinkAccent : Colors.tealAccent) : (isRelative ? Colors.pinkAccent : Colors.blueAccent.shade700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isRelative ? "KAVUŞMA ZAMAN ÇİZELGESİ" : "GÖREV ZAMAN ÇİZELGESİ",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _getSubtitleColor(),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 12, color: _getSubtitleColor().withValues(alpha: 0.6)),
                  const SizedBox(width: 3),
                  Text(
                    "Gizlemek için dokun",
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _getSubtitleColor().withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two-column side by side tactical time meters
          Row(
            children: [
              // LEFT: KALAN SÜRE
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    isKalanBlurred.value = !isKalanBlurred.value;
                    _saveBlurState();
                  },
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isKalanBlurred,
                    builder: (context, isBlurred, child) {
                      return buildTacticalTimeCard(
                        title: isRelative ? "KAVUŞMAYA KALAN" : "KALAN SÜRE",
                        icon: isRelative ? Icons.favorite_rounded : Icons.hourglass_bottom_rounded,
                        accentColor: isDark
                            ? (isRelative ? Colors.pinkAccent : Colors.cyanAccent)
                            : (isRelative ? Colors.pinkAccent : Colors.blueAccent.shade700),
                        duration: remainingDuration,
                        isBlurred: isBlurred,
                        isKalan: true,
                      );
                    },
                  ),
                ),
              ),

              // Vertical Tactical Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 1.2,
                height: 58,
                color: _getBorderColor(),
              ),

              // RIGHT: GEÇEN SÜRE
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    isGecenBlurred.value = !isGecenBlurred.value;
                    _saveBlurState();
                  },
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isGecenBlurred,
                    builder: (context, isBlurred, child) {
                      return buildTacticalTimeCard(
                        title: "GEÇEN SÜRE",
                        icon: Icons.history_toggle_off_rounded,
                        accentColor: isDark ? Colors.amberAccent : Colors.orange.shade700,
                        duration: elapsedDuration,
                        isBlurred: isBlurred,
                        isKalan: false,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTacticalTimeCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Duration duration,
    required bool isBlurred,
    required bool isKalan,
  }) {
    final String days = duration.inDays.toString();
    final String hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off_outlined, color: _getSubtitleColor(), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Gizlendi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getSubtitleColor(),
                  ),
                ),
              ],
            ),
          ),
          secondChild: duration == Duration.zero && isKalan
              ? Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(
                    'ZAMAN DOLDU 🫡',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isDefaultTheme ? Colors.green.shade700 : Colors.greenAccent,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildTacticalDigitBox(days, "GÜN"),
                    Text(":", style: TextStyle(color: _getSubtitleColor().withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                    buildTacticalDigitBox(hours, "SAAT"),
                    Text(":", style: TextStyle(color: _getSubtitleColor().withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                    buildTacticalDigitBox(minutes, "DK"),
                  ],
                ),
          crossFadeState: isBlurred ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget buildTacticalDigitBox(String val, String label) {
    final bool isDark = !_isDefaultTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _getTextColor(),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: _getSubtitleColor(),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProgressBar({bool isRelative = false}) {
    final double percentage = calculatePercentage();
    final bool isDark = !_isDefaultTheme;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _getCardColor(),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _getBorderColor(), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isRelative ? Icons.favorite_rounded : Icons.military_tech_rounded,
                      size: 16,
                      color: isDark ? (isRelative ? Colors.pinkAccent : Colors.tealAccent) : (isRelative ? Colors.pinkAccent : Colors.blueAccent.shade700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRelative ? "KAVUŞMA İLERLEMESİ" : "GÖREV İLERLEMESİ",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _getSubtitleColor(),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.tealAccent.withValues(alpha: 0.15)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.tealAccent.withValues(alpha: 0.4)
                          : Colors.blueAccent.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '%${(percentage * 100).toStringAsFixed(1)} TAMAMLANDI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.tealAccent : Colors.blueAccent.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double progressWidth = totalWidth * percentage;

                return Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // Outer track
                    Container(
                      width: totalWidth,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                    ),
                    // Glowing progress fill
                    Container(
                      width: progressWidth > 12.0 ? progressWidth : 12.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF06B6D4), const Color(0xFF10B981)]
                              : [Colors.blueAccent.shade400, Colors.teal.shade500],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.tealAccent : Colors.blueAccent)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    // Gliding runner GIF
                    Positioned(
                      left: (progressWidth - 16.0).clamp(0.0, totalWidth - 32.0),
                      top: -10.0,
                      child: Image.asset(
                        percentage >= 1.0
                            ? 'assets/images/finish.gif'
                            : 'assets/images/running_man2.gif',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Geçen: ${elapsedDuration.inDays} Gün",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getSubtitleColor(),
                  ),
                ),
                Text(
                  remainingDuration.inDays > 0
                      ? "Kalan: ${remainingDuration.inDays} Gün"
                      : "Terhis Tamamlandı 🫡",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.tealAccent : Colors.blueAccent.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. TACTICAL ACTION CARDS (ANI DEFTERİ & ŞAFAK ÇİZELGESİ)
  // ==========================================
  Widget buildActionCardsSection() {
    final bool isDark = !_isDefaultTheme;
    final bool isCompleted = remainingDuration <= Duration.zero;

    return Row(
      children: [
        // 1. TERHİS ANI DEFTERİ
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _getCardColor(),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF1F5F9),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isCompleted
                    ? (isDark ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.green.shade400)
                    : _getBorderColor(),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AniDefteriPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? (isDark
                                      ? Colors.greenAccent.withValues(alpha: 0.2)
                                      : Colors.green.shade100)
                                  : (isDark
                                      ? Colors.blueAccent.withValues(alpha: 0.15)
                                      : Colors.blue.shade50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.auto_stories_rounded
                                  : Icons.auto_stories_outlined,
                              size: 20,
                              color: isCompleted
                                  ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                                  : (isDark ? Colors.blueAccent : Colors.blueAccent.shade700),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: _getSubtitleColor().withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "ANI DEFTERİ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _getTextColor(),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isCompleted ? "Anıları İncele 🫡" : "Terhis Anıları",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                              : _getSubtitleColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. ŞAFAK ÇİZELGESİ
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _getCardColor(),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF1F5F9),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _getBorderColor(),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'SafakCizelgesiPage'),
                      builder: (context) => SafakCizelgesiPage(
                        backgroundImage: widget.backgroundImage,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.pinkAccent.withValues(alpha: 0.15)
                                  : Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              size: 20,
                              color: isDark ? Colors.pinkAccent : Colors.pink.shade700,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: _getSubtitleColor().withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "ŞAFAK ÇİZELGESİ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _getTextColor(),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Sevgi Takvimi 💖",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getSubtitleColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. ASKERİ KÜNYE (AUTHENTIC TSK MILITARY DOG TAG)
  // ==========================================
  Widget buildUserInfoPanel(Map<String, String?> data) {
    final bool isDark = !_isDefaultTheme;
    final bool isRelative = data['userRole'] == 'yakin';
    final bool isPaired = data['isPaired'] == 'true';
    final String soldierFullName = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
    final String displayName = soldierFullName.isNotEmpty
        ? soldierFullName
        : (isRelative ? 'TAKİP EDİLEN ASKER' : 'MEHMETÇİK');
    final String rutbe = (data['rutbe'] ?? 'ER').trim();
    final String kuvvet = (data['kuvvetKomutanligi'] ?? 'KARA K.').trim();
    final String askerlikYeri = (data['askerlikYeri'] ?? 'BELİRTİLMEDİ').trim();
    final String memleket = (data['memleket'] ?? 'BELİRTİLMEDİ').trim();
    final String kanGrubu = (data['kanGrubu'] ?? 'A Rh (+)').trim();
    final String babaAdi = (data['babaAdi'] ?? '').trim();
    final String dini = (data['dini'] ?? 'İSLAM').trim();
    final String tertip = (data['tertip'] ?? '2024/1').trim();
    final String formattedSulus = data['sulusTarihi'] != null
        ? DateFormat('dd.MM.yyyy').format(DateTime.parse(data['sulusTarihi']!))
        : '-';
    final String formattedTerhis = data['terhisTarihi'] != null
        ? DateFormat('dd.MM.yyyy').format(DateTime.parse(data['terhisTarihi']!))
        : '-';
    final String relationship = data['relationship'] ?? '';
    final String trackingCode = (data['trackingCode'] ?? '').trim();
    final String pairedCode = (data['pairedCode'] ?? '').trim();
    final String kunyeCode = isRelative
        ? (pairedCode.isNotEmpty ? pairedCode : (trackingCode.isNotEmpty ? trackingCode : 'SFK-YAKIN'))
        : (trackingCode.isNotEmpty ? trackingCode : 'SFK-TSK');

    // Metallic dog tag color palettes
    final Color silencerColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
    final Color plateBorderColor = isDark
        ? const Color(0xFF64748B).withValues(alpha: 0.6)
        : const Color(0xFF94A3B8);

    return Column(
      children: [
        // 1. Hanging Bead Chain (Askeri Bilyeli Künye Zinciri)
        Center(
          child: SizedBox(
            height: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.2),
                  width: 6.8,
                  height: 6.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [const Color(0xFFF1F5F9), const Color(0xFF94A3B8), const Color(0xFF1E293B)]
                          : [Colors.white, const Color(0xFF94A3B8), const Color(0xFF475569)],
                      center: const Alignment(-0.35, -0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),

        // 2. Dog Tag Outer Silencer Casing ("Künye Lastiği / Kauçuk Koruyucu")
        Container(
          decoration: BoxDecoration(
            color: silencerColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFF475569),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: (isDark ? Colors.blueGrey : const Color(0xFF64748B)).withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(5.0), // Outer rubber silencer gasket rim
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Inner Brushed Stainless Steel Plate (Fırçalanmış Pres Metal Levha)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF334155), // Specular streak
                            const Color(0xFF1E293B), // Cold steel base
                            const Color(0xFF475569), // Specular light highlight
                            const Color(0xFF161E2E), // Deep steel shadow
                            const Color(0xFF283347), // Bottom metallic reflection
                          ]
                        : [
                            const Color(0xFFFFFFFF), // Specular white glare
                            const Color(0xFFE2E8F0), // Brushed stainless aluminum
                            const Color(0xFFF8FAFC), // Center specular highlight
                            const Color(0xFFCBD5E1), // Steel shadow
                            const Color(0xFFE6EDF5), // Satin metal
                          ],
                    stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
                    begin: const Alignment(-0.8, -0.6),
                    end: const Alignment(0.8, 0.6),
                  ),
                  border: Border.all(color: plateBorderColor, width: 1.4),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP ROW: Punched Grommet Hole + Stamped T.C. Header + Edit Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Punched Grommet Eyelet Hole (Metal Pres Zincir Deliği)
                        Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF64748B), const Color(0xFF1E293B), const Color(0xFF94A3B8)]
                                  : [const Color(0xFFCBD5E1), const Color(0xFF64748B), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF030712) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Center Stamped Military Header
                        Expanded(
                          child: Text(
                            "★  T. C.  ★",
                            textAlign: TextAlign.center,
                            style: _getDogTagTextStyle(
                              isDark: isDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),

                        // Subtle Stamped Edit Action
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showEditKunyeDialog(data),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.15),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "DÜZENLE",
                                  style: _getDogTagTextStyle(
                                    isDark: isDark,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Dog Tag Official Subtitle
                    Text(
                      isRelative ? "TAKİP EDİLEN ASKER KÜNYESİ" : "TÜRKİYE CUMHURİYETİ ASKERİ KÜNYESİ",
                      textAlign: TextAlign.center,
                      style: _getDogTagTextStyle(
                        isDark: isDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                      ),
                    ),

                    // Stamped Metal Groove Divider
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      height: 1.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // ==========================================
                    // AUTHENTIC TSK DOG TAG STAMPED TEXT LINES
                    // (Directly stamped on metal plate - NO CARDS)
                    // ==========================================

                    // 1. AD SOYAD (Large Embossed Line)
                    _buildStampedLine(
                      label: "AD SOYAD    : ",
                      value: displayName.toUpperCase(),
                      isDark: isDark,
                      fontSize: 13.0,
                    ),

                    // 2. BABA ADI & KAN GRUBU (2-Column Stamped Row)
                    _buildStampedTwoColumnRow(
                      label1: "BABA ADI  : ",
                      value1: babaAdi.isNotEmpty ? babaAdi.toUpperCase() : 'MEHMET',
                      label2: "KAN GRUBU: ",
                      value2: kanGrubu.toUpperCase(),
                      isDark: isDark,
                    ),

                    // 3. MEMLEKET & DİNİ (2-Column Stamped Row)
                    _buildStampedTwoColumnRow(
                      label1: "MEMLEKET  : ",
                      value1: memleket.toUpperCase(),
                      label2: "DİNİ     : ",
                      value2: dini.toUpperCase(),
                      isDark: isDark,
                    ),

                    // 4. KUVVET & TERTİP (2-Column Stamped Row)
                    _buildStampedTwoColumnRow(
                      label1: "KUVVET    : ",
                      value1: "${kuvvet.toUpperCase()} (${rutbe.toUpperCase()})",
                      label2: "TERTİP   : ",
                      value2: tertip.toUpperCase(),
                      isDark: isDark,
                    ),

                    // 5. GÖREV YERİ / BİRLİĞİ
                    _buildStampedLine(
                      label: "GÖREV YERİ  : ",
                      value: askerlikYeri.toUpperCase(),
                      isDark: isDark,
                    ),

                    // 6. SÜLÜS / TERHİS TARİHLERİ
                    _buildStampedLine(
                      label: "SÜLÜS/TERHİS: ",
                      value: "$formattedSulus → $formattedTerhis",
                      isDark: isDark,
                    ),

                    // 7. KÜNYE SERİ NUMARASI (Tap to copy)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (kunyeCode.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: kunyeCode));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Künye No panoya kopyalandı: $kunyeCode'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF15803D),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            Text(
                              "KÜNYE NO    : ",
                              style: _getDogTagTextStyle(
                                isDark: isDark,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              "#$kunyeCode",
                              style: _getDogTagTextStyle(
                                isDark: isDark,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.amberAccent.shade100 : Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.copy_rounded,
                              size: 10,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 8. IF RELATIVE: TRACKING STATUS LINE
                    if (isRelative) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Text(
                              "TAKİP EDEN  : ",
                              style: _getDogTagTextStyle(
                                isDark: isDark,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${SoldierMatchService.getRelationshipLabel(relationship).toUpperCase()} (CANLI BAĞLI)",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _getDogTagTextStyle(
                                  isDark: isDark,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.pinkAccent.shade100 : Colors.pink.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Stamped Metal Groove Divider
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      height: 1.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // BOTTOM FOOTPRINT: TSK MİLLİ SAVUNMA BAKANLIĞI STAMP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "T.C. MİLLİ SAVUNMA BAKANLIĞI",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          isPaired ? "● CANLI EŞLEŞTİ" : "RESMİ ASKER KÜNYESİ",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Side Silencer Notches (Künye lastiği kenar tırtıkları)
              Positioned(top: 30, left: -2, child: _buildSilencerNotch(isDark)),
              Positioned(top: 60, left: -2, child: _buildSilencerNotch(isDark)),
              Positioned(top: 90, left: -2, child: _buildSilencerNotch(isDark)),
              Positioned(top: 30, right: -2, child: _buildSilencerNotch(isDark)),
              Positioned(top: 60, right: -2, child: _buildSilencerNotch(isDark)),
              Positioned(top: 90, right: -2, child: _buildSilencerNotch(isDark)),
            ],
          ),
        ),
      ],
    );
  }

  // Stamped typography styling helper producing physical letterpress depth
  TextStyle _getDogTagTextStyle({
    required bool isDark,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 1.0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Courier',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color ?? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
      shadows: [
        // Specular highlight on bottom edge
        Shadow(
          offset: const Offset(0.7, 0.9),
          color: isDark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.95),
          blurRadius: 0.3,
        ),
        // Stamped depression shadow on top-left edge
        Shadow(
          offset: const Offset(-0.6, -0.6),
          color: isDark ? Colors.black.withValues(alpha: 0.9) : const Color(0xFF0F172A).withValues(alpha: 0.65),
          blurRadius: 0.5,
        ),
      ],
    );
  }

  // Stamped single full-width row directly on the metal plate
  Widget _buildStampedLine({
    required String label,
    required String value,
    required bool isDark,
    double fontSize = 11.0,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _getDogTagTextStyle(
              isDark: isDark,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _getDogTagTextStyle(
                isDark: isDark,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stamped 2-column row directly on the metal plate
  Widget _buildStampedTwoColumnRow({
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    required bool isDark,
    double fontSize = 10.5,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Text(
                  label1,
                  style: _getDogTagTextStyle(
                    isDark: isDark,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Expanded(
                  child: Text(
                    value1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _getDogTagTextStyle(
                      isDark: isDark,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Text(
                  label2,
                  style: _getDogTagTextStyle(
                    isDark: isDark,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Expanded(
                  child: Text(
                    value2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _getDogTagTextStyle(
                      isDark: isDark,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rubber silencer side grip notch
  Widget _buildSilencerNotch(bool isDark) {
    return Container(
      width: 4,
      height: 7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Interactive Bottom Sheet to Edit Authentic Military Künye Details
  void _showEditKunyeDialog(Map<String, String?> data) {
    final TextEditingController babaController =
        TextEditingController(text: data['babaAdi'] ?? '');
    final TextEditingController diniController =
        TextEditingController(text: data['dini'] ?? 'İSLAM');
    final TextEditingController tertipController =
        TextEditingController(text: data['tertip'] ?? '2024/1');
    String selectedKanGrubu = data['kanGrubu'] ?? 'A Rh (+)';

    final List<String> kanGruplari = [
      'A Rh (+)',
      'A Rh (-)',
      'B Rh (+)',
      'B Rh (-)',
      'AB Rh (+)',
      'AB Rh (-)',
      '0 Rh (+)',
      '0 Rh (-)',
    ];

    if (!kanGruplari.contains(selectedKanGrubu)) {
      selectedKanGrubu = 'A Rh (+)';
    }

    final bool isDark = !_isDefaultTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, color: Colors.blueAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Asker Künyesi Bilgilerini Düzenle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gerçek TSK asker künyenizde yazan bilgileri buradan özelleştirebilirsiniz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Baba Adı
                    TextField(
                      controller: babaController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Baba Adı',
                        hintText: 'Örn: MEHMET',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Kan Grubu Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bloodtype_outlined, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedKanGrubu,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                icon: const Icon(Icons.arrow_drop_down),
                                isExpanded: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                items: kanGruplari.map((String k) {
                                  return DropdownMenuItem<String>(
                                    value: k,
                                    child: Text('Kan Grubu: $k'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedKanGrubu = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tertip & Dini
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tertipController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Tertip',
                              hintText: 'Örn: 2024/1',
                              prefixIcon: const Icon(Icons.event_note, size: 20),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: diniController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Dini',
                              hintText: 'İSLAM',
                              prefixIcon: const Icon(Icons.account_balance, size: 20),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('baba_adi', babaController.text.trim());
                          await prefs.setString('kan_grubu', selectedKanGrubu);
                          await prefs.setString('tertip', tertipController.text.trim());
                          await prefs.setString('dini', diniController.text.trim());
                          SoldierMatchService.instance.ensureSoldierPublished();
                          SoldierMatchService.instance.notifyDataChanged(pairingChanged: false);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          setState(() {
                            _profileDataFuture = _loadData();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Asker künyesi bilgileri güncellendi.'),
                                backgroundColor: Color(0xFF15803D),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'KÜNYEYİ KAYDET',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _clampCalendarFocus(DateTime target, DateTime first, DateTime last) {
    if (target.isBefore(first)) return first;
    if (target.isAfter(last)) return last;
    return target;
  }

  String _turkishMonthYearLabel(DateTime dt) {
    const months = [
      'OCAK',
      'ŞUBAT',
      'MART',
      'NİSAN',
      'MAYIS',
      'HAZİRAN',
      'TEMMUZ',
      'AĞUSTOS',
      'EYLÜL',
      'EKİM',
      'KASIM',
      'ARALIK',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _shortDayMonth(DateTime? dt) {
    if (dt == null) return '--.--';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  bool _isDayCheckedInMap(DateTime day, Map<DateTime, bool> selectedDays) {
    final dayNormalized = DateTime(day.year, day.month, day.day);
    if (_isElapsedDay(dayNormalized)) return true;
    if (selectedDays[day] == true) return true;
    return selectedDays.keys.any(
      (d) => _isSameCalendarDay(d, day) && selectedDays[d] == true,
    );
  }

  void _scrollToCalendarSection() {
    HapticFeedback.lightImpact();
    final ctx = _calendarSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  Future<void> _pickDateAndOpenCapsuleCreator({
    required String effectiveCode,
    required String userRole,
    required String senderDisplayName,
    required String senderRelationship,
    required String currentUserId,
  }) async {
    HapticFeedback.mediumImpact();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime parsedLast = (terhisTarihi != null && terhisTarihi!.isNotEmpty)
        ? (DateTime.tryParse(terhisTarihi!) ?? today.add(const Duration(days: 365)))
        : today.add(const Duration(days: 365));
    final DateTime lastDate = parsedLast.isAfter(today)
        ? parsedLast
        : today.add(const Duration(days: 365));
    final DateTime defaultCandidate = today.add(const Duration(days: 7));
    final DateTime initialDate =
        defaultCandidate.isAfter(lastDate) ? lastDate : defaultCandidate;

    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      helpText: 'SÜRPRİZ ZAMAN KAPSÜLÜ TARİHİ SEÇ',
      confirmText: 'TARİHİ SEÇ',
      cancelText: 'VAZGEÇ',
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFEC4899),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _focusedDay = picked;
      });
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CalendarCapsuleCreateSheet(
          targetDate: picked,
          trackingCode: effectiveCode,
          userRole: userRole,
          userName: senderDisplayName,
          senderRelationship: senderRelationship,
          userId: currentUserId,
          onSaved: () {
            if (mounted) setState(() {});
          },
        ),
      );
    }
  }

  // ==========================================
  // TOP-OF-HOME SLEEK DYNAMIC CAPSULE STRIP (~56px)
  // ==========================================
  Widget buildTopTimeCapsuleSpotlight(Map<String, String?> data) {
    final bool isDark = !_isDefaultTheme;
    final bool isPaired = data['isPaired'] == 'true';
    final String userRole = data['userRole'] ?? 'asker';
    final String trackingCode = (data['trackingCode'] ?? '').trim();
    final String pairedCode = (data['pairedCode'] ?? '').trim();
    final String effectiveCode = userRole == 'yakin' ? pairedCode : trackingCode;
    final String soldierFullName =
        '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
    final String followerName = (data['followerName'] ?? '').trim();
    final String relationship = (data['relationship'] ?? '').trim();
    final String relLabel = SoldierMatchService.getRelationshipLabel(relationship);
    final String senderDisplayName = userRole == 'yakin'
        ? (followerName.isNotEmpty ? '$relLabel $followerName' : relLabel)
        : (soldierFullName.isNotEmpty ? soldierFullName : 'Asker');
    final String senderRelationship = userRole == 'yakin' ? relLabel : 'Asker';
    final String currentUserId =
        data['userId'] ?? (userRole == 'asker' ? 'asker_user' : 'yakin_user');

    return StreamBuilder<List<CalendarCapsule>>(
      stream: effectiveCode.isNotEmpty
          ? CalendarCapsuleService.instance.streamCapsules(effectiveCode)
          : Stream.value(const []),
      builder: (context, snapshot) {
        final capsules = snapshot.data ?? const <CalendarCapsule>[];

        CalendarCapsule? unlockedSurprise;
        for (final c in capsules) {
          if (c.senderRole != userRole && c.isUnlockedForToday() && !c.isOpened) {
            unlockedSurprise = c;
            break;
          }
        }

        final lockedFuture = capsules
            .where((c) => !c.isUnlockedForToday())
            .toList()
          ..sort((a, b) => a.daysRemaining().compareTo(b.daysRemaining()));
        final CalendarCapsule? nextLocked =
            lockedFuture.isNotEmpty ? lockedFuture.first : null;

        return ValueListenableBuilder<bool>(
          valueListenable: RevenueCatService.instance.isPremiumNotifier,
          builder: (context, isPremium, _) {
            final bool isUrgentOpen = unlockedSurprise != null;
            final bool hasCountdown = !isUrgentOpen && nextLocked != null;

            String titleText;
            String badgeText;
            String subtitleText;
            String ctaLabel;

            if (isUrgentOpen) {
              titleText = 'Sürpriz Kapsül Açıldı';
              badgeText = 'BUGÜN';
              subtitleText =
                  '${unlockedSurprise.senderName} bugünün şafağına sürpriz bıraktı';
              ctaLabel = 'Aç';
            } else if (hasCountdown) {
              final int daysLeft = nextLocked.daysRemaining();
              titleText = 'Zaman Kapsülü';
              badgeText = '$daysLeft GÜN KALDI';
              subtitleText = 'Mühürlü sürpriz o sabah açılacak • Yeni ekle';
              ctaLabel = 'Mühürle';
            } else if (isPaired) {
              titleText = 'Zaman Kapsülü';
              badgeText = 'SES • FOTO • NOT';
              subtitleText = 'İleri bir şafağa o gün açılacak sürpriz bırak';
              ctaLabel = 'Mühürle';
            } else if (userRole == 'yakin') {
              titleText = 'Zaman Kapsülü';
              badgeText = 'SÜRPRİZ';
              subtitleText = 'Askerinin özel şafağına kilitli ses & not mühürle';
              ctaLabel = 'Eşleş';
            } else {
              titleText = 'Zaman Kapsülü';
              badgeText = isPremium ? 'AKTİF' : 'PRO';
              subtitleText =
                  'Sevdiklerin ileri şafağına kilitli ses & mektup bıraksın';
              ctaLabel = isPremium ? 'Davet' : 'İncele';
            }

            final Color accentPrimary = isUrgentOpen
                ? const Color(0xFFF59E0B)
                : const Color(0xFFE11D48);
            final Color accentSecondary = isUrgentOpen
                ? const Color(0xFFD97706)
                : const Color(0xFF7C3AED);

            void runFastAction(BuildContext btnCtx) {
              if (isUrgentOpen) {
                HapticFeedback.heavyImpact();
                showDialog(
                  context: context,
                  builder: (ctx) => CalendarCapsuleViewDialog(
                    capsule: unlockedSurprise!,
                    currentUserRole: userRole,
                    currentUserId: currentUserId,
                    onDeleted: () {
                      if (mounted) setState(() {});
                    },
                  ),
                );
                return;
              }

              if (isPaired || (userRole == 'asker' && hasCountdown)) {
                _pickDateAndOpenCapsuleCreator(
                  effectiveCode: effectiveCode,
                  userRole: userRole,
                  senderDisplayName: senderDisplayName,
                  senderRelationship: senderRelationship,
                  currentUserId: currentUserId,
                );
                return;
              }

              if (userRole == 'yakin') {
                _showHomePairingDialog(data['relationship']);
                return;
              }

              if (isPremium && trackingCode.isNotEmpty) {
                HapticFeedback.lightImpact();
                final inviteText =
                    '💌 Selam! Şafak Sayar uygulamasında şafak takvimime o gün gelene kadar kilitli kalacak sürpriz ses kaydı, fotoğraf ve mektup (Zaman Kapsülü) bırakabilirsin!\n\nTakip Kodum: $trackingCode\n\nUygulamayı indirip "Asker Yakınıyım" seçeneğinden bu kodla bağlanman yeterli! 🇹🇷';
                final box = btnCtx.findRenderObject() as RenderBox?;
                final Rect origin =
                    (box != null && box.hasSize && box.size.width > 0)
                        ? (box.localToGlobal(Offset.zero) & box.size)
                        : const Rect.fromLTWH(100, 100, 120, 48);
                Share.share(inviteText, sharePositionOrigin: origin);
              } else {
                _showTimeCapsuleShowcaseSheet(
                  isDark: isDark,
                  isPaired: isPaired,
                  isPremium: isPremium,
                  userRole: userRole,
                  trackingCode: trackingCode,
                  effectiveCode: effectiveCode,
                  senderDisplayName: senderDisplayName,
                  senderRelationship: senderRelationship,
                  currentUserId: currentUserId,
                  relationship: data['relationship'],
                  capsules: capsules,
                );
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: _getCardColor(),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B),
                          const Color(0xFF0F172A),
                        ]
                      : [
                          Colors.white,
                          isUrgentOpen
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFFFF8FA),
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isUrgentOpen
                      ? const Color(0xFFF59E0B)
                          .withValues(alpha: isDark ? 0.50 : 0.40)
                      : (isDark
                          ? const Color(0xFFF472B6).withValues(alpha: 0.28)
                          : const Color(0xFFFCE7F3)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (isUrgentOpen) {
                      HapticFeedback.heavyImpact();
                      showDialog(
                        context: context,
                        builder: (ctx) => CalendarCapsuleViewDialog(
                          capsule: unlockedSurprise!,
                          currentUserRole: userRole,
                          currentUserId: currentUserId,
                          onDeleted: () {
                            if (mounted) setState(() {});
                          },
                        ),
                      );
                    } else {
                      _showTimeCapsuleShowcaseSheet(
                        isDark: isDark,
                        isPaired: isPaired,
                        isPremium: isPremium,
                        userRole: userRole,
                        trackingCode: trackingCode,
                        effectiveCode: effectiveCode,
                        senderDisplayName: senderDisplayName,
                        senderRelationship: senderRelationship,
                        currentUserId: currentUserId,
                        relationship: data['relationship'],
                        capsules: capsules,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // 1. Sleek 36x36 Jewel Squircle Emblem
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentPrimary, accentSecondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: accentPrimary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isUrgentOpen
                                ? Icons.card_giftcard_rounded
                                : Icons.lock_clock_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 11),

                        // 2. Crisp 2-Line Compact Hierarchy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      titleText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _getTextColor(),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentPrimary.withValues(
                                        alpha: isDark ? 0.18 : 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                        color: isUrgentOpen
                                            ? (isDark
                                                ? const Color(0xFFFBBF24)
                                                : const Color(0xFFB45309))
                                            : (isDark
                                                ? const Color(0xFFF472B6)
                                                : const Color(0xFFBE185D)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getSubtitleColor(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 3. Compact Right Pill CTA
                        Builder(
                          builder: (btnCtx) {
                            return GestureDetector(
                              onTap: () => runFastAction(btnCtx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isUrgentOpen
                                      ? const Color(0xFFF59E0B)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.09)
                                          : const Color(0xFFFDF2F8)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isUrgentOpen
                                        ? const Color(0xFFF59E0B)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.14)
                                            : const Color(0xFFFBCFE8)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ctaLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isUrgentOpen
                                            ? const Color(0xFF1F1600)
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFFBE185D)),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: isUrgentOpen
                                          ? const Color(0xFF1F1600)
                                          : (isDark
                                              ? Colors.white70
                                              : const Color(0xFFBE185D)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTimeCapsuleShowcaseSheet({
    required bool isDark,
    required bool isPaired,
    required bool isPremium,
    required String userRole,
    required String trackingCode,
    required String effectiveCode,
    required String senderDisplayName,
    required String senderRelationship,
    required String currentUserId,
    required String? relationship,
    required List<CalendarCapsule> capsules,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final Color sheetBg =
            isDark ? const Color(0xFF0F172A) : Colors.white;
        final Color titleColor =
            isDark ? Colors.white : const Color(0xFF0F172A);
        final Color subColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final Color surfaceTile =
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetCtx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE11D48), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sürpriz Zaman Kapsülü',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Seçilen şafak sabahı gelene kadar kilitli kalır',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (capsules.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${capsules.length} Kapsül',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 3 Clean Media Feature Tiles
              Row(
                children: [
                  _buildSheetMediaTile(
                    icon: Icons.mic_rounded,
                    title: '60sn Ses',
                    sub: 'Sesli mesaj',
                    surfaceColor: surfaceTile,
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildSheetMediaTile(
                    icon: Icons.photo_camera_rounded,
                    title: 'Fotoğraf',
                    sub: 'Özel anı karesi',
                    surfaceColor: surfaceTile,
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildSheetMediaTile(
                    icon: Icons.mail_rounded,
                    title: 'Mektup',
                    sub: 'Duygusal not',
                    surfaceColor: surfaceTile,
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceTile,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  'Doğum günü, Plaka 81, yıl dönümü veya terhis sabahı gibi özel bir şafak gününü seçip sürprizinizi mühürleyin. Kapsül o gün saat 00:00 olana dek takvimde kilitli görünür ve erken açılamaz.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: subColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              if (!isPaired) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    LiveShareSimulationPage.show(context, initialTab: 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(
                        alpha: isDark ? 0.14 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFFE11D48),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nasıl çalıştığını merak ediyor musun? Canlı simülasyonla dene!',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFE11D48),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 4),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        _scrollToCalendarSection();
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text(
                        'Takvimde Gör',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: titleColor,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: RevenueCatService.instance.isPremiumNotifier,
                      builder: (context, liveIsPremium, _) {
                        return Builder(
                          builder: (shareBtnCtx) {
                            return ElevatedButton.icon(
                              onPressed: () {
                                if (isPaired) {
                                  Navigator.of(sheetCtx).pop();
                                  _pickDateAndOpenCapsuleCreator(
                                    effectiveCode: effectiveCode,
                                    userRole: userRole,
                                    senderDisplayName: senderDisplayName,
                                    senderRelationship: senderRelationship,
                                    currentUserId: currentUserId,
                                  );
                                } else if (userRole == 'yakin') {
                                  Navigator.of(sheetCtx).pop();
                                  _showHomePairingDialog(relationship);
                                } else if (liveIsPremium && trackingCode.isNotEmpty) {
                                  final inviteText =
                                      '💌 Selam! Şafak Sayar uygulamasında şafak takvimime o gün gelene kadar kilitli kalacak sürpriz ses kaydı, fotoğraf ve mektup (Zaman Kapsülü) bırakabilirsin!\n\nTakip Kodum: $trackingCode\n\nUygulamayı indirip "Asker Yakınıyım" seçeneğinden bu kodla bağlanman yeterli! 🇹🇷';
                                  final box =
                                      shareBtnCtx.findRenderObject() as RenderBox?;
                                  final Rect origin = (box != null &&
                                          box.hasSize &&
                                          box.size.width > 0)
                                      ? (box.localToGlobal(Offset.zero) & box.size)
                                      : const Rect.fromLTWH(100, 100, 120, 48);
                                  Navigator.of(sheetCtx).pop();
                                  Share.share(
                                    inviteText,
                                    sharePositionOrigin: origin,
                                  );
                                } else {
                                  Navigator.of(sheetCtx).pop();
                                  PremiumPaywallPage.show(
                                    context,
                                    source: 'home_capsule_spotlight',
                                  );
                                }
                              },
                              icon: Icon(
                                isPaired
                                    ? Icons.add_alarm_rounded
                                    : (userRole == 'yakin'
                                        ? Icons.qr_code_rounded
                                        : (liveIsPremium
                                            ? Icons.ios_share_rounded
                                            : Icons.workspace_premium_rounded)),
                                size: 16,
                              ),
                              label: Text(
                                isPaired
                                    ? 'Tarih Seç & Mühürle'
                                    : (userRole == 'yakin'
                                        ? 'Kod Gir & Eşleş'
                                        : (liveIsPremium
                                            ? 'Yakınını Davet Et'
                                            : 'PRO ile Aktifleştir')),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetMediaTile({
    required IconData icon,
    required String title,
    required String sub,
    required Color surfaceColor,
    required Color titleColor,
    required Color subColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: const Color(0xFFE11D48)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCalendarCard(Map<String, String?> data) {
    final bool isDark = !_isDefaultTheme;
    final bool isPaired = data['isPaired'] == 'true';
    final String userRole = data['userRole'] ?? 'asker';
    final String trackingCode = (data['trackingCode'] ?? '').trim();
    final String pairedCode = (data['pairedCode'] ?? '').trim();
    final String effectiveCode = userRole == 'yakin' ? pairedCode : trackingCode;
    final String soldierFullName = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
    final String followerName = (data['followerName'] ?? '').trim();
    final String relationship = (data['relationship'] ?? '').trim();
    final String relLabel = SoldierMatchService.getRelationshipLabel(relationship);
    final String senderDisplayName = userRole == 'yakin'
        ? (followerName.isNotEmpty ? '$relLabel $followerName' : relLabel)
        : (soldierFullName.isNotEmpty ? soldierFullName : 'Asker');
    final String senderRelationship = userRole == 'yakin' ? relLabel : 'Asker';
    final String currentUserId = data['userId'] ?? (userRole == 'asker' ? 'asker_user' : 'yakin_user');

    final DateTime? sulusDt = (sulusTarihi != null && sulusTarihi!.isNotEmpty)
        ? DateTime.tryParse(sulusTarihi!)
        : null;
    final DateTime? terhisDt = (terhisTarihi != null && terhisTarihi!.isNotEmpty)
        ? DateTime.tryParse(terhisTarihi!)
        : null;
    final DateTime? plaka81Dt = terhisDt?.subtract(const Duration(days: 81));

    final DateTime firstDay = sulusDt ?? DateTime.now().subtract(const Duration(days: 365));
    final DateTime rawLastDay = terhisDt ?? DateTime.now().add(const Duration(days: 365));
    final DateTime lastDay = rawLastDay.isAfter(firstDay)
        ? rawLastDay
        : firstDay.add(const Duration(days: 180));
    final DateTime effectiveFocused = _clampCalendarFocus(_focusedDay, firstDay, lastDay);

    final DateTime now = DateTime.now();
    final bool isViewingCurrentMonth =
        effectiveFocused.year == now.year && effectiveFocused.month == now.month;

    final bool canGoPrev = DateTime(effectiveFocused.year, effectiveFocused.month, 1)
        .isAfter(DateTime(firstDay.year, firstDay.month, 1));
    final bool canGoNext = DateTime(effectiveFocused.year, effectiveFocused.month, 1)
        .isBefore(DateTime(lastDay.year, lastDay.month, 1));

    return StreamBuilder<List<CalendarCapsule>>(
      stream: effectiveCode.isNotEmpty
          ? CalendarCapsuleService.instance.streamCapsules(effectiveCode)
          : Stream.value([]),
      builder: (context, capsuleSnapshot) {
        final capsules = capsuleSnapshot.data ?? [];
        final Map<String, List<CalendarCapsule>> capsuleMap = {};
        for (final c in capsules) {
          capsuleMap.putIfAbsent(c.dateKey, () => []).add(c);

          if (c.senderRole != userRole) {
            _knownCapsuleIds.add(c.id);

            // If unopened, schedule target date unlock notification at 09:00 AM
            if (!c.isOpened) {
              NotificationService().scheduleCapsuleUnlockNotification(
                capsuleId: c.id,
                senderName: c.senderName,
                dateKey: c.dateKey,
              );
            }
          }
        }

        if (!_initialCapsulesLoaded && capsuleSnapshot.hasData) {
          _initialCapsulesLoaded = true;
        }

        return Container(
          decoration: BoxDecoration(
            color: _getCardColor(),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E293B).withValues(alpha: 0.90),
                      const Color(0xFF0F172A).withValues(alpha: 0.94),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFFE2E8F0),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                // Subtle Decorative Ambient Glow
                Positioned(
                  top: -35,
                  right: -25,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isPaired
                              ? Colors.pinkAccent
                              : const Color(0xFF10B981))
                          .withValues(alpha: isDark ? 0.12 : 0.07),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: ValueListenableBuilder<Map<DateTime, bool>>(
                    valueListenable: _selectedDaysNotifier,
                    builder: (context, selectedDays, _) {
                      // Compute monthly completion metrics for effectiveFocused month
                      final int daysInMonth =
                          DateUtils.getDaysInMonth(effectiveFocused.year, effectiveFocused.month);
                      int activeMonthTotal = 0;
                      int activeMonthDone = 0;
                      final firstNorm = DateTime(firstDay.year, firstDay.month, firstDay.day);
                      final lastNorm = DateTime(lastDay.year, lastDay.month, lastDay.day);

                      for (int d = 1; d <= daysInMonth; d++) {
                        final cellDt = DateTime(effectiveFocused.year, effectiveFocused.month, d);
                        if (!cellDt.isBefore(firstNorm) && !cellDt.isAfter(lastNorm)) {
                          activeMonthTotal++;
                          if (_isDayCheckedInMap(cellDt, selectedDays)) {
                            activeMonthDone++;
                          }
                        }
                      }
                      final double monthRatio = activeMonthTotal > 0
                          ? (activeMonthDone / activeMonthTotal).clamp(0.0, 1.0)
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Top Tactical Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : [const Color(0xFF0284C7), const Color(0xFF2563EB)],
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF2563EB))
                                          .withValues(alpha: 0.30),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 19,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ASKERLİK TAKVİMİ',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: _getTextColor(),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isPaired
                                          ? 'Güne dokunarak şafak işaretle veya sürpriz kapsül bırak'
                                          : 'Geçen şafakları takip et, günlere dokunarak işaretle',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getSubtitleColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isPaired) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.pinkAccent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: Colors.pinkAccent.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.card_giftcard_rounded,
                                        size: 12,
                                        color: Colors.pinkAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        capsules.isNotEmpty
                                            ? '${capsules.length} Kapsül'
                                            : 'Kapsül Aktif',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.pinkAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 2. Milestone Quick-Jump Pills (Sülüs • Bugün • Terhis)
                          Row(
                            children: [
                              Expanded(
                                child: _buildMilestoneJumpPill(
                                  icon: Icons.flight_takeoff_rounded,
                                  label: 'SÜLÜS',
                                  value: _shortDayMonth(sulusDt),
                                  accent: const Color(0xFF6366F1),
                                  isDark: isDark,
                                  onTap: sulusDt == null
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _focusedDay = _clampCalendarFocus(
                                              sulusDt,
                                              firstDay,
                                              lastDay,
                                            );
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMilestoneJumpPill(
                                  icon: Icons.my_location_rounded,
                                  label: 'BUGÜN',
                                  value: isViewingCurrentMonth
                                      ? 'Şafak ${remainingDuration.inDays}'
                                      : 'Bugüne Dön',
                                  accent: const Color(0xFF0EA5E9),
                                  isHighlighted: !isViewingCurrentMonth,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _focusedDay = _clampCalendarFocus(
                                        DateTime.now(),
                                        firstDay,
                                        lastDay,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMilestoneJumpPill(
                                  icon: Icons.workspace_premium_rounded,
                                  label: 'TERHİS',
                                  value: _shortDayMonth(terhisDt),
                                  accent: const Color(0xFFF59E0B),
                                  isDark: isDark,
                                  onTap: terhisDt == null
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _focusedDay = _clampCalendarFocus(
                                              terhisDt,
                                              firstDay,
                                              lastDay,
                                            );
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 3. Custom Month Cockpit & Monthly Progress Bar
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildMonthNavArrow(
                                      icon: Icons.chevron_left_rounded,
                                      enabled: canGoPrev,
                                      isDark: isDark,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        final prev = DateTime(
                                          effectiveFocused.year,
                                          effectiveFocused.month - 1,
                                          15,
                                        );
                                        setState(() {
                                          _focusedDay =
                                              _clampCalendarFocus(prev, firstDay, lastDay);
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            _turkishMonthYearLabel(effectiveFocused),
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: _getTextColor(),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            activeMonthTotal > 0
                                                ? 'Bu ay: $activeMonthDone / $activeMonthTotal gün tamamlandı (%${(monthRatio * 100).round()})'
                                                : 'Takvim görünümü',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: _getSubtitleColor(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildMonthNavArrow(
                                      icon: Icons.chevron_right_rounded,
                                      enabled: canGoNext,
                                      isDark: isDark,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        final next = DateTime(
                                          effectiveFocused.year,
                                          effectiveFocused.month + 1,
                                          15,
                                        );
                                        setState(() {
                                          _focusedDay =
                                              _clampCalendarFocus(next, firstDay, lastDay);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (activeMonthTotal > 0) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: monthRatio,
                                      minHeight: 5.5,
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : const Color(0xFFCBD5E1).withValues(alpha: 0.55),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 4. Calendar Grid
                          RepaintBoundary(
                            child: TableCalendar(
                              locale: 'tr_TR',
                              headerVisible: false,
                              sixWeekMonthsEnforced: false,
                              rowHeight: 46,
                              daysOfWeekHeight: 24,
                              availableGestures: AvailableGestures.horizontalSwipe,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'Month',
                              },
                              onPageChanged: (newFocusedDay) {
                                setState(() {
                                  _focusedDay = _clampCalendarFocus(
                                    newFocusedDay,
                                    firstDay,
                                    lastDay,
                                  );
                                });
                              },
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekendStyle: TextStyle(
                                  fontSize: 10.5,
                                  color: _isDefaultTheme
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w800,
                                ),
                                weekdayStyle: TextStyle(
                                  fontSize: 10.5,
                                  color: _getSubtitleColor(),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              selectedDayPredicate: (day) =>
                                  _isDayCheckedInMap(day, selectedDays),
                              onDaySelected: (selectedDay, _) {
                                HapticFeedback.selectionClick();
                                final today = DateTime.now();
                                final todayNormalized =
                                    DateTime(today.year, today.month, today.day);
                                final selectedDayNormalized = DateTime(
                                  selectedDay.year,
                                  selectedDay.month,
                                  selectedDay.day,
                                );
                                final dateKey =
                                    CalendarCapsuleService.formatDateKey(selectedDay);
                                final dayCapsules = capsuleMap[dateKey] ?? [];

                                // 1. If a capsule already exists on this day: Open Viewer Dialog!
                                if (dayCapsules.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => CalendarCapsuleViewDialog(
                                      capsule: dayCapsules.first,
                                      currentUserRole: userRole,
                                      currentUserId: currentUserId,
                                      onDeleted: () {
                                        setState(() {});
                                      },
                                    ),
                                  );
                                  return;
                                }

                                // 2. If NO capsule exists:
                                // Case A: Future Day
                                if (selectedDayNormalized.isAfter(todayNormalized)) {
                                  if (!isPaired) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'İleri tarihe sürpriz zaman kapsülü bırakmak için eşleşmiş olmanız gerekmektedir.',
                                        ),
                                        backgroundColor: Colors.amber.shade800,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  // Open Create Capsule Sheet for this future day!
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => CalendarCapsuleCreateSheet(
                                      targetDate: selectedDay,
                                      trackingCode: effectiveCode,
                                      userRole: userRole,
                                      userName: senderDisplayName,
                                      senderRelationship: senderRelationship,
                                      userId: currentUserId,
                                      onSaved: () {
                                        setState(() {});
                                      },
                                    ),
                                  );
                                  return;
                                }

                                // Case B: Today or Past Day
                                _handlePastOrTodaySelection(
                                  selectedDay: selectedDay,
                                  isPaired: isPaired,
                                  userRole: userRole,
                                  effectiveCode: effectiveCode,
                                  userName: senderDisplayName,
                                  senderRelationship: senderRelationship,
                                  currentUserId: currentUserId,
                                  selectedDays: selectedDays,
                                );
                              },
                              firstDay: firstDay,
                              focusedDay: effectiveFocused,
                              lastDay: lastDay,
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, date, _) =>
                                    _buildDayCellWithCapsule(
                                  context: context,
                                  date: date,
                                  isSelected: false,
                                  isOutside: false,
                                  capsuleMap: capsuleMap,
                                  sulusDt: sulusDt,
                                  terhisDt: terhisDt,
                                  plaka81Dt: plaka81Dt,
                                ),
                                selectedBuilder: (context, date, _) =>
                                    _buildDayCellWithCapsule(
                                  context: context,
                                  date: date,
                                  isSelected: true,
                                  isOutside: false,
                                  capsuleMap: capsuleMap,
                                  sulusDt: sulusDt,
                                  terhisDt: terhisDt,
                                  plaka81Dt: plaka81Dt,
                                ),
                                todayBuilder: (context, date, _) =>
                                    _buildDayCellWithCapsule(
                                  context: context,
                                  date: date,
                                  isSelected: _isDayCheckedInMap(date, selectedDays),
                                  isOutside: false,
                                  capsuleMap: capsuleMap,
                                  sulusDt: sulusDt,
                                  terhisDt: terhisDt,
                                  plaka81Dt: plaka81Dt,
                                ),
                                outsideBuilder: (context, date, _) =>
                                    _buildDayCellWithCapsule(
                                  context: context,
                                  date: date,
                                  isSelected: false,
                                  isOutside: true,
                                  capsuleMap: capsuleMap,
                                  sulusDt: sulusDt,
                                  terhisDt: terhisDt,
                                  plaka81Dt: plaka81Dt,
                                ),
                                disabledBuilder: (context, date, _) =>
                                    _buildDayCellWithCapsule(
                                  context: context,
                                  date: date,
                                  isSelected: false,
                                  isOutside: true,
                                  capsuleMap: capsuleMap,
                                  sulusDt: sulusDt,
                                  terhisDt: terhisDt,
                                  plaka81Dt: plaka81Dt,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 5. Legend & Plate Schedule Quick Link Footer
                          Container(
                            padding: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    children: [
                                      _buildLegendDot(
                                        color: const Color(0xFF10B981),
                                        label: 'Biten Gün',
                                      ),
                                      _buildLegendDot(
                                        color: const Color(0xFF0EA5E9),
                                        label: 'Bugün',
                                      ),
                                      _buildLegendDot(
                                        color: const Color(0xFFF59E0B),
                                        label: 'Terhis',
                                      ),
                                      if (isPaired || capsules.isNotEmpty)
                                        _buildLegendDot(
                                          color: Colors.pinkAccent,
                                          label: 'Kapsül',
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        settings: const RouteSettings(
                                          name: 'SafakCizelgesiPage',
                                        ),
                                        builder: (context) => SafakCizelgesiPage(
                                          backgroundImage: widget.backgroundImage,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.14)
                                            : const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.grid_on_rounded,
                                          size: 12,
                                          color: isDark
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Çizelge',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 6. Compact Time Capsule Explainer Strip Below Calendar
                          _buildCalendarCapsuleExplainerBox(
                            isDark: isDark,
                            isPaired: isPaired,
                            userRole: userRole,
                            trackingCode: trackingCode,
                            effectiveCode: effectiveCode,
                            senderDisplayName: senderDisplayName,
                            senderRelationship: senderRelationship,
                            currentUserId: currentUserId,
                            relationship: data['relationship'],
                            capsules: capsules,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarCapsuleExplainerBox({
    required bool isDark,
    required bool isPaired,
    required String userRole,
    required String trackingCode,
    required String effectiveCode,
    required String senderDisplayName,
    required String senderRelationship,
    required String currentUserId,
    required String? relationship,
    required List<CalendarCapsule> capsules,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        final int capsuleCount = capsules.length;
        return Material(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (isPaired) {
                _pickDateAndOpenCapsuleCreator(
                  effectiveCode: effectiveCode,
                  userRole: userRole,
                  senderDisplayName: senderDisplayName,
                  senderRelationship: senderRelationship,
                  currentUserId: currentUserId,
                );
              } else {
                _showTimeCapsuleShowcaseSheet(
                  isDark: isDark,
                  isPaired: isPaired,
                  isPremium: isPremium,
                  userRole: userRole,
                  trackingCode: trackingCode,
                  effectiveCode: effectiveCode,
                  senderDisplayName: senderDisplayName,
                  senderRelationship: senderRelationship,
                  currentUserId: currentUserId,
                  relationship: relationship,
                  capsules: capsules,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48)
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.lock_clock_rounded,
                      size: 15,
                      color: isDark
                          ? const Color(0xFFF472B6)
                          : const Color(0xFFE11D48),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Zaman Kapsülü',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _getTextColor(),
                              ),
                            ),
                            if (capsuleCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• $capsuleCount mühürlü',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFF472B6)
                                      : const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          'İleri bir şafak gününe dokunarak o sabah açılacak ses, fotoğraf ve not bırakın.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.3,
                            color: _getSubtitleColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPaired ? 'Mühürle' : 'Detay',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFF472B6)
                              : const Color(0xFFE11D48),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: isDark
                            ? const Color(0xFFF472B6)
                            : const Color(0xFFE11D48),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestoneJumpPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required bool isDark,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: isHighlighted
          ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
          : (isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC)),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? accent.withValues(alpha: 0.55)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: accent,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavArrow({
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: enabled ? 0.09 : 0.03)
          : (enabled ? Colors.white : Colors.white.withValues(alpha: 0.5)),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? _getTextColor()
                : _getSubtitleColor().withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _getSubtitleColor(),
          ),
        ),
      ],
    );
  }

  // Custom Squircle Day Cell with Readable Dates, Milestones & Time Capsule Overlay
  Widget _buildDayCellWithCapsule({
    required BuildContext context,
    required DateTime date,
    required bool isSelected,
    required bool isOutside,
    required Map<String, List<CalendarCapsule>> capsuleMap,
    DateTime? sulusDt,
    DateTime? terhisDt,
    DateTime? plaka81Dt,
  }) {
    final bool isDark = !_isDefaultTheme;
    final DateTime now = DateTime.now();
    final bool isToday = !isOutside && _isSameCalendarDay(date, now);
    final bool isTerhisDay =
        !isOutside && terhisDt != null && _isSameCalendarDay(date, terhisDt);
    final bool isSulusDay =
        !isOutside && sulusDt != null && _isSameCalendarDay(date, sulusDt);
    final bool isPlakaStart =
        !isOutside && plaka81Dt != null && _isSameCalendarDay(date, plaka81Dt);

    final dateKey = CalendarCapsuleService.formatDateKey(date);
    final dayCapsules = capsuleMap[dateKey] ?? [];
    final bool hasCapsule = dayCapsules.isNotEmpty;
    final bool hasLockedCapsule =
        hasCapsule && dayCapsules.any((c) => !c.isUnlockedForToday());

    // Determine Cell Visual Styling
    Gradient? cellGradient;
    Color? cellColor;
    Border? cellBorder;
    List<BoxShadow>? cellShadow;
    Color textColor;

    if (isOutside) {
      cellColor = Colors.transparent;
      textColor = _getSubtitleColor().withValues(alpha: 0.28);
    } else if (isTerhisDay) {
      cellGradient = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cellBorder = Border.all(color: const Color(0xFFFDE68A), width: 1.4);
      cellShadow = [
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.38),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
      textColor = Colors.white;
    } else if (isToday) {
      cellGradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cellBorder = Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.4);
      cellShadow = [
        BoxShadow(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.38),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
      textColor = Colors.white;
    } else if (isSelected) {
      cellGradient = LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF10B981).withValues(alpha: 0.30),
                const Color(0xFF059669).withValues(alpha: 0.22),
              ]
            : [
                const Color(0xFFD1FAE5),
                const Color(0xFFA7F3D0),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      cellBorder = Border.all(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.55 : 0.65),
        width: 1.15,
      );
      textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
    } else {
      cellColor = isDark
          ? Colors.white.withValues(alpha: 0.035)
          : const Color(0xFFF8FAFC);
      cellBorder = hasCapsule
          ? Border.all(
              color: hasLockedCapsule
                  ? Colors.amber.withValues(alpha: 0.7)
                  : Colors.pinkAccent.withValues(alpha: 0.7),
              width: 1.2,
            )
          : (isSulusDay
              ? Border.all(color: const Color(0xFF6366F1), width: 1.3)
              : (isPlakaStart
                  ? Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.65),
                      width: 1.2,
                    )
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.75),
                    )));
      textColor = date.weekday >= 6
          ? (_isDefaultTheme ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5))
          : _getTextColor();
    }

    return Padding(
      padding: const EdgeInsets.all(2.8),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Squircle Day Surface
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: cellGradient == null ? cellColor : null,
              gradient: cellGradient,
              borderRadius: BorderRadius.circular(11.5),
              border: cellBorder,
              boxShadow: cellShadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Day Number (Always Crisp & Readable!)
                Positioned(
                  top: (isTerhisDay || isToday || isPlakaStart) ? 5 : null,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: (isToday || isTerhisDay || isSelected)
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),

                // Mini Status Micro-Indicator at Bottom
                if (isTerhisDay)
                  const Positioned(
                    bottom: 3,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 9,
                      color: Colors.white,
                    ),
                  )
                else if (isToday)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 12,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                else if (isPlakaStart && !isSelected)
                  const Positioned(
                    bottom: 2.5,
                    child: Text(
                      '81',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),

                // Corner Checkmark Seal for Completed Days
                if (isSelected && !isToday && !isTerhisDay)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 10.5,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                    ),
                  ),
              ],
            ),
          ),

          // Glowing Capsule Badge on Top-Right Corner
          if (hasCapsule)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: hasLockedCapsule
                        ? [const Color(0xFFF59E0B), const Color(0xFFDC2626)]
                        : [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (hasLockedCapsule ? Colors.amber : Colors.pinkAccent)
                          .withValues(alpha: 0.65),
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  hasLockedCapsule
                      ? Icons.lock_rounded
                      : Icons.card_giftcard_rounded,
                  size: 9.0,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Handle today or past day selection: allows toggling check or leaving a memory capsule
  void _handlePastOrTodaySelection({
    required DateTime selectedDay,
    required bool isPaired,
    required String userRole,
    required String effectiveCode,
    required String userName,
    String? senderRelationship,
    required String currentUserId,
    required Map<DateTime, bool> selectedDays,
  }) {
    if (!isPaired) {
      _selectedDaysNotifier.value = {
        ...selectedDays,
        selectedDay: !(selectedDays[selectedDay] ?? false),
      };
      _focusedDay = selectedDay;
      saveSelectedDays(_selectedDaysNotifier.value);
      return;
    }

    final formatted = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(selectedDay);
    final isChecked = (selectedDays[selectedDay] ?? false) || _isElapsedDay(selectedDay);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = !_isDefaultTheme;
        return Material(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                formatted,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isChecked ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  isChecked ? 'Günün İşaretini Kaldır' : 'Günü İşaretle (Şafak Düş)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Askerlik takviminde günü tamamlandı olarak işaretler.',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectedDaysNotifier.value = {
                    ...selectedDays,
                    selectedDay: !(selectedDays[selectedDay] ?? false),
                  };
                  _focusedDay = selectedDay;
                  saveSelectedDays(_selectedDaysNotifier.value);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.pinkAccent,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Bu Güne Özel Anı / Mektup / Ses Bırak 💌',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Bu tarihe özel not, ses kaydı veya fotoğraf ekle.',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (sheetCtx) => CalendarCapsuleCreateSheet(
                      targetDate: selectedDay,
                      trackingCode: effectiveCode,
                      userRole: userRole,
                      userName: userName,
                      senderRelationship: senderRelationship,
                      userId: currentUserId,
                      onSaved: () {
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget buildShortInfoContainer() {
    final bool isDark = !_isDefaultTheme;
    final Color arrowColor = _isDefaultTheme ? Colors.orange.shade700 : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: _isDefaultTheme ? Colors.orange : Colors.amber),
              const SizedBox(width: 6),
              Text(
                'KISA BİLGİLER',
                style: TextStyle(
                  color: _isDefaultTheme ? Colors.orange.shade800 : Colors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: _getBorderColor(), thickness: 0.8),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _prevInfo,
                icon: Icon(Icons.arrow_back_ios_rounded, color: arrowColor, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text(
                        displayedInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getTextColor(),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentInfoIndex + 1} / ${infoList.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getSubtitleColor().withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextInfo,
                icon: Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGununSozu() {
    final bool isDark = !_isDefaultTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_quote_rounded, size: 16, color: _isDefaultTheme ? Colors.red : Colors.redAccent),
              const SizedBox(width: 6),
              Text(
                'GÜNÜN SÖZÜ',
                style: TextStyle(
                  color: _isDefaultTheme ? Colors.red.shade700 : Colors.redAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: _getBorderColor(), thickness: 0.8),
          const SizedBox(height: 10),
          Text(
            displayGununSozu,
            style: TextStyle(
              fontSize: 14.5,
              color: _getTextColor(),
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> saveSelectedDays(Map<DateTime, bool> selectedDays) async {
    final prefs = await SharedPreferences.getInstance();
    final serializedDays = selectedDays
        .map((key, value) => MapEntry(key.toIso8601String(), value));
    prefs.setString('selectedDays', jsonEncode(serializedDays));
  }

  Future<Map<DateTime, bool>> loadSelectedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDays = prefs.getString('selectedDays');
    if (savedDays == null) {
      return {};
    }
    final Map<String, bool> serializedDays =
        Map<String, bool>.from(jsonDecode(savedDays));
    return serializedDays
        .map((key, value) => MapEntry(DateTime.parse(key), value));
  }

  bool _isElapsedDay(DateTime day) {
    if (sulusTarihi == null || sulusTarihi!.isEmpty) return false;
    try {
      final start = DateTime.parse(sulusTarihi!);
      final dayNormalized = DateTime(day.year, day.month, day.day);
      final startNormalized = DateTime(start.year, start.month, start.day);
      final now = DateTime.now();
      final todayNormalized = DateTime(now.year, now.month, now.day);

      return (dayNormalized.isAtSameMomentAs(startNormalized) || dayNormalized.isAfter(startNormalized)) &&
          dayNormalized.isBefore(todayNormalized);
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 8. TSK ASKERİ RÜTBELER (KOMUTA HİYERARŞİSİ)
  // ==========================================
  Widget buildInfoContainer(String? userRutbe, String? userKuvvet) {
    final bool isDark = !_isDefaultTheme;

    // Otomatik olarak kullanıcının kuvvet komutanlığına göre açılış sekmesini ayarla
    if (!_hasInitializedForceIndex && userKuvvet != null && userKuvvet.isNotEmpty) {
      final String kuvvetLower = userKuvvet.toLowerCase();
      if (kuvvetLower.contains('hava')) {
        _selectedRankForceIndex = 1;
      } else if (kuvetLowerIsDeniz(kuvvetLower)) {
        _selectedRankForceIndex = 2;
      } else if (kuvvetLower.contains('jandarma')) {
        _selectedRankForceIndex = 3;
      } else {
        _selectedRankForceIndex = 0;
      }
      _hasInitializedForceIndex = true;
    }

    final List<Map<String, dynamic>> forces = [
      {
        'name': 'KARA',
        'fullName': 'TÜRK KARA KUVVETLERİ',
        'image': 'assets/images/Kara.webp',
        'accent': const Color(0xFF10B981),
        'ranks': [
          {'name': 'MAREŞAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'GENELKURMAY BŞK.', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'ORGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'KORGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TÜMGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TUĞGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'ALBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YARBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'BİNBAŞI', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YÜZBAŞI', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ÜSTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'TEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTSB. KD. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'UZMAN ÇAVUŞ', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'UZMAN ONBAŞI', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'ONBAŞI', 'cat': 'ERBAŞ', 'color': const Color(0xFF94A3B8)},
          {'name': 'ER', 'cat': 'ER', 'color': const Color(0xFF94A3B8)},
        ],
      },
      {
        'name': 'HAVA',
        'fullName': 'TÜRK HAVA KUVVETLERİ',
        'image': 'assets/images/Hava.webp',
        'accent': const Color(0xFF0284C7),
        'ranks': [
          {'name': 'ORGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'KORGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TÜMGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TUĞGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'ALBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YARBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'BİNBAŞI', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YÜZBAŞI', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ÜSTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'TEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTSB. KD. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'UZMAN ÇAVUŞ', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'UZMAN ONBAŞI', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'ONBAŞI', 'cat': 'ERBAŞ', 'color': const Color(0xFF94A3B8)},
          {'name': 'ER', 'cat': 'ER', 'color': const Color(0xFF94A3B8)},
        ],
      },
      {
        'name': 'DENİZ',
        'fullName': 'TÜRK DENİZ KUVVETLERİ',
        'image': 'assets/images/Deniz.webp',
        'accent': const Color(0xFF2563EB),
        'ranks': [
          {'name': 'BÜYÜKAMİRAL', 'cat': 'AMİRAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'ORAMİRAL', 'cat': 'AMİRAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'KORAMİRAL', 'cat': 'AMİRAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TÜMAMİRAL', 'cat': 'AMİRAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TUĞAMİRAL', 'cat': 'AMİRAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'ALBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YARBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'BİNBAŞI', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YÜZBAŞI', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ÜSTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'TEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTSB. KD. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'UZMAN ÇAVUŞ', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'UZMAN ONBAŞI', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'ONBAŞI', 'cat': 'ERBAŞ', 'color': const Color(0xFF94A3B8)},
          {'name': 'ER', 'cat': 'ER', 'color': const Color(0xFF94A3B8)},
        ],
      },
      {
        'name': 'JANDARMA',
        'fullName': 'JANDARMA GENEL KOMUTANLIĞI',
        'image': 'assets/images/Jandarma.webp',
        'accent': const Color(0xFF0D9488),
        'ranks': [
          {'name': 'ORGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'KORGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TÜMGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'TUĞGENERAL', 'cat': 'GENERAL', 'color': const Color(0xFFF59E0B)},
          {'name': 'ALBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YARBAY', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'BİNBAŞI', 'cat': 'ÜSTSUBAY', 'color': const Color(0xFF3B82F6)},
          {'name': 'YÜZBAŞI', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ÜSTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'TEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTEĞMEN', 'cat': 'SUBAY', 'color': const Color(0xFF06B6D4)},
          {'name': 'ASTSB. KD. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. BÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÜÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. KD. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'ASTSB. ÇVŞ.', 'cat': 'ASTSUBAY', 'color': const Color(0xFF10B981)},
          {'name': 'UZM. J. VIII KAD. ÇVŞ.', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'UZMAN ÇAVUŞ', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'UZMAN ONBAŞI', 'cat': 'UZMAN', 'color': const Color(0xFFF97316)},
          {'name': 'ONBAŞI', 'cat': 'ERBAŞ', 'color': const Color(0xFF94A3B8)},
          {'name': 'ER', 'cat': 'ER', 'color': const Color(0xFF94A3B8)},
        ],
      },
    ];

    final currentForce = forces[_selectedRankForceIndex.clamp(0, forces.length - 1)];
    final List<Map<String, dynamic>> ranks = currentForce['ranks'];
    final Color forceAccent = currentForce['accent'] as Color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: 17,
                    color: isDark ? Colors.amberAccent : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TSK ASKERİ RÜTBELER",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _getSubtitleColor(),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amberAccent.withValues(alpha: 0.15)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.amberAccent.withValues(alpha: 0.3)
                        : Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  "HİYERARŞİ",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.amberAccent : Colors.orange.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tactical Force Switcher Segment (Kara, Hava, Deniz, Jandarma)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: List.generate(forces.length, (index) {
                final bool isSelected = _selectedRankForceIndex == index;
                final force = forces[index];
                final Color tabAccent = force['accent'] as Color;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRankForceIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? tabAccent.withValues(alpha: 0.22)
                                : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: isDark
                                    ? tabAccent.withValues(alpha: 0.5)
                                    : tabAccent.withValues(alpha: 0.3),
                                width: 1.2,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: tabAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            force['image'],
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            force['name'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? Colors.white : tabAccent)
                                  : _getSubtitleColor().withValues(alpha: 0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Active Command Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: forceAccent.withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: forceAccent.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  currentForce['image'],
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentForce['fullName'],
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : forceAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  "${ranks.length} RÜTBE",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: _getSubtitleColor(),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2-Column Tactical Ranks Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = (constraints.maxWidth - 8) / 2;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(ranks.length, (index) {
                  final rank = ranks[index];
                  final String rankName = rank['name'];
                  final String category = rank['cat'];
                  final Color catColor = rank['color'] as Color;

                  // Kullanıcının kendi rütbesi mi kontrol et
                  final bool isUserRank = userRutbe != null &&
                      userRutbe.trim().isNotEmpty &&
                      _isRankMatching(rankName, userRutbe);

                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: isUserRank
                          ? (isDark
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                              : Colors.amber.shade50)
                          : (isDark
                              ? Colors.black.withValues(alpha: 0.22)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUserRank
                            ? const Color(0xFFF59E0B)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.black.withValues(alpha: 0.06)),
                        width: isUserRank ? 1.5 : 1,
                      ),
                      boxShadow: isUserRank
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.3 : 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Rank Order Pill
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        // Rank Name & Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                rankName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isUserRank
                                      ? (isDark ? Colors.amberAccent : Colors.amber.shade900)
                                      : _getTextColor(),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Row(
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      color: catColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (isUserRank) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.amber.withValues(alpha: 0.25)
                                            : Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "RÜTBEN 🫡",
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 14),

          // Hierarchy Category Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryLegendDot(const Color(0xFFF59E0B), "General/Amiral"),
              const SizedBox(width: 10),
              _buildCategoryLegendDot(const Color(0xFF3B82F6), "Subay"),
              const SizedBox(width: 10),
              _buildCategoryLegendDot(const Color(0xFF10B981), "Astsubay"),
              const SizedBox(width: 10),
              _buildCategoryLegendDot(const Color(0xFFF97316), "Uzman"),
              const SizedBox(width: 10),
              _buildCategoryLegendDot(const Color(0xFF94A3B8), "Erbaş/Er"),
            ],
          ),
        ],
      ),
    );
  }

  bool kuvetLowerIsDeniz(String kuvvetLower) {
    return kuvvetLower.contains('deniz');
  }

  bool _isRankMatching(String rankName, String userRutbe) {
    final String cleanRank = rankName
        .replaceAll('.', '')
        .trim()
        .toUpperCase();
    final String cleanUser = userRutbe
        .replaceAll('.', '')
        .trim()
        .toUpperCase();

    if (cleanUser.isEmpty) return false;

    // 1. Tam birebir eşitlik (örn. "ER" == "ER", "ONBAŞI" == "ONBAŞI", "ASTEĞMEN" == "ASTEĞMEN", "TEĞMEN" == "TEĞMEN")
    if (cleanRank == cleanUser) return true;

    // 2. ER durumu: Sadece tam olarak "ER" veya "SÖZLEŞMELİ ER" ile eşleşir.
    // 'ORGENERAL', 'KORGENERAL', 'TÜMGENERAL' gibi rütbelerin içindeki 'ER' harfleriyle ASLA eşleşmemelidir!
    if (cleanUser == 'ER') {
      return cleanRank == 'ER' || cleanRank == 'SÖZLEŞMELİ ER';
    }

    // 3. ONBAŞI durumu
    if (cleanUser == 'ONBAŞI') {
      return cleanRank == 'ONBAŞI' || cleanRank == 'UZMAN ONBAŞI';
    }

    // 4. ÇAVUŞ durumu
    if (cleanUser == 'ÇAVUŞ') {
      return cleanRank == 'UZMAN ÇAVUŞ' || cleanRank.endsWith('ÇAVUŞ') || cleanRank.endsWith('ÇVŞ');
    }

    // 5. ASTSUBAY durumu
    if (cleanUser == 'ASTSUBAY') {
      return cleanRank.startsWith('ASTSB') || cleanRank.startsWith('ASTSUBAY');
    }

    // 6. ASTÇAVUŞ durumu
    if (cleanUser == 'ASTÇAVUŞ') {
      return cleanRank.contains('ASTSB') && (cleanRank.contains('ÇAVUŞ') || cleanRank.contains('ÇVŞ'));
    }

    // 7. Kelimelere ayırarak tam kelime eşleşmesi kontrolü
    final List<String> rankWords = cleanRank.split(' ');
    return rankWords.contains(cleanUser);
  }

  Widget _buildCategoryLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: _getSubtitleColor(),
          ),
        ),
      ],
    );
  }
}
