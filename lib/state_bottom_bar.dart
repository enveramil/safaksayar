import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/pages/info.dart';
import 'package:safaksayar/pages/profile.dart';
import 'package:safaksayar/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Services/log_service.dart';
import 'Services/notification_service.dart';
import 'Services/fcm_service.dart';
import 'Services/soldier_match_service.dart';
import 'Services/revenue_cat_service.dart';
import 'pages/premium_paywall_page.dart';
import 'ads/ad_manager.dart';

class ManagePages extends StatefulWidget {
  final String? backgroundImage;
  const ManagePages({super.key, this.backgroundImage});

  @override
  State<ManagePages> createState() => _ManagePagesState();
}

class _ManagePagesState extends State<ManagePages> with WidgetsBindingObserver {
  late String _backgroundImage; // Varsayılan arka plan
  int _currentIndex = 0;
  bool _showChat = false;
  String _userRole = 'asker';
  StreamSubscription? _soldierSub;

  List<Widget> get _screens {
    return [
      HomeScreen(backgroundImage: _backgroundImage),
      InfoScreen(backgroundImage: _backgroundImage),
      if (_showChat) ChatScreen(backgroundImage: _backgroundImage),
      ProfileScreen(backgroundImage: _backgroundImage)
    ];
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      LogService.instance.onTabChange(index);

      // Forum sekmesine geçişte akıllı frekanslı video reklam kontrolü
      if (_showChat && index == 2) {
        AdManager.instance.showForumInterstitialAd();
      }

      setState(() {
        _loadTheme(); // Arka plan temasını yükle
        _currentIndex = index;
      });
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('themeImage') ??
        'assets/images/img0.webp'; // Varsayılan resim
    if (mounted) {
      setState(() {
        _backgroundImage = imagePath;
      });
    }
  }

  Future<void> _loadUserRoleAndListen() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'asker';
    final pairedCode = prefs.getString('paired_code') ?? '';
    final isPaired = prefs.getBool('is_paired') ?? false;

    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }

    _soldierSub?.cancel();
    _soldierSub = null;

    if (role == 'yakin' && isPaired && pairedCode.isNotEmpty) {
      _soldierSub = SoldierMatchService.instance.listenToPairedSoldier(pairedCode).listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final soldier = (data['soldier_data'] as Map<String, dynamic>?) ?? data;
          if (soldier.isNotEmpty) {
            final p = await SharedPreferences.getInstance();
            // Guard: ensure user is still paired to this code before applying snapshot
            if (!(p.getBool('is_paired') ?? false) || (p.getString('paired_code') ?? '') != pairedCode) {
              return;
            }
            if (soldier['name'] != null) await p.setString('name', soldier['name'].toString());
            if (soldier['surname'] != null) await p.setString('surname', soldier['surname'].toString());
            if (soldier['askerlik_yeri'] != null) await p.setString('askerlik_yeri', soldier['askerlik_yeri'].toString());
            if (soldier['memleket'] != null) await p.setString('memleket', soldier['memleket'].toString());
            if (soldier['sulus_tarihi'] != null) await p.setString('sulus_tarihi', soldier['sulus_tarihi'].toString());
            if (soldier['end_date'] != null) await p.setString('end_date', soldier['end_date'].toString());
            if (soldier['kuvvet_komutanligi'] != null) await p.setString('kuvvet_komutanligi', soldier['kuvvet_komutanligi'].toString());
            if (soldier['rutbe'] != null) await p.setString('rutbe', soldier['rutbe'].toString());
            if (soldier['duration'] != null) {
              await p.setInt('duration', (soldier['duration'] as num).toInt());
            }
            if (soldier['izin'] != null) {
              await p.setInt('izin', (soldier['izin'] as num).toInt());
            }
            if (soldier['ceza'] != null) {
              await p.setInt('ceza', (soldier['ceza'] as num).toInt());
            }
            if (soldier['yolIzni'] != null) {
              await p.setString('yolIzni', soldier['yolIzni'].toString());
            }
            if (soldier['baba_adi'] != null) {
              await p.setString('baba_adi', soldier['baba_adi'].toString());
            }
            if (soldier['kan_grubu'] != null) {
              await p.setString('kan_grubu', soldier['kan_grubu'].toString());
            }
            if (soldier['dini'] != null) {
              await p.setString('dini', soldier['dini'].toString());
            }
            if (soldier['tertip'] != null) {
              await p.setString('tertip', soldier['tertip'].toString());
            }
            SoldierMatchService.instance.notifyDataChanged(pairingChanged: false);
            if (mounted) {
              setState(() {});
            }
          }
        }
      });
    }
  }

  void _onPairingStateChanged() {
    _loadUserRoleAndListen();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundImage = widget.backgroundImage ?? 'assets/images/img0.webp';
    SoldierMatchService.instance.pairingStateVersion.addListener(_onPairingStateChanged);
    _loadTheme();
    _loadUserRoleAndListen();
    _listenToChatConfig();
    // İlk karenin sıfır gecikmeyle çizilmesi için ağır bildirim planlamasını arka plana al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService().checkPendingNotification(context);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          NotificationService().scheduleAllNotifications();
          FCMService().syncToken();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoldierMatchService.instance.pairingStateVersion.removeListener(_onPairingStateChanged);
    _soldierSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama arka plandan ön plana geldiğinde bildirimleri yenile
      NotificationService().scheduleAllNotifications();
      _loadUserRoleAndListen();
    }
  }

  void _listenToChatConfig() {
    FirebaseFirestore.instance
        .collection('parameter')
        .doc('config')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final showChatVal = data['showChat'] as bool? ?? false;
        if (showChatVal != _showChat) {
          setState(() {
            _showChat = showChatVal;
            // Adjust index if out of bounds after toggle
            if (!_showChat && _currentIndex == 2) {
              _currentIndex = 0;
            } else if (!_showChat && _currentIndex == 3) {
              _currentIndex = 2;
            }
          });
        }

        // Anlık Zorunlu PRO Ekranı kontrolü:
        // Eğer veritabanından isNecessaryProScreen == true set edilirse ve kullanıcı PRO değilse (asker yakını hariç)
        // anında zorunlu PRO ekranını önüne getir!
        final isNecessary = data['isNecessaryProScreen'] as bool? ?? false;
        if (isNecessary && !RevenueCatService.instance.isPremium && _userRole != 'yakin') {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            PremiumPaywallPage.show(context, source: 'remote_config_enforce', isGate: true);
          }
        }
      }
    });
  }

  Widget _buildAppBarTitle() {
    final bool isRelative = _userRole == 'yakin';
    String titleText = isRelative ? 'KAVUŞMA EKRANI' : 'İZLEME EKRANI';
    if (_showChat) {
      if (_currentIndex == 0) {
        titleText = isRelative ? 'KAVUŞMA EKRANI' : 'İZLEME EKRANI';
      } else if (_currentIndex == 1) {
        titleText = 'KIŞLA MERKEZİ';
      } else if (_currentIndex == 2) {
        titleText = 'ASKER FORUMU';
      } else if (_currentIndex == 3) {
        titleText = 'YÖNETİM PANELİ';
      }
    } else {
      if (_currentIndex == 0) {
        titleText = isRelative ? 'KAVUŞMA EKRANI' : 'İZLEME EKRANI';
      } else if (_currentIndex == 1) {
        titleText = 'KIŞLA MERKEZİ';
      } else if (_currentIndex == 2) {
        titleText = 'YÖNETİM PANELİ';
      }
    }
    return Text(
      titleText,
      style: TextStyle(
          color: _backgroundImage == 'assets/images/img0.webp'
              ? Colors.black
              : Colors.white,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProBadge(BuildContext context, bool isDefaultBg) {
    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, child) {
        return Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              PremiumPaywallPage.show(context, source: 'app_bar');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14.0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPremium
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isPremium ? const Color(0xFF10B981) : const Color(0xFFFFD700))
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                    size: 14,
                    color: isPremium ? Colors.white : const Color(0xFF1F1600),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPremium ? 'VIP' : 'PRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isPremium ? Colors.white : const Color(0xFF1F1600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDefaultBg = _backgroundImage == 'assets/images/img0.webp';
    final Color scaffoldBgColor = isDefaultBg ? Colors.white : const Color(0xFF0F172A);

    return Container(
      color: scaffoldBgColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            appBar: (_currentIndex == 0 || _currentIndex == 1)
                ? null
                : AppBar(
                    centerTitle: true,
                    elevation: 0,
                    scrolledUnderElevation: 0.0,
                    notificationPredicate: (ScrollNotification _) => false,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    systemOverlayStyle: isDefaultBg
                        ? SystemUiOverlayStyle.dark
                        : SystemUiOverlayStyle.light,
                    title: _buildAppBarTitle(),
                    actions: [
                      _buildProBadge(context, isDefaultBg),
                    ],
                  ),
            body: RepaintBoundary(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isDefaultBg
                        ? Colors.black.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    height: 68.0 + MediaQuery.of(context).padding.bottom,
                    decoration: BoxDecoration(
                      color: isDefaultBg
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
                      border: Border(
                        top: BorderSide(
                          color: isDefaultBg
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final int totalItems = _showChat ? 4 : 3;
                              final double totalWidth = constraints.maxWidth;
                              final double itemWidth = totalWidth / totalItems;
                              
                              final double pillWidth = _showChat ? 48.0 : 54.0;
                              final double pillHeight = 32.0;
                              final double pillTop = 11.0;
                              final double pillLeft = (_currentIndex * itemWidth) + (itemWidth - pillWidth) / 2;

                              return Stack(
                                children: [
                                  // Sliding Active Pill Background
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutBack,
                                    left: pillLeft,
                                    top: pillTop,
                                    width: pillWidth,
                                    height: pillHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDefaultBg
                                            ? Colors.black.withValues(alpha: 0.06)
                                            : Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16.0),
                                        border: Border.all(
                                          color: isDefaultBg
                                              ? Colors.black.withValues(alpha: 0.03)
                                              : Colors.white.withValues(alpha: 0.08),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Navigation Items
                                  Row(
                                    children: [
                                      _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Ana Sayfa'),
                                      _buildNavItem(1, Icons.military_tech_outlined, Icons.military_tech_rounded, 'Kışla'),
                                      if (_showChat)
                                        _buildNavItem(2, Icons.forum_outlined, Icons.forum_rounded, 'Forum'),
                                      _buildNavItem(_showChat ? 3 : 2, Icons.settings_outlined, Icons.settings_rounded, 'Profil'),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData inactiveIcon, IconData activeIcon, String label) {
    final bool isSelected = _currentIndex == index;
    
    final bool isDefaultBg = _backgroundImage == 'assets/images/img0.webp';
    final Color activeColor = isDefaultBg ? Colors.black87 : Colors.white;
    final Color inactiveColor = isDefaultBg 
        ? Colors.grey.shade600 
        : Colors.white.withValues(alpha: 0.5);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 32,
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 0.95,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: _showChat ? 20.0 : 22.0,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: _showChat ? 9.0 : 10.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
