import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ultra-professional, Keynote-style Paywall Screen.
/// Strictly ZERO gradients, ZERO text walls.
/// Sequentially showcases each killer feature:
/// 1. First, the feature's tactile visual comes to life / animates.
/// 2. Then, the punchy impactful text smoothly slides up.
/// Includes interactive progress segments and instant tap-to-switch.
class PremiumPaywallPage extends StatefulWidget {
  final String source;

  const PremiumPaywallPage({
    super.key,
    this.source = 'general',
  });

  static Future<void> show(BuildContext context, {String source = 'general'}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'PremiumPaywallPage'),
        builder: (_) => PremiumPaywallPage(source: source),
      ),
    );
  }

  @override
  State<PremiumPaywallPage> createState() => _PremiumPaywallPageState();
}

class _PremiumPaywallPageState extends State<PremiumPaywallPage>
    with TickerProviderStateMixin {
  int _currentFeatureIndex = 0;
  int _selectedPlanIndex = 0; // 0: Annual (3-day trial), 1: Monthly
  bool _isProcessing = false;

  Package? _annualPackage;
  Package? _monthlyPackage;

  // Master sequence controller for the feature stage
  late AnimationController _sequenceController;
  late Animation<double> _visualFade;
  late Animation<double> _visualScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Secondary micro-loop controllers
  late AnimationController _waveLoopController;
  late AnimationController _pulseLoopController;

  Timer? _autoPlayTimer;
  Timer? _secondsTimer;
  int _syncSeconds = 7200 + 845; // 02:14:05

  final List<Map<String, dynamic>> _features = [
    {
      'tag': 'ÇİFT SENKRONİZASYONU',
      'headline': 'Aynı Şafak, Aynı Kalp.',
      'sub': 'Mesafeler sıfırlanır; kalan her saniye ikinizde anlık eşleşir.',
    },
    {
      'tag': 'ZAMAN KAPSÜLÜ',
      'headline': 'O Gün Gelene Kadar Sır.',
      'sub': 'İstediğin tarihe ses ve fotoğraf mühürle; o gün gelince açılsın.',
    },
    {
      'tag': 'SIFIR REKLAM',
      'headline': 'Sıfır Reklam, Saf Huzur.',
      'sub': 'Hiçbir reklam ve bekleme olmadan sadece anılarına odaklan.',
    },
    {
      'tag': '1v1 DÜELLO',
      'headline': 'Kışlanın Lideri Sen Ol.',
      'sub': 'Limitsiz canlı düello hakkı ve lider tablosunda VIP rozet.',
    },
    {
      'tag': 'KİLİT WIDGETI',
      'headline': 'Kilit Ekranında Canlı Şafak.',
      'sub': 'Uygulamayı açmadan telefon ekranında her an yanında hisset.',
    },
    {
      'tag': 'ÖZEL FOTOĞRAF & TEMALAR',
      'headline': 'Kendi Fotoğrafın ve Özel Temalar.',
      'sub': 'Şafak kartına sevdiğinin fotoğrafını koy veya askeri temalarla kişiselleştir.',
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
    if (widget.source.contains('theme') || widget.source.contains('photo')) {
      _currentFeatureIndex = 5;
    } else if (widget.source.contains('capsule')) {
      _currentFeatureIndex = 1;
    } else if (widget.source.contains('duel') || widget.source.contains('millionaire')) {
      _currentFeatureIndex = 3;
    } else if (widget.source.contains('widget')) {
      _currentFeatureIndex = 4;
    }
    _loadOfferings();
    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumExternallyActivated);

    // 1. Master Story Sequencer (4 seconds per feature)
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    // Visual entrance: 0ms -> 600ms (0.0 -> 0.20)
    _visualFade = CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _visualScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutBack),
      ),
    );

    // Text entrance (starts after visual brings it to life): 500ms -> 1000ms (0.16 -> 0.38)
    _textFade = CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.18, 0.38, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.18, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Micro loops for living waveform and radar dot
    _waveLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 3. Sequential automatic progression
    _sequenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextFeature();
      }
    });

    _sequenceController.forward();

    // 4. Live Clock Ticker
    _secondsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_syncSeconds > 0) {
            _syncSeconds--;
          } else {
            _syncSeconds = 8000;
          }
        });
      }
    });

    // 5. Testimonial auto-cycle every 6 seconds
    _testimonialTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _testimonials.length;
        });
      }
    });
  }

  @override
  void dispose() {
    RevenueCatService.instance.isPremiumNotifier.removeListener(_onPremiumExternallyActivated);
    _sequenceController.dispose();
    _waveLoopController.dispose();
    _pulseLoopController.dispose();
    _autoPlayTimer?.cancel();
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
    if (RevenueCatService.instance.isPremium && Navigator.of(context).canPop()) {
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

    // Mevcutta aktif PRO / aboneliği olan kullanıcıdan tekrar ödeme isteme!
    if (RevenueCatService.instance.isPremium) {
      HapticFeedback.heavyImpact();
      if (RevenueCatService.instance.isUserRelative) {
        _showSuccessDialog(
          title: "Asker Yakını Ayrıcalığı 💕",
          message: "Tüm PRO özellikler asker yakınlarımıza özel olarak tamamen ücretsiz tanımlanmıştır. Keyifle kullanabilirsiniz!",
        );
      } else {
        _showSuccessDialog(
          title: "PRO Üyeliğiniz Aktif",
          message: "Mevcut aboneliğiniz doğrulandı. Tekrar ödeme yapmanıza gerek olmadan tüm PRO özellikleriniz açıktır.",
        );
      }
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
        _showSuccessDialog();
      } else if (result.status == PaywallPurchaseStatus.error) {
        _showErrorSnackBar(result.message ?? "İşlem tamamlanamadı.");
      }
    } else if (kDebugMode) {
      // Debug / Simülatör Önizleme Modu (seçilen plana göre 1 ay veya 1 yıl süre tanımlar)
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
      _showSuccessDialog();
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
      _showSuccessDialog(
        title: "Satın Alımlar Geri Yüklendi",
        message: "Aboneliğiniz başarıyla aktif edildi.",
      );
    } else {
      _showErrorSnackBar(result.message ?? "Aktif abonelik bulunamadı.");
    }
  }

  void _showSuccessDialog({
    String title = "PRO Aktif Edildi",
    String message = "Tüm ayrıcalıklar sınırsız olarak hesabınıza tanımlandı.",
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16181F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF282B37), width: 1),
        ),
        title: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0C0D11),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0D11),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtle Tag & Brand
                      _buildHeaderTag(),

                      const SizedBox(height: 16),

                      // Sequential Feature Showcase (Visual animates first, text follows)
                      _buildCinematicFeatureStage(),

                      const SizedBox(height: 14),

                      // Real User Testimonial & Social Proof Card
                      _buildUserTestimonialCard(),

                      const SizedBox(height: 16),

                      // Solid Plan Selector (Matte cards, zero gradients)
                      _buildPlanSelector(),

                      const SizedBox(height: 16),

                      // Solid Action Button (No gradient)
                      _buildActionButton(),

                      const SizedBox(height: 10),

                      // Minimal Sub-note & Links
                      _buildFooter(),

                      const SizedBox(height: 16),
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

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            ),
          ),
          GestureDetector(
            onTap: _isProcessing ? null : _handleRestore,
            child: const Text(
              "Geri Yükle",
              style: TextStyle(
                color: Color(0xFF8E92A0),
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2028),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2E3240)),
          ),
          child: const Text(
            "PRO AYRICALIKLARI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CINEMATIC SEQUENTIAL FEATURE STAGE
  // ==========================================
  Widget _buildCinematicFeatureStage() {
    final currentFeature = _features[_currentFeatureIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14151B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22242D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Progress Step Indicators (Pills on top)
          Row(
            children: List.generate(_features.length, (index) {
              final bool isCurrent = index == _currentFeatureIndex;
              final bool isPast = index < _currentFeatureIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _goToFeature(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Colors.white
                          : (isPast ? const Color(0xFF4A4E5E) : const Color(0xFF22242D)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 18),

          // 2. STAGE VISUAL (Animates first!)
          Center(
            child: ScaleTransition(
              scale: _visualScale,
              child: FadeTransition(
                opacity: _visualFade,
                child: SizedBox(
                  height: 110,
                  child: Center(
                    child: _buildStageVisual(_currentFeatureIndex),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. IMPACTFUL TEXT (Slides up and reveals right after visual)
          SlideTransition(
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
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DYNAMIC STAGE VISUAL GENERATOR
  // ==========================================
  Widget _buildStageVisual(int index) {
    switch (index) {
      case 0:
        // FEATURE 0: CANLI ÇİFT SENKRONİZASYONU
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarPill(Icons.military_tech_rounded, "ASKER"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseLoopController,
                    builder: (context, child) {
                      return Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981)
                                  .withValues(alpha: 0.3 + 0.7 * _pulseLoopController.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "CANLI",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 70,
                    height: 2,
                    color: const Color(0xFF2C303E),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(_syncSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _buildAvatarPill(Icons.favorite_rounded, "SEVDİĞİN"),
          ],
        );

      case 1:
        // FEATURE 1: KİLİTLİ ZAMAN KAPSÜLÜ
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C303E)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF222530),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SES KAYDI VE FOTOĞRAF",
                    style: TextStyle(
                      color: Color(0xFF8E92A0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _waveLoopController,
                    builder: (context, child) {
                      final v = _waveLoopController.value;
                      return Row(
                        children: [
                          _buildWaveBar(6 + 10 * v),
                          const SizedBox(width: 3),
                          _buildWaveBar(18 - 10 * v),
                          const SizedBox(width: 3),
                          _buildWaveBar(8 + 12 * ((v + 0.3) % 1.0)),
                          const SizedBox(width: 3),
                          _buildWaveBar(16 - 12 * ((v + 0.6) % 1.0)),
                          const SizedBox(width: 3),
                          _buildWaveBar(10 + 8 * v),
                          const SizedBox(width: 8),
                          const Text(
                            "0:18",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case 2:
        // FEATURE 2: SIFIR REKLAM
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C303E)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF222530),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "0 REKLAM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Kesintisiz arayüz aktif",
                    style: TextStyle(
                      color: Color(0xFF8E92A0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 3:
        // FEATURE 3: SINIRSIZ DÜELLO
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C303E)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 24),
                  SizedBox(width: 8),
                  Text(
                    "VIP #1",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2028),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C303E)),
              ),
              child: const Text(
                "⚔️ 1v1 LİMİTSİZ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );

      case 4:
        // FEATURE 4: KİLİT EKRANI WİDGETI
        return Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2028),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2C303E)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF282B37),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "ŞAFAK SAYAR",
                    style: TextStyle(
                      color: Color(0xFF8E92A0),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "KALAN: 45 GÜN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 5:
      default:
        // FEATURE 5: ÖZEL ARKA PLAN TEMALARI
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeStageCard(Icons.flag_rounded, "VATAN", false),
            const SizedBox(width: 8),
            _buildThemeStageCard(Icons.military_tech_rounded, "PRO TEMA", true),
            const SizedBox(width: 8),
            _buildThemeStageCard(Icons.shield_rounded, "TAKTİK", false),
          ],
        );
    }
  }

  Widget _buildThemeStageCard(IconData icon, String label, bool isHighlighted) {
    return Container(
      width: isHighlighted ? 78 : 66,
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isHighlighted ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF222530) : const Color(0xFF1A1C24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? Colors.white : const Color(0xFF2C303E),
          width: isHighlighted ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isHighlighted ? const Color(0xFFFFD700) : Colors.white70,
            size: isHighlighted ? 22 : 17,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isHighlighted ? Colors.white : const Color(0xFF8E92A0),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C303E)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E92A0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(4.0, 18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==========================================
  // REAL USER TESTIMONIAL & SOCIAL PROOF
  // ==========================================
  Widget _buildUserTestimonialCard() {
    final t = _testimonials[_currentQuoteIndex];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _testimonials.length;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF14151B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF22242D)),
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
                      child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
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
            const SizedBox(height: 8),
            Text(
              t['quote']!,
              style: const TextStyle(
                color: Color(0xFFE2E4EC),
                fontSize: 12,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${t['author']} • ${t['location']}",
                  style: const TextStyle(
                    color: Color(0xFF787C8B),
                    fontSize: 11,
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
                        color: i == _currentQuoteIndex
                            ? Colors.white
                            : const Color(0xFF323644),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
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
  // PLAN SELECTOR (SOLID MATTE)
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
            // Radio circle
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

            // Plan Info
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

            // Price Right
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
  // ACTION BUTTON (SOLID - ZERO GRADIENT)
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
            _showSuccessDialog(
              title: "Asker Yakını Ayrıcalığı 💕",
              message: "Tüm PRO özellikler asker yakınlarımıza özel olarak tamamen ücretsiz tanımlanmıştır. Keyifle kullanabilirsiniz!",
            );
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
            style: const TextStyle(
              color: Color(0xFF6B7082),
              fontSize: 11.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLink("Kullanım Koşulları", "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("•", style: TextStyle(color: Color(0xFF4A4E5E))),
            ),
            _buildLink("Gizlilik Politikası", "https://safaksayar.vercel.app/#/privacy"),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              "Şimdilik Ücretsiz Devam Et",
              style: TextStyle(
                color: Color(0xFF8E92A0),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
