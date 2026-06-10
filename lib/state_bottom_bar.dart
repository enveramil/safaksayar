import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/pages/info.dart';
import 'package:safaksayar/pages/profile.dart';
import 'package:safaksayar/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePages extends StatefulWidget {
  const ManagePages({super.key});

  @override
  State<ManagePages> createState() => _ManagePagesState();
}

class _ManagePagesState extends State<ManagePages> {
  String _backgroundImage = 'assets/images/img0.webp'; // Varsayılan arka plan
  int _currentIndex = 0;
  bool _showChat = false;

  List<Widget> get _screens {
    return [
      const HomeScreen(),
      const InfoScreen(),
      if (_showChat) const ChatScreen(),
      const ProfileScreen()
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _loadTheme(); // Arka plan temasını yükle
      _currentIndex = index;
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('themeImage') ??
        'assets/images/img0.webp'; // Varsayılan resim
    setState(() {
      _backgroundImage = imagePath;
    });
  }

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.white,
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
          body: _screens[_currentIndex],
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 50,
                color: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onItemTapped(0),
                        child: _buildNavItem(Icons.home, 'Ana Sayfa', 0),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onItemTapped(1),
                        child: _buildNavItem(Icons.info, 'Bilgi', 1),
                      ),
                    ),
                    if (_showChat)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onItemTapped(2),
                          child: _buildNavItem(Icons.chat_bubble_outline, 'Sohbet', 2),
                        ),
                      ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onItemTapped(_showChat ? 3 : 2),
                        child: _buildNavItem(Icons.settings, 'Profil', _showChat ? 3 : 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    double iconSize = _showChat ? 22 : 26;
    double spacing = _showChat ? 4.0 : 8.0;
    double fontSize = _showChat ? 12.0 : 14.0;
    return Container(
      alignment: Alignment.center, // İçeriği ortalamak için
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // İçeriğin genişliğini içeriğe göre ayarlar
        crossAxisAlignment: CrossAxisAlignment.center, // Dikey eksende ortalar
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: _backgroundImage == 'assets/images/img0.webp'
                ? (_currentIndex == index ? Colors.black : Colors.grey[700])
                : (_currentIndex == index ? Colors.white : Colors.grey[400]),
          ),
          if (isSelected)
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: EdgeInsets.only(left: spacing),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: _backgroundImage == 'assets/images/img0.webp'
                          ? Colors.black54
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
