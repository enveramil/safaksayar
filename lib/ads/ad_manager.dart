import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/ads/ad_helper.dart';

class AdManager {
  AppOpenAd? _openAd;

  Future<void> loadAndShowAppOpenAd() async {
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
    await InterstitialAd.load(
      adUnitId:
          'ca-app-pub-4655119937024112/1860231792', // AdMob'dan aldığınız ID
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
