import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkIfUserDataExists(); // Verileri kontrol et

  }

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5135589807', // AdMob'dan aldığınız ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;

          // Bekleme süresi ekleyerek reklamı göster
          Future.delayed(const Duration(seconds: 5), () {
            _showInterstitialAd(); // 5 saniye bekledikten sonra reklamı göster
          });
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd yüklenemedi: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isAdReady) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          print('Reklam kapatıldı.');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          print('Reklam gösterilemedi: $error');
        },
      );

      _interstitialAd!.show();
    } else {
      print('Reklam hazır değil.');
    }
  }

  @override
  void dispose() {
    // Eğer _interstitialAd null değilse dispose et
    try {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
    catch (ex){}
    super.dispose();
  }


  // Verilerin SharedPreferences'ta olup olmadığını kontrol et
  Future<void> _checkIfUserDataExists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name');
    String? surname = prefs.getString('surname');
    String? askerlikYeri = prefs.getString('askerlik_yeri');
    String? memleket = prefs.getString('memleket');

    if (name != null && surname != null && askerlikYeri != null && memleket != null) {
      // Eğer veriler mevcutsa ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ManagePages()),
      );
      // Reklam göster
      _loadInterstitialAd(); // Reklamı yükle
    } else {
      // Eğer veri yoksa kullanıcıyı veri giriş sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserInputPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Geçici splash ekranı gösterebilirsin
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}