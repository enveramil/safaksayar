import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/app_config_service.dart';
import 'package:safaksayar/pages/pro_welcome_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ultra-High Converting, Keynote-style Mandatory PRO Paywall Screen.
/// Features a photorealistic iPhone chassis with live interactive simulations
/// of the app's killer features (Dual Sync, Lock Screen Widget, Time Capsule,
/// 4K Military Themes, Live Duel Arena, and 100% Ad-Free experience).
class PremiumPaywallPage extends StatefulWidget {
  final String source;
  final bool isGate;

  const PremiumPaywallPage({
    super.key,
    this.source = 'general',
    this.isGate = false,
  });

  static Future<void> show(
    BuildContext context, {
    String source = 'general',
    bool isGate = false,
  }) {
    // Zaten PRO olan üyeye satış ekranı yerine üyelik özeti gösterilir
    final revenueCat = RevenueCatService.instance;
    if (revenueCat.isPremium && !revenueCat.isUserRelative) {
      return ProWelcomePage.show(context, celebrate: false);
    }

    return Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'PremiumPaywallPage'),
        builder: (_) => PremiumPaywallPage(source: source, isGate: isGate),
      ),
    );
  }

  @override
  State<PremiumPaywallPage> createState() => _PremiumPaywallPageState();
}

class _PremiumPaywallPageState extends State<PremiumPaywallPage>
    with TickerProviderStateMixin {
  int _currentFeatureIndex = 0;
  int _selectedPlanIndex = 0; // 0: Annual (3-day free trial), 1: Monthly
  int _selectedThemePreviewIndex = 0;
  bool _isProcessing = false;
  bool _isShowingProWelcome = false;

  final List<Map<String, String>> _previewThemes = const [
    {
      'title': 'Bordo Bereli',
      'tag': '4K HD',
      'image': 'assets/images/img3.webp',
      'detail': 'Bordo Bereliler Özel Kuvvet Teması',
    },
    {
      'title': 'JÖH Komando',
      'tag': '4K HD',
      'image': 'assets/images/img19.webp',
      'detail': 'Jandarma Özel Harekât Çelik Bakış',
    },
    {
      'title': 'Şanlı Bayrak',
      'tag': '4K HD',
      'image': 'assets/images/img12.webp',
      'detail': 'Dolmabahçe Şanlı Al Bayrak Teması',
    },
  ];

  Package? _annualPackage;
  Package? _monthlyPackage;

  // Real-time Firestore & AppConfigService subscriptions for dynamic paywall gate
  StreamSubscription<DocumentSnapshot>? _firestoreConfigSub;
  StreamSubscription<bool>? _appConfigSub;
  late bool _isNecessaryProScreen;

  // Master sequence controller for the feature stage
  late AnimationController _sequenceController;
  late Animation<double> _visualFade;
  late Animation<double> _visualScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Micro-loops for living animations
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _radarController;

  Timer? _secondsTimer;
  int _syncSeconds = 7200 + 845; // 02:14:05

  // User details dynamically read from device prefs to personalize the preview!
  String _userName = 'Mehmet';
  String _userRank = 'Er';
  String _userDutyLocation = 'Şırnak';
  String _userHometown = 'Adana';
  String _trackingCode = 'SFK-3584';

  final List<Map<String, dynamic>> _features = [
    {
      'tag': 'ÇİFT SENKRONİZASYONU',
      'headline': 'Aynı Şafak, Aynı Kalp.',
      'sub': 'Mesafeler sıfırlanır; kalan her saniye ikinizde anlık eşleşir.',
      'pillIcon': Icons.favorite_rounded,
      'pillTitle': 'Çift Eşleşmesi',
      'glowColor': const Color(0xFFE11D48),
    },
    {
      'tag': 'KİLİT EKRANI WİDGETI',
      'headline': 'Kilit Ekranında Canlı Şafak.',
      'sub': 'Uygulamayı açmadan telefon ekranında her an yanında hisset.',
      'pillIcon': Icons.widgets_rounded,
      'pillTitle': 'Canlı Widget',
      'glowColor': const Color(0xFF06B6D4),
    },
    {
      'tag': 'ZAMAN KAPSÜLÜ',
      'headline': 'O Gün Gelene Kadar Sır.',
      'sub': 'İstediğin tarihe ses ve fotoğraf mühürle; o gün gelince açılsın.',
      'pillIcon': Icons.lock_clock_rounded,
      'pillTitle': 'Zaman Kapsülü',
      'glowColor': const Color(0xFFF59E0B),
    },
    {
      'tag': 'ÖZEL FOTOĞRAF & TEMALAR',
      'headline': 'Kendi Fotoğrafın & 4K Temalar.',
      'sub': 'Şafak kartına sevdiğinin fotoğrafını koy veya askeri kamuflajla donat.',
      'pillIcon': Icons.palette_rounded,
      'pillTitle': '4K Temalar',
      'glowColor': const Color(0xFF84CC16),
    },
    {
      'tag': '1v1 ASKER DÜELLOSU',
      'headline': 'Kışlanın Lideri Sen Ol.',
      'sub': 'Limitsiz canlı düello hakkı, lider tablosunda VIP altın taç rozet.',
      'pillIcon': Icons.military_tech_rounded,
      'pillTitle': 'Canlı Düello',
      'glowColor': const Color(0xFF8B5CF6),
    },
    {
      'tag': 'SIFIR REKLAM',
      'headline': 'Sıfır Reklam, Saf Huzur.',
      'sub': 'Hiçbir reklam ve bekleme olmadan sadece anılarına ve şafağına odaklan.',
      'pillIcon': Icons.block_rounded,
      'pillTitle': 'Sıfır Reklam',
      'glowColor': const Color(0xFF10B981),
    },
  ];

  int _currentQuoteIndex = 0;
  Timer? _testimonialTimer;

  final List<Map<String, String>> _testimonials = [
    {
      'quote':
          '«Aynı şafağı sevgilimle saniyesi saniyesine saymak ve ona 100. gün için ses kaydı bırakmak kışladaki en büyük tesellim oldu.»',
      'author': 'P. Er Emre K. & Buse',
      'location': 'Kıbrıs & Ankara',
      'tag': 'Doğrulanmış Çift',
    },
    {
      'quote':
          '«Oğlum askerdeyken doğum gününe kilitli mektup ve dua bıraktım, o gün açtı; ağlayarak aradı. İyi ki varsınız.»',
      'author': 'Fatma Hanım & Burak',
      'location': 'Şırnak & İzmir',
      'tag': 'Asker Annesi',
    },
    {
      'quote':
          '«Hiç reklam olmadan sayaç widget\'ını kilit ekranına koydum, her telefonuma baktığımda kavuşacağımız günü görmek harika bir duygu.»',
      'author': 'Selin T. (Asker Yâri)',
      'location': 'İstanbul',
      'tag': 'Yıldızlı Yorum',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isNecessaryProScreen = widget.isGate || AppConfigService.instance.isNecessaryProScreen;
    _listenToLiveProConfig();
    _loadUserData();

    if (widget.source.contains('theme') || widget.source.contains('photo')) {
      _currentFeatureIndex = 3;
    } else if (widget.source.contains('capsule')) {
      _currentFeatureIndex = 2;
    } else if (widget.source.contains('duel') || widget.source.contains('millionaire')) {
      _currentFeatureIndex = 4;
    } else if (widget.source.contains('widget')) {
      _currentFeatureIndex = 1;
    }

    _loadOfferings();
    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumExternallyActivated);

    // 1. Master Sequence Animation Controller (3.8 seconds per feature showcase)
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _visualFade = CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _visualScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.18, 0.38, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.18, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Micro loops
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _sequenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextFeature();
      }
    });

    _sequenceController.forward();

    // 3. Live Clock Ticker
    _secondsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_syncSeconds > 0) {
            _syncSeconds--;
          } else {
            _syncSeconds = 7200 + 845;
          }
        });
      }
    });

    // 4. Testimonials auto-cycle
    _testimonialTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _testimonials.length;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final rank = prefs.getString('rutbe');
      final location = prefs.getString('askerlik_yeri');
      final city = prefs.getString('memleket');
      final code = prefs.getString('tracking_code') ?? prefs.getString('paired_code');

      if (mounted) {
        setState(() {
          if (name != null && name.trim().isNotEmpty) _userName = name.trim();
          if (rank != null && rank.trim().isNotEmpty) _userRank = rank.trim();
          if (location != null && location.trim().isNotEmpty) _userDutyLocation = location.trim();
          if (city != null && city.trim().isNotEmpty) _userHometown = city.trim();
          if (code != null && code.trim().isNotEmpty) _trackingCode = code.trim();
        });
      }
    } catch (_) {}
  }

  void _listenToLiveProConfig() {
    // 1. Doğrudan Firestore parameter/config tablosundaki snapshot akışını dinle
    _firestoreConfigSub = FirebaseFirestore.instance
        .collection('parameter')
        .doc('config')
        .snapshots()
        .listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;
      if (data.containsKey('isNecessaryProScreen')) {
        final bool isNecessary = data['isNecessaryProScreen'] as bool? ?? false;
        if (mounted && _isNecessaryProScreen != isNecessary) {
          setState(() {
            _isNecessaryProScreen = isNecessary;
          });
          debugPrint('[Paywall] Firestore canlı isNecessaryProScreen güncellendi: $isNecessary');
        }
      }
    }, onError: (e) {
      debugPrint('[Paywall] Firestore dinleme hatası: $e');
    });

    // 2. AppConfigService broadcast stream'ini de dinle
    _appConfigSub = AppConfigService.instance.onNecessaryProScreenChanged.listen((isNecessary) {
      if (mounted && _isNecessaryProScreen != isNecessary) {
        setState(() {
          _isNecessaryProScreen = isNecessary;
        });
      }
    });
  }

  Future<void> _dismissPaywall() async {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'ManagePages'),
            builder: (_) => ManagePages(backgroundImage: themeImage),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _firestoreConfigSub?.cancel();
    _appConfigSub?.cancel();
    RevenueCatService.instance.isPremiumNotifier.removeListener(_onPremiumExternallyActivated);
    _sequenceController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _radarController.dispose();
    _secondsTimer?.cancel();
    _testimonialTimer?.cancel();
    super.dispose();
  }

  void _goToFeature(int index) {
    if (_currentFeatureIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentFeatureIndex = index;
    });
    _sequenceController.forward(from: 0.0);
  }

  void _nextFeature() {
    setState(() {
      _currentFeatureIndex = (_currentFeatureIndex + 1) % _features.length;
    });
    _sequenceController.forward(from: 0.0);
  }

  String _formatTime(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await RevenueCatService.instance.getOfferings();
      if (mounted && offerings != null) {
        final currentOffering = offerings.current ?? offerings.all['default'];
        if (currentOffering != null) {
          setState(() {
            _annualPackage = currentOffering.annual;
            _monthlyPackage = currentOffering.monthly;

            for (final p in currentOffering.availablePackages) {
              final id = p.identifier.toLowerCase();
              if (p.packageType == PackageType.annual ||
                  id == '\$rc_annual' ||
                  id.contains('annual') ||
                  id.contains('year') ||
                  id.contains('yillik')) {
                _annualPackage ??= p;
              }
              if (p.packageType == PackageType.monthly ||
                  id == '\$rc_monthly' ||
                  id.contains('month') ||
                  id.contains('aylik')) {
                _monthlyPackage ??= p;
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  void _onPremiumExternallyActivated() {
    if (!mounted || _isProcessing) return;
    if (RevenueCatService.instance.isPremium) {
      _showProWelcomeAndContinue();
    }
  }

  /// PRO karşılama ekranını gösterir; kullanıcı devam edince paywall akışını tamamlar.
  /// Asker yakınları PRO'yu ücretsiz aldığı için karşılama ekranını görmez.
  Future<void> _showProWelcomeAndContinue({
    String? planLabel,
    bool isRestore = false,
  }) async {
    if (!mounted || _isShowingProWelcome) return;
    if (RevenueCatService.instance.isUserRelative) {
      await _navigateToHomeOrClose();
      return;
    }

    setState(() => _isShowingProWelcome = true);
    await ProWelcomePage.show(context, planLabel: planLabel, isRestore: isRestore);
    await _navigateToHomeOrClose();
    if (mounted) setState(() => _isShowingProWelcome = false);
  }

  String get _selectedPlanLabel =>
      _selectedPlanIndex == 0 ? 'Yıllık Plan' : 'Aylık Plan';

  Future<void> _navigateToHomeOrClose() async {
    if (!mounted) return;
    if (widget.isGate) {
      final prefs = await SharedPreferences.getInstance();
      final themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'ManagePages'),
            builder: (_) => ManagePages(backgroundImage: themeImage),
          ),
          (route) => false,
        );
      }
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Package? _getSelectedPackage() {
    if (_selectedPlanIndex == 0) return _annualPackage;
    if (_selectedPlanIndex == 1) return _monthlyPackage;
    return null;
  }

  Future<void> _handlePurchase() async {
    if (_isProcessing) return;

    if (RevenueCatService.instance.isPremium) {
      HapticFeedback.heavyImpact();
      _showProWelcomeAndContinue();
      return;
    }

    Package? selectedPackage = _getSelectedPackage();
    if (selectedPackage == null) {
      setState(() => _isProcessing = true);
      await _loadOfferings();
      selectedPackage = _getSelectedPackage();
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }

    if (selectedPackage != null) {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final result = await RevenueCatService.instance.purchasePackage(selectedPackage);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result.status == PaywallPurchaseStatus.success) {
        HapticFeedback.heavyImpact();
        await _showProWelcomeAndContinue(planLabel: _selectedPlanLabel);
      } else if (result.status == PaywallPurchaseStatus.error) {
        _showErrorSnackBar(result.message ?? "İşlem tamamlanamadı.");
      }
    } else if (kDebugMode) {
      // Simulator / Debug Mode bypass
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(milliseconds: 600));
      final simulatedDuration = _selectedPlanIndex == 0
          ? const Duration(days: 365)
          : const Duration(days: 30);
      await RevenueCatService.instance.setPremiumManually(
        true,
        duration: simulatedDuration,
        source: 'debug_subscription',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      HapticFeedback.heavyImpact();
      await _showProWelcomeAndContinue(planLabel: _selectedPlanLabel);
    } else {
      _showErrorSnackBar(
        "Abonelik paketleri şu an yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.",
      );
    }
  }

  Future<void> _handleRestore() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    final result = await RevenueCatService.instance.restorePurchases();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.status == PaywallPurchaseStatus.success) {
      HapticFeedback.heavyImpact();
      await _showProWelcomeAndContinue(isRestore: true);
    } else {
      _showErrorSnackBar(result.message ?? "Aktif abonelik bulunamadı.");
    }
  }

  void _showMandatoryGateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16181F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF282B37), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 8),
            Text(
              "Şafak Sayar PRO",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Canlı sayaç, çift senkronizasyonu, kilit ekranı widget'ı ve özel askeri temalar PRO abonelik kapsamındadır.\n\nÜcretsiz deneyebilir, dilediğiniz an tek dokunuşla iptal edebilirsiniz.",
          style: TextStyle(color: Color(0xFFB0B5C6), fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SystemNavigator.pop();
            },
            child: const Text("Uygulamadan Çık", style: TextStyle(color: Color(0xFF787C8B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handlePurchase();
            },
            child: const Text("Ücretsiz Dene", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2028),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF323644)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isNecessaryProScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isNecessaryProScreen) {
          _showMandatoryGateDialog();
        } else {
          _dismissPaywall();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0C0D11),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0C0D11),
          // Karşılama ekranından dönerken satış içeriği yeniden görünmesin
          body: AnimatedOpacity(
            opacity: _isShowingProWelcome ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  _buildTopBar(),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PRO Brand Pill
                          _buildHeaderTag(),

                          const SizedBox(height: 12),

                          // Interactive Scenario Switcher Bar (6 tabs)
                          _buildScenarioPills(),

                          const SizedBox(height: 12),

                          // The Killer Smartphone Live App Preview Stage!
                          _buildLivePhoneMockupStage(),

                          const SizedBox(height: 16),

                          // Impactful Sequential Headline
                          _buildFeatureHeadline(),

                          const SizedBox(height: 14),

                          // Real User Social Proof Card
                          _buildUserTestimonialCard(),

                          const SizedBox(height: 16),

                          // Solid Plan Selector (Annual with 3-Day Free Trial vs Monthly)
                          _buildPlanSelector(),

                          const SizedBox(height: 16),

                          // Primary Action Button
                          _buildActionButton(),

                          const SizedBox(height: 12),

                          // Orderly Footer (Trial Note, EULA & Privacy, and Optional Free Dismiss)
                          _buildFooter(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ÇARPI BUTONU: isNecessaryProScreen == false ise kapatıp ücretsiz kullanmaya izin verir
          if (!_isNecessaryProScreen)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissPaywall,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            )
          else
            const SizedBox(width: 36),
          GestureDetector(
            onTap: _isProcessing ? null : _handleRestore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Text(
                "Satın Alımları Geri Yükle",
                style: TextStyle(
                  color: Color(0xFFB0B5C6),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER TAG
  // ==========================================
  Widget _buildHeaderTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3240)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 14),
          SizedBox(width: 5),
          Text(
            "ŞAFAK SAYAR PRO • TÜM AYRICALIKLAR",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INTERACTIVE SCENARIO PILLS (6 TABS)
  // ==========================================
  Widget _buildScenarioPills() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _features.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = _features[index];
          final bool isSelected = index == _currentFeatureIndex;
          final Color glow = item['glowColor'] as Color;

          return GestureDetector(
            onTap: () => _goToFeature(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? glow.withValues(alpha: 0.18)
                    : const Color(0xFF14161E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? glow.withValues(alpha: 0.8) : const Color(0xFF222633),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['pillIcon'] as IconData,
                    size: 13,
                    color: isSelected ? Colors.white : const Color(0xFF787E92),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item['pillTitle'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF8E94A6),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // LIVE SMARTPHONE MOCKUP STAGE
  // ==========================================
  Widget _buildLivePhoneMockupStage() {
    final activeFeature = _features[_currentFeatureIndex];
    final Color accentGlow = activeFeature['glowColor'] as Color;

    return Center(
      child: ScaleTransition(
        scale: _visualScale,
        child: FadeTransition(
          opacity: _visualFade,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              // Multi-layered luxury ambient aura
              boxShadow: [
                BoxShadow(
                  color: accentGlow.withValues(alpha: 0.22),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              // Realistic iPhone 16 Pro chassis
              height: 226,
              decoration: BoxDecoration(
                color: const Color(0xFF090A0E),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF2E3342), width: 2.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  children: [
                    // Glass specular highlight reflection overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Phone Status Bar & Dynamic Island
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildPhoneStatusBar(accentGlow),
                    ),

                    // Scenario Screen Content
                    Positioned(
                      top: 36,
                      left: 12,
                      right: 12,
                      bottom: 8,
                      child: _buildScenarioContent(_currentFeatureIndex),
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

  // ==========================================
  // PHONE STATUS BAR & DYNAMIC ISLAND
  // ==========================================
  Widget _buildPhoneStatusBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "09:41",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),

          // Dynamic Island Capsule
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  "Şafak Sayar PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Row(
            children: [
              Icon(Icons.signal_cellular_4_bar_rounded, color: Colors.white70, size: 10),
              SizedBox(width: 3),
              Icon(Icons.wifi_rounded, color: Colors.white70, size: 10),
              SizedBox(width: 3),
              Icon(Icons.battery_full_rounded, color: Colors.white70, size: 11),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6 SCENARIOS INSIDE THE PHONE CHASSIS
  // ==========================================
  Widget _buildScenarioContent(int index) {
    switch (index) {
      case 0:
        return _buildDualSyncSimulation();
      case 1:
        return _buildLockScreenWidgetSimulation();
      case 2:
        return _buildTimeCapsuleSimulation();
      case 3:
        return _buildThemesAndPhotoSimulation();
      case 4:
        return _buildDuelArenaSimulation();
      case 5:
        return _buildZeroAdsComparisonSimulation();
      default:
        return _buildDualSyncSimulation();
    }
  }

  // SCENARIO 0: LIVE DUAL SYNC (CANLI ÇİFT EŞLEŞMESİ)
  Widget _buildDualSyncSimulation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Live Heartbeat Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Soldier Card
            _buildMiniProfile(
              icon: Icons.military_tech_rounded,
              iconColor: const Color(0xFFF59E0B),
              name: "$_userRank $_userName",
              location: _userDutyLocation,
              label: "ASKER (SEN)",
            ),

            // Animated Pulse Beam
            Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    final v = _pulseController.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15 + 0.15 * v),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4 + 0.4 * v)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_rounded, size: 9, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            "0 MS CANLI",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // ECG Heartbeat line simulation
                SizedBox(
                  width: 58,
                  height: 14,
                  child: CustomPaint(
                    painter: _EcWavePainter(progress: _pulseController.value),
                  ),
                ),
                Text(
                  _trackingCode,
                  style: const TextStyle(
                    color: Color(0xFF787C8B),
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            // Lover / Relative Card
            _buildMiniProfile(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFE11D48),
              name: "Sevdiğin 💕",
              location: _userHometown,
              label: "YÂRİN (EŞLEŞTİ)",
            ),
          ],
        ),

        // Live Countdown Ticker Pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF161922),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF262B3A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timelapse_rounded, color: Color(0xFFF59E0B), size: 13),
                  SizedBox(width: 4),
                  Text(
                    "KALAN ŞAFAK",
                    style: TextStyle(color: Color(0xFF8E92A0), fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                "48 Gün • ${_formatTime(_syncSeconds)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        // Toast message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFE11D48).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Color(0xFFE11D48), size: 10),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  "Sevgilin şu an şafağına bakıyor • Canlı Senkronize",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFFF859B),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SCENARIO 1: LIVE LOCK SCREEN WIDGET
  Widget _buildLockScreenWidgetSimulation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // iOS Lock Screen Clock
        const Column(
          children: [
            Text(
              "09:41",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w200,
                height: 1.0,
                letterSpacing: -1.0,
              ),
            ),
            Text(
              "Pazar, 1 Kasım",
              style: TextStyle(
                color: Color(0xFFB0B5C6),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Frosted Glassmorphic iOS 18 Lock Screen Widget
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2333).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF38405A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: Color(0xFF06B6D4), size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "$_userRank $_userName".toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Doğan Güneş: $_userHometown",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF06B6D4),
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10141E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 5,
                    width: 170,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Şafak: 48 Gün • %74 Tamamlandı",
                    style: TextStyle(color: Color(0xFF9EABB9), fontSize: 8, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "PRO Widget",
                    style: TextStyle(color: Color(0xFF06B6D4), fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Text(
          "Uygulamayı açmadan telefon kilit ekranında canlı takip",
          style: TextStyle(color: Color(0xFF787E92), fontSize: 8.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // SCENARIO 2: TIME CAPSULE (KİLİTLİ ZAMAN KAPSÜLÜ)
  Widget _buildTimeCapsuleSimulation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envelope & Wax Seal Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3E3224)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.mail_lock_rounded, color: Color(0xFFF59E0B), size: 14),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        "MÜHÜRLÜ ZAMAN KAPSÜLÜ",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "100. GÜN",
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),

        // Live Audio Player Simulation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141720),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF262D3E)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sevdiğinden Gizli Ses Kaydı & Fotoğraf",
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (_, __) {
                        final v = _waveController.value;
                        return Row(
                          children: [
                            _buildWaveBar(5 + 8 * v),
                            const SizedBox(width: 2.5),
                            _buildWaveBar(14 - 8 * v),
                            const SizedBox(width: 2.5),
                            _buildWaveBar(7 + 10 * ((v + 0.3) % 1.0)),
                            const SizedBox(width: 2.5),
                            _buildWaveBar(16 - 10 * ((v + 0.6) % 1.0)),
                            const SizedBox(width: 2.5),
                            _buildWaveBar(9 + 6 * v),
                            const SizedBox(width: 2.5),
                            _buildWaveBar(12 - 7 * v),
                            const SizedBox(width: 8),
                            const Text(
                              "0:28 / 1:45",
                              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8.5, fontFamily: 'monospace'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Text(
          "O gün gelene kadar kimse açamaz; zamanı gelince telefonunuza bildirim gelir.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF787E92), fontSize: 8.5),
        ),
      ],
    );
  }

  // SCENARIO 3: 4K THEMES & CUSTOM PHOTO
  Widget _buildThemesAndPhotoSimulation() {
    final activeTheme = _previewThemes[_selectedThemePreviewIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 3 Real App Theme Previews with Actual Images
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_previewThemes.length, (index) {
            final theme = _previewThemes[index];
            final bool isSelected = _selectedThemePreviewIndex == index;
            return _buildThemeMiniPreview(
              title: theme['title']!,
              imagePath: theme['image']!,
              tag: theme['tag']!,
              isActive: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedThemePreviewIndex = index;
                });
              },
            );
          }),
        ),

        // Personalized Gold Plate Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E2A1C), Color(0xFF1B1810)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF85682A), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$_userRank $_userName",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            "$_userDutyLocation • ${activeTheme['detail']}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "4K ULTRA HD",
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const Text(
          "Kendi özel fotoğrafını yükle veya 40+ 4K askeri temayla kişiselleştir",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Color(0xFF787E92), fontSize: 8.5),
        ),
      ],
    );
  }

  // SCENARIO 4: 1v1 DUEL ARENA (CANLI ASKER DÜELLOSU)
  Widget _buildDuelArenaSimulation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Match Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF8B5CF6)),
                ),
                child: Text(
                  "$_userName (850)",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "⚔️ 1v1 DÜELLO",
              style: TextStyle(color: Color(0xFFFBBF24), fontSize: 8.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Rakip (700)",
                style: TextStyle(color: Color(0xFF8E92A0), fontSize: 8),
              ),
            ),
          ],
        ),

        // Live Question Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF191B26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2C3246)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Soru 8: Çanakkale Zaferi hangi yılda gerçekleşti?",
                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "A) 1914",
                      style: TextStyle(color: Color(0xFF787C8B), fontSize: 8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "B) 1915 ✓",
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Victory Crown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 12),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  "KIŞLA 1.'Sİ • VIP ALTIN ROZET",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SCENARIO 5: ZERO ADS COMPARISON
  Widget _buildZeroAdsComparisonSimulation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Standard / Free side
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1315),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3E2024)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 11),
                        SizedBox(width: 3),
                        Text(
                          "ÜCRETSİZ",
                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "• Pop-up reklamlar\n• 5 sn bekleme süresi\n• Sınırlı özellikler",
                      style: TextStyle(color: Color(0xFF8E92A0), fontSize: 8, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // PRO side
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10261E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 11),
                        SizedBox(width: 3),
                        Text(
                          "PRO SÜRÜM",
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "• %100 Sıfır Reklam\n• Anında pürüzsüz açılış\n• Tüm VIP özellikler açık",
                      style: TextStyle(color: Colors.white, fontSize: 8, height: 1.3, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF161922),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "Hiçbir reklam olmadan sadece sevdiğine ve şafağına odaklan",
            style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniProfile({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String location,
    required String label,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
        Text(
          location,
          style: const TextStyle(color: Color(0xFF787C8B), fontSize: 8),
        ),
      ],
    );
  }

  Widget _buildThemeMiniPreview({
    required String title,
    required String imagePath,
    required String tag,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 80,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isActive ? const Color(0xFFF59E0B) : const Color(0xFF2C3246),
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gerçek Uygulama Tema Görseli
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(Icons.image, color: Colors.white24, size: 18),
                ),
              ),

              // Metin okunabilirliği için alt gradyan
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),

              // Sağ üst rozet
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF59E0B) : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    isActive ? "SEÇİLİ" : tag,
                    style: TextStyle(
                      color: isActive ? Colors.black : const Color(0xFFFDE68A),
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // Alt başlık
              Positioned(
                bottom: 3,
                left: 3,
                right: 3,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==========================================
  // HEADLINE & SUBHEADLINE TEXT
  // ==========================================
  Widget _buildFeatureHeadline() {
    final currentFeature = _features[_currentFeatureIndex];

    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1F222B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                currentFeature['tag'] as String,
                style: const TextStyle(
                  color: Color(0xFF8E92A0),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentFeature['headline'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentFeature['sub'] as String,
              style: const TextStyle(
                color: Color(0xFF8E92A0),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TESTIMONIAL CARD
  // ==========================================
  Widget _buildUserTestimonialCard() {
    final t = _testimonials[_currentQuoteIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12141A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222530)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => const Padding(
                    padding: EdgeInsets.only(right: 2.0),
                    child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2028),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2C303E)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 10),
                    const SizedBox(width: 4),
                    Text(
                      t['tag']!,
                      style: const TextStyle(
                        color: Color(0xFF8E92A0),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t['quote']!,
            style: const TextStyle(
              color: Color(0xFFE2E4EC),
              fontSize: 11.5,
              height: 1.35,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${t['author']} • ${t['location']}",
                style: const TextStyle(
                  color: Color(0xFF787C8B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: List.generate(_testimonials.length, (i) {
                  return Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _currentQuoteIndex ? Colors.white : const Color(0xFF323644),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateMonthlyEquivalent(Package? package, String fallback) {
    if (package != null && package.storeProduct.price > 0) {
      final monthlyVal = package.storeProduct.price / 12.0;
      final String currencySymbol = package.storeProduct.currencyCode == 'TRY'
          ? '₺'
          : package.storeProduct.priceString.replaceAll(RegExp(r'[0-9.,\s]'), '');
      final symbol = currencySymbol.isEmpty ? '₺' : currencySymbol;
      return "$symbol${monthlyVal.toStringAsFixed(2).replaceAll('.', ',')}";
    }
    return fallback;
  }

  // ==========================================
  // PLAN SELECTOR
  // ==========================================
  Widget _buildPlanSelector() {
    final String annualPrice = _annualPackage?.storeProduct.priceString ?? '₺199,99';
    final String monthlyPrice = _monthlyPackage?.storeProduct.priceString ?? '₺39,99';
    final String annualMonthlyEquivalent = _calculateMonthlyEquivalent(_annualPackage, '₺16,66');

    return Column(
      children: [
        // 1. YILLIK PLAN (7 GÜN ÜCRETSİZ)
        _buildPlanTile(
          index: 0,
          title: "Yıllık Plan",
          tag: "7 GÜN ÜCRETSİZ",
          note: "7 gün ücretsiz dene, sonra $annualPrice / yıl",
          priceRight: annualMonthlyEquivalent,
          periodRight: "/ ay",
          isSelected: _selectedPlanIndex == 0,
        ),

        const SizedBox(height: 8),

        // 2. AYLIK PLAN (3 GÜN ÜCRETSİZ)
        _buildPlanTile(
          index: 1,
          title: "Aylık Plan",
          tag: "3 GÜN ÜCRETSİZ",
          note: "3 gün ücretsiz dene, sonra $monthlyPrice / ay",
          priceRight: monthlyPrice,
          periodRight: "/ ay",
          isSelected: _selectedPlanIndex == 1,
        ),
      ],
    );
  }

  Widget _buildPlanTile({
    required int index,
    required String title,
    required String? tag,
    required String note,
    required String priceRight,
    required String periodRight,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF191B22) : const Color(0xFF121319),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF22242D),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF4A4E5E),
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 7, color: Colors.black),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: const TextStyle(
                      color: Color(0xFF787C8B),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceRight,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  periodRight,
                  style: const TextStyle(
                    color: Color(0xFF787C8B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ACTION BUTTON
  // ==========================================
  Widget _buildActionButton() {
    if (RevenueCatService.instance.isUserRelative) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            HapticFeedback.heavyImpact();
            _navigateToHomeOrClose();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "Asker Yakınına Özel • Tüm Özellikler Açık",
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String label = _selectedPlanIndex == 0
        ? "7 Gün Ücretsiz Dene ve Başla"
        : "3 Gün Ücretsiz Dene ve Başla";

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isProcessing ? null : _handlePurchase,
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  // ==========================================
  // FOOTER (LEGAL & CANCEL NOTE)
  // ==========================================
  Widget _buildFooter() {
    final isRelative = RevenueCatService.instance.isUserRelative;
    final String trialNote = isRelative
        ? "Asker yakını olduğunuz için tüm ayrıcalıklardan ücretsiz yararlanıyorsunuz."
        : (_selectedPlanIndex == 0
            ? "7 gün ücretsizdir. İstediğiniz an tek dokunuşla iptal edebilirsiniz."
            : "3 gün ücretsizdir. İstediğiniz an tek dokunuşla iptal edebilirsiniz.");

    return Column(
      children: [
        Center(
          child: Text(
            trialNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E94A6),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLink("Kullanım Koşulları (EULA)", "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("•", style: TextStyle(color: Color(0xFF4A4E5E))),
            ),
            _buildLink("Gizlilik Politikası", "https://safaksayar.vercel.app/#/privacy"),
          ],
        ),
        if (!_isNecessaryProScreen) ...[
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismissPaywall,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Text(
                "Şimdilik Ücretsiz Devam Et",
                style: TextStyle(
                  color: Color(0xFF787C8B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF787C8B),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLink(String text, String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF787C8B),
          fontSize: 11,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

/// Custom ECG wave painter for live dual heartbeat animation
class _EcWavePainter extends CustomPainter {
  final double progress;

  _EcWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE11D48)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.35, size.height * 0.1);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    path.lineTo(size.width * 0.65, size.height * 0.3);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);

    // Moving glowing particle
    final dotX = size.width * progress;
    final dotY = size.height * 0.5;
    final dotPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(dotX, dotY), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _EcWavePainter oldDelegate) => true;
}
