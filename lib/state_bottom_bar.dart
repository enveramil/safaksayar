import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/pages/info.dart';
import 'package:safaksayar/pages/profile.dart';
import 'package:safaksayar/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePages extends StatefulWidget {
  final String? backgroundImage;
  const ManagePages({super.key, this.backgroundImage});

  @override
  State<ManagePages> createState() => _ManagePagesState();
}

class _ManagePagesState extends State<ManagePages> {
  late String _backgroundImage; // Varsayılan arka plan
  int _currentIndex = 0;
  bool _showChat = false;

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

  @override
  void initState() {
    super.initState();
    _backgroundImage = widget.backgroundImage ?? 'assets/images/img0.webp';
    _loadTheme();
    _listenToChatConfig();
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
      }
    });
  }

  Widget _buildAppBarTitle() {
    String titleText = 'İZLEME EKRANI';
    if (_showChat) {
      if (_currentIndex == 0) {
        titleText = 'İZLEME EKRANI';
      } else if (_currentIndex == 1) {
        titleText = 'BİLGİLENDİRME EKRANI';
      } else if (_currentIndex == 2) {
        titleText = 'ASKER SOHBET';
      } else if (_currentIndex == 3) {
        titleText = 'YÖNETİM PANELİ';
      }
    } else {
      if (_currentIndex == 0) {
        titleText = 'İZLEME EKRANI';
      } else if (_currentIndex == 1) {
        titleText = 'BİLGİLENDİRME EKRANI';
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

  @override
  Widget build(BuildContext context) {
    final bool isDefaultBg = _backgroundImage == 'assets/images/img0.webp';
    final Color scaffoldBgColor = isDefaultBg ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImage), // Arka plan resmi
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, // Arka plan görünür kalsın
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            systemOverlayStyle: _backgroundImage == 'assets/images/img0.webp'
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            title: _buildAppBarTitle(),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: _backgroundImage == 'assets/images/img0.webp'
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
                    color: _backgroundImage == 'assets/images/img0.webp'
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.35),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
                    border: Border(
                      top: BorderSide(
                        color: _backgroundImage == 'assets/images/img0.webp'
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
                                      color: _backgroundImage == 'assets/images/img0.webp'
                                          ? Colors.black.withValues(alpha: 0.06)
                                          : Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: _backgroundImage == 'assets/images/img0.webp'
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
                                    _buildNavItem(1, Icons.info_outline_rounded, Icons.info_rounded, 'Bilgi'),
                                    if (_showChat)
                                      _buildNavItem(2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Sohbet'),
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
