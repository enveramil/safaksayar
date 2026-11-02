import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static final LogService instance = LogService._internal();
  LogService._internal();

  String? _userId;
  String? _userName;
  String? _userRole;
  String? _rutbe;
  String _currentPage = 'Açılış Ekranı';
  int _activeTabIndex = 0;
  DateTime? _pageStartTime;
  bool _isResumed = true;
  Timer? _periodicFlushTimer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Uygulamanın diğer servislerinde (FCM, RevenueCat, Eşleşme) kullanılan ana userId ile tam senkronize ol
    final String? appUserId = prefs.getString('userId') ?? prefs.getString('user_id');
    if (appUserId != null && appUserId.isNotEmpty) {
      _userId = appUserId;
      await prefs.setString('logging_user_id', appUserId);
    } else {
      _userId = prefs.getString('logging_user_id');
      if (_userId == null || _userId!.isEmpty) {
        _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('userId', _userId!);
        await prefs.setString('logging_user_id', _userId!);
      }
    }

    final String? name = prefs.getString('name');
    final String? surname = prefs.getString('surname');
    final fullName = '${name ?? ''} ${surname ?? ''}'.trim();
    if (fullName.isNotEmpty) _userName = fullName;
    _userRole = prefs.getString('user_role');
    _rutbe = prefs.getString('rutbe');

    _startPeriodicFlushTimer();
  }

  /// Harici olarak userId oluşturulduğunda LogService'i anında günceller
  void setUserId(String userId) {
    if (userId.isNotEmpty) {
      _userId = userId;
    }
  }

  /// Kullanıcı adı ve askeri bilgileri günceller
  void setUserInfo({String? name, String? surname, String? role, String? rutbe}) {
    final fullName = '${name ?? ''} ${surname ?? ''}'.trim();
    if (fullName.isNotEmpty) _userName = fullName;
    if (role != null && role.isNotEmpty) _userRole = role;
    if (rutbe != null && rutbe.isNotEmpty) _rutbe = rutbe;
  }

  void _startPeriodicFlushTimer() {
    _periodicFlushTimer?.cancel();
    // Kullanıcı aynı ekranda uzun süre kalsa bile her 40 saniyede bir harcanan süreyi Firestore'a ve panele yansıt
    _periodicFlushTimer = Timer.periodic(const Duration(seconds: 40), (_) {
      if (_isResumed && _pageStartTime != null) {
        final elapsed = DateTime.now().difference(_pageStartTime!).inSeconds;
        if (elapsed >= 10) {
          _saveTimeSpent(_currentPage, elapsed);
          _pageStartTime = DateTime.now(); // Periyodu sıfırla
        }
      }
    });
  }

  void onAppStart() {
    _pageStartTime = DateTime.now();
  }

  void onAppPause() {
    if (_pageStartTime != null && _isResumed) {
      final duration = DateTime.now().difference(_pageStartTime!).inSeconds;
      if (duration > 0) {
        _saveTimeSpent(_currentPage, duration);
      }
    }
    _isResumed = false;
  }

  void onAppResume() {
    _isResumed = true;
    _pageStartTime = DateTime.now();
  }

  void onAppExit() {
    if (_pageStartTime != null && _isResumed) {
      final duration = DateTime.now().difference(_pageStartTime!).inSeconds;
      if (duration > 0) {
        _saveTimeSpent(_currentPage, duration);
      }
    }
  }

  String _translatePageName(String pageName) {
    switch (pageName) {
      case 'SplashScreen':
        return 'Açılış Ekranı';
      case 'ManagePages':
        return 'Ana Sayfa';
      case 'UserInputPage':
        return 'Kurulum Sihirbazı';
      case 'FaqPage':
        return 'Sıkça Sorulan Sorular';
      case 'RankPage':
        return 'Rütbeler';
      case 'QuizPage':
        return 'Kim Milyoner Olmak İster';
      case 'NotesScreen':
        return 'Not Tut';
      case 'IllerPlakaScreen':
        return 'İller ve Plaka Kodları';
      case 'SafakSozleri':
        return 'Şafak Sözleri';
      case 'SafakCizelgesiPage':
        return 'Şafak Çizelgesi';
      case 'ThemePage':
        return 'Temalar';
      case 'ThemePreviewPage':
        return 'Tema Önizleme';
      case 'LiveShareSimulationPage':
        return 'Canlı Paylaşım Simülasyonu';
      case 'HomeScreen':
        return 'Ana Sayfa';
      case 'InfoScreen':
        return 'Kışla Merkezi';
      case 'ChatScreen':
        return 'Asker Forumu';
      case 'ProfileScreen':
        return 'Yönetim Paneli';
      default:
        return pageName;
    }
  }

  void onPageChange(String rawRouteName) {
    String pageName = rawRouteName;
    if (pageName == 'ManagePages' || pageName == '/') {
      pageName = _getTabName(_activeTabIndex);
    } else {
      pageName = _translatePageName(pageName);
    }
    _handlePageTransition(pageName);
  }

  void onTabChange(int tabIndex) {
    _activeTabIndex = tabIndex;
    final pageName = _getTabName(tabIndex);
    _handlePageTransition(pageName);
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Kışla Merkezi';
      case 2:
        return 'Asker Forumu';
      case 3:
        return 'Yönetim Paneli';
      default:
        return 'Ana Sayfa';
    }
  }

  void _handlePageTransition(String newPage) {
    if (_currentPage == newPage) return;

    if (_pageStartTime != null && _isResumed) {
      final duration = DateTime.now().difference(_pageStartTime!).inSeconds;
      if (duration > 0) {
        _saveTimeSpent(_currentPage, duration);
      }
    }

    _currentPage = newPage;
    _pageStartTime = DateTime.now();
  }

  Future<void> _saveTimeSpent(String page, int duration) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      
      await _firestore.collection('logs').add({
        'userId': _userId ?? 'bilinmeyen_kullanıcı',
        if (_userName != null && _userName!.isNotEmpty) 'userName': _userName,
        if (_userRole != null && _userRole!.isNotEmpty) 'userRole': _userRole,
        if (_rutbe != null && _rutbe!.isNotEmpty) 'rutbe': _rutbe,
        'timestamp': timestamp,
        'eventType': 'süre_harcandı',
        'pageName': page,
        'duration': duration,
      });

      final pageRef = _firestore.collection('page_stats').doc(page);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(pageRef);
        int totalSeconds = duration;
        if (doc.exists) {
          final current = doc.data()?['totalSeconds'] as int? ?? 0;
          totalSeconds = current + duration;
        }

        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;

        List<String> parts = [];
        if (hours > 0) parts.add('$hours saat');
        if (minutes > 0) parts.add('$minutes dakika');
        if (seconds > 0 || parts.isEmpty) parts.add('$seconds saniye');
        final formatted = parts.join(' ');

        transaction.set(pageRef, {
          'pageName': page,
          'totalSeconds': totalSeconds,
          'totalDuration': formatted,
          'lastUpdated': timestamp,
        }, SetOptions(merge: true));
      });

      // 3. Kullanıcının users/{userId} tablosundaki günlük ve toplam ekran süresini artır
      if (_userId != null && _userId!.isNotEmpty) {
        unawaited(
          _firestore.collection('users').doc(_userId).set({
            'todayScreenTimeSeconds': FieldValue.increment(duration),
            'totalScreenTimeSeconds': FieldValue.increment(duration),
            'lastActiveAt': timestamp,
            'updatedAt': timestamp,
            'favoriteModule': page,
            if (_userName != null && _userName!.isNotEmpty) 'name': _userName,
            if (_userRole != null && _userRole!.isNotEmpty) 'user_role': _userRole,
            if (_rutbe != null && _rutbe!.isNotEmpty) 'rutbe': _rutbe,
          }, SetOptions(merge: true)),
        );
      }

    } catch (e) {
      debugPrint('Firestore logging error: $e');
    }
  }

  void onGlobalTap(PointerDownEvent event) {
    Future.microtask(() {
      try {
        final String tappedItem = _getTappedElementName(event);
        _saveClick(_currentPage, tappedItem);
      } catch (e) {
        debugPrint('Error in global tap log: $e');
      }
    });
  }

  Future<void> _saveClick(String page, String elementId) async {
    try {
      await _firestore.collection('logs').add({
        'userId': _userId ?? 'bilinmeyen_kullanıcı',
        if (_userName != null && _userName!.isNotEmpty) 'userName': _userName,
        if (_userRole != null && _userRole!.isNotEmpty) 'userRole': _userRole,
        if (_rutbe != null && _rutbe!.isNotEmpty) 'rutbe': _rutbe,
        'timestamp': FieldValue.serverTimestamp(),
        'eventType': 'tıklama',
        'pageName': page,
        'elementId': elementId,
      });
    } catch (e) {
      debugPrint('Firestore click logging error: $e');
    }
  }

  String _getTappedElementName(PointerDownEvent event) {
    try {
      final HitTestResult result = HitTestResult();
      WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);

      for (final entry in result.path) {
        final target = entry.target;
        if (target is RenderParagraph) {
          final text = target.text.toPlainText().trim();
          if (text.isNotEmpty) {
            return text.length > 40 ? '${text.substring(0, 40)}...' : text;
          }
        }
      }
    } catch (e) {
      debugPrint('Error hit testing: $e');
    }

    return 'tıklama_konumu_(${event.position.dx.toInt()}, ${event.position.dy.toInt()})';
  }

  Future<Map<String, dynamic>> getUserStats() async {
    int totalDuration = 0;
    int totalClicks = 0;
    Map<String, int> pageDurations = {};

    try {
      if (_userId == null) {
        await init();
      }
      
      final querySnapshot = await _firestore
          .collection('logs')
          .where('userId', isEqualTo: _userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final eventType = data['eventType'] as String?;
        if (eventType == 'süre_harcandı') {
          final duration = data['duration'] as int? ?? 0;
          totalDuration += duration;
          final pageName = data['pageName'] as String? ?? 'Bilinmeyen';
          pageDurations[pageName] = (pageDurations[pageName] ?? 0) + duration;
        } else if (eventType == 'tıklama') {
          totalClicks += 1;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
    }

    String mostVisitedPage = 'Ana Sayfa';
    int maxDuration = 0;
    pageDurations.forEach((page, duration) {
      if (duration > maxDuration) {
        maxDuration = duration;
        mostVisitedPage = page;
      }
    });

    return {
      'totalDuration': totalDuration,
      'totalClicks': totalClicks,
      'mostVisitedPage': mostVisitedPage,
    };
  }
}
