import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/pages/info.dart';
import 'package:safaksayar/pages/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagePages extends StatefulWidget {
  const ManagePages({super.key});

  @override
  State<ManagePages> createState() => _ManagePagesState();
}

class _ManagePagesState extends State<ManagePages> {
  String _backgroundImage = 'assets/images/img0.png'; // Varsayılan arka plan
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const InfoScreen(),
    const ProfileScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _loadTheme(); // Arka plan temasını yükle
      _currentIndex = index;
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('themeImage') ??
        'assets/images/img0.png'; // Varsayılan resim
    setState(() {
      _backgroundImage = imagePath;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
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
            systemOverlayStyle: _backgroundImage == 'assets/images/img0.png'
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            title: _currentIndex == 0
                ? Text(
                    'İZLEME EKRANI',
                    style: TextStyle(
                        color: _backgroundImage == 'assets/images/img0.png'
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold),
                  )
                : _currentIndex == 1
                    ? Text(
                        'BİLGİLENDİRME EKRANI',
                        style: TextStyle(
                            color: _backgroundImage == 'assets/images/img0.png'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold),
                      )
                    : Text(
                        'YÖNETİM PANELİ',
                        style: TextStyle(
                            color: _backgroundImage == 'assets/images/img0.png'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
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
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onItemTapped(2),
                        child: _buildNavItem(Icons.settings, 'Profil', 2),
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
            size: 26,
            color: _backgroundImage == 'assets/images/img0.png'
                ? (_currentIndex == index ? Colors.black : Colors.grey[700])
                : (_currentIndex == index ? Colors.white : Colors.grey[400]),
          ),
          Visibility(
            visible: isSelected,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: _backgroundImage == 'assets/images/img0.png'
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
