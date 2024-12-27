import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/pages/splash.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'Services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  NotificationService().initNotification();
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
