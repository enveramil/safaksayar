import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';
import 'revenue_cat_service.dart';

/// Soldier matching, pairing and realtime synchronization service.
/// Connects soldiers with their spouses, lovers, family members, and friends.
class SoldierMatchService {
  static final SoldierMatchService instance = SoldierMatchService._internal();
  SoldierMatchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pre-warmed SharedPreferences reference set at startup so initial screens render synchronously on Frame 1.
  SharedPreferences? cachedPrefs;

  /// Reactive notifiers so HomeScreen, ProfileScreen, InfoScreen, and ManagePages
  /// update immediately across IndexedStack tabs without requiring an app restart.
  final ValueNotifier<int> dataSyncVersion = ValueNotifier<int>(0);
  final ValueNotifier<int> pairingStateVersion = ValueNotifier<int>(0);

  void notifyDataChanged({bool pairingChanged = false}) {
    dataSyncVersion.value++;
    if (pairingChanged) {
      pairingStateVersion.value++;
    }
  }

  // Characters for tracking code generation (unambiguous uppercase alphanumeric)
  static const String _codeChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const String _codePrefix = 'SFK-';

  /// Generates or retrieves existing unique tracking code for a soldier
  Future<String> generateOrGetTrackingCode({bool forceRegenerate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    String? existingCode = prefs.getString('tracking_code');

    if (!forceRegenerate && existingCode != null && existingCode.isNotEmpty) {
      return existingCode;
    }

    // Generate random unique 5-character suffix (e.g. SFK-7842)
    final random = Random();
    String code = '';
    bool isUnique = false;
    int attempts = 0;

    while (!isUnique && attempts < 10) {
      attempts++;
      final suffix = List.generate(4, (_) => _codeChars[random.nextInt(_codeChars.length)]).join();
      final candidate = '$_codePrefix$suffix';

      try {
        final doc = await _firestore
            .collection('tracking_codes')
            .doc(candidate)
            .get()
            .timeout(const Duration(milliseconds: 1200));
        if (!doc.exists) {
          code = candidate;
          isUnique = true;
        }
      } catch (e) {
        debugPrint('[SoldierMatch] Firestore check error: $e');
        // If offline or error, use candidate directly
        code = candidate;
        isUnique = true;
      }
    }

    if (code.isEmpty) {
      final fallbackSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      code = '$_codePrefix$fallbackSuffix';
    }

    await prefs.setString('tracking_code', code);
    return code;
  }

  /// Normalizes user-entered code (trims, uppercases, ensures SFK- prefix)
  String normalizeCode(String input) {
    String cleaned = input.trim().toUpperCase().replaceAll(' ', '');
    if (!cleaned.startsWith('SFK-')) {
      if (cleaned.startsWith('SFK')) {
        cleaned = 'SFK-${cleaned.substring(3)}';
      } else {
        cleaned = '$_codePrefix$cleaned';
      }
    }
    return cleaned;
  }

  /// Publishes or updates soldier data in Firestore under `tracking_codes/{code}`
  Future<void> publishSoldierData({
    required String trackingCode,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final codeDocRef = _firestore.collection('tracking_codes').doc(trackingCode);

      String? fcmToken;
      try {
        fcmToken = await FCMService().getSafeFCMToken();
      } catch (_) {}

      final payload = {
        'code': trackingCode,
        'userId': userId,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        'name': data['name'] ?? '',
        'surname': data['surname'] ?? '',
        'askerlik_yeri': data['askerlik_yeri'] ?? '',
        'memleket': data['memleket'] ?? '',
        'kuvvet_komutanligi': data['kuvvet_komutanligi'] ?? '',
        'sulus_tarihi': data['sulus_tarihi'] ?? '',
        'end_date': data['end_date'] ?? '',
        'duration': data['duration'] ?? 6,
        'rutbe': data['rutbe'] ?? 'ER',
        'izin': data['izin'] ?? 0,
        'ceza': data['ceza'] ?? 0,
        'yolIzni': data['yolIzni'] ?? '',
        'baba_adi': data['baba_adi'] ?? '',
        'kan_grubu': data['kan_grubu'] ?? '',
        'dini': data['dini'] ?? '',
        'tertip': data['tertip'] ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      };

      await codeDocRef.set(payload, SetOptions(merge: true));
      notifyDataChanged(pairingChanged: false);
      debugPrint('[SoldierMatch] Soldier data published for code: $trackingCode');
    } catch (e) {
      debugPrint('[SoldierMatch] Error publishing soldier data: $e');
    }
  }

  /// Ensures current soldier profile has a tracking code and is published in Firestore
  Future<void> ensureSoldierPublished() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'asker';
    if (role == 'yakin') return; // Do not publish relatives as soldiers

    final name = prefs.getString('name');
    final surname = prefs.getString('surname');
    if (name == null || surname == null) return;

    final code = await generateOrGetTrackingCode();
    final userId = prefs.getString('userId') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    await publishSoldierData(
      trackingCode: code,
      userId: userId,
      data: {
        'name': name,
        'surname': surname,
        'askerlik_yeri': prefs.getString('askerlik_yeri') ?? '',
        'memleket': prefs.getString('memleket') ?? '',
        'kuvvet_komutanligi': prefs.getString('kuvvet_komutanligi') ?? '',
        'sulus_tarihi': prefs.getString('sulus_tarihi') ?? '',
        'end_date': prefs.getString('end_date') ?? '',
        'duration': prefs.getInt('duration') ?? 6,
        'rutbe': prefs.getString('rutbe') ?? 'ER',
        'izin': prefs.getInt('izin') ?? 0,
        'ceza': prefs.getInt('ceza') ?? 0,
        'yolIzni': prefs.getString('yolIzni') ?? '',
        'baba_adi': prefs.getString('baba_adi') ?? '',
        'kan_grubu': prefs.getString('kan_grubu') ?? '',
        'dini': prefs.getString('dini') ?? '',
        'tertip': prefs.getString('tertip') ?? '',
      },
    );
  }

  /// Actively syncs current device's FCM token to tracking_codes/{code} and user_fcm_tokens
  Future<void> syncSoldierFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? 'asker';
      final trackingCode = prefs.getString('tracking_code');
      final pairedCode = prefs.getString('paired_code');
      String? userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('userId', userId);
      }

      String? fcmToken;
      try {
        fcmToken = await FCMService().getSafeFCMToken();
      } catch (_) {}

      if (fcmToken == null || fcmToken.isEmpty) return;

      final name = prefs.getString('name') ?? 'Asker';
      final surname = prefs.getString('surname') ?? '';
      final fullName = surname.isNotEmpty ? '$name $surname' : name;

      // 1. If soldier: directly update tracking_codes/{trackingCode}
      if (role == 'asker' && trackingCode != null && trackingCode.isNotEmpty) {
        final normalized = normalizeCode(trackingCode);
        await _firestore.collection('tracking_codes').doc(normalized).set({
          'fcmToken': fcmToken,
          'userId': userId,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[SoldierMatch] Synced fcmToken directly to tracking_codes/$normalized');
      }

      // 2. If relative: update followers doc in tracking_codes/{pairedCode}/followers/{userId}
      if (role == 'yakin' && pairedCode != null && pairedCode.isNotEmpty) {
        final normalized = normalizeCode(pairedCode);
        await _firestore
            .collection('tracking_codes')
            .doc(normalized)
            .collection('followers')
            .doc(userId)
            .set({
          'fcmToken': fcmToken,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[SoldierMatch] Synced fcmToken to followers under $normalized');
      }

      // 3. Always update user_fcm_tokens/{userId} with trackingCode index
      final effectiveCode = role == 'yakin' ? pairedCode : trackingCode;
      await _firestore.collection('user_fcm_tokens').doc(userId).set({
        'userId': userId,
        'token': fcmToken,
        'userName': fullName,
        'role': role,
        if (effectiveCode != null && effectiveCode.isNotEmpty) 'trackingCode': normalizeCode(effectiveCode),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SoldierMatch] Error syncing soldier FCM token: $e');
    }
  }

  /// Finds soldier by tracking code in Firestore
  Future<Map<String, dynamic>?> findSoldierByCode(String inputCode) async {
    try {
      final code = normalizeCode(inputCode);
      final doc = await _firestore.collection('tracking_codes').doc(code).get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('[SoldierMatch] Error finding soldier: $e');
      return null;
    }
  }

  /// Alias for findSoldierByCode
  Future<Map<String, dynamic>?> getSoldierByTrackingCode(String code) => findSoldierByCode(code);

  /// Pairs current user as a follower with the specified soldier code
  Future<bool> pairWithSoldier({
    String? inputCode,
    String? code,
    required String relationship,
    String? followerName,
  }) async {
    final effectiveCode = normalizeCode(inputCode ?? code ?? '');
    if (effectiveCode.isEmpty || effectiveCode == _codePrefix) {
      return false;
    }
    final soldierData = await findSoldierByCode(effectiveCode);

    if (soldierData == null) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    // 0. Back up existing manual profile fields if transitioning from manual to paired
    final bool wasAlreadyPaired = prefs.getBool('is_paired') ?? false;
    final String existingName = prefs.getString('name') ?? '';
    if (!wasAlreadyPaired && existingName.isNotEmpty) {
      await prefs.setBool('manual_backup_exists', true);
      await prefs.setString('manual_backup_name', existingName);
      await prefs.setString('manual_backup_surname', prefs.getString('surname') ?? '');
      await prefs.setString('manual_backup_askerlik_yeri', prefs.getString('askerlik_yeri') ?? '');
      await prefs.setString('manual_backup_memleket', prefs.getString('memleket') ?? '');
      await prefs.setString('manual_backup_kuvvet_komutanligi', prefs.getString('kuvvet_komutanligi') ?? '');
      await prefs.setString('manual_backup_sulus_tarihi', prefs.getString('sulus_tarihi') ?? '');
      await prefs.setString('manual_backup_end_date', prefs.getString('end_date') ?? '');
      await prefs.setInt('manual_backup_duration', prefs.getInt('duration') ?? 6);
      await prefs.setString('manual_backup_rutbe', prefs.getString('rutbe') ?? 'ER');
      await prefs.setInt('manual_backup_izin', prefs.getInt('izin') ?? 0);
      await prefs.setInt('manual_backup_ceza', prefs.getInt('ceza') ?? 0);
      await prefs.setString('manual_backup_yolIzni', prefs.getString('yolIzni') ?? '');
      await prefs.setString('manual_backup_baba_adi', prefs.getString('baba_adi') ?? '');
      await prefs.setString('manual_backup_kan_grubu', prefs.getString('kan_grubu') ?? '');
      await prefs.setString('manual_backup_dini', prefs.getString('dini') ?? '');
      await prefs.setString('manual_backup_tertip', prefs.getString('tertip') ?? '');
    }

    // 1. Copy soldier calculation fields locally into SharedPreferences
    await prefs.setString('name', (soldierData['name'] ?? '').toString());
    await prefs.setString('surname', (soldierData['surname'] ?? '').toString());
    await prefs.setString('askerlik_yeri', (soldierData['askerlik_yeri'] ?? '').toString());
    await prefs.setString('memleket', (soldierData['memleket'] ?? '').toString());
    await prefs.setString('kuvvet_komutanligi', (soldierData['kuvvet_komutanligi'] ?? '').toString());
    await prefs.setString('sulus_tarihi', (soldierData['sulus_tarihi'] ?? '').toString());
    await prefs.setString('end_date', (soldierData['end_date'] ?? '').toString());
    await prefs.setInt('duration', (soldierData['duration'] as num?)?.toInt() ?? 6);
    await prefs.setString('rutbe', (soldierData['rutbe'] ?? 'ER').toString());
    await prefs.setInt('izin', (soldierData['izin'] as num?)?.toInt() ?? 0);
    await prefs.setInt('ceza', (soldierData['ceza'] as num?)?.toInt() ?? 0);
    await prefs.setString('yolIzni', (soldierData['yolIzni'] ?? '').toString());
    await prefs.setString('baba_adi', (soldierData['baba_adi'] ?? '').toString());
    await prefs.setString('kan_grubu', (soldierData['kan_grubu'] ?? '').toString());
    await prefs.setString('dini', (soldierData['dini'] ?? '').toString());
    await prefs.setString('tertip', (soldierData['tertip'] ?? '').toString());

    // 2. Set follower role and pairing metadata
    await prefs.setString('user_role', 'yakin');
    await prefs.setString('relationship', relationship);
    await prefs.setString('paired_code', effectiveCode);
    await prefs.setBool('is_paired', true);
    if (followerName != null && followerName.trim().isNotEmpty) {
      await prefs.setString('follower_name', followerName.trim());
    }

    // Asker yakını için tüm PRO özellikleri anında ve ücretsiz aktif et
    await RevenueCatService.instance.syncUserRole('yakin');

    // Immediately notify all mounted tabs & ManagePages stream listener
    notifyDataChanged(pairingChanged: true);

    // 3. Register follower in Firestore under soldier's subcollection
    try {
      String? followerUserId = prefs.getString('userId');
      if (followerUserId == null || followerUserId.isEmpty) {
        followerUserId = 'follower_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('userId', followerUserId);
      }

      String? fcmToken;
      try {
        fcmToken = await FCMService().getSafeFCMToken();
      } catch (_) {}

      await _firestore
          .collection('tracking_codes')
          .doc(effectiveCode)
          .collection('followers')
          .doc(followerUserId)
          .set({
        'followerId': followerUserId,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        'name': (followerName != null && followerName.trim().isNotEmpty)
            ? followerName.trim()
            : (prefs.getString('follower_name') ?? 'Yakını'),
        'relationship': relationship,
        'pairedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also ensure follower user record exists in users/{followerUserId} without overwriting isPremium
      await _firestore.collection('users').doc(followerUserId).set({
        'userId': followerUserId,
        'user_role': 'yakin',
        'paired_code': effectiveCode,
        'relationship': relationship,
        'name': (followerName != null && followerName.trim().isNotEmpty)
            ? followerName.trim()
            : (prefs.getString('follower_name') ?? 'Yakını'),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update followers count
      await _firestore.collection('tracking_codes').doc(effectiveCode).update({
        'followersCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[SoldierMatch] Error registering follower in Firestore: $e');
    }

    return true;
  }

  /// Pulls the latest soldier data for the paired soldier and updates local prefs
  Future<bool> syncPairedSoldierData() async {
    final prefs = await SharedPreferences.getInstance();
    final pairedCode = prefs.getString('paired_code');
    final isPaired = prefs.getBool('is_paired') ?? false;

    if (!isPaired || pairedCode == null || pairedCode.isEmpty) {
      return false;
    }

    final soldierData = await findSoldierByCode(pairedCode);
    if (soldierData == null) return false;

    await prefs.setString('name', (soldierData['name'] ?? '').toString());
    await prefs.setString('surname', (soldierData['surname'] ?? '').toString());
    await prefs.setString('askerlik_yeri', (soldierData['askerlik_yeri'] ?? '').toString());
    await prefs.setString('memleket', (soldierData['memleket'] ?? '').toString());
    await prefs.setString('kuvvet_komutanligi', (soldierData['kuvvet_komutanligi'] ?? '').toString());
    await prefs.setString('sulus_tarihi', (soldierData['sulus_tarihi'] ?? '').toString());
    await prefs.setString('end_date', (soldierData['end_date'] ?? '').toString());
    await prefs.setInt('duration', (soldierData['duration'] as num?)?.toInt() ?? 6);
    await prefs.setString('rutbe', (soldierData['rutbe'] ?? 'ER').toString());
    await prefs.setInt('izin', (soldierData['izin'] as num?)?.toInt() ?? 0);
    await prefs.setInt('ceza', (soldierData['ceza'] as num?)?.toInt() ?? 0);
    await prefs.setString('yolIzni', (soldierData['yolIzni'] ?? '').toString());
    if (soldierData['baba_adi'] != null) {
      await prefs.setString('baba_adi', soldierData['baba_adi'].toString());
    }
    if (soldierData['kan_grubu'] != null) {
      await prefs.setString('kan_grubu', soldierData['kan_grubu'].toString());
    }
    if (soldierData['dini'] != null) {
      await prefs.setString('dini', soldierData['dini'].toString());
    }
    if (soldierData['tertip'] != null) {
      await prefs.setString('tertip', soldierData['tertip'].toString());
    }

    notifyDataChanged(pairingChanged: false);
    debugPrint('[SoldierMatch] Synced paired soldier data for $pairedCode');
    return true;
  }

  /// Realtime stream of the paired soldier's document
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToPairedSoldier(String code) {
    try {
      final normalized = normalizeCode(code);
      return _firestore.collection('tracking_codes').doc(normalized).snapshots();
    } catch (e) {
      debugPrint('[SoldierMatch] Error listening to soldier: $e');
      return const Stream.empty();
    }
  }

  /// Alias for unpair
  Future<void> unpairSoldier() => unpair();

  /// Retrieves list of followers for a soldier
  Future<List<Map<String, dynamic>>> getFollowers(String trackingCode) async {
    try {
      final snapshot = await _firestore
          .collection('tracking_codes')
          .doc(trackingCode)
          .collection('followers')
          .orderBy('pairedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[SoldierMatch] Error getting followers: $e');
      return [];
    }
  }

  /// Unpairs the follower from the soldier
  Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    final pairedCode = prefs.getString('paired_code');
    final followerUserId = prefs.getString('userId');

    // 1. Update local state first and restore pre-pair manual profile if available
    await prefs.remove('paired_code');
    await prefs.setBool('is_paired', false);

    if (prefs.getBool('manual_backup_exists') == true) {
      await prefs.setString('name', prefs.getString('manual_backup_name') ?? '');
      await prefs.setString('surname', prefs.getString('manual_backup_surname') ?? '');
      await prefs.setString('askerlik_yeri', prefs.getString('manual_backup_askerlik_yeri') ?? '');
      await prefs.setString('memleket', prefs.getString('manual_backup_memleket') ?? '');
      await prefs.setString('kuvvet_komutanligi', prefs.getString('manual_backup_kuvvet_komutanligi') ?? '');
      await prefs.setString('sulus_tarihi', prefs.getString('manual_backup_sulus_tarihi') ?? '');
      await prefs.setString('end_date', prefs.getString('manual_backup_end_date') ?? '');
      await prefs.setInt('duration', prefs.getInt('manual_backup_duration') ?? 6);
      await prefs.setString('rutbe', prefs.getString('manual_backup_rutbe') ?? 'ER');
      await prefs.setInt('izin', prefs.getInt('manual_backup_izin') ?? 0);
      await prefs.setInt('ceza', prefs.getInt('manual_backup_ceza') ?? 0);
      await prefs.setString('yolIzni', prefs.getString('manual_backup_yolIzni') ?? '');
      await prefs.setString('baba_adi', prefs.getString('manual_backup_baba_adi') ?? '');
      await prefs.setString('kan_grubu', prefs.getString('manual_backup_kan_grubu') ?? '');
      await prefs.setString('dini', prefs.getString('manual_backup_dini') ?? '');
      await prefs.setString('tertip', prefs.getString('manual_backup_tertip') ?? '');
      await prefs.setBool('manual_backup_exists', false);
    }

    // Immediately notify all mounted tabs & cancel ManagePages Firestore stream
    notifyDataChanged(pairingChanged: true);

    // 2. Remove follower record in Firestore
    if (pairedCode != null && followerUserId != null) {
      try {
        await _firestore
            .collection('tracking_codes')
            .doc(pairedCode)
            .collection('followers')
            .doc(followerUserId)
            .delete();

        await _firestore.collection('tracking_codes').doc(pairedCode).update({
          'followersCount': FieldValue.increment(-1),
        });
      } catch (e) {
        debugPrint('[SoldierMatch] Error removing follower entry: $e');
      }
    }
  }

  /// Helper to get Turkish human-readable relationship label
  static String getRelationshipLabel(String? relationship) {
    switch (relationship) {
      case 'es':
      case 'sevgili':
        return 'Eşi / Sevgilisi';
      case 'nisanli':
        return 'Nişanlısı / Sözlüsü';
      case 'aile':
        return 'Ailesi (Anne / Baba)';
      case 'kardes':
        return 'Kardeşi';
      case 'arkadas':
        return 'Arkadaşı / Devresi';
      default:
        return 'Asker Yakını';
    }
  }

  /// Helper to get relationship icon
  static IconData getRelationshipIcon(String? relationship) {
    switch (relationship) {
      case 'es':
      case 'sevgili':
      case 'nisanli':
        return Icons.favorite_rounded;
      case 'aile':
        return Icons.family_restroom_rounded;
      case 'kardes':
        return Icons.people_alt_rounded;
      case 'arkadas':
        return Icons.handshake_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }
}
