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
  String _backgroundImage = 'assets/images/default.png'; // Varsayılan arka plan
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
    final imagePath = prefs.getString('themeImage') ?? 'assets/images/default.png'; // Varsayılan resim
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
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            systemOverlayStyle: _backgroundImage == 'assets/images/default.png' ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
            title: _currentIndex == 0
                ? Text('İZLEME EKRANI' ,style: TextStyle(color: _backgroundImage == 'assets/images/default.png' ? Colors.black : Colors.white, fontWeight: FontWeight.bold),)
                : _currentIndex == 1
                ? Text('BİLGİLENDİRME EKRANI',style: TextStyle(color: _backgroundImage == 'assets/images/default.png' ? Colors.black : Colors.white, fontWeight: FontWeight.bold),)
                : Text('YÖNETİM PANELİ', style: TextStyle(color: _backgroundImage == 'assets/images/default.png' ? Colors.black : Colors.white, fontWeight: FontWeight.bold),),
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 'Ana Sayfa', 0),
                    _buildNavItem(Icons.info, 'Bilgi', 1),
                    _buildNavItem(Icons.settings, 'Profil', 2),
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
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Row(
        children: [
          Icon(
            icon,
            size: 36,
            color: _backgroundImage == 'assets/images/default.png'
                ? (_currentIndex == index ? Colors.black : Colors.grey[700])
                : (_currentIndex == index ? Colors.white : Colors.grey[400]),
          ),

          Visibility(
            visible: _currentIndex == index,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: const BoxConstraints(minWidth: 60), // Minimum genişlik
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: TextStyle(color: _backgroundImage == 'assets/images/default.png' ?  Colors.black54 : Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
