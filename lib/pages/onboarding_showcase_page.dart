import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';

/// Professional, cinematic, full-bleed interactive Onboarding & Feature Showcase.
/// Completely edge-to-edge with authentic high-resolution soldier & military figures,
/// living micro-animations, zero card wrappers, and responsive overflow-free layout.
class OnboardingShowcasePage extends StatefulWidget {
  final bool isViewingFromSettings;

  const OnboardingShowcasePage({super.key, this.isViewingFromSettings = false});

  @override
  State<OnboardingShowcasePage> createState() => _OnboardingShowcasePageState();
}

class _OnboardingShowcasePageState extends State<OnboardingShowcasePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Cinematic looping motion & floating controllers
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    if (widget.isViewingFromSettings) {
      Navigator.pop(context);
      return;
    }

    // Check if user profile already exists
    final String? name = prefs.getString('name');
    final String? surname = prefs.getString('surname');
    final String? askerlikYeri = prefs.getString('askerlik_yeri');
    final String? memleket = prefs.getString('memleket');
    final String themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';

    if (name != null && surname != null && askerlikYeri != null && memleket != null) {
      final role = prefs.getString('user_role') ?? 'asker';
      if (role == 'asker') {
        SoldierMatchService.instance.ensureSoldierPublished();
      } else if (role == 'yakin' && (prefs.getBool('is_paired') ?? false)) {
        SoldierMatchService.instance.syncPairedSoldierData();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ManagePages'),
          builder: (context) => ManagePages(backgroundImage: themeImage),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'WelcomeRolePage'),
          builder: (context) => const WelcomeRolePage(),
        ),
      );
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White status bar icons for Android
        statusBarBrightness: Brightness.dark,       // White status bar icons for iOS
        systemNavigationBarColor: Color(0xFF050814),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF050814),
        body: Stack(
          children: [
            // 1. PageView for full-bleed edge-to-edge slides
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildSlide(
                  heroVisual: _buildCapsuleHero(),
                  accentColor: const Color(0xFFF43F5E),
                  title: 'Geleceğe Bırakılan\nSevgi Dolu Sürprizler',
                  highlightQuote:
                      '«Amaç anlık mesajlaşmak değil; o günü bekleyip o şafak gününün heyecanıyla sevdiğinden gelen sürprizi açmaktır.»',
                  description:
                      'Seni takip eden sevgilin, eşin veya ailen askerlik takviminden istediği tarihe özel ses kaydı, not ve fotoğraf bırakır. O tarih gelene kadar kilit açılmaz; o gün gelince sevdiğinin sesi ve hatırası kışlayı bayrama çevirir.',
                ),
                _buildSlide(
                  heroVisual: _buildDuelHero(),
                  accentColor: const Color(0xFFF59E0B),
                  title: 'Canın mı Sıkıldı?\nDüello Başlasın!',
                  highlightQuote:
                      '«Sıfır bot, %100 gerçek yarışmacılar! İki taraf da hazır olunca 5 soruluk nefes kesen karşılaşma başlar.»',
                  description:
                      'Boş vakitlerinde Türkiye genelindeki diğer askerler ve yakınlarıyla canlı eşleş. 5 hızlı soruyla kozlarını paylaş, puanları topla ve Türkiye şampiyonlar liginde adını zirveye yazdır!',
                ),
                _buildSlide(
                  heroVisual: _buildForumHero(),
                  accentColor: const Color(0xFF10B981),
                  title: 'Yalnız Değilsin:\nSor, Paylaş, Öğren',
                  highlightQuote:
                      '«Kışlalar ve şehirler farklı olsa da gönüller ve şafaklar bir.»',
                  description:
                      'Celp dönemleri, acemi birliği tavsiyeleri, usta birliği ve kışla hayatı hakkında aklına takılan her şeyi sor. 81 ilden binlerce tecrübeli Mehmetçik ve asker yakınıyla anında konuş ve yardımlaş.',
                ),
                _buildSlide(
                  heroVisual: _buildDogTagHero(),
                  accentColor: const Color(0xFFEF4444),
                  title: 'Gerçek Asker Künyesi &\nHassas Şafak Sayımı',
                  highlightQuote:
                      '«Tezkerene giden her saniye kabartmalı metal künyenle cebinde.»',
                  description:
                      'Resmi izin ve yol düşümü hesaplamaları, anlık saat-dakika-saniye sayacı, il plaka gösterimi ve eşleşme kodu ile askerliğini gururla takip et!',
                ),
              ],
            ),

          // 2. Fixed Top Bar: Branding & Skip Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Skip button
                    if (_currentPage < 3)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              backgroundColor: Colors.black.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                            ),
                            onPressed: _completeOnboarding,
                            child: const Text(
                              "Atla",
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Fixed Bottom Bar: Sliding Indicators & Full-Width Gradient CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF050814),
                    const Color(0xFF050814).withValues(alpha: 0.95),
                    const Color(0xFF050814).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing sliding progress indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isSelected = index == _currentPage;
                        final color = _getThemeColor(_currentPage);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 5,
                          width: isSelected ? 34 : 8,
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.7),
                                      blurRadius: 10,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    // Primary Full-Width CTA
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _nextPage,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFDC2626),
                                Color(0xFF991B1B),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == 3 ? "Şafağımı Saymaya Başla" : "Devam Et",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == 3 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ==========================================
  // FULL-BLEED SLIDE BUILDER (NATIVE FEATURE SHOWCASE)
  // ==========================================
  Widget _buildSlide({
    required Widget heroVisual,
    required Color accentColor,
    required String title,
    required String highlightQuote,
    required String description,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final topHeroHeight = screenHeight * 0.44;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Edge-to-Edge Hero Feature Showcase Visual
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeroHeight,
              child: heroVisual,
            ),

            // 2. Edge-to-Edge Spacious Typography & Story (Spacious margin below hero)
            Positioned(
              top: topHeroHeight + 20,
              left: 0,
              right: 0,
              bottom: 105, // Leave room for bottom CTA
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bold Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.22,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Highlight Quote
                      Text(
                        highlightQuote,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Description Body
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.45,
                          letterSpacing: 0.15,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 1. SPATIAL HERO FOR TIME CAPSULE (Sıfır Kart, Serbest Yüzen Ögeler)
  // ==========================================
  Widget _buildCapsuleHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _waveController]),
      builder: (context, child) {
        final float1 = math.sin(_floatController.value * math.pi * 2) * 6;
        final float2 = math.cos(_floatController.value * math.pi * 2) * 5;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Ambient rose aurora glow in the backdrop
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.9,
                    colors: [
                      const Color(0xFFF43F5E).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Centered visual group: Polaroid, Padlock, Wax Seal & Audio frequency
            SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Upper row: Polaroid, Padlock, Wax Seal (No clipping boundary)
                      SizedBox(
                        height: 155,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Left: Floating Polaroid Memory Photo (Tilted)
                            Positioned(
                              left: 18,
                              top: 16 + float2,
                              child: Transform.rotate(
                                angle: -0.12,
                                child: Container(
                                  width: 92,
                                  padding: const EdgeInsets.fromLTRB(6, 5, 6, 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                        offset: const Offset(-2, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Align(
                                        alignment: Alignment.topCenter,
                                        child: Text("📌", style: TextStyle(fontSize: 11)),
                                      ),
                                      Container(
                                        height: 58,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFFFB7185)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        "Biz ❤️",
                                        style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Center: Glowing Golden Padlock & Future Secret Date
                            Positioned(
                              top: 10 + float1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                                          blurRadius: 26,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.lock_clock_rounded, color: Color(0xFF451A03), size: 36),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "KİLİTLİ SÜRPRİZ",
                                      style: TextStyle(
                                        color: Color(0xFFFBBF24),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right: Floating TSK Postal Seal & Stamp
                            Positioned(
                              right: 18,
                              top: 14 - float2,
                              child: Transform.rotate(
                                angle: 0.14,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Wax Seal
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const RadialGradient(
                                          colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                            blurRadius: 14,
                                            offset: const Offset(2, 6),
                                          ),
                                        ],
                                        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "TSK\nPOSTA",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text("✉️ 14 KASIM", style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Lower: Free-Floating Audio Frequency Bars
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF38BDF8),
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 13),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "0:42",
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Animated Free-Air Soundwaves
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(20, (i) {
                              final waveH = 5 + (math.sin((_waveController.value * math.pi * 2) + i) * 11).abs();
                              return Container(
                                margin: const EdgeInsets.only(right: 3),
                                width: 3.5,
                                height: waveH,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "🎙️ Ses Kaydı",
                            style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 2. SPATIAL HERO FOR 1V1 DUEL (Elektrikli Karşılaşma Alanı)
  // ==========================================
  Widget _buildDuelHero() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.08);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Ambient amber battle aura
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.9,
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Centered Combatants & Question Group
            SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Combatants Row: SEN - VS - RAKİP
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Left: SEN
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                                ),
                                const SizedBox(height: 6),
                                const Text("SEN", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                                const Text("320 PUAN", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),

                            // Center: Flaming VS Electric Core
                            Transform.scale(
                              scale: pulseScale,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("⚡", style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 4),
                                        Text(
                                          "VS",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text("⚡", style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "CANLI EŞLEŞME",
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right: RAKİP
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 30),
                                ),
                                const SizedBox(height: 6),
                                const Text("RAKİP", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                                const Text("310 PUAN", style: TextStyle(color: Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Free-Floating Quiz Question & Options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("⏱️ 08 sn", style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "•  SORU 3/5: \"Cumhuriyet kaç yılında ilan edildi?\"",
                                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text("A) 1920", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("B) 1919", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                                      SizedBox(width: 6),
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text("+100 P", style: TextStyle(color: Color(0xFFFEF08A), fontSize: 10.5, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 3. SPATIAL HERO FOR FORUM (81 İl Takımyıldızı & Konuşma Balonları)
  // ==========================================
  Widget _buildForumHero() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final float1 = math.sin(_floatController.value * math.pi * 2) * 5;
        final float2 = math.cos(_floatController.value * math.pi * 2) * 4;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Ambient emerald constellation aura
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Background Constellation Lines CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: ConstellationPainter(progress: _floatController.value),
              ),
            ),

            // Centered Conversation Group: İzmir Node, Ankara Node & 81-City Badge
            SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating City Node 1: İZMİR & Speech Cloud
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 30),
                          child: Transform.translate(
                            offset: Offset(0, float1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF064E3B).withValues(alpha: 0.85),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("🇹🇷 ", style: TextStyle(fontSize: 12)),
                                      Flexible(
                                        child: Text(
                                          "Acemi birliğinde tabanlık çok önemli devrem!",
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Text(
                                    "📍 35 İZMİR • Mehmet Ç.",
                                    style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 9.5, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Floating City Node 2: ANKARA & Advice Cloud
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30, right: 20),
                          child: Transform.translate(
                            offset: Offset(0, -float2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2027).withValues(alpha: 0.9),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "Celp yerleri açıklandı, hayırlı tezkereler! 🛡️",
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Text(
                                    "📍 06 ANKARA • Çavuş Burak (❤️ 184)",
                                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dynamic 81-City Network Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text(
                              "81 İL • 24.500+ ASKER TEK YÜREK",
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 4. SPATIAL HERO FOR DOG TAG & COUNTDOWN (Sallanan Metal Künye & Radar)
  // ==========================================
  Widget _buildDogTagHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _pulseController]),
      builder: (context, child) {
        final swingAngle = math.sin(_floatController.value * math.pi * 2) * 0.06;
        final float = math.sin(_floatController.value * math.pi) * 4;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Ambient red aura
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.9,
                    colors: [
                      const Color(0xFFEF4444).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Centered Row: Progress Radar + Swinging Künye + Live Seconds Counter
            SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 12, right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Orbiting Progress Radar
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: CustomPaint(
                              painter: RadarGaugePainter(progress: 0.68),
                              child: const Center(
                                child: Text(
                                  "%68",
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("BİTTİ", style: TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        ],
                      ),

                      // Center: 3D Metal Dog Tag (Künye) hanging on chain & swinging freely
                      Transform.rotate(
                        angle: swingAngle,
                        child: Transform.translate(
                          offset: Offset(0, float),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Metallic ball chain hanging from above
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("⚪-⚪-⚪-⚪-⚪", style: TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 1)),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // Realistic Metallic Dog Tag
                              Container(
                                width: 165,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF1F5F9),
                                      Color(0xFF94A3B8),
                                      Color(0xFF475569),
                                      Color(0xFF1E293B),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Punch Hole
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0F172A),
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text("K.K.K. • TÜRKİYE", style: TextStyle(color: Color(0xFF0F172A), fontSize: 9.5, fontWeight: FontWeight.w900)),
                                    const Text("MEHMETÇİK", style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 2),
                                    const Text("TERTİP: 2026/1", style: TextStyle(color: Color(0xFF1E293B), fontSize: 9, fontWeight: FontWeight.bold)),
                                    const Text("KAN: A Rh (+)", style: TextStyle(color: Color(0xFF1E293B), fontSize: 9, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("ŞAFAK: 142 GÜN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right: Orbiting Digital Seconds Clock & Plate
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("08:44:12", style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          const SizedBox(height: 2),
                          const Text("CANLI GERİ SAYIM", style: TextStyle(color: Color(0xFFEF4444), fontSize: 7.5, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text("🇹🇷 06 ANKARA", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getThemeColor(int page) {
    switch (page) {
      case 0:
        return const Color(0xFFF43F5E);
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFF10B981);
      case 3:
      default:
        return const Color(0xFFEF4444);
    }
  }
}

class ConstellationPainter extends CustomPainter {
  final double progress;
  ConstellationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final p1 = Offset(size.width * 0.22, size.height * 0.38);
    final p2 = Offset(size.width * 0.52, size.height * 0.22);
    final p3 = Offset(size.width * 0.82, size.height * 0.52);
    final p4 = Offset(size.width * 0.42, size.height * 0.82);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawLine(p1, p3, paint);

    for (final p in [p1, p2, p3, p4]) {
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) => true;
}

class RadarGaugePainter extends CustomPainter {
  final double progress;
  RadarGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFEF4444)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadarGaugePainter oldDelegate) => false;
}
