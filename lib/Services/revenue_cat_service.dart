import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safaksayar/Services/millionaire_duel_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PaywallPurchaseStatus { success, cancelled, pending, error }

class PaywallActionResult {
  final PaywallPurchaseStatus status;
  final String? message;
  final CustomerInfo? customerInfo;

  PaywallActionResult({
    required this.status,
    this.message,
    this.customerInfo,
  });
}

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  // ===========================================================================
  // REVENUECAT CONFIGURATION
  // RevenueCat Console (https://app.revenuecat.com) üzerinden aldığınız
  // Public API anahtarlarını buraya ekleyebilirsiniz.
  // ===========================================================================
  static const String appleApiKey = 'appl_sngObxGZUOFitvjNeSKeUwxmbum';
  static const String googleApiKey = 'goog_YOUR_REVENUECAT_GOOGLE_KEY';
  static const String defaultEntitlementId = 'premium';

  final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);

  bool _isInitialized = false;
  bool _isSdkConfigured = false;
  bool _hasVerifiedStatus = false;
  Future<void>? _initFuture;
  Offerings? _cachedOfferings;

  String? _boundUserId;
  CustomerInfo? _latestCustomerInfo;
  Map<String, dynamic>? _latestFirestoreUserData;
  bool _firestoreDocLoaded = false;
  bool _customerInfoLoaded = false;
  bool _didFreshInvalidatedCheck = false;
  DateTime? _lastRefreshAt;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  bool _isUserRelative = false;

  bool get isPremium => isPremiumNotifier.value;
  bool get hasVerifiedStatus => _hasVerifiedStatus;
  bool get isUserRelative => _isUserRelative;

  /// Aktif aboneliğin bitiş / yenileme tarihi (süresiz üyeliklerde null).
  DateTime? get premiumExpiresAt {
    final info = _latestCustomerInfo;
    return _parseAnyDate(
          _extractRelevantEntitlement(info)?.expirationDate ??
              info?.latestExpirationDate,
        ) ??
        _parseAnyDate(_latestFirestoreUserData?['premiumExpiresAt']);
  }

  bool get isOnFreeTrial =>
      _extractRelevantEntitlement(_latestCustomerInfo)?.periodType ==
      PeriodType.trial;

  bool get premiumWillRenew =>
      _extractRelevantEntitlement(_latestCustomerInfo)?.willRenew ??
      _latestFirestoreUserData?['premiumWillRenew'] == true;

  /// Uygulama ilk kareyi çizmeden önce önbellekteki PRO durumunu senkron yükler (0ms gecikme).
  /// Asker yakını rolündeki kullanıcılara tüm PRO özellikler doğrudan ve ücretsiz tanımlanır.
  void primeFromPrefs(SharedPreferences prefs) {
    final role = prefs.getString('user_role');
    _isUserRelative = (role == 'yakin');
    if (_isUserRelative) {
      isPremiumNotifier.value = true;
      return;
    }
    isPremiumNotifier.value = prefs.getBool('is_premium_active') ?? false;
  }

  /// RevenueCat SDK ve Firestore `users/{userId}` abonelik senkronizasyonunu başlatır.
  Future<void> init() {
    if (_isInitialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<String?> _resolveLocalUserId([SharedPreferences? existingPrefs]) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    final id = prefs.getString('userId') ?? prefs.getString('user_id');
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    return null;
  }

  /// Satın alma anında henüz yerel bir userId oluşmamışsa (eski kurulum vb.),
  /// kalıcı bir userId üretip SharedPreferences ve RevenueCat ile bağlar.
  Future<String> _ensureUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _resolveLocalUserId(prefs);
    if (existing != null) return existing;

    String generatedId;
    try {
      final counterRef =
          FirebaseFirestore.instance.collection('counters').doc('users');
      generatedId = await FirebaseFirestore.instance
          .runTransaction((transaction) async {
            final counterDoc = await transaction.get(counterRef);
            final int currentId =
                counterDoc.exists ? (counterDoc.data()?['currentId'] ?? 0) : 0;
            final int nextId = currentId + 1;
            transaction.set(counterRef, {'currentId': nextId});
            return nextId.toString();
          })
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      generatedId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }

    await prefs.setString('userId', generatedId);
    return generatedId;
  }

  Future<void> _doInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      _isUserRelative = (role == 'yakin');
      if (_isUserRelative) {
        isPremiumNotifier.value = true;
      } else {
        isPremiumNotifier.value = prefs.getBool('is_premium_active') ?? false;
      }

      final String? userId = await _resolveLocalUserId(prefs);

      // 1. Firestore users/{userId} gerçek zamanlı dinleyicisini başlat (varsa)
      if (userId != null) {
        _attachUserDocListener(userId);
      }

      // 2. Platforma göre API Key seç
      String apiKey = '';
      if (Platform.isIOS) {
        apiKey = appleApiKey;
      } else if (Platform.isAndroid) {
        apiKey = googleApiKey;
      }

      final bool hasValidStoreKey =
          apiKey.isNotEmpty && !apiKey.contains('YOUR_REVENUECAT');

      if (!hasValidStoreKey) {
        debugPrint(
          '⚠️ [RevenueCat] Platform API Key henüz girilmemiş; Firestore users.isPremium durumu esas alınıyor.',
        );
        _isSdkConfigured = false;
        _customerInfoLoaded = true;
        _isInitialized = true;
        await _fetchFirestoreUserOnce(userId);
        await _reconcileAndSync();
        return;
      }

      // 3. RevenueCat SDK konfigürasyonu (userId mevcutsa doğrudan appUserID ile bağla)
      final configuration = PurchasesConfiguration(apiKey);
      if (userId != null && userId.isNotEmpty) {
        configuration.appUserID = userId;
        _boundUserId = userId;
      }
      await Purchases.configure(configuration);
      _isSdkConfigured = true;

      Purchases.addCustomerInfoUpdateListener((info) {
        _latestCustomerInfo = info;
        _customerInfoLoaded = true;
        unawaited(_reconcileAndSync());
      });

      _isInitialized = true;

      // 4. Hem Firestore users/{userId} hem de RevenueCat abonelik durumunu paralel doğrula
      unawaited(refreshSubscriptionStatus(force: true));
    } catch (e) {
      debugPrint('❌ [RevenueCat] Başlatma hatası: $e');
      _isInitialized = true;
    }
  }

  /// Kullanıcı kimliği (userId) kurulum veya eşleşme sonrası oluştuğunda/değiştiğinde
  /// RevenueCat `appUserID` ve Firestore `users/{userId}` kaydını bağlar ve doğrular.
  Future<void> bindUser(String? userId) async {
    final cleanId = userId?.trim();
    if (cleanId == null || cleanId.isEmpty) return;

    if (!_isInitialized) {
      await init();
    }

    _attachUserDocListener(cleanId);

    if (_isSdkConfigured && _boundUserId != cleanId) {
      try {
        final currentAppUserId = await Purchases.appUserID;
        if (currentAppUserId != cleanId) {
          final logInResult = await Purchases.logIn(cleanId);
          _latestCustomerInfo = logInResult.customerInfo;
          _customerInfoLoaded = true;
        }
        _boundUserId = cleanId;
      } catch (e) {
        debugPrint('⚠️ [RevenueCat] logIn($cleanId) hatası: $e');
      }
    }

    await refreshSubscriptionStatus(force: true);
  }

  /// Kullanıcı rolü 'yakin' veya 'asker' olarak değiştiğinde senkronize eder.
  /// Asker yakını ise tüm PRO özellikleri anında ücretsiz tanımlar.
  Future<void> syncUserRole([String? explicitRole]) async {
    final prefs = await SharedPreferences.getInstance();
    final role = explicitRole ?? prefs.getString('user_role') ?? 'asker';
    _isUserRelative = (role == 'yakin');

    if (_isUserRelative) {
      _hasVerifiedStatus = true;
      _didFreshInvalidatedCheck = false;
      await _applyPremiumState(
        true,
        syncFirestorePayload: {
          'isPremium': true,
          'user_role': 'yakin',
          'premiumSource': 'relative_free_pro',
          'premiumStatus': 'active_free_relative',
          'premiumLastVerifiedAt': FieldValue.serverTimestamp(),
          'quiz_stats': {'isPremium': true},
        },
      );
      debugPrint('💕 [RevenueCat] syncUserRole: Asker yakını rolü için PRO aktif edildi.');
    } else {
      await refreshSubscriptionStatus(force: true);
    }
  }

  /// Uygulama ön plana geldiğinde (resume) veya önemli geçişlerde
  /// abonelik yenilenme / bitiş durumunu taze olarak kontrol eder.
  Future<void> refreshSubscriptionStatus({bool force = false}) async {
    if (!force &&
        _lastRefreshAt != null &&
        DateTime.now().difference(_lastRefreshAt!) < const Duration(seconds: 45)) {
      return;
    }
    _lastRefreshAt = DateTime.now();

    final userId = await _resolveLocalUserId();
    if (userId != null && _boundUserId != userId) {
      _attachUserDocListener(userId);
      if (_isSdkConfigured) {
        try {
          final currentAppUserId = await Purchases.appUserID;
          if (currentAppUserId != userId) {
            final res = await Purchases.logIn(userId);
            _latestCustomerInfo = res.customerInfo;
            _customerInfoLoaded = true;
          }
          _boundUserId = userId;
        } catch (_) {}
      }
    }

    await Future.wait([
      _fetchFirestoreUserOnce(userId),
      _fetchCustomerInfoOnce(forceInvalidate: force),
    ]);

    await _reconcileAndSync();
  }

  void _attachUserDocListener(String userId) {
    if (_boundUserId == userId && _userDocSubscription != null) return;
    _userDocSubscription?.cancel();
    _boundUserId = userId;

    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        _latestFirestoreUserData = snapshot.data();
        _firestoreDocLoaded = true;
        unawaited(_reconcileAndSync());
      },
      onError: (Object e) {
        debugPrint('⚠️ [RevenueCat] Firestore users/$userId dinleme hatası: $e');
      },
    );
  }

  Future<void> _fetchFirestoreUserOnce(String? userId) async {
    if (userId == null || userId.isEmpty) {
      _firestoreDocLoaded = true;
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 4));
      _latestFirestoreUserData = doc.data();
      _firestoreDocLoaded = true;
    } catch (e) {
      debugPrint('⚠️ [RevenueCat] Firestore users/$userId okunamadı: $e');
    }
  }

  Future<bool> _fetchCustomerInfoOnce({bool forceInvalidate = false}) async {
    if (!_isSdkConfigured) {
      _customerInfoLoaded = true;
      return true;
    }
    try {
      if (forceInvalidate) {
        await Purchases.invalidateCustomerInfoCache();
      }
      _latestCustomerInfo = await Purchases.getCustomerInfo();
      _customerInfoLoaded = true;
      return true;
    } catch (e) {
      debugPrint('⚠️ [RevenueCat] Müşteri bilgisi alınamadı (çevrimdışı olabilir): $e');
      return false;
    }
  }

  EntitlementInfo? _extractRelevantEntitlement(CustomerInfo? info) {
    if (info == null) return null;
    final defaultEnt = info.entitlements.all[defaultEntitlementId];
    if (defaultEnt != null) return defaultEnt;
    if (info.entitlements.active.isNotEmpty) {
      return info.entitlements.active.values.first;
    }
    if (info.entitlements.all.isNotEmpty) {
      return info.entitlements.all.values.first;
    }
    return null;
  }

  DateTime? _parseAnyDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  /// Firestore `users/{userId}` ile RevenueCat (App Store / Google Play) abonelik durumunu uzlaştırır:
  /// 1) Mevcutta `users/{userId}.isPremium == true` olan aktif kullanıcıları KORUR (tekrar ödeme istemez).
  /// 2) Aylık / yıllık abonelik yenilenmişse `isPremium: true` ve yeni bitiş tarihini devam ettirir.
  /// 3) Aylık / yıllık abonelik süresi bitmiş ve yenilenmemişse `isPremium: false` olarak durdurur.
  Future<void> _reconcileAndSync() async {
    if (!_firestoreDocLoaded && !_customerInfoLoaded) return;

    final now = DateTime.now();
    final info = _latestCustomerInfo;
    final userDoc = _latestFirestoreUserData;

    final EntitlementInfo? ent = _extractRelevantEntitlement(info);
    final bool rcActive = info != null &&
        (info.entitlements.all[defaultEntitlementId]?.isActive == true ||
            info.entitlements.active.isNotEmpty);
    final bool rcHadSubscription = info != null &&
        (info.entitlements.all.isNotEmpty ||
            info.allPurchasedProductIdentifiers.isNotEmpty);

    final DateTime? rcExpiresAt =
        _parseAnyDate(ent?.expirationDate ?? info?.latestExpirationDate);
    final String? rcExpiresIso = rcExpiresAt?.toUtc().toIso8601String();
    final DateTime? rcLatestPurchaseAt = _parseAnyDate(ent?.latestPurchaseDate);
    final DateTime? rcUnsubscribeAt =
        _parseAnyDate(ent?.unsubscribeDetectedAt);
    final DateTime? rcBillingIssueAt =
        _parseAnyDate(ent?.billingIssueDetectedAt);
    final bool? rcWillRenew = ent?.willRenew;
    final String? rcProductId = ent?.productIdentifier;
    final String? rcPeriodType = ent?.periodType.name;

    final bool fsIsPremium = userDoc?['isPremium'] == true;
    final String? fsSource = userDoc?['premiumSource'] as String?;
    final String? fsStatus = userDoc?['premiumStatus'] as String?;
    final String? fsExpiredAtIso = userDoc?['premiumExpiredAtIso'] as String?;
    final DateTime? fsExpiresAt = _parseAnyDate(
      userDoc?['premiumExpiresAt'] ??
          userDoc?['subscriptionExpiresAt'] ??
          userDoc?['premiumUntil'],
    );
    final bool fsExpiryPassed = fsExpiresAt != null && now.isAfter(fsExpiresAt);

    // -------------------------------------------------------------------------
    // DURUM 0: ASKER YAKINI - TÜM PRO ÖZELLİKLER TAMAMEN ÜCRETSİZ!
    // -------------------------------------------------------------------------
    final prefs = await SharedPreferences.getInstance();
    final String currentRole =
        prefs.getString('user_role') ?? (userDoc?['user_role'] as String?) ?? 'asker';
    _isUserRelative = (currentRole == 'yakin');

    if (_isUserRelative) {
      _hasVerifiedStatus = true;
      _didFreshInvalidatedCheck = false;
      await _applyPremiumState(
        true,
        syncFirestorePayload: {
          'isPremium': true,
          'user_role': 'yakin',
          'premiumSource': 'relative_free_pro',
          'premiumStatus': 'active_free_relative',
          'premiumLastVerifiedAt': FieldValue.serverTimestamp(),
          'quiz_stats': {'isPremium': true},
        },
      );
      debugPrint('💕 [RevenueCat] Asker yakını rolü tespit edildi; tüm PRO ayrıcalıkları ücretsiz olarak aktif edildi.');
      return;
    }

    // -------------------------------------------------------------------------
    // DURUM 1: Mağaza (App Store / Play Store) üzerinde AKTİF veya YENİLENMİŞ abonelik var!
    // -------------------------------------------------------------------------
    if (rcActive) {
      _hasVerifiedStatus = true;
      _didFreshInvalidatedCheck = false;
      final String targetStatus = rcBillingIssueAt != null
          ? 'billing_retry'
          : ((rcUnsubscribeAt != null || rcWillRenew == false)
              ? 'cancelled_active_until_expiry'
              : 'active');

      await _applyPremiumState(
        true,
        syncFirestorePayload: {
          'isPremium': true,
          'premiumSource': 'revenuecat',
          'premiumStatus': targetStatus,
          if (rcProductId != null) 'premiumProductId': rcProductId,
          if (rcPeriodType != null) 'premiumPeriodType': rcPeriodType,
          'premiumWillRenew': rcWillRenew ?? true,
          'premiumExpiresAt':
              rcExpiresAt != null ? Timestamp.fromDate(rcExpiresAt) : null,
          'premiumExpiresAtIso': rcExpiresIso,
          'premiumLatestPurchaseAt': rcLatestPurchaseAt != null
              ? Timestamp.fromDate(rcLatestPurchaseAt)
              : null,
          'premiumUnsubscribeDetectedAt': rcUnsubscribeAt != null
              ? Timestamp.fromDate(rcUnsubscribeAt)
              : null,
          'premiumBillingIssueDetectedAt': rcBillingIssueAt != null
              ? Timestamp.fromDate(rcBillingIssueAt)
              : null,
          'premiumLastVerifiedAt': FieldValue.serverTimestamp(),
          'quiz_stats': {'isPremium': true},
        },
      );
      return;
    }

    // -------------------------------------------------------------------------
    // DURUM 2: Manuel / Süresiz tanımlanmış korumalı VIP kullanıcılar
    // -------------------------------------------------------------------------
    if (fsIsPremium &&
        (fsSource == 'manual' || fsSource == 'lifetime') &&
        !fsExpiryPassed) {
      _hasVerifiedStatus = true;
      await _applyPremiumState(true);
      return;
    }

    // Yönetici Firestore üzerinden daha önce süresi bitmiş bir kullanıcının
    // isPremium alanını manuel olarak tekrar true yaptıysa koru:
    if (fsIsPremium &&
        fsStatus == 'expired' &&
        !fsExpiryPassed &&
        fsExpiredAtIso != null &&
        fsExpiredAtIso == rcExpiresIso) {
      _hasVerifiedStatus = true;
      await _applyPremiumState(
        true,
        syncFirestorePayload: {
          'isPremium': true,
          'premiumSource': 'manual',
          'premiumStatus': 'active_protected',
          'premiumLastVerifiedAt': FieldValue.serverTimestamp(),
        },
      );
      return;
    }

    // -------------------------------------------------------------------------
    // DURUM 3: Aylık / Yıllık Abonelik SÜRESİ BİTMİŞ ve YENİLENMEMİŞ!
    // (RevenueCat üzerinde geçmiş abonelik var ama artık aktif değil VEYA
    // Firestore'daki abonelik bitiş tarihi geçmiş ve yenilenmemiş)
    // -------------------------------------------------------------------------
    final bool shouldCheckExpiration =
        (!rcActive && rcHadSubscription) || (fsIsPremium && fsExpiryPassed && !rcActive);

    if (shouldCheckExpiration) {
      // Kullanıcı şu an aktif görünüyorsa, mağdur etmemek adına düşürmeden hemen önce
      // RevenueCat önbelleğini temizleyip 1 kez canlı mağaza kontrolü yap (tam o an yenilenmiş olabilir!)
      if (_isSdkConfigured &&
          !_didFreshInvalidatedCheck &&
          (fsIsPremium || isPremiumNotifier.value)) {
        _didFreshInvalidatedCheck = true;
        final onlineOk = await _fetchCustomerInfoOnce(forceInvalidate: true);
        if (!onlineOk) {
          // İnternet yoksa çevrimdışı kullanıcıyı mağdur etme, bağlantı gelince tekrar kontrol edilecek
          debugPrint('ℹ️ [RevenueCat] Çevrimdışı olunduğu için mevcut PRO durumu geçici olarak korundu.');
          return;
        }
        // Canlı kontrolde yenilendiği görüldüyse tekrar uzlaştır (Durum 1'e girecek)
        final refreshedInfo = _latestCustomerInfo;
        final bool refreshedActive = refreshedInfo != null &&
            (refreshedInfo.entitlements.all[defaultEntitlementId]?.isActive == true ||
                refreshedInfo.entitlements.active.isNotEmpty);
        if (refreshedActive) {
          await _reconcileAndSync();
          return;
        }
      }

      // Abonelik süresi kesin olarak dolmuş, iptal edilmiş veya ödeme alınamadığı için durmuş -> isPremium: false
      _hasVerifiedStatus = true;
      final String inactiveReason = rcBillingIssueAt != null
          ? 'payment_failed'
          : (rcUnsubscribeAt != null ? 'cancelled_expired' : 'expired');

      await _applyPremiumState(
        false,
        syncFirestorePayload: {
          'isPremium': false,
          'premiumSource': fsSource ?? 'revenuecat',
          'premiumStatus': inactiveReason,
          'premiumWillRenew': false,
          if (rcExpiresIso != null) 'premiumExpiredAtIso': rcExpiresIso,
          if (rcUnsubscribeAt != null)
            'premiumUnsubscribeDetectedAt': Timestamp.fromDate(rcUnsubscribeAt),
          if (rcBillingIssueAt != null)
            'premiumBillingIssueDetectedAt':
                Timestamp.fromDate(rcBillingIssueAt),
          'premiumLastVerifiedAt': FieldValue.serverTimestamp(),
          'quiz_stats': {'isPremium': false},
        },
      );
      debugPrint('ℹ️ [RevenueCat] Abonelik süresi dolmuş ve yenilenmemiş; isPremium=false olarak güncellendi.');
      return;
    }

    // -------------------------------------------------------------------------
    // DURUM 4: Mevcutta Firestore `users/{userId}` tablosunda `isPremium: true` olan
    // ve süresi dolmamış aktif kullanıcıları KORU! (Tekrar ödeme isteme)
    // -------------------------------------------------------------------------
    if (_firestoreDocLoaded && fsIsPremium && !fsExpiryPassed) {
      _hasVerifiedStatus = true;
      await _applyPremiumState(true);
      debugPrint('✅ [RevenueCat] Mevcut Firestore users.isPremium=true kullanıcısı korundu.');
      return;
    }

    // -------------------------------------------------------------------------
    // DURUM 5: Firestore henüz yüklenmediyse ama bekliyorsak erken düşürme yapma
    // -------------------------------------------------------------------------
    if (!_firestoreDocLoaded) {
      return;
    }

    // -------------------------------------------------------------------------
    // DURUM 6: Standart ücretsiz kullanıcı (`fsIsPremium == false` ve `rcActive == false`)
    // -------------------------------------------------------------------------
    _hasVerifiedStatus = true;
    await _applyPremiumState(false);
  }

  /// Güncel paket tekliflerini (Offerings) getir
  Future<Offerings?> getOfferings() async {
    try {
      if (!_isInitialized) await init();
      if (!_isSdkConfigured) return null;
      _cachedOfferings = await Purchases.getOfferings();
      return _cachedOfferings;
    } catch (e) {
      debugPrint('⚠️ [RevenueCat] Teklifler alınamadı: $e');
      return _cachedOfferings;
    }
  }

  /// Seçili paketi satın al (Aylık / Yıllık)
  Future<PaywallActionResult> purchasePackage(Package package) async {
    try {
      final userId = await _ensureUserId();
      await bindUser(userId);

      final purchaseResult =
          await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;
      _latestCustomerInfo = customerInfo;
      _customerInfoLoaded = true;

      await _reconcileAndSync();

      if (isPremiumNotifier.value) {
        return PaywallActionResult(
          status: PaywallPurchaseStatus.success,
          customerInfo: customerInfo,
        );
      } else {
        return PaywallActionResult(
          status: PaywallPurchaseStatus.error,
          message: 'Satın alma tamamlandı ancak yetki doğrulanamadı.',
          customerInfo: customerInfo,
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PaywallActionResult(
          status: PaywallPurchaseStatus.cancelled,
          message: 'İşlem iptal edildi.',
        );
      }
      // Kullanıcı zaten bu ürüne aktif olarak aboneyse Apple/Google hata döndürebilir -> Restore ile koru!
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        return await restorePurchases();
      }
      return PaywallActionResult(
        status: PaywallPurchaseStatus.error,
        message: e.message ?? 'Satın alma sırasında bir hata oluştu.',
      );
    } catch (e) {
      return PaywallActionResult(
        status: PaywallPurchaseStatus.error,
        message: 'Beklenmeyen bir hata oluştu: $e',
      );
    }
  }

  /// Geçmiş satın alımları geri yükle (Restore Purchases)
  /// Hem App Store / Play Store makbuzunu hem de Firestore `users/{userId}.isPremium` durumunu kontrol eder.
  Future<PaywallActionResult> restorePurchases() async {
    try {
      final userId = await _resolveLocalUserId();
      if (userId != null) {
        _attachUserDocListener(userId);
        await _fetchFirestoreUserOnce(userId);
      }

      CustomerInfo? customerInfo;
      if (_isSdkConfigured) {
        if (userId != null) {
          try {
            final currentAppUserId = await Purchases.appUserID;
            if (currentAppUserId != userId) {
              await Purchases.logIn(userId);
            }
          } catch (_) {}
        }
        customerInfo = await Purchases.restorePurchases();
        _latestCustomerInfo = customerInfo;
        _customerInfoLoaded = true;
      }

      await _reconcileAndSync();

      if (isPremiumNotifier.value) {
        return PaywallActionResult(
          status: PaywallPurchaseStatus.success,
          message: 'Aboneliğiniz başarıyla geri yüklendi! 🎉',
          customerInfo: customerInfo,
        );
      } else {
        return PaywallActionResult(
          status: PaywallPurchaseStatus.error,
          message: 'Aktif bir abonelik veya satın alım bulunamadı.',
          customerInfo: customerInfo,
        );
      }
    } on PlatformException catch (e) {
      // Mağaza hatası olsa bile Firestore'da aktif isPremium varsa koru
      await _reconcileAndSync();
      if (isPremiumNotifier.value) {
        return PaywallActionResult(
          status: PaywallPurchaseStatus.success,
          message: 'Mevcut PRO üyeliğiniz doğrulandı ve aktif edildi! 🎉',
        );
      }
      return PaywallActionResult(
        status: PaywallPurchaseStatus.error,
        message: e.message ?? 'Geri yükleme başarısız oldu.',
      );
    } catch (e) {
      return PaywallActionResult(
        status: PaywallPurchaseStatus.error,
        message: 'Geri yükleme sırasında hata oluştu: $e',
      );
    }
  }

  /// Manuel test veya promosyon için premium durumunu ayarla
  Future<void> setPremiumManually(
    bool active, {
    Duration? duration,
    String source = 'manual',
  }) async {
    _hasVerifiedStatus = true;
    final DateTime? expiresAt =
        duration != null ? DateTime.now().add(duration) : null;
    await _applyPremiumState(
      active,
      syncFirestorePayload: {
        'isPremium': active,
        'premiumSource': source,
        'premiumStatus': active ? 'active' : 'expired',
        'premiumExpiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'premiumExpiresAtIso': expiresAt?.toUtc().toIso8601String(),
        'premiumLastVerifiedAt': FieldValue.serverTimestamp(),
        'quiz_stats': {'isPremium': active},
      },
    );
  }

  bool _needsFirestoreWrite(Map<String, dynamic> payload) {
    final doc = _latestFirestoreUserData;
    if (doc == null) return true;
    if (doc['isPremium'] != payload['isPremium']) return true;
    if (payload.containsKey('premiumStatus') &&
        doc['premiumStatus'] != payload['premiumStatus']) {
      return true;
    }
    if (payload.containsKey('premiumSource') &&
        doc['premiumSource'] != payload['premiumSource']) {
      return true;
    }
    if (payload.containsKey('premiumWillRenew') &&
        doc['premiumWillRenew'] != payload['premiumWillRenew']) {
      return true;
    }
    if (payload.containsKey('premiumExpiresAtIso') &&
        doc['premiumExpiresAtIso'] != payload['premiumExpiresAtIso']) {
      return true;
    }
    return false;
  }

  Future<void> _applyPremiumState(
    bool active, {
    Map<String, dynamic>? syncFirestorePayload,
  }) async {
    final bool changed = isPremiumNotifier.value != active;
    isPremiumNotifier.value = active;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_active', active);
    } catch (_) {}

    // Firestore users/{userId} senkronizasyonu (yalnızca gerçek değişiklik varsa yazar, sonsuz döngü oluşturmaz)
    if (syncFirestorePayload != null && _needsFirestoreWrite(syncFirestorePayload)) {
      final userId = _boundUserId ??
          (active ? await _ensureUserId() : await _resolveLocalUserId());
      if (userId != null && userId.isNotEmpty) {
        try {
          _latestFirestoreUserData = {
            ...?_latestFirestoreUserData,
            ...syncFirestorePayload,
          };
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(syncFirestorePayload, SetOptions(merge: true));
        } catch (e) {
          debugPrint('⚠️ [RevenueCat] Firestore users/$userId güncellenemedi: $e');
        }
      }
    }

    if (changed || active) {
      // Lider tablosu VIP rozetini anında güncelle
      MillionaireDuelService.instance.syncPremiumStatus();
      // Asker ise açılan takip kodunun Firestore'da yayında olduğundan emin ol
      if (active) {
        SoldierMatchService.instance.ensureSoldierPublished();
      }
    }
  }
}
