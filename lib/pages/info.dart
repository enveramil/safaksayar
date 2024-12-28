import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/pages/faq_page.dart';
import 'package:safaksayar/pages/notification_screen.dart';
import 'package:safaksayar/pages/quiz_page.dart';
import 'package:safaksayar/pages/rank_page.dart';
import 'package:safaksayar/pages/safak_sozleri.dart';
import 'package:share_plus/share_plus.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-3940256099942544/5135589807', // Buraya AdMob'dan aldığınız reklam ID'sini yazın.
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isAdReady) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          // Reklam kapandıktan sonra uygulamanın devam etmesi
          print("Reklam kapandı.");
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          print("Reklam gösterilemedi: $error");
        },
      );

      _interstitialAd!.show();
    } else {
      print("Reklam hazır değil!");
    }
  }

  @override
  void dispose() {
    try {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    } catch (ex) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 15),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FaqPage()),
                );
              },
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10), // İçerik için yatay ve dikey padding
                title: Text(
                  'Sıkça Sorulan Sorular',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Aklınıza takılan tüm soruları bu kısımdan giderebilirsiniz',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing:
                    Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              ),
            ),
          ),

          // Rütbeler section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RankPage()),
                );
              },
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10), // İçerik için yatay ve dikey padding
                title: Text(
                  'Rütbeler',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Askeri rütbelere bakmak için tıklayınız.',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing:
                    Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              Share.share('Bu harika uygulamayı dene: https://safaksayar.com');
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10), // İçerik için yatay ve dikey padding
                title: Text(
                  'Uygulamayı Paylaşın',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Askerlik görevini yerine getirecek arkadaşlarınızla ve devrelerinizle uygulamayı paylaşmayı unutmayın',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing:
                    Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10), // İçerik için yatay ve dikey padding
              title: Text(
                'İller ve Plaka Kodları',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Türkiye’nin illerini ve plaka kodlarını görün',
                style: TextStyle(color: Colors.white70),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IllerPlakaScreen()),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10), // İçerik için yatay ve dikey padding
              title: Text(
                'Şafak Sözleri',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Asker de can sıkıntısına birebir sözler',
                style: TextStyle(color: Colors.white70),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SafakSozleri()),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10), // İçerik için yatay ve dikey padding
              title: Text(
                'Bildirim Servisi',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'İstenilen vakitte şafak bildirimi yapılır',
                style: TextStyle(color: Colors.white70),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              onTap: () {
                _showInterstitialAd();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10), // İçerik için yatay ve dikey padding
              title: Text(
                'Kim Milyoner Olmak İster',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Canın sıkıldıkça soru çöz',
                style: TextStyle(color: Colors.white70),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizPage()),
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}

class IllerPlakaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İller ve Plaka Kodları'),
      ),
      body: ListView.builder(
        itemCount: illerVePlakalar.length,
        itemBuilder: (context, index) {
          final il = illerVePlakalar[index];
          return Container(
            margin: EdgeInsets.all(10),
            height: 150, // Container yüksekliği
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Resim arka planda olacak
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    il['resim'], // İlin resmi
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit
                        .cover, // Resmi tüm alanı kaplayacak şekilde ayarlar
                  ),
                ),
                // Yazılar resim üzerinde olacak
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        il['il'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Yazı rengi beyaz
                          shadows: [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black, // Yazının altına gölge
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Plaka: ${il['plaka']}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white, // Yazı rengi beyaz
                          shadows: [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black, // Yazının altına gölge
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// JSON Veri Yapısı
const List<Map<String, dynamic>> illerVePlakalar = [
  {
    "plaka": "01",
    "il": "Adana",
    "resim": "assets/images/adana.png" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "02",
    "il": "Adıyaman",
    "resim": "assets/images/adıyaman.png" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "03",
    "il": "Afyonkarahisar",
    "resim": "assets/images/afyonkarahisar.png" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "04",
    "il": "Ağrı",
    "resim": "assets/images/agrı.png" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "05",
    "il": "Amasya",
    "resim": "assets/images/amasya.png" // Projeye eklenen resim dosyası
  },
  {"plaka": "06", "il": "Ankara", "resim": "assets/images/ankara.png"},
  {"plaka": "07", "il": "Antalya", "resim": "assets/images/antalya.png"},
  {"plaka": "08", "il": "Artvin", "resim": "assets/images/artvin.png"},
  {"plaka": "09", "il": "Aydın", "resim": "assets/images/aydin.png"},
  {"plaka": "10", "il": "Balıkesir", "resim": "assets/images/balıkesir.png"},
  {"plaka": "11", "il": "Bilecik", "resim": "assets/images/bilecik.png"},
  {"plaka": "12", "il": "Bingöl", "resim": "assets/images/bingöl.png"},
  {"plaka": "13", "il": "Bitlis", "resim": "assets/images/bitlis.png"},
  {"plaka": "14", "il": "Bolu", "resim": "assets/images/bolu.png"},
  {"plaka": "15", "il": "Burdur", "resim": "assets/images/burdur.png"},
  {"plaka": "16", "il": "Bursa", "resim": "assets/images/bursa.png"},
  {"plaka": "17", "il": "Çanakkale", "resim": "assets/images/canakkale.png"},
  {"plaka": "18", "il": "Çankırı", "resim": "assets/images/cankiri.png"},
  {"plaka": "19", "il": "Çorum", "resim": "assets/images/corum.png"},
  {"plaka": "20", "il": "Denizli", "resim": "assets/images/denizli.png"},
  {"plaka": "21", "il": "Diyarbakır", "resim": "assets/images/diyarbakır.png"},
  {"plaka": "22", "il": "Edirne", "resim": "assets/images/edirne.png"},
  {"plaka": "23", "il": "Elazığ", "resim": "assets/images/elazıg.png"},
  {"plaka": "24", "il": "Erzincan", "resim": "assets/images/erzincan.png"},
  {"plaka": "25", "il": "Erzurum", "resim": "assets/images/erzurum.png"},
  {"plaka": "26", "il": "Eskişehir", "resim": "assets/images/eskisehir.png"},
  {"plaka": "27", "il": "Gaziantep", "resim": "assets/images/gaziantep.png"},
  {"plaka": "28", "il": "Giresun", "resim": "assets/images/giresun.png"},
  {"plaka": "29", "il": "Gümüşhane", "resim": "assets/images/gumushane.png"},
  {"plaka": "30", "il": "Hakkari", "resim": "assets/images/hakkari.png"},
  {"plaka": "31", "il": "Hatay", "resim": "assets/images/hatay.png"},
  {"plaka": "32", "il": "Isparta", "resim": "assets/images/ısparta.png"},
  {"plaka": "33", "il": "Mersin", "resim": "assets/images/mersin.png"},
  {
    "plaka": "34",
    "il": "İstanbul",
    "resim": "assets/images/istanbul.png" // Projeye eklenen resim dosyası
  },

  {"plaka": "35", "il": "İzmir", "resim": "assets/images/izmir.png"},
  {"plaka": "36", "il": "Kars", "resim": "assets/images/kars.png"},
  {"plaka": "37", "il": "Kastamonu", "resim": "assets/images/kastamonu.png"},
  {"plaka": "38", "il": "Kayseri", "resim": "assets/images/kayseri.png"},
  {"plaka": "39", "il": "Kırklareli", "resim": "assets/images/kırklareli.png"},
  {"plaka": "40", "il": "Kırşehir", "resim": "assets/images/kırsehir.png"},
  {"plaka": "41", "il": "Kocaeli", "resim": "assets/images/kocaeli.png"},
  {"plaka": "42", "il": "Konya", "resim": "assets/images/konya.png"},
  {"plaka": "43", "il": "Kütahya", "resim": "assets/images/kutahya.png"},
  {"plaka": "44", "il": "Malatya", "resim": "assets/images/malatya.png"},
  {"plaka": "45", "il": "Manisa", "resim": "assets/images/manisa.png"},
  {
    "plaka": "46",
    "il": "Kahramanmaraş",
    "resim": "assets/images/kahramanmaras.png"
  },
  {"plaka": "47", "il": "Mardin", "resim": "assets/images/mardin.png"},
  {"plaka": "48", "il": "Muğla", "resim": "assets/images/mugla.png"},
  {"plaka": "49", "il": "Muş", "resim": "assets/images/mus.png"},
  {"plaka": "50", "il": "Nevşehir", "resim": "assets/images/nevsehir.png"},
  {"plaka": "51", "il": "Niğde", "resim": "assets/images/nigde.png"},
  {"plaka": "52", "il": "Ordu", "resim": "assets/images/ordu.png"},
  {"plaka": "53", "il": "Rize", "resim": "assets/images/rize.png"},
  {"plaka": "54", "il": "Sakarya", "resim": "assets/images/sakarya.png"},
  {"plaka": "55", "il": "Samsun", "resim": "assets/images/samsun.png"},
  {"plaka": "56", "il": "Siirt", "resim": "assets/images/siirt.png"},
  {"plaka": "57", "il": "Sinop", "resim": "assets/images/sinop.png"},
  {"plaka": "58", "il": "Sivas", "resim": "assets/images/sivas.png"},
  {"plaka": "59", "il": "Tekirdağ", "resim": "assets/images/tekirdag.png"},
  {"plaka": "60", "il": "Tokat", "resim": "assets/images/tokat.png"},
  {"plaka": "61", "il": "Trabzon", "resim": "assets/images/trabzon.png"},
  {"plaka": "62", "il": "Tunceli", "resim": "assets/images/tunceli.png"},
  {"plaka": "63", "il": "Şanlıurfa", "resim": "assets/images/sanliurfa.png"},
  {"plaka": "64", "il": "Uşak", "resim": "assets/images/usak.png"},
  {"plaka": "65", "il": "Van", "resim": "assets/images/van.png"},
  {"plaka": "66", "il": "Yozgat", "resim": "assets/images/yozgat.png"},
  {"plaka": "67", "il": "Zonguldak", "resim": "assets/images/zonguldak.png"},
  {"plaka": "68", "il": "Aksaray", "resim": "assets/images/aksaray.png"},
  {"plaka": "69", "il": "Bayburt", "resim": "assets/images/bayburt.png"},
  {"plaka": "70", "il": "Karaman", "resim": "assets/images/karaman.png"},
  {"plaka": "71", "il": "Kırıkkale", "resim": "assets/images/kırıkkale.png"},
  {"plaka": "72", "il": "Batman", "resim": "assets/images/batman.png"},
  {"plaka": "73", "il": "Şırnak", "resim": "assets/images/sirnak.png"},
  {"plaka": "74", "il": "Bartın", "resim": "assets/images/bartin.png"},
  {"plaka": "75", "il": "Ardahan", "resim": "assets/images/ardahan.png"},
  {"plaka": "76", "il": "Iğdır", "resim": "assets/images/ıgdir.png"},
  {"plaka": "77", "il": "Yalova", "resim": "assets/images/yalova.png"},
  {"plaka": "78", "il": "Karabük", "resim": "assets/images/karabuk.png"},
  {"plaka": "79", "il": "Kilis", "resim": "assets/images/kilis.png"},
  {"plaka": "80", "il": "Osmaniye", "resim": "assets/images/osmaniye.png"},
  {"plaka": "81", "il": "Düzce", "resim": "assets/images/düzce.png"},

  // Diğer iller ve plakalar...
];
