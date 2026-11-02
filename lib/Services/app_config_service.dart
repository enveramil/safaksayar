import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Remote Configuration & Parameters Service.
/// Synchronizes Firestore `parameter/config` real-time with the local device.
class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  static const String _docCollection = 'parameter';
  static const String _docId = 'config';
  static const String _prefKeyIsNecessaryPro = 'isNecessaryProScreen';

  StreamSubscription<DocumentSnapshot>? _subscription;
  final StreamController<bool> _necessaryProController =
      StreamController<bool>.broadcast();

  bool _isNecessaryProScreen = false;
  bool _showChat = true;
  bool _isDev = false;
  bool _isInitialized = false;

  /// Whether the PRO paywall screen is mandatory (hard paywall gatekeeper).
  /// If `true`: Users cannot bypass the paywall without an active PRO subscription.
  /// If `false`: An "X" (close) button is visible, allowing free usage.
  bool get isNecessaryProScreen => _isNecessaryProScreen;

  bool get showChat => _showChat;
  bool get isDev => _isDev;
  bool get isInitialized => _isInitialized;

  /// Broadcast stream that emits whenever `isNecessaryProScreen` changes in real-time.
  Stream<bool> get onNecessaryProScreenChanged =>
      _necessaryProController.stream;

  /// Initializes the service:
  /// 1. Reads cached configuration from SharedPreferences immediately.
  /// 2. Attaches a real-time Firestore listener to `parameter/config`.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isNecessaryProScreen = prefs.getBool(_prefKeyIsNecessaryPro) ?? false;
      debugPrint(
        '[AppConfigService] Loaded cached isNecessaryProScreen: $_isNecessaryProScreen',
      );
    } catch (e) {
      debugPrint('[AppConfigService] Error reading cached config: $e');
    }

    _listenToRemoteConfig();
    _isInitialized = true;
  }

  void _listenToRemoteConfig() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection(_docCollection)
        .doc(_docId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return;
        final data = snapshot.data()!;

        // 1. isNecessaryProScreen
        if (data.containsKey('isNecessaryProScreen')) {
          final bool newNecessaryVal =
              data['isNecessaryProScreen'] as bool? ?? false;
          if (newNecessaryVal != _isNecessaryProScreen) {
            _isNecessaryProScreen = newNecessaryVal;
            _cacheBoolean(_prefKeyIsNecessaryPro, newNecessaryVal);
            _necessaryProController.add(newNecessaryVal);
            debugPrint(
              '[AppConfigService] Realtime update -> isNecessaryProScreen: $_isNecessaryProScreen',
            );
          }
        }

        // 2. showChat
        if (data.containsKey('showChat')) {
          _showChat = data['showChat'] as bool? ?? true;
        }

        // 3. isDev
        if (data.containsKey('isDev')) {
          _isDev = data['isDev'] as bool? ?? false;
        }
      },
      onError: (error) {
        debugPrint('[AppConfigService] Firestore listen error: $error');
      },
    );
  }

  Future<void> _cacheBoolean(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('[AppConfigService] Error caching $key: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _necessaryProController.close();
  }
}

