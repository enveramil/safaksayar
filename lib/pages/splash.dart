import 'package:flutter/material.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/onboarding_showcase_page.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkIfUserDataExists(); // Verileri kontrol et
  }

  // Verilerin SharedPreferences'ta olup olmadığını kontrol et
  Future<void> _checkIfUserDataExists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // 1. Show cinematic onboarding once upon fresh launch
    if (!onboardingCompleted) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'OnboardingShowcasePage'),
          builder: (context) => const OnboardingShowcasePage(),
        ),
      );
      return;
    }

    String? name = prefs.getString('name');
    String? surname = prefs.getString('surname');
    String? askerlikYeri = prefs.getString('askerlik_yeri');
    String? memleket = prefs.getString('memleket');
    String themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';

    if (name != null &&
        surname != null &&
        askerlikYeri != null &&
        memleket != null) {
      final role = prefs.getString('user_role') ?? 'asker';
      if (role == 'asker') {
        SoldierMatchService.instance.ensureSoldierPublished();
      } else if (role == 'yakin' && (prefs.getBool('is_paired') ?? false)) {
        SoldierMatchService.instance.syncPairedSoldierData();
      }

      // Eğer veriler mevcutsa ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ManagePages'),
          builder: (context) => ManagePages(backgroundImage: themeImage),
        ),
      );
    } else {
      // Eğer veri yoksa kullanıcıyı Karşılama & Rol Seçim sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'WelcomeRolePage'),
          builder: (context) => const WelcomeRolePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Image.asset(
          'assets/images/app_logo.png',
          width: 96,
          height: 96,
        ),
      ),
    );
  }
}
