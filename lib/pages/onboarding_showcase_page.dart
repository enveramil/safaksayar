import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/Services/fcm_service.dart';
import 'package:safaksayar/Services/notification_service.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/widgets/setup_ui.dart';

class _OnboardingSlide {
  final Color accent;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.accent,
    required this.title,
    required this.description,
  });
}

/// Uygulamanın temel değerlerini dört kısa slaytta anlatan tanıtım ekranı.
class OnboardingShowcasePage extends StatefulWidget {
  final bool isViewingFromSettings;

  const OnboardingShowcasePage({super.key, this.isViewingFromSettings = false});

  @override
  State<OnboardingShowcasePage> createState() => _OnboardingShowcasePageState();
}

class _OnboardingShowcasePageState extends State<OnboardingShowcasePage>
    with TickerProviderStateMixin {
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      accent: SetupColors.goldDeep,
      title: 'Terhisine Giden\nHer Saniye Yanında',
      description:
          'İzin ve yol düşümleriyle net terhis tarihini gör, geri sayımı saniyesine kadar takip et.',
    ),
    _OnboardingSlide(
      accent: Color(0xFFF43F5E),
      title: 'Geleceğe Bırakılan\nSürprizler',
      description:
          'Sevdiklerin seçtiği güne ses kaydı, not ve fotoğraf bırakır. O gün gelene kadar kilit açılmaz.',
    ),
    _OnboardingSlide(
      accent: Color(0xFF8B5CF6),
      title: 'Canın mı Sıkıldı?\nDüello Başlasın',
      description:
          'Diğer asker ve yakınlarıyla canlı eşleş, 5 hızlı soruda puanları topla, ligde zirveye çık.',
    ),
    _OnboardingSlide(
      accent: SetupColors.green,
      title: 'Yalnız Değilsin:\nSor, Paylaş, Öğren',
      description:
          'Celp, acemi birliği ve kışla hayatı hakkında merak ettiklerini 81 ilden asker ve yakınlarına sor.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _waveController;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  double get _pageValue {
    if (_pageController.hasClients && _pageController.position.haveDimensions) {
      return _pageController.page ?? _currentPage.toDouble();
    }
    return _currentPage.toDouble();
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Onboarding tamamlandıktan hemen sonra bildirim iznini iste ve FCM/Notification servislerini başlat
    unawaited(FCMService().init());
    unawaited(NotificationService().init());

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
    final String themeImage =
        prefs.getString('themeImage') ?? 'assets/images/img0.webp';

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
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Color _accentAt(double page) {
    final int lower = page.floor().clamp(0, _slides.length - 1);
    final int upper = page.ceil().clamp(0, _slides.length - 1);
    return Color.lerp(
        _slides[lower].accent, _slides[upper].accent, page - lower)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: setupOverlayStyle,
      child: Scaffold(
        backgroundColor: SetupColors.background,
        body: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            return SetupBackground(
                accent: _accentAt(_pageValue), child: child!);
          },
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _slides.length,
                    onPageChanged: (page) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) => _buildSlide(index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                  child: SetupPrimaryButton(
                    label: _isLastPage ? 'Hadi Başlayalım' : 'Devam Et',
                    onPressed: _nextPage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ÜST BAR: İLERLEME ÇUBUKLARI & ATLA
  // ==========================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 10, 2),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final double page = _pageValue;
                return Row(
                  children: List.generate(_slides.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: (page - index + 1).clamp(0.0, 1.0),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            valueColor:
                                const AlwaysStoppedAnimation(SetupColors.gold),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            height: 40,
            child: _isLastPage
                ? null
                : TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: SetupColors.textMuted,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Atla',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SLAYT
  // ==========================================
  Widget _buildSlide(int index) {
    final slide = _slides[index];

    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          final double delta = _pageValue - index;
          final double visibility = (1 - delta.abs()).clamp(0.0, 1.0);
          return Column(
            children: [
              // Görsel, metinden biraz daha yavaş kayarak derinlik hissi verir
              Expanded(
                child: Transform.translate(
                  offset: Offset(delta * 70, 0),
                  child: Opacity(
                    opacity: visibility,
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * visibility,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 340,
                          height: 340,
                          // Görsel bir tanıtım maketi; yazı boyutu ayarıyla bozulmaz
                          child: MediaQuery.withNoTextScaling(
                              child: _buildHero(index)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Büyük yazı boyutlarında metin kendi içinde kayar, görseli ezmez
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: constraints.maxHeight * 0.48),
                child: child!,
              ),
            ],
          );
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 16),
          child: Column(
            children: [
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SetupColors.textMuted,
                  fontSize: 14.5,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(int index) {
    switch (index) {
      case 0:
        return _buildCountdownHero();
      case 1:
        return _buildCapsuleHero();
      case 2:
        return _buildDuelHero();
      default:
        return _buildForumHero();
    }
  }

  /// Yavaşça süzülen öge için dikey kayma değeri.
  double _floatOffset(double phase, double amplitude) {
    return math.sin((_floatController.value + phase) * math.pi * 2) * amplitude;
  }

  BoxDecoration _heroCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: SetupColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor ?? SetupColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  // ==========================================
  // 1. ŞAFAK SAYACI & KÜNYE
  // ==========================================
  Widget _buildCountdownHero() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 236,
              height: 236,
              child: CustomPaint(
                painter: SafakRingPainter(progress: 0.68),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ŞAFAK',
                      style: TextStyle(
                        color: SetupColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                      ),
                    ),
                    Text(
                      '142',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      '08 : 44 : 12',
                      style: TextStyle(
                        color: SetupColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 34 + _floatOffset(0, 5),
              child: _buildHeroPill(Icons.location_on_rounded, '06 Ankara'),
            ),
            Positioned(
              right: 4,
              top: 66 + _floatOffset(0.5, 5),
              child: _buildHeroPill(Icons.trending_up_rounded, '%68 bitti'),
            ),
            Positioned(
              right: 14,
              bottom: 12 + _floatOffset(0.25, 5),
              child: Transform.rotate(angle: 0.1, child: _buildDogTag()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SetupColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SetupColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: SetupColors.gold, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogTag() {
    return Container(
      width: 124,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F5F9), Color(0xFFA9B4C4), Color(0xFF64748B)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: SetupColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'MEHMETÇİK',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const Text(
            'TERTİP 2026/1',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. ZAMAN KAPSÜLÜ
  // ==========================================
  Widget _buildCapsuleHero() {
    const Color rose = Color(0xFFF43F5E);

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _waveController]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Polaroid anı
            Positioned(
              left: 16,
              top: 12 + _floatOffset(0.2, 5),
              child: Transform.rotate(angle: -0.1, child: _buildPolaroid()),
            ),

            // Mühürlü zarf
            Positioned(
              right: 14,
              top: 158 + _floatOffset(0.6, 5),
              child: Transform.rotate(
                angle: 0.03,
                child: Container(
                  width: 214,
                  padding: const EdgeInsets.all(14),
                  decoration: _heroCardDecoration(
                      borderColor: rose.withValues(alpha: 0.45)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  SetupColors.goldLight,
                                  SetupColors.goldDeep
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_clock_rounded,
                              color: SetupColors.onGold,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kilitli Sürpriz',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '14 Kasım\'da açılır',
                                  style: TextStyle(
                                    color: SetupColors.gold,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                                color: rose, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(16, (i) {
                                final double height = 5 +
                                    (math.sin(_waveController.value *
                                                    math.pi *
                                                    2 +
                                                i * 0.9) *
                                            13)
                                        .abs();
                                return Container(
                                  width: 3,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: rose.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              right: 34,
              top: 52 + _floatOffset(0.4, 4),
              child: _buildHeroPill(Icons.mic_rounded, 'Ses kaydı'),
            ),
            Positioned(
              right: 58,
              top: 102 + _floatOffset(0.8, 4),
              child: _buildHeroPill(Icons.favorite_rounded, 'Sevdiğinden'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolaroid() {
    return Container(
      width: 104,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 86,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF831843),
                  Color(0xFFBE185D),
                  Color(0xFFFB7185)
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 7),
          const Text(
            'Bizim günümüz',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. CANLI DÜELLO
  // ==========================================
  Widget _buildDuelHero() {
    const Color violet = Color(0xFF8B5CF6);
    const Color rose = Color(0xFFF43F5E);

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Center(
          child: Transform.translate(
            offset: Offset(0, _floatOffset(0, 5)),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: _heroCardDecoration(
                  borderColor: violet.withValues(alpha: 0.45)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildDuelist(
                              'Sen', '320', violet, Icons.person_rounded)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [SetupColors.gold, SetupColors.goldDeep]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            color: SetupColors.onGold,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                          child: _buildDuelist('Rakip', '310', rose,
                              Icons.person_outline_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text(
                        'SORU 3/5',
                        style: TextStyle(
                          color: SetupColors.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.timer_outlined,
                          color: SetupColors.gold, size: 14),
                      SizedBox(width: 3),
                      Text(
                        '8 sn',
                        style: TextStyle(
                          color: SetupColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cumhuriyet hangi yıl ilan edildi?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  _buildDuelAnswer('1920', isCorrect: false),
                  const SizedBox(height: 7),
                  _buildDuelAnswer('1923', isCorrect: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuelist(String name, String score, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 27),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
        ),
        Text(
          '$score puan',
          style: const TextStyle(
            color: SetupColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDuelAnswer(String label, {required bool isCorrect}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect
            ? SetupColors.green.withValues(alpha: 0.16)
            : SetupColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isCorrect ? SetupColors.green : SetupColors.border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isCorrect ? Colors.white : SetupColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (isCorrect) ...[
            const Text(
              '+100',
              style: TextStyle(
                color: SetupColors.greenLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.check_circle_rounded,
                color: SetupColors.green, size: 17),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 4. FORUM
  // ==========================================
  Widget _buildForumHero() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: ConstellationPainter()),
            ),
            Positioned(
              left: 12,
              top: 34 + _floatOffset(0, 4),
              child: _buildChatBubble(
                author: 'Mehmet Ç. • 35 İzmir',
                message: 'Acemi birliğinde tabanlık çok önemli devrem!',
                color: SetupColors.green,
                isIncoming: true,
              ),
            ),
            Positioned(
              right: 12,
              top: 136 + _floatOffset(0.45, 4),
              child: _buildChatBubble(
                author: 'Burak • 06 Ankara',
                message: 'Celp yerleri açıklandı, hayırlı tezkereler!',
                color: const Color(0xFF38BDF8),
                isIncoming: false,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40 + _floatOffset(0.7, 3),
              child: Center(
                  child: _buildHeroPill(Icons.hub_rounded, '81 il, tek yürek')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatBubble({
    required String author,
    required String message,
    required Color color,
    required bool isIncoming,
  }) {
    return Container(
      width: 252,
      padding: const EdgeInsets.all(13),
      decoration: _heroCardDecoration(borderColor: color.withValues(alpha: 0.4))
          .copyWith(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isIncoming ? 4 : 18),
          bottomRight: Radius.circular(isIncoming ? 18 : 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = SetupColors.green.withValues(alpha: 0.16)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = SetupColors.green.withValues(alpha: 0.45);

    final points = [
      Offset(size.width * 0.12, size.height * 0.12),
      Offset(size.width * 0.86, size.height * 0.2),
      Offset(size.width * 0.93, size.height * 0.68),
      Offset(size.width * 0.5, size.height * 0.92),
      Offset(size.width * 0.07, size.height * 0.62),
    ];

    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, linePaint);
    canvas.drawLine(points[0], points[2], linePaint);
    canvas.drawLine(points[1], points[4], linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) => false;
}

class SafakRingPainter extends CustomPainter {
  final double progress;
  SafakRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [
            SetupColors.goldLight,
            SetupColors.gold,
            SetupColors.goldDeep
          ],
        ).createShader(rect)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant SafakRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
