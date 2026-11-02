import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Satın alma veya geri yükleme sonrasında gösterilen "Artık PRO Plandasın" karşılama ekranı.
/// [celebrate] kapalıyken mevcut PRO üyeye sade bir üyelik özeti olarak açılır.
/// Kullanıcı devam ettiğinde kapanır; akışın geri kalanı çağıran sayfaya aittir.
class ProWelcomePage extends StatefulWidget {
  final String? planLabel;
  final bool isRestore;
  final bool celebrate;

  const ProWelcomePage({
    super.key,
    this.planLabel,
    this.isRestore = false,
    this.celebrate = true,
  });

  static Future<void> show(
    BuildContext context, {
    String? planLabel,
    bool isRestore = false,
    bool celebrate = true,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'ProWelcomePage'),
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => ProWelcomePage(
          planLabel: planLabel,
          isRestore: isRestore,
          celebrate: celebrate,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ProWelcomePage> createState() => _ProWelcomePageState();
}

class _ProWelcomePageState extends State<ProWelcomePage>
    with TickerProviderStateMixin {
  static const Color _background = Color(0xFF0C0D11);
  static const Color _gold = Color(0xFFFBBF24);
  static const Color _goldDeep = Color(0xFFF59E0B);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const Color _onGold = Color(0xFF1F1600);
  static const Color _green = Color(0xFF10B981);

  static const List<Map<String, dynamic>> _unlockedFeatures = [
    {
      'title': 'Çift Eşleşmesi',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFE11D48),
    },
    {
      'title': 'Canlı Widget',
      'icon': Icons.widgets_rounded,
      'color': Color(0xFF06B6D4),
    },
    {
      'title': 'Zaman Kapsülü',
      'icon': Icons.lock_clock_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': '4K Temalar',
      'icon': Icons.palette_rounded,
      'color': Color(0xFF84CC16),
    },
    {
      'title': 'Canlı Düello',
      'icon': Icons.military_tech_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Sıfır Reklam',
      'icon': Icons.block_rounded,
      'color': Color(0xFF10B981),
    },
  ];

  late AnimationController _introController;
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late ConfettiController _confettiController;

  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.celebrate) _confettiController.play();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name')?.trim() ?? '';
      final rank = prefs.getString('rutbe')?.trim() ?? '';
      if (mounted && name.isNotEmpty) {
        setState(() {
          _displayName = rank.isNotEmpty ? '$rank $name' : name;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _introController.dispose();
    _ringController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _continue() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  String get _title {
    if (!widget.celebrate) return 'PRO Plandasın';
    return widget.isRestore ? 'PRO Üyeliğin Geri Yüklendi' : 'Artık PRO Plandasın';
  }

  String get _subtitle {
    final String name = _displayName ?? '';
    if (!widget.celebrate) {
      final String greeting = name.isEmpty ? 'Merhaba.' : 'Merhaba, $name.';
      return '$greeting Tüm ayrıcalıkların açık.';
    }
    if (widget.isRestore) {
      final String greeting =
          name.isEmpty ? 'Tekrar hoş geldin.' : 'Tekrar hoş geldin, $name.';
      return '$greeting Tüm ayrıcalıkların yeniden açık.';
    }
    final String greeting = name.isEmpty ? 'Hoş geldin.' : 'Hoş geldin, $name.';
    return '$greeting Tüm ayrıcalıkların açıldı, şafağın bundan sonra reklamsız.';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            // Üstten yayılan altın ışık
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.72),
                    radius: 0.9,
                    colors: [
                      _goldDeep.withValues(alpha: 0.20),
                      _background.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 16),
                                SizedBox.square(
                                  dimension: constraints.maxHeight < 640 ? 108 : 148,
                                  child: FittedBox(child: _buildSeal()),
                                ),
                                const SizedBox(height: 20),
                                _reveal(0.28, 0.52, _buildStatusPill()),
                                const SizedBox(height: 12),
                                _reveal(0.32, 0.56, _buildHeadline()),
                                const SizedBox(height: 20),
                                _reveal(0.42, 0.66, _buildMembershipCard()),
                                const SizedBox(height: 12),
                                _buildFeatureGrid(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _reveal(0.78, 1.0, _buildFooter()),
                ],
              ),
            ),

            // Konfeti
            Align(
              alignment: const Alignment(0, -0.62),
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 14,
                maxBlastForce: 22,
                minBlastForce: 8,
                gravity: 0.22,
                colors: const [_gold, _goldLight, _goldDeep, Colors.white, _green],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// İçeriği giriş animasyonunun verilen aralığında yumuşakça belirginleştirir.
  Widget _reveal(double start, double end, Widget child) {
    final curved = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  // ==========================================
  // ALTIN MÜHÜR
  // ==========================================
  Widget _buildSeal() {
    final sealScale = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );
    final badgeScale = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.34, 0.62, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: sealScale,
      child: SizedBox(
        width: 148,
        height: 148,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Nefes alan ışık halkası
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final double v = _pulseController.value;
                return Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _goldDeep.withValues(alpha: 0.26 + 0.20 * v),
                        blurRadius: 30 + 16 * v,
                        spreadRadius: 2 + 4 * v,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Dönen altın çerçeve
            RotationTransition(
              turns: _ringController,
              child: Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _goldLight,
                      Color(0xFF85682A),
                      _gold,
                      Color(0xFF85682A),
                      _goldLight,
                    ],
                  ),
                ),
              ),
            ),

            // Mühür gövdesi
            Container(
              width: 118,
              height: 118,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_goldLight, _gold, _goldDeep],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: _onGold,
                size: 66,
              ),
            ),

            // Onay rozeti
            Positioned(
              right: 12,
              bottom: 12,
              child: ScaleTransition(
                scale: badgeScale,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _background, width: 3.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DURUM ETİKETİ
  // ==========================================
  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3240)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green.withValues(alpha: 0.55 + 0.45 * _pulseController.value),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          const Text(
            'ŞAFAK SAYAR PRO • AKTİF',
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
  // BAŞLIK
  // ==========================================
  Widget _buildHeadline() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_goldLight, _gold, _goldLight],
          ).createShader(bounds),
          child: Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB0B5C6),
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ÜYELİK KARTI
  // ==========================================
  Widget _buildMembershipCard() {
    final service = RevenueCatService.instance;
    final DateTime? expiresAt = service.premiumExpiresAt;
    final bool hasUpcomingDate =
        expiresAt != null && expiresAt.isAfter(DateTime.now());

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2A1C), Color(0xFF1B1810)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF85682A), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: _gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planLabel ?? 'PRO Üyelik',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _goldLight,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_displayName != null)
                      Text(
                        _displayName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD9B566),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _green.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'AKTİF',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (hasUpcomingDate) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: const Color(0xFF85682A).withValues(alpha: 0.45),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  service.isOnFreeTrial
                      ? 'Ücretsiz deneme bitişi'
                      : (service.premiumWillRenew ? 'Yenileme tarihi' : 'Geçerlilik bitişi'),
                  style: const TextStyle(
                    color: Color(0xFFD9B566),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('d MMMM yyyy', 'tr_TR').format(expiresAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // AÇILAN ÖZELLİKLER
  // ==========================================
  Widget _buildFeatureGrid() {
    final int rowCount = (_unlockedFeatures.length / 2).ceil();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        children: List.generate(rowCount, (row) {
          return Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : 8),
            child: Row(
              children: [
                Expanded(child: _buildFeatureTile(row * 2)),
                const SizedBox(width: 8),
                Expanded(child: _buildFeatureTile(row * 2 + 1)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeatureTile(int index) {
    final feature = _unlockedFeatures[index];
    final Color accent = feature['color'] as Color;
    final double start = 0.52 + index * 0.05;

    return _reveal(
      start,
      math.min(start + 0.2, 1.0),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF14161E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222633)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(feature['icon'] as IconData, color: accent, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      feature['title'] as String,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: _green, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        widget.celebrate ? 'Açıldı' : 'Açık',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
    );
  }

  // ==========================================
  // ANA BUTON
  // ==========================================
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_goldLight, _gold, _goldDeep]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _goldDeep.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _continue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.celebrate ? 'Keşfetmeye Başla' : 'Tamam',
                        style: const TextStyle(
                          color: _onGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: _onGold, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (RevenueCatService.instance.premiumWillRenew) ...[
            const SizedBox(height: 10),
            const Text(
              'Aboneliğini mağaza ayarlarından dilediğin an yönetebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF787C8B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
