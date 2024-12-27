import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
Duration remainingDuration = Duration.zero;

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<Map<DateTime, bool>> _selectedDaysNotifier = ValueNotifier({});
  DateTime _focusedDay = DateTime.now(); // focusedDay için bir değişken
  Timer? countdownTimer;
  Duration elapsedDuration = Duration.zero; // For elapsed time
  int? durationMonths; // Declare durationMonths as a member variable
  ValueNotifier<bool> isKalanBlurred = ValueNotifier<bool>(false); // Blur state for KALAN SÜRE
  ValueNotifier<bool> isGecenBlurred = ValueNotifier<bool>(false); // Blur state for GEÇEN SÜRE

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
    "Dünya’dan Ay’a gönderilen ışığın ulaşma süresi yaklaşık 1,3 saniyedir."
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
    "Kim bükebilir Türk’ün bileğini? Vatan için fedadır tüm varlığımız!"
  ];


  @override
  void initState() {
    super.initState();
    loadCountdown();
    pickRandomInfo(); // Pick random info when the app starts
    gununSozu();
    loadSelectedDays().then((loadedDays) {
      _selectedDaysNotifier.value = loadedDays;
    });
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

  void gununSozu(){
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
  Future<void> loadCountdown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load blur states from SharedPreferences
    isKalanBlurred.value = prefs.getBool('isKalanBlurred') ?? false;
    isGecenBlurred.value = prefs.getBool('isGecenBlurred') ?? false;

    String? dueDateStr = prefs.getString('sulus_tarihi');
    durationMonths = prefs.getInt('duration'); // Assign it here

    // Load izin (leave days) and ceza (penalty days)
    izin = prefs.getInt('izin') ?? 0;  // Kullanılan izin
    ceza = prefs.getInt('ceza') ?? 0;  // Alınan ceza

    if (dueDateStr != null && durationMonths != null) {
      DateTime dueDate = DateTime.parse(dueDateStr);
      // Adjust the end date by adding both izin (leave days) and ceza (penalty days)
      DateTime endDate = dueDate
          .add(Duration(days: durationMonths! * 30))  // Normal duration
          .add(Duration(days: (izin! ?? 0) + (ceza! ?? 0)));          // Add both leave and penalty days

      DateTime now = DateTime.now();

      if (endDate.isAfter(now)) {
        setState(() {
          remainingDuration = endDate.difference(now);  // Remaining time
          elapsedDuration = now.difference(dueDate);    // Elapsed time since dueDate
        });
      } else {
        setState(() {
          remainingDuration = Duration.zero;            // No remaining time
          elapsedDuration = now.difference(dueDate);    // Elapsed time since dueDate
        });
      }
      print(remainingDuration.inDays);

    }
  }



  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingDuration.inSeconds > 0) {
        setState(() {
          remainingDuration -= Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        // When the countdown ends, calculate elapsed duration
        elapsedDuration = DateTime.now().difference(DateTime.parse('sulus_tarihi')); // Update elapsedDuration correctly
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  double calculatePercentage() {
    // Total duration in seconds, adjusted for izin and ceza
    final totalDurationInSeconds = (durationMonths! * 30 * 24 * 60 * 60)
        + ((izin! ?? 0) * 24 * 60 * 60)  // Subtract izin days
        + ((ceza! ?? 0) * 24 * 60 * 60); // Add ceza days

    // Elapsed duration in seconds
    final elapsedDurationInSeconds = elapsedDuration.inSeconds;

    // Calculate percentage
    if (totalDurationInSeconds > 0) {
      return (elapsedDurationInSeconds / totalDurationInSeconds).clamp(0.0, 1.0);
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
      'kuvvetKomutanligi' : kuvvetKomutanligi,
      'rutbe' : rutbe,
      'themeColor' : themeColor
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
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu.'));
            } else {
              final data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header Section with Avatar and Name
                    buildHeaderSection(data['name'], data['surname'], data['kuvvetKomutanligi'], data['rutbe']),

                    SizedBox(height: 15), // Add some space below the header

                    // Row for Remaining and Elapsed Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              isKalanBlurred.value = !isKalanBlurred.value; // Toggle blur state
                              _saveBlurState(); // Save state whenever toggled
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isKalanBlurred,
                              builder: (context, isBlurred, child) {
                                return buildBlurContainer(
                                  title: "KALAN SÜRE",
                                  content: isBlurred
                                      ? 'Veriler Gizlendi'
                                      : (remainingDuration.inSeconds > 0
                                      ? formatDuration(remainingDuration)
                                      : 'Zaman Doldu'),
                                  isBlurred: isBlurred, // Pass blur state
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 16), // Add space between the containers
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              isGecenBlurred.value = !isGecenBlurred.value; // Toggle blur state
                              _saveBlurState(); // Save state whenever toggled
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isGecenBlurred,
                              builder: (context, isBlurred, child) {
                                return buildBlurContainer(
                                  title: "GEÇEN SÜRE",
                                  content: isBlurred
                                      ? 'Veriler Gizlendi'
                                      : formatDuration(elapsedDuration),
                                  isBlurred: isBlurred, // Pass blur state
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8), // Space between time containers and the progress bar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 30.0, // Set the height of the progress bar
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // Background color for the progress bar
                            borderRadius: BorderRadius.circular(6), // Rounded corners
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6), // Clip the child to have rounded corners
                            child: LinearProgressIndicator(
                              value: calculatePercentage(), // Use the calculated percentage based on elapsed time
                              backgroundColor: Colors.transparent, // Set to transparent for rounded effect
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                          children: [ (calculatePercentage() * 100) < 100 ?
                            Image.asset(
                              'assets/images/running_man2.gif', // Path to the GIF
                              width: 30, // Adjust the size of the GIF as needed
                              height: 30,
                            ) : Image.asset(
                            'assets/images/finish.gif', // Path to the GIF
                            width: 30, // Adjust the size of the GIF as needed
                            height: 30,
                          ),

                            Text(
                              '${(calculatePercentage() * 100).toStringAsFixed(0)}%', // Display the percentage
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),


                    SizedBox(height: 8), // Space between time containers and the progress bar



                    // User Information Containers
                    //buildUserInfoContainer('Ad', data['name'] ?? ''),
                    //buildUserInfoContainer('Soyad', data['surname'] ?? ''),
                    buildUserInfoContainer(
                      'Sülüs Tarihi',
                      data['sulusTarihi'] != null
                          ? DateFormat('dd.MM.yyyy').format(DateTime.parse(data['sulusTarihi']!))
                          : '',
                    ),
                    buildUserInfoContainer(
                      'Terhis Tarihi',
                      data['terhisTarihi'] != null
                          ? DateFormat('dd.MM.yyyy').format(DateTime.parse(data['terhisTarihi']!))
                          : '',
                    ),
                    buildUserInfoContainer('Askerlik Yeri', data['askerlikYeri'] ?? ''),
                    buildUserInfoContainer('Memleket', data['memleket'] ?? ''),
                    SizedBox(height: 10,),
                    buildShortInfoContainer2(),
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

  // New method to save blur states to SharedPreferences
  Future<void> _saveBlurState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKalanBlurred', isKalanBlurred.value);
    await prefs.setBool('isGecenBlurred', isGecenBlurred.value);
  }

  Widget buildBlurContainer({required String title, required String content, required bool isBlurred}) {
    return AnimatedOpacity(
      opacity: isBlurred ? 0.6 : 1.0, // Fully hide the content if blurred
      duration: Duration(milliseconds: 300), // Duration of the animation
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.6),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // New Widget for Header Section
  Widget buildHeaderSection(String? name, String? surname, String? kuvvetKomutanligi, String? rutbe) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Add this line
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30, // Size of the avatar
                backgroundImage: AssetImage('assets/images/app_logo.png'), // Replace with your image path
              ),
              SizedBox(width: 16), // Space between avatar and text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name != null && rutbe != null ? '$name - $rutbe' : 'Şafak Sayar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    surname ?? '2025',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    remainingDuration.inDays > 0
                        ? "Şafak: ${remainingDuration.inDays}"
                        : "Şafak: Bitti :)",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    remainingDuration.inDays - 1 == 0
                        ? "Atarsa: Doğan Güneş" : remainingDuration.inDays < 1 ? "Atarsa: Atmıyor :)"
                        : "Atarsa: ${remainingDuration.inDays - 1}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),

                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 4,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/$kuvvetKomutanligi.png', // Path to your image
              width: 50, // Set desired width
              height: 50, // Set desired height
            ),
          ),
        ],
      ),
    );
  }



  Widget buildShortInfoContainer() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 4,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('KISA BİLGİLER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
          Divider( indent: 10, endIndent: 10,),

          SizedBox(height: 10,),
          Text(
            displayedInfo, // Display the info here
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildGununSozu() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 4,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('GÜNÜN SÖZÜ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
          Divider( indent: 10, endIndent: 10,),

          SizedBox(height: 10,),
          Text(
            displayGununSozu, // Display the info here
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Seçilen günleri Shared Preferences'a kaydet
  Future<void> saveSelectedDays(Map<DateTime, bool> selectedDays) async {
    final prefs = await SharedPreferences.getInstance();
    // DateTime'ı String'e dönüştürerek kaydediyoruz
    final serializedDays = selectedDays.map((key, value) => MapEntry(key.toIso8601String(), value));
    prefs.setString('selectedDays', jsonEncode(serializedDays));
  }

  Future<Map<DateTime, bool>> loadSelectedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDays = prefs.getString('selectedDays');
    if (savedDays == null) {
      return {};
    }
    final Map<String, bool> serializedDays = Map<String, bool>.from(jsonDecode(savedDays));
    return serializedDays.map((key, value) => MapEntry(DateTime.parse(key), value));
  }


  Widget buildShortInfoContainer2() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 4,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ValueListenableBuilder ile takvimi entegre etme
          ValueListenableBuilder<Map<DateTime, bool>>(
            valueListenable: _selectedDaysNotifier,
            builder: (context, selectedDays, child) {
              return Column(
                children: [
                  TableCalendar(
                    locale: 'tr_TR',
              availableCalendarFormats: const {
              CalendarFormat.month : 'Month'
              },
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekendStyle: TextStyle(fontSize: 10), // Hafta sonu günleri için
                      weekdayStyle: TextStyle(fontSize: 10), // Hafta içi günleri için
                    ),
                  headerStyle: HeaderStyle(
                      titleCentered: true
                  ),
                    selectedDayPredicate: (day) => selectedDays[day] ?? false,
                    onDaySelected: (selectedDay, _) {
                      _selectedDaysNotifier.value = {
                        ...selectedDays,
                        selectedDay: !(selectedDays[selectedDay] ?? false),
                      };
                      _focusedDay = selectedDay;

                      // Seçilen günleri kaydet
                      saveSelectedDays(_selectedDaysNotifier.value);
                    },

                    focusedDay: _focusedDay, // focusedDay'ı güncelle
                    firstDay: DateTime.parse(sulusTarihi!),
                    lastDay: DateTime.parse(terhisTarihi!),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.green, // Yeşil renkli arka plan
                        shape: BoxShape.circle, // Yuvarlak şekil
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      // Seçilen günün üzerine ikon eklemek için
                      selectedBuilder: (context, date, focusedDay) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            height: 50,
                            width: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                // Tik işaretini beyaz container içinde sağ üst köşeye yerleştiriyoruz
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white, // Tik ikonu için beyaz arka plan
                                        shape: BoxShape.circle, // Yuvarlak köşeler
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.green, // Tik ikonu yeşil
                                        size: 24, // İkon boyutu
                                      ),
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
                            color: Colors.blue.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
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


// Seçilen günlerin formatlanmış metnini döndüren yardımcı fonksiyon
  String _getSelectedDaysText(Map<DateTime, bool> selectedDays) {
    final selectedDates = selectedDays.keys.where((date) => selectedDays[date] == true).toList();
    if (selectedDates.isEmpty) {
      return 'Hiçbir gün seçilmedi';
    }
    return selectedDates.map((date) => '${date.day}/${date.month}/${date.year}').join(', ');
  }


  Widget buildInfoContainer() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 4,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Text("ASKERİ RÜTBELER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
              Divider( indent: 10, endIndent: 10,),
            ],
          ),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Ortalamak için
                crossAxisAlignment: CrossAxisAlignment.center, // Ortalamak için
                children: [
                  Image.asset(
                    'assets/images/Deniz.png',
                    width: 30,
                    height: 30,
                  ),
                  Expanded(  // Text öğesinin genişlemesini engelleyen bir alan sağlar
                    child: Text(
                      "TSK DENİZ KUVVETLERİ RÜTBE SIRALAMASI - YÜKSEKTEN DÜŞÜĞE DOĞRU",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center, // Metni ortalar
                    ),
                  ),
                  Image.asset(
                    'assets/images/Deniz.png',
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 10,),
          Text("BÜYÜKAMİRAL\nORAMİRAL\nKORAMİRAL\nTÜMAMİRAL\nTUĞAMİRAL\nALBAY\nYARBAY\nBİNBAŞI\nYÜZBAŞI\nÜSTEĞMEN\nTEĞMEN\nASTEĞMEN"),
          SizedBox(height: 10,),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Ortalamak için
                crossAxisAlignment: CrossAxisAlignment.center, // Ortalamak için
                children: [
                  Image.asset(
                    'assets/images/Hava.png',
                    width: 30,
                    height: 30,
                  ),
                  Expanded(  // Text öğesinin genişlemesini engelleyen bir alan sağlar
                    child: Text(
                      "TSK HAVA KUVVETLERİ RÜTBE SIRALAMASI - YÜKSEKTEN DÜŞÜĞE DOĞRU",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center, // Metni ortalar
                    ),
                  ),
                  Image.asset(
                    'assets/images/Hava.png',
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10,),

          Text("ORGENERAL\nKORGENERAL\nTÜMGENERAL\nTUĞGENERAL\nALBAY\nYARBAY\nBİNBAŞI\nYÜZBAŞI\nÜSTEĞMEN\nTEĞMEN\nASTEĞMEN"),
          SizedBox(height: 10,),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Ortalamak için
                crossAxisAlignment: CrossAxisAlignment.center, // Ortalamak için
                children: [
                  Image.asset(
                    'assets/images/Kara.png',
                    width: 30,
                    height: 30,
                  ),
                  Expanded(  // Text öğesinin genişlemesini engelleyen bir alan sağlar
                    child: Text(
                      "TSK KARA KUVVETLERİ RÜTBE SIRALAMASI - YÜKSEKTEN DÜŞÜĞE DOĞRU",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center, // Metni ortalar
                    ),
                  ),
                  Image.asset(
                    'assets/images/Kara.png',
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10,),

          Text("MAREŞAL\nGENEL KURMAY BAŞKANI\nORGENERAL\nKORGENERAL\nTÜMGENERAL\nTUĞGENERAL\nALBAY\nYARBAY\nBİNBAŞI\nYÜZBAŞI\nÜSTEĞMEN\nTEĞMEN\nASTEĞMEN\nASTSUBAY KIDEMLİ BAŞÇAVUŞ\nASTSUBAY BAŞÇAVUŞ\nASTSUBAY KIDEMLİ ÜSTÇAVUŞ\nASTSUBAY ÜSTÇAVUŞ\nASTSUBAY KIDEMLİ ÇAVUŞ\nASTSUBAY ÇAVUŞ\nUZMAN ÇAVUŞ\nUZMAN ONBAŞI\nONBAŞI\nER"),


        ],
      )
    );
  }


  Widget buildTimeContainer({required String title, required String content}) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildUserInfoContainer(String title, String content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        SizedBox(width: 16), // Add space between the title and content containers
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }}

