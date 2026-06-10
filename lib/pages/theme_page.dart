import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/pages/splash.dart'; // SplashScreen import edildi.

class ThemePage extends StatefulWidget {
  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  String _backgroundImage = 'assets/images/img0.webp';
  final List<String> themes = [
    for (int i = 0; i <= 29; i++) 'assets/images/img$i.webp'
  ];

  Future<void> _changeTheme(String newImagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeImage', newImagePath);
    setState(() {
      _backgroundImage = newImagePath;
    });

    // SplashScreen'e yönlendir ve önceki sayfaları temizle
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
      (route) => false, // Tüm rotaları sil
    );
  }

  @override
  void initState() {
    super.initState();
    imageCache.clear();
    imageCache.maximumSize = 50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Temalar"),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final imagePath = themes[index];
          return GestureDetector(
            onTap: () => _changeTheme(imagePath),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  cacheHeight: 200, // Bellek optimizasyonu
                  cacheWidth: 200,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
