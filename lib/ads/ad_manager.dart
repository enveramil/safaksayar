import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/ads/ad_helper.dart';

class AdManager {
  static bool isDev = true;

  static Future<void> fetchAdConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('parameter')
          .doc('config')
          .get()
          .timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('isDev')) {
          isDev = data['isDev'] as bool;
          print("Loaded ad configuration from Firestore: isDev = $isDev");
        }
      }
    } catch (e) {
      print("Error fetching ad configuration from Firestore: $e");
    }
  }

  AppOpenAd? _openAd;

  Future<void> loadAndShowAppOpenAd() async {
    if (isDev) return;
    try {
      await AppOpenAd.load(
        adUnitId: AdHelper.openAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _openAd = ad;
            _openAd!.show();
            _openAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print("Açılış reklamı kapatıldı.");
                _openAd?.dispose();
                _openAd = null; // Bellek sızıntısını önlemek için temizleme
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print("Açılış reklamı gösterilemedi: $error");
                _openAd?.dispose();
                _openAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            print("AppOpenAd yüklenemedi: $error");
          },
        ),
      );
    } catch (e) {
      print("AppOpenAd yüklenirken hata oluştu: $e");
    }
  }

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  Future<void> loadInterstitialAd() async {
    if (isDev) return;
    await InterstitialAd.load(
      adUnitId:
          'ca-app-pub-4655119937024112/6340277716', // AdMob'dan aldığınız ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;

          _showInterstitialAd(); // 5 saniye bekledikten sonra reklamı göster
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
}
