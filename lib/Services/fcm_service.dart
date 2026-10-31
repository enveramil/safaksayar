import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/chat_page.dart';
import '../pages/millionaire/millionaire_duel_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String forumChannelId = 'forum_notifications_channel';
  static const String forumChannelName = 'Asker Forumu Bildirimleri';
  static const String forumChannelDesc = 'Forumdaki yeni konular ve yanıt bildirimleri';

  String? _pendingTopicId;
  String? _pendingDuelId;
  Map<String, dynamic>? _pendingCapsuleData;
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    _initialized = true;

    try {
      // 1. Request notification permissions
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // 2. Set foreground presentation options for Apple
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Android High Importance Channels
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          forumChannelId,
          forumChannelName,
          description: forumChannelDesc,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        const AndroidNotificationChannel capsuleChannel = AndroidNotificationChannel(
          'capsule_notifications_channel',
          'Zaman Kapsülü Bildirimleri',
          description: 'Zaman kapsülüne eklenen not, ses kaydı ve fotoğraf bildirimleri',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(channel);
        await androidPlugin?.createNotificationChannel(capsuleChannel);
      }

      // 4. Local notifications initialization for foreground display & click handling
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              final type = data['type'];
              if (type == 'calendar_capsule') {
                openCalendarCapsule(data);
              } else {
                final duelId = data['duelId'];
                if (duelId != null && duelId.toString().isNotEmpty) {
                  openDuel(duelId.toString());
                } else {
                  final topicId = data['topicId'];
                  if (topicId != null && topicId.toString().isNotEmpty) {
                    openTopic(topicId.toString());
                  }
                }
              }
            } catch (e) {
              debugPrint('[FCM] Error decoding local notification payload: $e');
            }
          }
        },
      );

      // 5. Get and register FCM token in background (do not block app startup!)
      unawaited(syncToken());

      // 6. Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _saveTokenToFirestore(newToken);
      });

      // 7. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
        final RemoteNotification? notification = message.notification;
        final Map<String, dynamic> data = message.data;

        // On iOS, setForegroundNotificationPresentationOptions(alert: true) already presents the notification.
        // Calling _showForegroundNotification on iOS causes duplicate notifications.
        if (Platform.isAndroid && notification != null) {
          _showForegroundNotification(
            title: notification.title ?? 'Asker Bildirimi',
            body: notification.body ?? '',
            payload: jsonEncode(data),
          );
        }
      });

      // 8. Notification opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification opened app from background: ${message.data}');
        final type = message.data['type'];
        if (type == 'calendar_capsule') {
          openCalendarCapsule(message.data);
        } else {
          final duelId = message.data['duelId'];
          if (duelId != null && duelId.toString().isNotEmpty) {
            openDuel(duelId.toString());
          } else {
            final topicId = message.data['topicId'];
            if (topicId != null && topicId.toString().isNotEmpty) {
              openTopic(topicId.toString());
            }
          }
        }
      });

      // 9. Notification opened from terminated state
      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] Notification launched app from terminated: ${initialMessage.data}');
        final type = initialMessage.data['type'];
        if (type == 'calendar_capsule') {
          _pendingCapsuleData = initialMessage.data;
        } else {
          final duelId = initialMessage.data['duelId'];
          if (duelId != null && duelId.toString().isNotEmpty) {
            _pendingDuelId = duelId.toString();
          } else {
            final topicId = initialMessage.data['topicId'];
            if (topicId != null && topicId.toString().isNotEmpty) {
              _pendingTopicId = topicId.toString();
            }
          }
        }
        final BuildContext? ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          checkPendingNotification(ctx);
        }
      }
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Safely waits for APNs token on iOS before calling getToken()
  Future<String?> getSafeFCMToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          // Wait up to 5 seconds for Apple APNs handshake on real iOS device
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(milliseconds: 1000));
            apnsToken = await _fcm.getAPNSToken();
            if (apnsToken != null) break;
          }
        }
        if (apnsToken == null) {
          debugPrint('[FCM] APNs token has not been set by iOS yet (Simulator or APNs pending). Skipping direct getToken.');
          return null;
        }
      }
      return await _fcm.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') {
        debugPrint('[FCM] APNs token is not set yet (iOS Simulator or APNs pending).');
      } else {
        debugPrint('[FCM] FirebaseException fetching token: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('[FCM] Error fetching token safely: $e');
      return null;
    }
  }

  /// Syncs current user's FCM token with Firestore
  Future<void> syncToken() async {
    try {
      final token = await getSafeFCMToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM] Token retrieved successfully: $token');
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error syncing token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('userId', userId);
      }

      final String name = prefs.getString('name') ?? 'Asker';
      final String surname = prefs.getString('surname') ?? '';
      final String rutbe = prefs.getString('rutbe') ?? 'ER';
      final String kuvvet = prefs.getString('kuvvet_komutanligi') ?? 'Kara';
      final String askerlikYeri = prefs.getString('askerlik_yeri') ?? '';

      final Map<String, dynamic> tokenData = {
        'userId': userId,
        'token': token,
        'userName': surname.isNotEmpty ? '$name $surname' : name,
        'rutbe': rutbe,
        'kuvvet': kuvvet,
        'askerlikYeri': askerlikYeri,
        'platform': Platform.operatingSystem,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Save to dedicated user_fcm_tokens collection
      await FirebaseFirestore.instance.collection('user_fcm_tokens').doc(userId).set(
            tokenData,
            SetOptions(merge: true),
          );

      // 2. Also save to users collection
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Also update tracking_codes if current user is a soldier or relative
      final String? trackingCode = prefs.getString('tracking_code');
      if (trackingCode != null && trackingCode.isNotEmpty) {
        await FirebaseFirestore.instance.collection('tracking_codes').doc(trackingCode).set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final String? pairedCode = prefs.getString('paired_code');
      if (pairedCode != null && pairedCode.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('tracking_codes')
            .doc(pairedCode)
            .collection('followers')
            .doc(userId)
            .set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      debugPrint('[FCM] Token successfully synced to Firestore for user: $userId');
    } catch (e) {
      debugPrint('[FCM] Error saving token to Firestore: $e');
    }
  }

  Future<void> _showForegroundNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      forumChannelId,
      forumChannelName,
      channelDescription: forumChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Directly navigates to a forum topic when notification is clicked
  void openTopic(String topicId) {
    debugPrint('[FCM] Opening topic: $topicId');
    final BuildContext? context = navigatorKey.currentContext;
    if (context != null) {
      ForumDetailScreen.openTopicById(context, topicId);
    } else {
      _pendingTopicId = topicId;
    }
  }

  /// Directly navigates to 1v1 duel room when challenge notification is clicked
  void openDuel(String duelId) {
    debugPrint('[FCM] Opening duel: $duelId');
    final BuildContext? context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MillionaireDuelPage(joinedDuelId: duelId),
        ),
      );
    } else {
      _pendingDuelId = duelId;
    }
  }

  /// Handles opening / displaying calendar capsule notification
  void openCalendarCapsule(Map<String, dynamic> data) {
    debugPrint('[FCM] Opening calendar capsule: $data');
    final BuildContext? context = navigatorKey.currentContext;
    if (context != null) {
      final senderName = data['senderName'] ?? 'Yakının';
      final dateKey = data['dateKey'] ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '💌 $senderName takvimine yeni bir zaman kapsülü kilitledi! ($dateKey)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'AÇ',
            textColor: Colors.white,
            onPressed: () {
              // User is already on HomeScreen or can view the calendar card directly
            },
          ),
        ),
      );
    } else {
      _pendingCapsuleData = data;
    }
  }

  /// Checks and opens any pending notification (e.g. after splash screen loads)
  void checkPendingNotification(BuildContext context) {
    if (_pendingCapsuleData != null) {
      final data = _pendingCapsuleData!;
      _pendingCapsuleData = null;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) {
          openCalendarCapsule(data);
        }
      });
      return;
    }

    if (_pendingDuelId != null) {
      final duelId = _pendingDuelId!;
      _pendingDuelId = null;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MillionaireDuelPage(joinedDuelId: duelId),
            ),
          );
        }
      });
      return;
    }

    if (_pendingTopicId != null) {
      final topicId = _pendingTopicId!;
      _pendingTopicId = null;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          ForumDetailScreen.openTopicById(context, topicId);
        }
      });
    }
  }
}
