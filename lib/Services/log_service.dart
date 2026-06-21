import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static final LogService instance = LogService._internal();
  LogService._internal();

  String? _userId;
  String _currentPage = 'Açılış Ekranı';
  int _activeTabIndex = 0;
  DateTime? _pageStartTime;
  bool _isResumed = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('logging_user_id');
    if (_userId == null) {
      _userId = 'kullanici_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().microsecond % 100))).toInt()}';
      await prefs.setString('logging_user_id', _userId!);
    }
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
      case 'HomeScreen':
        return 'Ana Sayfa';
      case 'InfoScreen':
        return 'Bilgi Ekranı';
      case 'ChatScreen':
        return 'Asker Sohbet';
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
        return 'Bilgi Ekranı';
      case 2:
        return 'Asker Sohbet';
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

    } catch (e) {
      debugPrint('Firestore logging error: $e');
    }
  }

  void onGlobalTap(PointerDownEvent event) {
    final String tappedItem = _getTappedElementName(event);
    _saveClick(_currentPage, tappedItem);
  }

  Future<void> _saveClick(String page, String elementId) async {
    try {
      await _firestore.collection('logs').add({
        'userId': _userId ?? 'bilinmeyen_kullanıcı',
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
            return text.length > 40 ? text.substring(0, 40) + '...' : text;
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
