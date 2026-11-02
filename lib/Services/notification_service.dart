import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'safak_daily_channel';
  static const String _channelName = 'Günlük Şafak Bildirimi';
  static const String _channelDesc =
      'Kalan askerlik gününüzü her gün hatırlatan bildirimler';

  // SharedPreferences keys for notification time
  static const String _prefHour = 'notif_hour';
  static const String _prefMinute = 'notif_minute';
  static const int _defaultHour = 21;
  static const int _defaultMinute = 0;

  // iOS allows max 64 pending notifications; we use 60 to be safe
  static const int _maxNotifications = 60;

  bool _initialized = false;
  Future<void>? _initFuture;

  // ── Init ─────────────────────────────────────────────────────────────────

  /// Initializes timezone data and the notifications plugin.
  /// Call this once at app startup.
  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    // Load all timezone definitions
    tzdata.initializeTimeZones();

    // Set local timezone
    final String localTz = _detectTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    // Android: use app icon for notification
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS: izin istemeyi FCMService'e bırak (çift izin modalını önle), ön planda sunumu aktif tut
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // ✅ These make notifications appear even when app is open (foreground)
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTappedBackground,
    );

    // ✅ Android: create notification channel with high importance
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );
    }
    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {}

  void _onNotificationTapped(NotificationResponse response) {}

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Requests notification permissions.
  Future<bool> requestPermissions() async {
    await init();
    bool granted = false;

    if (Platform.isIOS) {
      final bool? result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      granted = result ?? false;
    } else if (Platform.isAndroid) {
      final bool? result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      granted = result ?? false;
    }

    print('[NotificationService] İzin durumu: $granted');
    return granted;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Cancels ALL pending notifications and reschedules for the next N days.
  /// ✅ Includes TODAY if the notification time hasn't passed yet.
  /// Call this every time the app opens or resumes foreground.
  Future<void> scheduleAllNotifications() async {
    await init();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? endDateStr = prefs.getString('end_date');
    final String? sulusDateStr = prefs.getString('sulus_tarihi');

    if (endDateStr == null || sulusDateStr == null) {
      print('[NotificationService] Kullanıcı verisi yok, bildirim planlanmadı.');
      return;
    }

    DateTime endDate;
    try {
      endDate = DateTime.parse(endDateStr);
    } catch (e) {
      print('[NotificationService] Tarih parse hatası: $e');
      return;
    }

    // Cancel all first
    await _plugin.cancelAll();

    final tz.TZDateTime nowTZ = tz.TZDateTime.now(tz.local);

    // Already discharged?
    if (nowTZ.isAfter(tz.TZDateTime.from(endDate, tz.local))) {
      print('[NotificationService] Terhis olmuş, bildirim planlanmadı.');
      return;
    }

    final int hour = prefs.getInt(_prefHour) ?? _defaultHour;
    final int minute = prefs.getInt(_prefMinute) ?? _defaultMinute;

    final int totalRemainingDays =
        endDate.difference(DateTime.now()).inDays + 1; // +1 to include today
    final int daysToSchedule =
        totalRemainingDays.clamp(0, _maxNotifications);

    int scheduled = 0;

    // ✅ Loop starts at i=0 (today). If today's time already passed, the
    //    isBefore check below will skip it automatically.
    for (int i = 0; i < daysToSchedule; i++) {
      final DateTime targetDay = DateTime.now().add(Duration(days: i));

      final tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local,
        targetDay.year,
        targetDay.month,
        targetDay.day,
        hour,
        minute,
        0,
      );

      // ✅ Skip past times (but allow up to 5 seconds in the past to handle
      //    same-minute scheduling edge case)
      if (scheduledTime.isBefore(nowTZ.subtract(const Duration(seconds: 5)))) {
        continue;
      }

      final int remainingOnThatDay =
          endDate.difference(targetDay).inDays;

      final String userRole = prefs.getString('user_role') ?? 'asker';
      final bool isRelative = userRole == 'yakin';
      final String title = isRelative ? '💕 Şafak Sayar' : '🪖 Şafak Sayar';
      final String body = _buildMessage(remainingOnThatDay, isRelative: isRelative);

      await _plugin.zonedSchedule(
        i, // notification ID = day offset (0 = today, 1 = tomorrow, ...)
        title,
        body,
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );

      scheduled++;
    }

    await prefs.setString(
        'last_notif_schedule', DateTime.now().toIso8601String());

    print('[NotificationService] ✅ $scheduled bildirim planlandı '
        '(saat: ${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")})');
  }

  /// ✅ Shows an INSTANT (immediate) notification for testing.
  Future<void> showTestNotification() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? endDateStr = prefs.getString('end_date');
    final String userRole = prefs.getString('user_role') ?? 'asker';
    final bool isRelative = userRole == 'yakin';
    int remaining = 0;
    if (endDateStr != null) {
      try {
        remaining = DateTime.parse(endDateStr).difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    await _plugin.show(
      999,
      isRelative ? '💕 Şafak Sayar — Test' : '🪖 Şafak Sayar — Test',
      _buildMessage(remaining, isRelative: isRelative),
      _notificationDetails(),
    );
    print('[NotificationService] Test bildirimi gönderildi.');
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    print('[NotificationService] Tüm bildirimler iptal edildi.');
  }

  /// Shows an instant local notification when a new capsule is received from the other party
  Future<void> showInstantCapsuleNotification({
    required String senderName,
    required String senderRole,
    required String dateKey,
    bool hasAudio = false,
    bool hasImage = false,
    bool hasNote = false,
  }) async {
    try {
      final notifId = (DateTime.now().millisecondsSinceEpoch % 100000) + 40000;
      final title = senderRole == 'yakin'
          ? '💌 $senderName Takvime Zaman Kapsülü Bıraktı!'
          : '🎖️ Askerin $senderName Takvime Anı Bıraktı!';

      String body;
      if (hasAudio && hasImage) {
        body = '🎙️📸 Sana özel sesli mesaj ve fotoğraf bıraktı! ($dateKey) 🔒';
      } else if (hasAudio) {
        body = '🎙️ Sana özel sesli bir mesaj kaydetti! ($dateKey) 🔒';
      } else if (hasImage) {
        body = '📸 Sana özel bir fotoğraf ve anı bıraktı! ($dateKey) 🔒';
      } else if (hasNote) {
        body = '📝 Sana özel yeni bir mektup bıraktı! ($dateKey) 🔒';
      } else {
        body = 'Takviminde sana özel yeni bir zaman kapsülü kilitledi! ($dateKey) 🔒';
      }

      await _plugin.show(
        notifId,
        title,
        body,
        _notificationDetails(),
        payload: jsonEncode({
          'type': 'calendar_capsule',
          'dateKey': dateKey,
          'senderName': senderName,
        }),
      );
      debugPrint('[NotificationService] Instant capsule notification displayed: $title');
    } catch (e) {
      debugPrint('[NotificationService] Error showing instant capsule notification: $e');
    }
  }

  /// Schedules a reminder notification for when a time capsule unlocks (on targetDate at 09:00 AM)
  Future<void> scheduleCapsuleUnlockNotification({
    required String capsuleId,
    required String senderName,
    required String dateKey, // 'YYYY-MM-DD'
  }) async {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final tz.TZDateTime nowTZ = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local,
        year,
        month,
        day,
        9, // 09:00 AM
        0,
        0,
      );

      // If 09:00 on that day already passed and today is the target day, schedule for now + 2 seconds
      if (scheduledTime.isBefore(nowTZ)) {
        final todayNormalized = DateTime(nowTZ.year, nowTZ.month, nowTZ.day);
        final targetNormalized = DateTime(year, month, day);
        if (todayNormalized.isAtSameMomentAs(targetNormalized)) {
          scheduledTime = nowTZ.add(const Duration(seconds: 2));
        } else {
          return; // Past date, do not schedule
        }
      }

      final notifId = (capsuleId.hashCode.abs() % 100000) + 30000;
      final title = '🎉 Zaman Kapsülünün Kilidi Açıldı!';
      final body = '💌 $senderName tarafından senin için bırakılan zaman kapsülü mesajı açıldı! Görmek için dokun.';

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        payload: jsonEncode({
          'type': 'calendar_capsule_unlocked',
          'capsuleId': capsuleId,
          'dateKey': dateKey,
          'senderName': senderName,
        }),
      );
      debugPrint('[NotificationService] Scheduled capsule unlock notification for $dateKey at ${scheduledTime.toString()} (ID: $notifId)');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling capsule unlock: $e');
    }
  }

  /// Returns count of pending notifications (for debug).
  Future<int> pendingCount() async {
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    print('[NotificationService] Bekleyen bildirim sayısı: ${pending.length}');
    for (final p in pending) {
      print('  → ID=${p.id} title="${p.title}" body="${p.body}"');
    }
    return pending.length;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
        // ✅ Show heads-up notification banner on Android
        fullScreenIntent: false,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        // ✅ These ensure foreground notifications are shown on iOS
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _buildMessage(int remainingDays, {bool isRelative = false}) {
    if (isRelative) {
      if (remainingDays <= 0) {
        return 'Büyük kavuşma günü geldi çattı! Gözünüz aydın! 🎉💕';
      } else if (remainingDays == 1) {
        return 'Kavuşmaya son 1 gün! Yarın büyük kavuşma! 💕🔥';
      } else if (remainingDays <= 7) {
        return 'Kavuşmaya $remainingDays gün kaldı! Sabırsızlıkla beklenen an çok yakın! 💕';
      } else if (remainingDays <= 30) {
        return 'Kavuşmaya $remainingDays gün kaldı! Günler hızla tükeniyor! ✨';
      } else {
        return 'Kavuşmaya $remainingDays gün kaldı! Sevgi ve sabırla beklemeye devam! 💕';
      }
    }
    if (remainingDays <= 0) {
      return 'Terhis! Hayırlı uğurlu olsun, asker! 🎉';
    } else if (remainingDays == 1) {
      return 'Yarın terhis! Son gece, dayanabilirsin! 🔥';
    } else if (remainingDays <= 7) {
      return '$remainingDays gün kaldı! Son birkaç gün, bitmek üzere! 🔥';
    } else if (remainingDays <= 30) {
      return '$remainingDays gün kaldı! Işık görünüyor artık! ✨';
    } else if (remainingDays <= 90) {
      return '$remainingDays gün kaldı! Sayıyoruz, yaklaşıyoruz! 💪';
    } else {
      return '$remainingDays gün kaldı! Dayanmak lazım, devam! 🪖';
    }
  }

  /// Detects the local IANA timezone name from the device's UTC offset.
  String _detectTimezone() {
    try {
      final Duration offset = DateTime.now().timeZoneOffset;
      final int hours = offset.inHours;

      // Common timezones — Turkey is always +3 (no DST)
      if (hours == 3) return 'Europe/Istanbul';
      if (hours == 0) return 'Europe/London';
      if (hours == 1) return 'Europe/Berlin';
      if (hours == 2) return 'Europe/Athens';
      if (hours == 4) return 'Asia/Dubai';
      if (hours == -3) return 'America/Sao_Paulo';
      if (hours == -5) return 'America/New_York';
      if (hours == -6) return 'America/Chicago';
      if (hours == -7) return 'America/Denver';
      if (hours == -8) return 'America/Los_Angeles';
      if (hours == 5) return 'Asia/Karachi';
      if (hours == 6) return 'Asia/Dhaka';
      if (hours == 8) return 'Asia/Shanghai';
      if (hours == 9) return 'Asia/Tokyo';
    } catch (_) {}
    return 'Europe/Istanbul'; // safe default
  }

  // ── Preference accessors ──────────────────────────────────────────────────

  static Future<int> getSavedHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefHour) ?? _defaultHour;
  }

  static Future<int> getSavedMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefMinute) ?? _defaultMinute;
  }

  /// Saves new time preference and immediately reschedules all notifications.
  Future<void> saveNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHour, hour);
    await prefs.setInt(_prefMinute, minute);
    await scheduleAllNotifications();
    await pendingCount(); // debug log
  }
}
