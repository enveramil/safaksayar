import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';

/// Kim Milyoner Olmak İster oyun hakları servisi.
/// Ücretsiz kullanıcılara günlük 3 adet klasik yarışma hakkı verir.
/// PRO kullanıcılar ise sınırsız oynama hakkına sahiptir.
class MillionaireRightsService {
  MillionaireRightsService._() {
    if (RevenueCatService.instance.isPremium) {
      remainingRightsNotifier.value = 999;
    }
    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumStatusChanged);
  }

  static final MillionaireRightsService instance = MillionaireRightsService._();

  static const int maxFreeDailyRights = 3;
  static const String _keyDailyRights = 'millionaire_daily_rights';
  static const String _keyLastDate = 'millionaire_last_rights_date';

  final ValueNotifier<int> remainingRightsNotifier = ValueNotifier<int>(maxFreeDailyRights);

  String get _todayDateStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _onPremiumStatusChanged() {
    if (RevenueCatService.instance.isPremium) {
      remainingRightsNotifier.value = 999;
    } else {
      getRemainingRights();
    }
  }

  /// Kalan oyun hakkını getirir ve yeni gün başlamışsa 3'e yeniler.
  /// PRO kullanıcılar için 999 (sınırsız) döner.
  Future<int> getRemainingRights() async {
    if (RevenueCatService.instance.isPremium) {
      remainingRightsNotifier.value = 999;
      return 999;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_keyLastDate);
      final today = _todayDateStr;

      int rights;
      if (lastDate != today) {
        // Yeni bir gün, hakları 3'e yenile
        rights = maxFreeDailyRights;
        await prefs.setString(_keyLastDate, today);
        await prefs.setInt(_keyDailyRights, rights);
      } else {
        rights = prefs.getInt(_keyDailyRights) ?? maxFreeDailyRights;
      }

      remainingRightsNotifier.value = rights;
      return rights;
    } catch (_) {
      return maxFreeDailyRights;
    }
  }

  /// 1 yarışma hakkı düşer (Oyun başlatıldığında çağrılır).
  /// PRO kullanıcı ise hak düşmez ve doğrudan true döner.
  /// Hak kalmadıysa false döner.
  Future<bool> useOneRight() async {
    if (RevenueCatService.instance.isPremium) {
      remainingRightsNotifier.value = 999;
      return true;
    }

    final currentRights = await getRemainingRights();
    if (currentRights <= 0) {
      return false;
    }

    final newRights = currentRights - 1;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDailyRights, newRights);
      remainingRightsNotifier.value = newRights;
    } catch (_) {}

    return true;
  }

  /// Kullanıcının oynama hakkı var mı?
  bool get hasRights {
    if (RevenueCatService.instance.isPremium) return true;
    return remainingRightsNotifier.value > 0;
  }
}
