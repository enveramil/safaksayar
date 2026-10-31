import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/ads/ad_helper.dart';

/// Akıllı ve kullanıcı dostu Google AdMob Reklam Yöneticisi.
///
/// Özellikler:
/// - Kullanıcıyı darlamaz / sıkmaz: Frekans sınırlaması (Frequency Capping) uygular.
/// - Cooldown: İki tam ekran reklam arasına minimum 40 saniye zorunlu bekleme koyar.
/// - Preload (Ön yükleme): Reklamlar arka planda önceden hazırlanır, tıklandığında anında açılır.
/// - PRO Kullanıcı Koruması: `RevenueCatService.isPremium == true` ise reklamlar tamamen kapalıdır.
class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal();
  factory AdManager() => instance;

  static bool _firestoreIsDev = false;

  /// PRO kullanıcılarda veya Firestore üzerinden reklamlar kapatıldıysa true döner.
  static bool get isDev =>
      RevenueCatService.instance.isPremium || _firestoreIsDev;

  static set isDev(bool value) => _firestoreIsDev = value;

  // Frekans sayaçları ve zaman damgaları
  int _forumClickCount = 0;
  int _arenaEntryCount = 0;
  DateTime? _lastFullScreenAdShownAt;

  // Frekans Ayarları:
  // "Örneğin foruma tıkladı karşısına reklam çıktı sonraki 2 tıklamasında çıkmasın 3 üncüde çıksın"
  // Tıklama 1: Reklam (1 % 3 == 1)
  // Tıklama 2: Pas
  // Tıklama 3: Pas
  // Tıklama 4: Reklam (4 % 3 == 1)
  static const int forumInterval = 3;
  static const int arenaInterval = 3;
  static const Duration minAdCooldown = Duration(seconds: 40);

  // Önceden yüklenmiş tam ekran geçiş reklamı
  InterstitialAd? _preloadedInterstitialAd;
  bool _isPreloading = false;

  // Açılış reklamı referansı
  AppOpenAd? _openAd;
  bool _isOpenAdLoading = false;

  /// Firestore'daki uzaktan reklam konfigürasyonunu yükler.
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
          _firestoreIsDev = data['isDev'] as bool;
          debugPrint(
            "[AdManager] Firestore reklam yapılandırması: isDev = $_firestoreIsDev (effective isDev = $isDev)",
          );
        }
      }
    } catch (e) {
      debugPrint("[AdManager] Firestore reklam yapılandırması alınamadı: $e");
    }

    // Uygulama açılışında ilk geçiş reklamını arka planda önceden hazırla
    instance.preloadInterstitialAd();
  }

  /// İki tam ekran reklam arasında yeterli süre geçti mi kontrol eder.
  bool _canShowAdNow() {
    if (isDev) return false;
    if (_lastFullScreenAdShownAt != null) {
      final elapsed = DateTime.now().difference(_lastFullScreenAdShownAt!);
      if (elapsed < minAdCooldown) {
        debugPrint(
          '[AdManager] Cooldown süresi henüz dolmadı (${elapsed.inSeconds}s < ${minAdCooldown.inSeconds}s), reklam atlandı.',
        );
        return false;
      }
    }
    return true;
  }

  /// Geçiş reklamını arka planda sessizce önceden yükler (Sıfır gecikme).
  void preloadInterstitialAd({String? customAdUnitId}) {
    if (isDev) return;
    if (_preloadedInterstitialAd != null || _isPreloading) return;

    _isPreloading = true;
    final adUnit = customAdUnitId ?? AdHelper.interstitialAdUnitId;

    InterstitialAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isPreloading = false;
          if (isDev) {
            ad.dispose();
            return;
          }
          _preloadedInterstitialAd = ad;
          debugPrint('[AdManager] Tam ekran geçiş reklamı önceden yüklendi ve hazır.');
        },
        onAdFailedToLoad: (error) {
          _isPreloading = false;
          _preloadedInterstitialAd = null;
          debugPrint('[AdManager] Geçiş reklamı ön yüklemesi başarısız: $error');
        },
      ),
    );
  }

  /// FORUM SEKMESİNE TIKLANDIĞINDA ÇAĞRILIR
  /// - 1. tıklamada gösterir, sonraki 2 tıklamada göstermez (her 3 tıklamada 1 gösterir).
  /// - PRO kullanıcılara ASLA çıkmaz.
  /// - Son 40 saniye içinde başka bir tam ekran reklam izlendiyse kullanıcıyı darlamaz.
  void showForumInterstitialAd({VoidCallback? onAdClosed}) {
    if (isDev) {
      onAdClosed?.call();
      return;
    }

    _forumClickCount++;
    debugPrint('[AdManager] Forum sekmesine tıklandı (Sayaç: $_forumClickCount)');

    // Frekans kontrolü (1. göster, 2. pas, 3. pas, 4. göster...)
    if (_forumClickCount % forumInterval != 1) {
      debugPrint('[AdManager] Forum reklam frekansı eşleşmedi, pas geçildi.');
      onAdClosed?.call();
      return;
    }

    if (!_canShowAdNow()) {
      onAdClosed?.call();
      return;
    }

    _showPreloadedOrLoad(
      adUnitId: AdHelper.forumInterstitialAdUnitId,
      source: 'Forum',
      onAdClosed: onAdClosed,
    );
  }

  /// ARENA (DÜELLO & MİLYONER) GİRİŞİNDE ÇAĞRILIR
  /// - Her 3 girişte 1 tam ekran video reklam gösterir.
  /// - PRO kullanıcılara ASLA çıkmaz.
  /// - Cooldown koruması vardır.
  void showArenaInterstitialAd({VoidCallback? onAdClosed}) {
    if (isDev) {
      onAdClosed?.call();
      return;
    }

    _arenaEntryCount++;
    debugPrint('[AdManager] Arenaya giriş yapıldı (Sayaç: $_arenaEntryCount)');

    if (_arenaEntryCount % arenaInterval != 1) {
      debugPrint('[AdManager] Arena reklam frekansı eşleşmedi, pas geçildi.');
      onAdClosed?.call();
      return;
    }

    if (!_canShowAdNow()) {
      onAdClosed?.call();
      return;
    }

    _showPreloadedOrLoad(
      adUnitId: AdHelper.arenaInterstitialAdUnitId,
      source: 'Arena',
      onAdClosed: onAdClosed,
    );
  }

  /// Hazır reklamı gösterir veya yoksa sessizce yükler.
  void _showPreloadedOrLoad({
    required String adUnitId,
    required String source,
    VoidCallback? onAdClosed,
  }) {
    if (_preloadedInterstitialAd != null) {
      final ad = _preloadedInterstitialAd!;
      _preloadedInterstitialAd = null;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _lastFullScreenAdShownAt = DateTime.now();
          debugPrint('[AdManager] $source tam ekran video reklamı açıldı.');
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          debugPrint('[AdManager] $source reklamı kapatıldı.');
          onAdClosed?.call();
          preloadInterstitialAd(customAdUnitId: adUnitId);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          debugPrint('[AdManager] $source reklamı gösterilemedi: $error');
          onAdClosed?.call();
          preloadInterstitialAd(customAdUnitId: adUnitId);
        },
      );

      ad.show();
    } else {
      // Reklam o an hazır değilse kullanıcıyı bekletmeyip hemen geçir, arka planda hazırla
      debugPrint('[AdManager] $source için hazır reklam yoktu, arka planda yükleniyor.');
      onAdClosed?.call();
      preloadInterstitialAd(customAdUnitId: adUnitId);
    }
  }

  /// Geriye dönük uyumluluk için standart geçiş reklamı çağrısı
  Future<void> loadInterstitialAd() async {
    preloadInterstitialAd();
  }

  /// Uygulama ilk açıldığında gösterilen açılış reklamı (App Open Ad)
  Future<void> loadAndShowAppOpenAd() async {
    if (isDev || _isOpenAdLoading) return;
    _isOpenAdLoading = true;

    try {
      await AppOpenAd.load(
        adUnitId: AdHelper.openAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _isOpenAdLoading = false;
            if (isDev) {
              ad.dispose();
              return;
            }
            _openAd = ad;
            _openAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _lastFullScreenAdShownAt = DateTime.now();
              },
              onAdDismissedFullScreenContent: (ad) {
                _openAd?.dispose();
                _openAd = null;
                preloadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _openAd?.dispose();
                _openAd = null;
                preloadInterstitialAd();
              },
            );
            _openAd!.show();
          },
          onAdFailedToLoad: (error) {
            _isOpenAdLoading = false;
            debugPrint('[AdManager] AppOpenAd yüklenemedi: $error');
            preloadInterstitialAd();
          },
        ),
      );
    } catch (e) {
      _isOpenAdLoading = false;
      debugPrint('[AdManager] AppOpenAd yükleme hatası: $e');
      preloadInterstitialAd();
    }
  }
}
