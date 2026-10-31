import 'dart:io';
import 'package:flutter/foundation.dart';

/// Google AdMob Reklam Birimi Kimlikleri (Ad Unit IDs)
///
/// AdMob Konsolu: https://apps.admob.com
/// Hesap Yayıncı Kimliği (Publisher ID): pub-4655119937024112
/// Uygulama Kimliği (App ID): ca-app-pub-4655119937024112~3342915993
class AdHelper {
  // ===========================================================================
  // GOOGLE RESMİ TEST REKLAM KİMLİKLERİ
  // Debug / Test modunda hesabınızın AdMob kural ihlali (geçersiz trafik)
  // almaması için Google'ın resmi test reklam birimleri kullanılır.
  // ===========================================================================
  static const String _testIosAppOpenId = 'ca-app-pub-3940256099942544/5575463023';
  static const String _testAndroidAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  static const String _testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  // ===========================================================================
  // CANLI (PRODUCTION) REKLAM KİMLİKLERİ
  // ===========================================================================

  /// 1. Uygulama Açılış Reklamı (App Open Ad)
  static const String prodAppOpenAdId = 'ca-app-pub-4655119937024112/4080945883';

  /// 2. Genel Tam Ekran Video / Geçiş Reklamı (Interstitial Ad)
  static const String prodInterstitialAdId = 'ca-app-pub-4655119937024112/6340277716';

  /// 3. Forum Sayfası Geçiş Reklamı
  /// (AdMob'da ayrı birim açılırsa buraya yazılır, yoksa ana geçiş kimliği kullanılır)
  static const String prodForumInterstitialAdId = 'ca-app-pub-4655119937024112/6340277716';

  /// 4. Arena (Düello & Milyoner) Geçiş Reklamı
  /// (AdMob'da ayrı birim açılırsa buraya yazılır, yoksa ana geçiş kimliği kullanılır)
  static const String prodArenaInterstitialAdId = 'ca-app-pub-4655119937024112/6340277716';

  // ===========================================================================
  // DİNAMİK GETTER METOTLARI (Platform ve Debug/Release Uyumlu)
  // ===========================================================================

  /// Uygulama Açılış Reklamı Kimliği
  static String get openAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidAppOpenId : _testIosAppOpenId;
    }
    return prodAppOpenAdId;
  }

  /// Genel Geçiş Reklamı Kimliği
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidInterstitialId : _testIosInterstitialId;
    }
    return prodInterstitialAdId;
  }

  /// Forum Sayfası Geçiş Reklamı Kimliği
  static String get forumInterstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidInterstitialId : _testIosInterstitialId;
    }
    return prodForumInterstitialAdId;
  }

  /// Arena Sayfası Geçiş Reklamı Kimliği
  static String get arenaInterstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidInterstitialId : _testIosInterstitialId;
    }
    return prodArenaInterstitialAdId;
  }
}
