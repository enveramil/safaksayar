import 'package:flutter/material.dart';
import 'package:safaksayar/pages/splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePage extends StatefulWidget {
  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  String _backgroundImage = 'assets/images/default.png';
  final List<String> themes = [
    'assets/images/default.png',
    'assets/images/img1.png',
    'assets/images/img2.png',
    'assets/images/img3.png',
    'assets/images/img4.png',
    'assets/images/img5.png',
    'assets/images/img6.png',
    'assets/images/img7.png',
    'assets/images/img8.png',
    'assets/images/img9.png',
    'assets/images/img10.png',
    'assets/images/img11.png',
    'assets/images/img12.png',
    'assets/images/img13.png',
    'assets/images/img14.png',
    'assets/images/img15.png',
    'assets/images/img16.png',
    'assets/images/img17.png',
    'assets/images/img18.png',
    'assets/images/img19.png',
    'assets/images/img20.png',
    'assets/images/img21.png',
    'assets/images/img22.png',
  ];

  Future<void> _changeTheme(String newImagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeImage', newImagePath);
    setState(() {
      _backgroundImage = newImagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Temalar")),
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
            onTap: () {
              _changeTheme(imagePath);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => SplashScreen(), // Yönlendirilmek istenen sayfa
                ),
                    (route) => false, // Geriye tüm rotaları sil
              );
            },

            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
