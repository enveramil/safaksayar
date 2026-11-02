import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/pages/onboarding_showcase_page.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/pages/splash.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Services/notification_service.dart';
import 'Services/log_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Services/fcm_service.dart';
import 'Services/revenue_cat_service.dart';
import 'Services/soldier_match_service.dart';
import 'Services/app_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Yalnızca yerel, milisaniyelik kritik çekirdeği paralel başlat (~30-50ms)
  final coreInit = await Future.wait<dynamic>([
    Firebase.initializeApp(),
    SharedPreferences.getInstance(),
    initializeDateFormatting('tr_TR', null),
  ]);

  final SharedPreferences prefs = coreInit[1] as SharedPreferences;
  SoldierMatchService.instance.cachedPrefs = prefs;

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Önbellekteki PRO durumunu ilk kare çizilmeden önce senkron yükle (0ms gecikme)
  RevenueCatService.instance.primeFromPrefs(prefs);
  LogService.instance.onAppStart();

  // Ara beyaz Splash ekranında beklemek yerine doğrudan hedef ekranı ilk karede çiz
  final Widget initialScreen = _resolveInitialScreen(prefs);

  runApp(MyApp(initialScreen: initialScreen));

  // Tüm ağ, bildirim izni, FCM token ve SDK işlemlerini ilk kare çizildikten sonra arka planda çalıştır
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrapBackgroundServices(prefs));
  });
}

Widget _resolveInitialScreen(SharedPreferences prefs) {
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  if (!onboardingCompleted) {
    return const OnboardingShowcasePage();
  }

  final String? name = prefs.getString('name');
  final String? surname = prefs.getString('surname');
  final String? askerlikYeri = prefs.getString('askerlik_yeri');
  final String? memleket = prefs.getString('memleket');

  if (name != null &&
      surname != null &&
      askerlikYeri != null &&
      memleket != null) {
    // Dinamik PRO Kapısı Kontrolü:
    // Firestore'da isNecessaryProScreen == true ise, PRO olmayan kullanıcılar uygulamayı kullanamaz.
    // isNecessaryProScreen == false ise veya kullanıcı PRO/yakın ise ücretsiz kullanabilir.
    final bool isPremium = prefs.getBool('is_premium_active') ?? false;
    final String? userRole = prefs.getString('user_role');
    final bool isRelative = userRole == 'yakin';
    final bool isNecessaryPro = prefs.getBool('isNecessaryProScreen') ?? false;

    if (!isPremium && !isRelative && isNecessaryPro) {
      return const PremiumPaywallPage(source: 'app_launch_gate', isGate: true);
    }

    final String themeImage =
        prefs.getString('themeImage') ?? 'assets/images/img0.webp';
    return ManagePages(backgroundImage: themeImage);
  }

  return const WelcomeRolePage();
}

Future<void> _bootstrapBackgroundServices(SharedPreferences prefs) async {
  unawaited(HomeWidget.setAppGroupId('group.com.bayesa.ios.safaksayar2026'));
  unawaited(MobileAds.instance.initialize());
  unawaited(LogService.instance.init());
  unawaited(RevenueCatService.instance.init());
  unawaited(AppConfigService.instance.init());
  unawaited(AdManager.fetchAdConfig());

  // Onboarding tamamlanmamışsa bildirim izni isteme; onboarding tamamlandığında istenecek
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  if (onboardingCompleted) {
    unawaited(FCMService().init());
    unawaited(NotificationService().init());
  }

  // Mevcut kullanıcı verilerini arka planda sessizce eşitle
  final String? name = prefs.getString('name');
  final String? surname = prefs.getString('surname');
  final String? askerlikYeri = prefs.getString('askerlik_yeri');
  final String? memleket = prefs.getString('memleket');

  if (onboardingCompleted &&
      name != null &&
      surname != null &&
      askerlikYeri != null &&
      memleket != null) {
    final String role = prefs.getString('user_role') ?? 'asker';
    if (role == 'asker') {
      unawaited(SoldierMatchService.instance.ensureSoldierPublished());
    } else if (role == 'yakin' && (prefs.getBool('is_paired') ?? false)) {
      unawaited(SoldierMatchService.instance.syncPairedSoldierData());
    }
  }
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
      unawaited(RevenueCatService.instance.refreshSubscriptionStatus());
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
  final Widget? initialScreen;
  const MyApp({super.key, this.initialScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FCMService.navigatorKey,
      title: 'Şafak Sayar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe desteği
      ],
      home: widget.initialScreen ?? SplashScreen(),
      navigatorObservers: [AppNavigatorObserver()],
      builder: (context, child) {
        return AppLifecycleAndClickTracker(child: child!);
      },
    );
  }
}
