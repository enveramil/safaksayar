import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/pages/faq_page.dart';
import 'package:safaksayar/pages/notes_page.dart';
import 'package:safaksayar/pages/quiz_page.dart';
import 'package:safaksayar/pages/rank_page.dart';
import 'package:safaksayar/pages/onboarding_showcase_page.dart';
import 'package:safaksayar/pages/safak_cizelgesi_page.dart';
import 'package:safaksayar/pages/safak_sozleri.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoScreen extends StatefulWidget {
  final String backgroundImage;
  const InfoScreen({super.key, required this.backgroundImage});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  InterstitialAd? _interstitialAd;
  int _remainingDays = 84;
  String _memleket = '';
  int _slangIndex = 0;

  static const List<Map<String, String>> _kislaSozlugu = [
    {
      'term': 'PLAKA ŞAFAĞI',
      'desc': 'Kalan gün sayısı 81\'in altına düştüğünde her günün Türkiye il plakalarıyla (81 Düzce\'den 01 Adana\'ya) sayılması geleneğidir.',
    },
    {
      'term': 'ATARSA',
      'desc': 'Bugünkü nöbet ve gün bittiğinde yarın sabah doğacak güneşle birlikte kalacak olan şafak sayısını ifade eder.',
    },
    {
      'term': 'DOĞAN GÜNEŞ',
      'desc': 'Terhis sabahından bir önceki son günü anlatır. Artık sayılacak gün kalmamış, hürriyet güneşi doğmak üzeredir.',
    },
    {
      'term': 'DEVRE & TERTİP',
      'desc': 'Aynı celp döneminde silah altına alınan, aynı şafağı sayan kader ve koğuş arkadaşlarına verilen isimdir.',
    },
    {
      'term': 'SÜLÜS',
      'desc': 'Sevk belgesi; askerin birliğine katılacağı resmi başlangıç tarihini ve görev yerini gösteren belgedir.',
    },
    {
      'term': 'HÜRGENERAL',
      'desc': 'Tezkeresini alıp sivil hayata kavuşan askerin kışla kültüründeki en yüksek ve en tatlı fahri rütbesidir.',
    },
    {
      'term': 'İÇTİMA',
      'desc': 'Birliğin yoklama, denetim veya günlük emirlerin tebliği için sabah ve akşam düzenli saf halinde toplanmasıdır.',
    },
  ];

  @override
  void initState() {
    super.initState();
    SoldierMatchService.instance.dataSyncVersion.addListener(_onExternalDataChanged);
    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumChanged);
    _loadUserSafakContext();
    _loadInterstitialAd();
  }

  void _onPremiumChanged() {
    if (RevenueCatService.instance.isPremium && _interstitialAd != null) {
      try {
        _interstitialAd?.dispose();
        _interstitialAd = null;
      } catch (_) {}
    }
  }

  void _onExternalDataChanged() {
    if (mounted) {
      _loadUserSafakContext();
    }
  }

  Future<void> _loadUserSafakContext() async {
    final prefs = await SharedPreferences.getInstance();
    final endStr = prefs.getString('end_date') ?? '';
    final memleket = prefs.getString('memleket') ?? '';

    int calcDays = 84;
    if (endStr.isNotEmpty) {
      try {
        final end = DateTime.parse(endStr);
        final diff = end.difference(DateTime.now()).inDays;
        calcDays = diff < 0 ? 0 : diff;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _remainingDays = calcDays;
        _memleket = memleket;
      });
    }
  }

  void _loadInterstitialAd() {
    if (AdManager.isDev) return;
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-4655119937024112/6340277716',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (AdManager.isDev) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  @override
  void dispose() {
    SoldierMatchService.instance.dataSyncVersion.removeListener(_onExternalDataChanged);
    RevenueCatService.instance.isPremiumNotifier.removeListener(_onPremiumChanged);
    try {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    } catch (_) {}
    super.dispose();
  }

  bool get _isDefaultTheme => widget.backgroundImage == 'assets/images/img0.webp';

  Color _getTextColor() => _isDefaultTheme ? const Color(0xFF0F172A) : Colors.white;

  Color _getSubtitleColor() =>
      _isDefaultTheme ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.72);

  Color _getSurfaceColor() => _isDefaultTheme
      ? Colors.white.withValues(alpha: 0.94)
      : const Color(0xFF0F172A).withValues(alpha: 0.62);

  Color _getBorderColor() => _isDefaultTheme
      ? const Color(0xFFE2E8F0)
      : Colors.white.withValues(alpha: 0.14);

  String _normalizeTr(String input) {
    return input
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase()
        .trim();
  }

  Map<String, dynamic> _resolveFeaturedCity() {
    if (_remainingDays >= 1 && _remainingDays <= 81) {
      return illerVePlakalar[_remainingDays - 1];
    }
    if (_memleket.trim().isNotEmpty) {
      final normMem = _normalizeTr(_memleket);
      for (final city in illerVePlakalar) {
        if (_normalizeTr(city['il'] ?? '') == normMem) {
          return city;
        }
      }
    }
    return illerVePlakalar[80]; // 81 Düzce (plaka başlangıcı)
  }

  @override
  Widget build(BuildContext context) {
    final double topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDefaultTheme ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: (topPad > 0 ? topPad : 20) + 10,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Custom Kışla Merkezi Header
            _buildKislaHeader(),

            const SizedBox(height: 16),

            // 2. Canlı Plaka Şafağı Radarı (Hero Card -> Opens 81 İl Plaka Atlası)
            _buildLivePlateRadarCard(),

            const SizedBox(height: 14),

            // 3. Kışla Bilgi Arenası Spotlight (1v1 Düello & Milyoner)
            _buildArenaSpotlightCard(),

            const SizedBox(height: 20),

            // 4. Section Label: Askeri Rehber & Kışla Araçları
            _buildSectionLabel(
              icon: Icons.grid_view_rounded,
              label: 'KIŞLA ARAÇLARI & REHBER',
            ),

            const SizedBox(height: 10),

            // 5. 2x2 Asymmetric Bento Grid
            _buildBentoGrid(),

            const SizedBox(height: 12),

            // 6. Dual Quick Tools Strip (Şafak Çizelgesi & Özellik Turu)
            _buildQuickToolsRow(),

            const SizedBox(height: 20),

            // 7. Interactive Kışla Sözlüğü & Kültür Kartı
            _buildSectionLabel(
              icon: Icons.menu_book_rounded,
              label: 'KIŞLA KÜLTÜRÜ & SÖZLÜK',
            ),

            const SizedBox(height: 10),

            _buildKislaCultureCard(),

            const SizedBox(height: 16),

            // 8. Compact PRO Membership Card
            _buildProShowcaseFooter(),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 1. CUSTOM HEADER ("KIŞLA MERKEZİ")
  // ============================================================================
  Widget _buildKislaHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'OYUN • REHBER • ASKERİ KÜLTÜR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: _isDefaultTheme
                            ? const Color(0xFF059669)
                            : const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'KIŞLA MERKEZİ',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: _getTextColor(),
                  ),
                ),
              ],
            ),
          ),

          // Quick Share Button
          Builder(
            builder: (shareCtx) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final String shareLink = Platform.isIOS
                      ? 'https://apps.apple.com/app/id6777999683'
                      : 'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar';
                  final box = shareCtx.findRenderObject() as RenderBox?;
                  Rect? origin;
                  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
                    origin = box.localToGlobal(Offset.zero) & box.size;
                  } else {
                    final size = MediaQuery.sizeOf(shareCtx);
                    origin = Rect.fromLTWH(size.width / 2 - 20, size.height / 2 - 20, 40, 40);
                  }
                  Share.share(shareLink, sharePositionOrigin: origin);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _getSurfaceColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getBorderColor()),
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    size: 17,
                    color: _getTextColor(),
                  ),
                ),
              );
            },
          ),

          // PRO / VIP Badge
          ValueListenableBuilder<bool>(
            valueListenable: RevenueCatService.instance.isPremiumNotifier,
            builder: (context, isPremium, _) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  PremiumPaywallPage.show(context, source: 'kisla_header');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPremium
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                        size: 14,
                        color: isPremium ? Colors.white : const Color(0xFF1F1600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? 'VIP' : 'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isPremium ? Colors.white : const Color(0xFF1F1600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 2. CANLI PLAKA ŞAFAĞI RADARI (81 İL & PLAKA REHBERİ GİRİŞİ)
  // ============================================================================
  Widget _buildLivePlateRadarCard() {
    final city = _resolveFeaturedCity();
    final String cityName = (city['il'] ?? 'Düzce').toString();
    final String plateCode = (city['plaka'] ?? '81').toString();
    final String cityAsset = (city['resim'] ?? 'assets/images/istanbul.webp').toString();

    final bool isInPlateZone = _remainingDays >= 1 && _remainingDays <= 81;
    final String topTag = isInPlateZone
        ? '🎯 BUGÜNKÜ PLAKA ŞAFAĞIN'
        : (_remainingDays > 81
            ? 'PLAKALARA DÜŞMEYE ${_remainingDays - 81} GÜN KALDI'
            : '81 İL & PLAKA ATLASI');

    final String subHeadline = isInPlateZone
        ? 'Şafak $plateCode $cityName! Tüm 81 il plaka listesini keşfet'
        : (_memleket.isNotEmpty
            ? 'Memleket: $cityName ($plateCode) • 81 il plaka kodlarını incele'
            : 'Türkiye\'nin 81 ili ve plaka şafağı sırasına göz at');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'IllerPlakaScreen'),
              builder: (context) => IllerPlakaScreen(
                activePlateSafak: isInPlateZone ? _remainingDays : null,
              ),
            ),
          );
        },
        child: Container(
          height: 158,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isInPlateZone
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: _isDefaultTheme ? 0.0 : 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.14 : 0.35),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // City Background Photo
                Image.asset(
                  cityAsset,
                  fit: BoxFit.cover,
                  cacheWidth: 700,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),

                // Cinematic Gradient Overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.50),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Real TR License Plate + Status Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Authentic TR Plate Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: Colors.black87, width: 1.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF003399),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'TR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  plateCode,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Radar Tag Pill
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                topTag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Bottom Row: City Headline + Action Chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cityName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subHeadline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '81 İl Plaka',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Color(0xFF0F172A),
                                ),
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
    );
  }

  // ============================================================================
  // 3. KIŞLA BİLGİ ARENASI SPOTLIGHT (1v1 DÜELLO & MİLYONER)
  // ============================================================================
  Widget _buildArenaSpotlightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF171332),
              Color(0xFF0F172A),
              Color(0xFF271B09),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.mediumImpact();
              AdManager.instance.showArenaInterstitialAd();
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'QuizPage'),
                  builder: (context) => const QuizPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            '⚔️ 1v1 CANLI DÜELLO & YARIŞMA',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Kışla Bilgi Arenası',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kim Milyoner Olmak İster heyecanıyla devrelerinle canlı düelloya gir, liderlik tablosuna çık!',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            height: 1.32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: Color(0xFF1F1600),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Arenaya Gir',
                                style: TextStyle(
                                  color: Color(0xFF1F1600),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              const Color(0xFFF59E0B).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/milyoner.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 4. SECTION LABEL
  // ============================================================================
  Widget _buildSectionLabel({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: _getSubtitleColor(),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: _getSubtitleColor(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 5. 2x2 TACTICAL BENTO GRID
  // ============================================================================
  Widget _buildBentoGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  tag: '4 KUVVET',
                  title: 'TSK Rütbeler',
                  subtitle: 'Kara, Deniz, Hava ve Jandarma hiyerarşisi',
                  assetPath: 'assets/images/military-rank.webp',
                  accent: const Color(0xFF6366F1),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'RankPage'),
                        builder: (context) => const RankPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  tag: 'EL KİTABI',
                  title: 'Askerlik Rehberi',
                  subtitle: 'İzin, sülüs, haklar ve merak edilenler',
                  assetPath: 'assets/images/question-mark.webp',
                  accent: const Color(0xFF0EA5E9),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'FaqPage'),
                        builder: (context) => const FaqPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  tag: '50+ KART',
                  title: 'Şafak Sözleri',
                  subtitle: 'Paylaşmaya hazır vatan ve hasret sözleri',
                  assetPath: 'assets/images/pen.webp',
                  accent: const Color(0xFFF43F5E),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'SafakSozleri'),
                        builder: (context) => SafakSozleri(
                          backgroundImage: widget.backgroundImage,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  tag: 'ANI DEFTERİ',
                  title: 'Kışla Notlarım',
                  subtitle: 'Nöbet saatlerini ve askerlik anılarını yaz',
                  assetPath: 'assets/images/notes.webp',
                  accent: const Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'NotesScreen'),
                        builder: (context) => NotesScreen(context: context),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required String tag,
    required String title,
    required String subtitle,
    required String assetPath,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final bool isDark = !_isDefaultTheme;

    return Container(
      height: 164,
      decoration: BoxDecoration(
        color: _getSurfaceColor(),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.32)
              : accent.withValues(alpha: 0.22),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Subtle Corner Accent Glow
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.09),
                ),
              ),
            ),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Asset Icon + Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white : accent,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Bottom Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: _getTextColor(),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_outward_rounded,
                                size: 15,
                                color: accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.28,
                              color: _getSubtitleColor(),
                            ),
                          ),
                        ],
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

  // ============================================================================
  // 6. QUICK TOOLS ROW (ŞAFAK ÇİZELGESİ & ÖZELLİKLERİ KEŞFET)
  // ============================================================================
  Widget _buildQuickToolsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactToolPill(
              icon: Icons.calendar_view_month_rounded,
              title: 'Şafak Çizelgesi',
              subtitle: 'Günleri boya & bitir',
              accent: const Color(0xFF8B5CF6),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'SafakCizelgesiPage'),
                    builder: (context) => SafakCizelgesiPage(
                      backgroundImage: widget.backgroundImage,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactToolPill(
              icon: Icons.auto_awesome_rounded,
              title: 'Özellik Turu',
              subtitle: 'Kapsül & düello rehberi',
              accent: const Color(0xFFEC4899),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'OnboardingShowcasePage'),
                    builder: (context) => const OnboardingShowcasePage(
                      isViewingFromSettings: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolPill({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final bool isDark = !_isDefaultTheme;
    return Container(
      decoration: BoxDecoration(
        color: _getSurfaceColor(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _getBorderColor(), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _getSubtitleColor(),
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
    );
  }

  // ============================================================================
  // 7. INTERACTIVE KIŞLA SÖZLÜĞÜ & KÜLTÜR KARTI (TAP TO CYCLE)
  // ============================================================================
  Widget _buildKislaCultureCard() {
    final current = _kislaSozlugu[_slangIndex];
    final bool isDark = !_isDefaultTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _slangIndex = (_slangIndex + 1) % _kislaSozlugu.length;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getSurfaceColor(),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _getBorderColor(), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TERİM ${_slangIndex + 1}/${_kislaSozlugu.length} • ${current['term']}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sonraki',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getSubtitleColor(),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: _getSubtitleColor(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  current['desc']!,
                  key: ValueKey(_slangIndex),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 8. COMPACT PRO SHOWCASE FOOTER
  // ============================================================================
  Widget _buildProShowcaseFooter() {
    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPremium
                  ? [
                      const Color(0xFF064E3B).withValues(alpha: 0.92),
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                    ]
                  : [
                      const Color(0xFF451A03).withValues(alpha: 0.92),
                      const Color(0xFF0F172A).withValues(alpha: 0.96),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: (isPremium ? const Color(0xFF10B981) : const Color(0xFFFFD700))
                  .withValues(alpha: 0.45),
              width: 1.3,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                HapticFeedback.lightImpact();
                PremiumPaywallPage.show(context, source: 'kisla_footer_banner');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPremium
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                        color: isPremium ? Colors.white : const Color(0xFF1F1600),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium
                                ? 'Şafak Sayar VIP Aktif'
                                : 'Kışla Deneyimini PRO\'ya Taşı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPremium
                                ? 'Sınırsız düello, özel askeri temalar ve tüm ayrıcalıklar açık.'
                                : 'Sınırsız 1v1 düello, 30 askeri tema, canlı takip kodu ve sıfır reklam.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: isPremium ? const Color(0xFF34D399) : const Color(0xFFFFD700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 81 İL VE PLAKA KODLARI EKRANI
// ============================================================================
class IllerPlakaScreen extends StatefulWidget {
  final int? activePlateSafak;
  const IllerPlakaScreen({super.key, this.activePlateSafak});

  @override
  State<IllerPlakaScreen> createState() => _IllerPlakaScreenState();
}

class _IllerPlakaScreenState extends State<IllerPlakaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    return input
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase()
        .trim();
  }

  List<Map<String, dynamic>> get _filteredIller {
    if (_searchQuery.trim().isEmpty) {
      return illerVePlakalar;
    }
    final query = _normalize(_searchQuery);
    return illerVePlakalar.where((item) {
      final ilName = _normalize(item['il']?.toString() ?? '');
      final plaka = (item['plaka']?.toString() ?? '').trim();
      final plakaNum = int.tryParse(plaka)?.toString() ?? '';

      return ilName.contains(query) ||
          plaka.contains(query) ||
          plakaNum == query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredIller;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '81 İl & Plaka Şafağı',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${filteredList.length} İl',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'İl adı veya plaka kodu ara (Örn: 34, İzmir, 06)...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final il = filteredList[index];
                      return _buildCityCard(il);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(Map<String, dynamic> il) {
    final int? plateInt = int.tryParse((il['plaka'] ?? '').toString());
    final bool isCurrentSafak =
        widget.activePlateSafak != null && plateInt == widget.activePlateSafak;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 144,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: isCurrentSafak
            ? Border.all(color: const Color(0xFF10B981), width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentSafak
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.12),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCurrentSafak ? 15.5 : 18),
        child: Stack(
          children: [
            Image.asset(
              il['resim'] ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 650,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1E293B),
                  alignment: Alignment.center,
                  child: const Icon(Icons.location_city_rounded, color: Colors.white24, size: 48),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black87, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003399),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'TR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          il['plaka'] ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentSafak)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🎯 BUGÜNKÜ ŞAFAĞIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      il['il'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(offset: Offset(1.0, 1.0), blurRadius: 4.0, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Text(
                      'Şafak ${il['plaka']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sonuç Bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"$_searchQuery" ile eşleşen il veya plaka kodu bulunamadı.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text('Aramayı Temizle'),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Map<String, dynamic>> illerVePlakalar = [
  {"plaka": "01", "il": "Adana", "resim": "assets/images/adana.webp"},
  {"plaka": "02", "il": "Adıyaman", "resim": "assets/images/adıyaman.webp"},
  {"plaka": "03", "il": "Afyonkarahisar", "resim": "assets/images/afyonkarahisar.webp"},
  {"plaka": "04", "il": "Ağrı", "resim": "assets/images/agrı.webp"},
  {"plaka": "05", "il": "Amasya", "resim": "assets/images/amasya.webp"},
  {"plaka": "06", "il": "Ankara", "resim": "assets/images/ankara.webp"},
  {"plaka": "07", "il": "Antalya", "resim": "assets/images/antalya.webp"},
  {"plaka": "08", "il": "Artvin", "resim": "assets/images/artvin.webp"},
  {"plaka": "09", "il": "Aydın", "resim": "assets/images/aydin.webp"},
  {"plaka": "10", "il": "Balıkesir", "resim": "assets/images/balıkesir.webp"},
  {"plaka": "11", "il": "Bilecik", "resim": "assets/images/bilecik.webp"},
  {"plaka": "12", "il": "Bingöl", "resim": "assets/images/bingöl.webp"},
  {"plaka": "13", "il": "Bitlis", "resim": "assets/images/bitlis.webp"},
  {"plaka": "14", "il": "Bolu", "resim": "assets/images/bolu.webp"},
  {"plaka": "15", "il": "Burdur", "resim": "assets/images/burdur.webp"},
  {"plaka": "16", "il": "Bursa", "resim": "assets/images/bursa.webp"},
  {"plaka": "17", "il": "Çanakkale", "resim": "assets/images/canakkale.webp"},
  {"plaka": "18", "il": "Çankırı", "resim": "assets/images/cankiri.webp"},
  {"plaka": "19", "il": "Çorum", "resim": "assets/images/corum.webp"},
  {"plaka": "20", "il": "Denizli", "resim": "assets/images/denizli.webp"},
  {"plaka": "21", "il": "Diyarbakır", "resim": "assets/images/diyarbakır.webp"},
  {"plaka": "22", "il": "Edirne", "resim": "assets/images/edirne.webp"},
  {"plaka": "23", "il": "Elazığ", "resim": "assets/images/elazıg.webp"},
  {"plaka": "24", "il": "Erzincan", "resim": "assets/images/erzincan.webp"},
  {"plaka": "25", "il": "Erzurum", "resim": "assets/images/erzurum.webp"},
  {"plaka": "26", "il": "Eskişehir", "resim": "assets/images/eskisehir.webp"},
  {"plaka": "27", "il": "Gaziantep", "resim": "assets/images/gaziantep.webp"},
  {"plaka": "28", "il": "Giresun", "resim": "assets/images/giresun.webp"},
  {"plaka": "29", "il": "Gümüşhane", "resim": "assets/images/gumushane.webp"},
  {"plaka": "30", "il": "Hakkari", "resim": "assets/images/hakkari.webp"},
  {"plaka": "31", "il": "Hatay", "resim": "assets/images/hatay.webp"},
  {"plaka": "32", "il": "Isparta", "resim": "assets/images/ısparta.webp"},
  {"plaka": "33", "il": "Mersin", "resim": "assets/images/mersin.webp"},
  {"plaka": "34", "il": "İstanbul", "resim": "assets/images/istanbul.webp"},
  {"plaka": "35", "il": "İzmir", "resim": "assets/images/izmir.webp"},
  {"plaka": "36", "il": "Kars", "resim": "assets/images/kars.webp"},
  {"plaka": "37", "il": "Kastamonu", "resim": "assets/images/kastamonu.webp"},
  {"plaka": "38", "il": "Kayseri", "resim": "assets/images/kayseri.webp"},
  {"plaka": "39", "il": "Kırklareli", "resim": "assets/images/kırklareli.webp"},
  {"plaka": "40", "il": "Kırşehir", "resim": "assets/images/kırsehir.webp"},
  {"plaka": "41", "il": "Kocaeli", "resim": "assets/images/kocaeli.webp"},
  {"plaka": "42", "il": "Konya", "resim": "assets/images/konya.webp"},
  {"plaka": "43", "il": "Kütahya", "resim": "assets/images/kutahya.webp"},
  {"plaka": "44", "il": "Malatya", "resim": "assets/images/malatya.webp"},
  {"plaka": "45", "il": "Manisa", "resim": "assets/images/manisa.webp"},
  {"plaka": "46", "il": "Kahramanmaraş", "resim": "assets/images/kahramanmaras.webp"},
  {"plaka": "47", "il": "Mardin", "resim": "assets/images/mardin.webp"},
  {"plaka": "48", "il": "Muğla", "resim": "assets/images/mugla.webp"},
  {"plaka": "49", "il": "Muş", "resim": "assets/images/mus.webp"},
  {"plaka": "50", "il": "Nevşehir", "resim": "assets/images/nevsehir.webp"},
  {"plaka": "51", "il": "Niğde", "resim": "assets/images/nigde.webp"},
  {"plaka": "52", "il": "Ordu", "resim": "assets/images/ordu.webp"},
  {"plaka": "53", "il": "Rize", "resim": "assets/images/rize.webp"},
  {"plaka": "54", "il": "Sakarya", "resim": "assets/images/sakarya.webp"},
  {"plaka": "55", "il": "Samsun", "resim": "assets/images/samsun.webp"},
  {"plaka": "56", "il": "Siirt", "resim": "assets/images/siirt.webp"},
  {"plaka": "57", "il": "Sinop", "resim": "assets/images/sinop.webp"},
  {"plaka": "58", "il": "Sivas", "resim": "assets/images/sivas.webp"},
  {"plaka": "59", "il": "Tekirdağ", "resim": "assets/images/tekirdag.webp"},
  {"plaka": "60", "il": "Tokat", "resim": "assets/images/tokat.webp"},
  {"plaka": "61", "il": "Trabzon", "resim": "assets/images/trabzon.webp"},
  {"plaka": "62", "il": "Tunceli", "resim": "assets/images/tunceli.webp"},
  {"plaka": "63", "il": "Şanlıurfa", "resim": "assets/images/sanliurfa.webp"},
  {"plaka": "64", "il": "Uşak", "resim": "assets/images/usak.webp"},
  {"plaka": "65", "il": "Van", "resim": "assets/images/van.webp"},
  {"plaka": "66", "il": "Yozgat", "resim": "assets/images/yozgat.webp"},
  {"plaka": "67", "il": "Zonguldak", "resim": "assets/images/zonguldak.webp"},
  {"plaka": "68", "il": "Aksaray", "resim": "assets/images/aksaray.webp"},
  {"plaka": "69", "il": "Bayburt", "resim": "assets/images/bayburt.webp"},
  {"plaka": "70", "il": "Karaman", "resim": "assets/images/karaman.webp"},
  {"plaka": "71", "il": "Kırıkkale", "resim": "assets/images/kırıkkale.webp"},
  {"plaka": "72", "il": "Batman", "resim": "assets/images/batman.webp"},
  {"plaka": "73", "il": "Şırnak", "resim": "assets/images/sirnak.webp"},
  {"plaka": "74", "il": "Bartın", "resim": "assets/images/bartin.webp"},
  {"plaka": "75", "il": "Ardahan", "resim": "assets/images/ardahan.webp"},
  {"plaka": "76", "il": "Iğdır", "resim": "assets/images/ıgdir.webp"},
  {"plaka": "77", "il": "Yalova", "resim": "assets/images/yalova.webp"},
  {"plaka": "78", "il": "Karabük", "resim": "assets/images/karabuk.webp"},
  {"plaka": "79", "il": "Kilis", "resim": "assets/images/kilis.webp"},
  {"plaka": "80", "il": "Osmaniye", "resim": "assets/images/osmaniye.webp"},
  {"plaka": "81", "il": "Düzce", "resim": "assets/images/düzce.webp"},
];
