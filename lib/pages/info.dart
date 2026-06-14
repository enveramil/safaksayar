import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/pages/faq_page.dart';
import 'package:safaksayar/pages/notes_page.dart';
import 'package:safaksayar/pages/quiz_page.dart';
import 'package:safaksayar/pages/rank_page.dart';
import 'package:safaksayar/pages/safak_sozleri.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoScreen extends StatefulWidget {
  final String backgroundImage;
  const InfoScreen({super.key, required this.backgroundImage});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowDialog();
    });
  }

  Future<void> _checkAndShowDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDialogShown = prefs.getBool('isDialogShown') ?? false;

    if (!isDialogShown) {
      showInfoDialog();
      await prefs.setBool(
          'isDialogShown', true); // Bir daha göstermemek için işaretle
    }
  }

  void showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hoş Geldiniz!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/milyoner.webp'),
            SizedBox(height: 10),
            Text('Asker de can sıkıntısına birebir bir özellik sunuyoruz. '
                'Kim Milyoner Olmak İster de çıkmış soruları çözebilirsin. Hadi başlayalım...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _loadInterstitialAd() {
    if (AdManager.isDev) return;
    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-4655119937024112/6340277716', // Buraya AdMob'dan aldığınız reklam ID'sini yazın.
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15),
                _buildInfoTile(
                  title: 'Sıkça Sorulan Sorular',
                  subtitle: 'Aklınıza takılan tüm soruları bu kısımdan giderebilirsiniz',
                  imagePath: 'assets/images/question-mark.webp',
                  accentColor: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FaqPage()),
                    );
                  },
                ),
                _buildInfoTile(
                  title: 'Rütbeler',
                  subtitle: 'Askeri rütbelere bakmak için tıklayınız.',
                  imagePath: 'assets/images/military-rank.webp',
                  accentColor: Colors.deepPurpleAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RankPage()),
                    );
                  },
                ),
                _buildInfoTile(
                  title: 'Kim Milyoner Olmak İster',
                  subtitle: 'Canın sıkıldıkça soru çöz',
                  imagePath: 'assets/images/milyoner.webp',
                  accentColor: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizPage()),
                    );
                    AdManager().loadInterstitialAd();
                  },
                ),
                _buildInfoTile(
                  title: 'Not Tut',
                  subtitle: 'Askerlik anılarını kayıt altına al',
                  imagePath: 'assets/images/notes.webp',
                  accentColor: Colors.greenAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesScreen(context: context),
                      ),
                    );
                  },
                ),
                _buildInfoTile(
                  title: 'İller ve Plaka Kodları',
                  subtitle: 'Türkiye’nin illerini ve plaka kodlarını görün',
                  imagePath: 'assets/images/license.webp',
                  accentColor: Colors.cyan,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IllerPlakaScreen()),
                    );
                  },
                ),
                _buildInfoTile(
                  title: 'Şafak Sözleri',
                  subtitle: 'Asker de can sıkıntısına birebir sözler',
                  imagePath: 'assets/images/pen.webp',
                  accentColor: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SafakSozleri()),
                    );
                  },
                ),
                _buildInfoTile(
                  title: 'Uygulamayı Paylaşın',
                  subtitle: 'Askerlik görevini yerine getirecek arkadaşlarınızla ve devrelerinizle uygulamayı paylaşmayı unutmayın',
                  imagePath: 'assets/images/share.webp',
                  accentColor: Colors.teal,
                  onTap: () {
                    final String shareLink = Platform.isIOS
                        ? 'https://apps.apple.com/app/id6777999683'
                        : 'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar';
                    final box = context.findRenderObject() as RenderBox?;
                    final Rect? sharePositionOrigin = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;
                    Share.share(shareLink, sharePositionOrigin: sharePositionOrigin);
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required String imagePath,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.04 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDefaultTheme 
                        ? accentColor.withValues(alpha: 0.1) 
                        : Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isDefaultTheme 
                          ? accentColor.withValues(alpha: 0.3) 
                          : Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: _getSubtitleColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _getSubtitleColor().withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IllerPlakaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('İller ve Plaka Kodları'),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
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
                  color: Colors.grey.withValues(alpha: 0.5),
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
    "resim": "assets/images/adana.webp" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "02",
    "il": "Adıyaman",
    "resim": "assets/images/adıyaman.webp" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "03",
    "il": "Afyonkarahisar",
    "resim": "assets/images/afyonkarahisar.webp" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "04",
    "il": "Ağrı",
    "resim": "assets/images/agrı.webp" // Projeye eklenen resim dosyası
  },
  {
    "plaka": "05",
    "il": "Amasya",
    "resim": "assets/images/amasya.webp" // Projeye eklenen resim dosyası
  },
  {"plaka": "06", "il": "Ankara", "resim": "assets/images/ankara.webp"},
  {"plaka": "07", "il": "Antalya", "resim": "assets/images/antalya.webp"},
  {"plaka": "08", "il": "Artvin", "resim": "assets/images/artvin.webp"},
  {"plaka": "09", "il": "Aydın", "resim": "assets/images/aydin.webp"},
  {"plaka": "10", "il": "Balıkesir", "resim": "assets/images/balıkesir.webp"},
  {"plaka": "11", "il": "Bilecik", "resim": "assets/images/bilecik.webp"},
  {"plaka": "12", "il": "Bingöl", "resim": "assets/images/bingöl.webp"},
  {"plaka": "13", "il": "Bitlis", "resim": "assets/images/bitlis.webp"},
  {"plaka": "14", "il": "Bolu", "resim": "assets/images/bolu.webp"},
  {"plaka": "15", "il": "Burdur", "resim": "assets/images/burdur.webp"},
  {"plaka": "16", "il": "Bursa", "resim": "assets/images/bursa.webp"},
  {"plaka": "17", "il": "Çanakkale", "resim": "assets/images/canakkale.webp"},
  {"plaka": "18", "il": "Çankırı", "resim": "assets/images/cankiri.webp"},
  {"plaka": "19", "il": "Çorum", "resim": "assets/images/corum.webp"},
  {"plaka": "20", "il": "Denizli", "resim": "assets/images/denizli.webp"},
  {"plaka": "21", "il": "Diyarbakır", "resim": "assets/images/diyarbakır.webp"},
  {"plaka": "22", "il": "Edirne", "resim": "assets/images/edirne.webp"},
  {"plaka": "23", "il": "Elazığ", "resim": "assets/images/elazıg.webp"},
  {"plaka": "24", "il": "Erzincan", "resim": "assets/images/erzincan.webp"},
  {"plaka": "25", "il": "Erzurum", "resim": "assets/images/erzurum.webp"},
  {"plaka": "26", "il": "Eskişehir", "resim": "assets/images/eskisehir.webp"},
  {"plaka": "27", "il": "Gaziantep", "resim": "assets/images/gaziantep.webp"},
  {"plaka": "28", "il": "Giresun", "resim": "assets/images/giresun.webp"},
  {"plaka": "29", "il": "Gümüşhane", "resim": "assets/images/gumushane.webp"},
  {"plaka": "30", "il": "Hakkari", "resim": "assets/images/hakkari.webp"},
  {"plaka": "31", "il": "Hatay", "resim": "assets/images/hatay.webp"},
  {"plaka": "32", "il": "Isparta", "resim": "assets/images/ısparta.webp"},
  {"plaka": "33", "il": "Mersin", "resim": "assets/images/mersin.webp"},
  {
    "plaka": "34",
    "il": "İstanbul",
    "resim": "assets/images/istanbul.webp" // Projeye eklenen resim dosyası
  },

  {"plaka": "35", "il": "İzmir", "resim": "assets/images/izmir.webp"},
  {"plaka": "36", "il": "Kars", "resim": "assets/images/kars.webp"},
  {"plaka": "37", "il": "Kastamonu", "resim": "assets/images/kastamonu.webp"},
  {"plaka": "38", "il": "Kayseri", "resim": "assets/images/kayseri.webp"},
  {"plaka": "39", "il": "Kırklareli", "resim": "assets/images/kırklareli.webp"},
  {"plaka": "40", "il": "Kırşehir", "resim": "assets/images/kırsehir.webp"},
  {"plaka": "41", "il": "Kocaeli", "resim": "assets/images/kocaeli.webp"},
  {"plaka": "42", "il": "Konya", "resim": "assets/images/konya.webp"},
  {"plaka": "43", "il": "Kütahya", "resim": "assets/images/kutahya.webp"},
  {"plaka": "44", "il": "Malatya", "resim": "assets/images/malatya.webp"},
  {"plaka": "45", "il": "Manisa", "resim": "assets/images/manisa.webp"},
  {
    "plaka": "46",
    "il": "Kahramanmaraş",
    "resim": "assets/images/kahramanmaras.webp"
  },
  {"plaka": "47", "il": "Mardin", "resim": "assets/images/mardin.webp"},
  {"plaka": "48", "il": "Muğla", "resim": "assets/images/mugla.webp"},
  {"plaka": "49", "il": "Muş", "resim": "assets/images/mus.webp"},
  {"plaka": "50", "il": "Nevşehir", "resim": "assets/images/nevsehir.webp"},
  {"plaka": "51", "il": "Niğde", "resim": "assets/images/nigde.webp"},
  {"plaka": "52", "il": "Ordu", "resim": "assets/images/ordu.webp"},
  {"plaka": "53", "il": "Rize", "resim": "assets/images/rize.webp"},
  {"plaka": "54", "il": "Sakarya", "resim": "assets/images/sakarya.webp"},
  {"plaka": "55", "il": "Samsun", "resim": "assets/images/samsun.webp"},
  {"plaka": "56", "il": "Siirt", "resim": "assets/images/siirt.webp"},
  {"plaka": "57", "il": "Sinop", "resim": "assets/images/sinop.webp"},
  {"plaka": "58", "il": "Sivas", "resim": "assets/images/sivas.webp"},
  {"plaka": "59", "il": "Tekirdağ", "resim": "assets/images/tekirdag.webp"},
  {"plaka": "60", "il": "Tokat", "resim": "assets/images/tokat.webp"},
  {"plaka": "61", "il": "Trabzon", "resim": "assets/images/trabzon.webp"},
  {"plaka": "62", "il": "Tunceli", "resim": "assets/images/tunceli.webp"},
  {"plaka": "63", "il": "Şanlıurfa", "resim": "assets/images/sanliurfa.webp"},
  {"plaka": "64", "il": "Uşak", "resim": "assets/images/usak.webp"},
  {"plaka": "65", "il": "Van", "resim": "assets/images/van.webp"},
  {"plaka": "66", "il": "Yozgat", "resim": "assets/images/yozgat.webp"},
  {"plaka": "67", "il": "Zonguldak", "resim": "assets/images/zonguldak.webp"},
  {"plaka": "68", "il": "Aksaray", "resim": "assets/images/aksaray.webp"},
  {"plaka": "69", "il": "Bayburt", "resim": "assets/images/bayburt.webp"},
  {"plaka": "70", "il": "Karaman", "resim": "assets/images/karaman.webp"},
  {"plaka": "71", "il": "Kırıkkale", "resim": "assets/images/kırıkkale.webp"},
  {"plaka": "72", "il": "Batman", "resim": "assets/images/batman.webp"},
  {"plaka": "73", "il": "Şırnak", "resim": "assets/images/sirnak.webp"},
  {"plaka": "74", "il": "Bartın", "resim": "assets/images/bartin.webp"},
  {"plaka": "75", "il": "Ardahan", "resim": "assets/images/ardahan.webp"},
  {"plaka": "76", "il": "Iğdır", "resim": "assets/images/ıgdir.webp"},
  {"plaka": "77", "il": "Yalova", "resim": "assets/images/yalova.webp"},
  {"plaka": "78", "il": "Karabük", "resim": "assets/images/karabuk.webp"},
  {"plaka": "79", "il": "Kilis", "resim": "assets/images/kilis.webp"},
  {"plaka": "80", "il": "Osmaniye", "resim": "assets/images/osmaniye.webp"},
  {"plaka": "81", "il": "Düzce", "resim": "assets/images/düzce.webp"},

  // Diğer iller ve plakalar...
];
