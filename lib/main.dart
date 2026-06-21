import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:safaksayar/pages/splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'Services/notification_service.dart';
import 'Services/log_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.setAppGroupId('group.com.bayesa.ios.safaksayar2026');
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  await AdManager.fetchAdConfig();
  await NotificationService().init();
  await NotificationService().requestPermissions();
  await LogService.instance.init();
  LogService.instance.onAppStart();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Status Bar rengi

    systemNavigationBarColor: Colors.transparent, // Navigation Bar rengi
  ));
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class AppLifecycleAndClickTracker extends StatefulWidget {
  final Widget child;
  const AppLifecycleAndClickTracker({super.key, required this.child});

  @override
  State<AppLifecycleAndClickTracker> createState() => _AppLifecycleAndClickTrackerState();
}

class _AppLifecycleAndClickTrackerState extends State<AppLifecycleAndClickTracker> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      LogService.instance.onAppPause();
    } else if (state == AppLifecycleState.resumed) {
      LogService.instance.onAppResume();
    } else if (state == AppLifecycleState.detached) {
      LogService.instance.onAppExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        LogService.instance.onGlobalTap(event);
      },
      child: widget.child,
    );
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name != null) {
      LogService.instance.onPageChange(name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final name = previousRoute?.settings.name;
    if (name != null) {
      LogService.instance.onPageChange(name);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final name = newRoute?.settings.name;
    if (name != null) {
      LogService.instance.onPageChange(name);
    }
  }
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
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('tr', 'TR'), // Türkçe desteği
      ],
      home: SplashScreen(),
      navigatorObservers: [AppNavigatorObserver()],
      builder: (context, child) {
        return AppLifecycleAndClickTracker(child: child!);
      },
    );
  }
}
