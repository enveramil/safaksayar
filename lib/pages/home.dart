import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:home_widget/home_widget.dart';

class HomeScreen extends StatefulWidget {
  final String backgroundImage;
  const HomeScreen({super.key, required this.backgroundImage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Duration remainingDuration = Duration.zero;

class _HomeScreenState extends State<HomeScreen> {
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

  String? sulusTarihi;
  String? terhisTarihi;

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
    "Mona Lisa tablosunun kaşları yoktur. O dönemde kadınların kaşlarını tamamen tıraş etmesi modaydı."
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

  AppOpenAd? openAd;

  Future<void> _loadAppOpenAd() async {
    if (AdManager.isDev) return;
    await AppOpenAd.load(
      adUnitId:
          'ca-app-pub-4655119937024112/4080945883', // AdMob'dan aldığınız ID
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          openAd = ad;
          openAd!.show();
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd yüklenemedi: $error');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadCountdown();
    _loadAppOpenAd(); // Load the app open ad when the app starts
    pickRandomInfo(); // Pick random info when the app starts
    gununSozu();
    loadSelectedDays().then((loadedDays) {
      _selectedDaysNotifier.value = loadedDays;
    });
    AdManager().loadAndShowAppOpenAd();
  }

  // Function to randomly select an info
  void pickRandomInfo() {
    final random = Random();

    // Check if infoList is not empty to prevent null value
    if (infoList.isNotEmpty) {
      setState(() {
        displayedInfo = infoList[random.nextInt(infoList.length)];
      });
    } else {
      setState(() {
        displayedInfo = 'Bilgi bulunamadı'; // Fallback if list is empty
      });
    }
  }

  void gununSozu() {
    final random = Random();

    // Check if infoList is not empty to prevent null value
    if (askeriSozler.isNotEmpty) {
      setState(() {
        displayGununSozu = askeriSozler[random.nextInt(askeriSozler.length)];
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

    if (dueDateStr != null && durationMonths! > 0) {
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
      }

      DateTime now = DateTime.now();

      setState(() {
        remainingDuration =
            endDate.isAfter(now) ? endDate.difference(now) : Duration.zero;
        elapsedDuration =
            now.isAfter(dueDate) ? now.difference(dueDate) : Duration.zero;
      });

      prefs.setInt('remainingDays', remainingDuration.inDays);
      await prefs.setString('end_date', endDate.toIso8601String());
      print('Remaining Days: ${remainingDuration.inDays}');
      updateHomeWidget();
    } else {
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
        elapsedDuration = DateTime.now()
            .difference(DateTime.parse(prefs.getString('sulus_tarihi')!));
      }
    });
  }

  @override
  void dispose() {
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
    // Total duration in seconds, adjusted for izin and ceza
    final totalDurationInSeconds = (durationMonths! * 30 * 24 * 60 * 60) +
        ((izin ?? 0) * 24 * 60 * 60)
        +
        ((ceza ?? 0) * 24 * 60 * 60) -
        ((yolIzniDisplay ?? 0) * 24 * 60 * 60);

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
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$days Gün $hours Saat $minutes Dakika";
  }

  Future<Map<String, String?>> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name');
    String? surname = prefs.getString('surname');
    String? askerlikYeri = prefs.getString('askerlik_yeri');
    String? memleket = prefs.getString('memleket');
    sulusTarihi = prefs.getString('sulus_tarihi');
    terhisTarihi = prefs.getString('end_date');
    String? kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi');
    String? rutbe = prefs.getString('rutbe');
    String? themeColor = prefs.getString('themeColor');

    return {
      'name': name,
      'surname': surname,
      'askerlikYeri': askerlikYeri,
      'memleket': memleket,
      'sulusTarihi': sulusTarihi,
      'terhisTarihi': terhisTarihi,
      'kuvvetKomutanligi': kuvvetKomutanligi,
      'rutbe': rutbe,
      'themeColor': themeColor
    };
  }

  final Map<DateTime, bool> _selectedDays = {}; // Seçilen günler
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: FutureBuilder<Map<String, String?>>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Bir hata oluştu.'));
            } else {
              final data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Header Section with Avatar, Name, Badges
                    buildHeaderSection(
                      data['name'],
                      data['surname'],
                      data['kuvvetKomutanligi'],
                      data['rutbe'],
                    ),

                    const SizedBox(height: 4),

                    // Row for Remaining and Elapsed Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              isKalanBlurred.value = !isKalanBlurred.value;
                              _saveBlurState();
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isKalanBlurred,
                              builder: (context, isBlurred, child) {
                                return buildBlurContainer(
                                  title: "KALAN SÜRE",
                                  duration: remainingDuration,
                                  isBlurred: isBlurred,
                                  isKalan: true,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              isGecenBlurred.value = !isGecenBlurred.value;
                              _saveBlurState();
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isGecenBlurred,
                              builder: (context, isBlurred, child) {
                                return buildBlurContainer(
                                  title: "GEÇEN SÜRE",
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

                    const SizedBox(height: 4),

                    // Dynamic Sliding Gradient Progress Bar
                    buildProgressBar(),

                    const SizedBox(height: 4),

                    // Consolidated User Info Card Panel
                    buildUserInfoPanel(data),

                    const SizedBox(height: 4),

                    // Calendar card
                    buildCalendarCard(),

                    const SizedBox(height: 4),

                    // Editorial cards
                    buildShortInfoContainer(),
                    buildGununSozu(),
                    buildInfoContainer(),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveBlurState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKalanBlurred', isKalanBlurred.value);
    await prefs.setBool('isGecenBlurred', isGecenBlurred.value);
  }

  Widget buildBlurContainer({
    required String title,
    required Duration duration,
    required bool isBlurred,
    required bool isKalan,
  }) {
    final String days = duration.inDays.toString();
    final String hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 12,
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
              Icon(
                isKalan ? Icons.hourglass_bottom_rounded : Icons.history_rounded,
                size: 15,
                color: _isDefaultTheme ? Colors.grey.shade700 : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getSubtitleColor(),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Container(
              height: 40,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_outlined, color: _getSubtitleColor(), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Veriler Gizlendi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getSubtitleColor(),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: duration == Duration.zero && isKalan
                ? Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      'ZAMAN DOLDU :)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isDefaultTheme ? Colors.green.shade700 : Colors.greenAccent,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeSegment(days, "GÜN"),
                      _buildTimeDivider(),
                      _buildTimeSegment(hours, "SAAT"),
                      _buildTimeDivider(),
                      _buildTimeSegment(minutes, "DAKİKA"),
                    ],
                  ),
            crossFadeState: isBlurred ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSegment(String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _getTextColor(),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          unit,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: _getSubtitleColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDivider() {
    return Container(
      width: 1.5,
      height: 20,
      color: _getBorderColor(),
    );
  }

  Widget buildHeaderSection(
      String? name, String? surname, String? kuvvetKomutanligi, String? rutbe) {
    final bool isDark = !_isDefaultTheme;
    final String commandLogo = kuvvetKomutanligi != null && kuvvetKomutanligi.trim().isNotEmpty
        ? 'assets/images/${kuvvetKomutanligi.trim()}.webp'
        : 'assets/images/app_logo.png';
    final String fullName = name != null && name.isNotEmpty
        ? '${name.toUpperCase()} ${surname?.toUpperCase() ?? ""}'
        : 'ŞAFAK SAYAR';

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and command logo row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                    ),
                    if (rutbe != null && rutbe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        rutbe.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.blueAccent.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                commandLogo,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Large Standout Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.blueAccent.withValues(alpha: 0.12) 
                        : Colors.blueAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark 
                          ? Colors.blueAccent.withValues(alpha: 0.3) 
                          : Colors.blueAccent.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ŞAFAK",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.blue.shade200 : Colors.blueAccent.shade700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                remainingDuration.inDays > 0
                                    ? "${remainingDuration.inDays}"
                                    : "Bitti :)",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.blueAccent.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.flag_rounded,
                        size: 32,
                        color: isDark 
                            ? Colors.blue.shade200.withValues(alpha: 0.5) 
                            : Colors.blueAccent.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.orangeAccent.withValues(alpha: 0.12) 
                        : Colors.orangeAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark 
                          ? Colors.orangeAccent.withValues(alpha: 0.3) 
                          : Colors.orangeAccent.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ATARSA",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.orange.shade200 : Colors.orangeAccent.shade700,
                                letterSpacing: 1.0,
                              ),
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
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.orangeAccent.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.wb_sunny_rounded,
                        size: 32,
                        color: isDark 
                            ? Colors.orange.shade200.withValues(alpha: 0.5) 
                            : Colors.orangeAccent.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildProgressBar() {
    final double percentage = calculatePercentage();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TERHİS ORANI",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getSubtitleColor(),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isDefaultTheme ? Colors.blueAccent.shade700 : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double progressWidth = totalWidth * percentage;

              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Container(
                    width: totalWidth,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: _isDefaultTheme ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                  // Progress Fill
                  Container(
                    width: progressWidth > 12.0 ? progressWidth : 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDefaultTheme
                            ? [Colors.blueAccent.shade400, Colors.blueAccent.shade700]
                            : [Colors.tealAccent.shade400, Colors.blueAccent.shade400],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      boxShadow: [
                        BoxShadow(
                          color: (_isDefaultTheme ? Colors.blueAccent : Colors.tealAccent).withValues(alpha: 0.25),
                          blurRadius: 5,
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
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildUserInfoPanel(Map<String, String?> data) {
    final String formattedSulus = data['sulusTarihi'] != null
        ? DateFormat('dd.MM.yyyy').format(DateTime.parse(data['sulusTarihi']!))
        : '-';
    final String formattedTerhis = data['terhisTarihi'] != null
        ? DateFormat('dd.MM.yyyy').format(DateTime.parse(data['terhisTarihi']!))
        : '-';

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_ind_outlined, size: 17, color: _isDefaultTheme ? Colors.blueAccent.shade700 : Colors.white70),
              const SizedBox(width: 8),
              Text(
                "ASKERLİK BİLGİLERİ",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getSubtitleColor(),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.calendar_month_outlined, "Sülüs Tarihi", formattedSulus),
          _buildInfoDivider(),
          _buildInfoRow(Icons.verified_user_outlined, "Terhis Tarihi", formattedTerhis),
          _buildInfoDivider(),
          _buildInfoRow(Icons.location_on_outlined, "Askerlik Yeri", data['askerlikYeri'] ?? '-'),
          _buildInfoDivider(),
          _buildInfoRow(Icons.home_outlined, "Memleket", data['memleket'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: _getSubtitleColor()),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _getSubtitleColor(),
            ),
          ),
        ),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _getTextColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: _getBorderColor(),
        height: 1,
        thickness: 0.8,
      ),
    );
  }

  Widget buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 17, color: _isDefaultTheme ? Colors.blueAccent.shade700 : Colors.white70),
              const SizedBox(width: 8),
              Text(
                "ASKERLİK TAKVİMİ",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getSubtitleColor(),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<Map<DateTime, bool>>(
            valueListenable: _selectedDaysNotifier,
            builder: (context, selectedDays, child) {
              return TableCalendar(
                locale: 'tr_TR',
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month'
                },
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(fontSize: 10, color: _isDefaultTheme ? Colors.red.shade400 : Colors.redAccent.shade100, fontWeight: FontWeight.bold),
                  weekdayStyle: TextStyle(fontSize: 10, color: _getSubtitleColor(), fontWeight: FontWeight.bold),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getTextColor()),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded, color: _getTextColor(), size: 20),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded, color: _getTextColor(), size: 20),
                ),
                selectedDayPredicate: (day) {
                  final dayNormalized = DateTime(day.year, day.month, day.day);
                  if (_isElapsedDay(dayNormalized)) {
                    return true;
                  }
                  if (selectedDays[day] == true) return true;
                  return selectedDays.keys.any((d) =>
                      d.year == day.year &&
                      d.month == day.month &&
                      d.day == day.day &&
                      selectedDays[d] == true);
                },
                onDaySelected: (selectedDay, _) {
                  _selectedDaysNotifier.value = {
                    ...selectedDays,
                    selectedDay: !(selectedDays[selectedDay] ?? false),
                  };
                  _focusedDay = selectedDay;
                  saveSelectedDays(_selectedDaysNotifier.value);
                },
                firstDay: sulusTarihi != null ? DateTime.parse(sulusTarihi!) : DateTime.now().subtract(const Duration(days: 365)),
                focusedDay: () {
                  final first = sulusTarihi != null ? DateTime.parse(sulusTarihi!) : DateTime.now();
                  final last = terhisTarihi != null ? DateTime.parse(terhisTarihi!) : DateTime.now().add(const Duration(days: 365));
                  if (_focusedDay.isBefore(first)) {
                    return first;
                  } else if (_focusedDay.isAfter(last)) {
                    return last;
                  } else {
                    return _focusedDay;
                  }
                }(),
                lastDay: terhisTarihi != null ? DateTime.parse(terhisTarihi!) : DateTime.now().add(const Duration(days: 365)),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(color: _getTextColor(), fontSize: 13),
                  weekendTextStyle: TextStyle(color: _isDefaultTheme ? Colors.red.shade400 : Colors.redAccent.shade100, fontSize: 13),
                  outsideTextStyle: TextStyle(color: _getSubtitleColor().withValues(alpha: 0.3), fontSize: 12),
                  disabledTextStyle: TextStyle(color: _getSubtitleColor().withValues(alpha: 0.3), fontSize: 12),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  selectedBuilder: (context, date, focusedDay) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, date, focusedDay) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildShortInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 12,
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
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: _getBorderColor(), thickness: 0.8),
          const SizedBox(height: 10),
          Text(
            displayedInfo,
            style: TextStyle(
              fontSize: 15,
              color: _getTextColor(),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildGununSozu() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 12,
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
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: _getBorderColor(), thickness: 0.8),
          const SizedBox(height: 10),
          Text(
            displayGununSozu,
            style: TextStyle(
              fontSize: 15,
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

  Widget buildInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 18, color: _isDefaultTheme ? Colors.blueAccent : Colors.white70),
              const SizedBox(width: 8),
              Text(
                "ASKERİ RÜTBELER",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getSubtitleColor(),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: _getBorderColor(), thickness: 0.8),
          const SizedBox(height: 12),
          _buildRankSection("assets/images/Deniz.webp", "TSK DENİZ KUVVETLERİ RÜTBE SIRALAMASI", 
              "BÜYÜKAMİRAL\\nORAMİRAL\\nKORAMİRAL\\nTÜMAMİRAL\\nTUĞAMİRAL\\nALBAY\\nYARBAY\\nBİNBAŞI\\nYÜZBAŞI\\nÜSTEĞMEN\\nTEĞMEN\\nASTEĞMEN"),
          const SizedBox(height: 20),
          _buildRankSection("assets/images/Hava.webp", "TSK HAVA KUVVETLERİ RÜTBE SIRALAMASI", 
              "ORGENERAL\\nKORGENERAL\\nTÜMGENERAL\\nTUĞGENERAL\\nALBAY\\nYARBAY\\nBİNBAŞI\\nYÜZBAŞI\\nÜSTEĞMEN\\nTEĞMEN\\nASTEĞMEN"),
          const SizedBox(height: 20),
          _buildRankSection("assets/images/Kara.webp", "TSK KARA KUVVETLERİ RÜTBE SIRALAMASI", 
              "MAREŞAL\\nGENEL KURMAY BAŞKANI\\nORGENERAL\\nKORGENERAL\\nTÜMGENERAL\\nTUĞGENERAL\\nALBAY\\nYARBAY\\nBİNBAŞI\\nYÜZBAŞI\\nÜSTEĞMEN\\nTEĞMEN\\nASTEĞMEN\\nASTSUBAY KIDEMLİ BAŞÇAVUŞ\\nASTSUBAY BAŞÇAVUŞ\\nASTSUBAY KIDEMLİ ÜSTÇAVUŞ\\nASTSUBAY ÜSTÇAVUŞ\\nASTSUBAY KIDEMLİ ÇAVUŞ\\nASTSUBAY ÇAVUŞ\\nUZMAN ÇAVUŞ\\nUZMAN ONBAŞI\\nONBAŞI\\nER"),
        ],
      ),
    );
  }

  Widget _buildRankSection(String imagePath, String title, String ranks) {
    final List<String> rankList = ranks.split(RegExp(r'\\n|\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(imagePath, width: 24, height: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  color: _getTextColor(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDefaultTheme ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getBorderColor(), width: 1),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rankList.map((rank) {
              final int index = rankList.indexOf(rank) + 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isDefaultTheme 
                      ? Colors.blueAccent.withValues(alpha: 0.05) 
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isDefaultTheme 
                        ? Colors.blueAccent.withValues(alpha: 0.1) 
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$index. ",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isDefaultTheme ? Colors.blueAccent.shade700 : Colors.white38,
                      ),
                    ),
                    Text(
                      rank.trim(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
