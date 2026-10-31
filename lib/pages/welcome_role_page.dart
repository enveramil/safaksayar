import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';

class WelcomeRolePage extends StatefulWidget {
  final bool isSwitchingRole;
  const WelcomeRolePage({super.key, this.isSwitchingRole = false});

  @override
  State<WelcomeRolePage> createState() => _WelcomeRolePageState();
}

class _WelcomeRolePageState extends State<WelcomeRolePage> with SingleTickerProviderStateMixin {
  String _selectedRole = 'asker'; // 'asker' or 'yakin'
  String _selectedRelationship = 'es'; // 'es', 'aile', 'kardes', 'arkadas'

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _followerNameController = TextEditingController();

  bool _isSearching = false;
  bool _isPairing = false;
  Map<String, dynamic>? _foundSoldier;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _codeController.dispose();
    _followerNameController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _codeController.text = data.text!.trim().toUpperCase();
      });
    }
  }

  Future<void> _searchSoldier() async {
    final rawCode = _codeController.text.trim();
    if (rawCode.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen askerinize ait takip kodunu giriniz.';
        _foundSoldier = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundSoldier = null;
    });

    try {
      final soldier = await SoldierMatchService.instance.findSoldierByCode(rawCode);
      if (mounted) {
        setState(() {
          _isSearching = false;
          if (soldier != null) {
            _foundSoldier = soldier;
            _errorMessage = null;
          } else {
            _errorMessage = 'Bu koda ait asker bulunamadı.\nLütfen kodu kontrol edip tekrar deneyin.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Sorgulama sırasında bir hata oluştu: $e';
        });
      }
    }
  }

  Future<void> _confirmPairing() async {
    if (_foundSoldier == null) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });

    try {
      final success = await SoldierMatchService.instance.pairWithSoldier(
        inputCode: _codeController.text.trim(),
        relationship: _selectedRelationship,
        followerName: _followerNameController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
        await RevenueCatService.instance.syncUserRole('yakin');
        await RevenueCatService.instance.bindUser(prefs.getString('userId'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_foundSoldier!['name']} ile başarıyla eşleşildi! Tüm PRO özellikler ücretsiz açıldı.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'ManagePages'),
              builder: (context) => ManagePages(backgroundImage: themeImage),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _isPairing = false;
          _errorMessage = 'Eşleşme yapılamadı. Lütfen tekrar deneyin.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPairing = false;
          _errorMessage = 'Eşleşme hatası: $e';
        });
      }
    }
  }

  void _proceedAsSoldier() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', 'asker');
    await prefs.setBool('is_paired', false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'UserInputPage'),
          builder: (context) => const UserInputPage(initialRole: 'asker'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            // Ambient glowing gradient backgrounds
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -50,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox.shrink(),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    if (widget.isSwitchingRole)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroHeader(),
                            const SizedBox(height: 24),
                            _buildRoleSelector(),
                            const SizedBox(height: 20),
                            if (_selectedRole == 'asker') ...[
                              _buildSoldierExplanationCard(),
                              const SizedBox(height: 24),
                              _buildSoldierContinueButton(),
                            ] else ...[
                              _buildRelativeSection(),
                            ],
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇹🇷', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(
                'VATANİ GÖREV & KAVUŞMA REHBERİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'ŞAFAK SAYAR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uygulamayı kimin için kullanacaksınız?\nSeçiminize göre ekranlarınız ve şafak deneyiminiz özelleştirilecek.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final bool isSoldier = _selectedRole == 'asker';
    final bool isRelative = _selectedRole == 'yakin';

    return Row(
      children: [
        // Role 1: Asker
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedRole = 'asker';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSoldier
                      ? [
                          const Color(0xFF1E3A8A).withValues(alpha: 0.8),
                          const Color(0xFF0F172A),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSoldier ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
                  width: isSoldier ? 2.0 : 1.0,
                ),
                boxShadow: isSoldier
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isSoldier
                            ? [Colors.blueAccent, Colors.cyanAccent]
                            : [Colors.white24, Colors.white10],
                      ),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ben Askerim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vatani görevimi yapıyorum',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Role 2: Asker Yakını
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedRole = 'yakin';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRelative
                      ? [
                          const Color(0xFF831843).withValues(alpha: 0.8),
                          const Color(0xFF0F172A),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isRelative ? Colors.pinkAccent : Colors.white.withValues(alpha: 0.1),
                  width: isRelative ? 2.0 : 1.0,
                ),
                boxShadow: isRelative
                    ? [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isRelative
                            ? [Colors.pinkAccent, Colors.purpleAccent]
                            : [Colors.white24, Colors.white10],
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Asker Yakınıyım',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Eşi, sevgilisi veya ailesiyim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoldierExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share_location_rounded, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Asker Modu Özellikleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureBullet(
            icon: Icons.calculate_outlined,
            title: 'Hassas Şafak & Terhis Hesabı',
            subtitle: 'Sülüs, yol izni, ceza ve izin günlerinize göre net terhis tarihinizi görün.',
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            icon: Icons.qr_code_rounded,
            title: 'Canlı Takip Kodu Paylaşımı',
            subtitle: 'Size özel üretilecek eşsiz kod ile eşiniz veya aileniz şafağınızı anlık takip edebilir.',
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            icon: Icons.badge_outlined,
            title: 'Kuvvet ve Rütbe Künyesi',
            subtitle: 'Kendi kuvvet komutanlığınız ve rütbenize özel taktiksel arayüz.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoldierContinueButton() {
    return ElevatedButton(
      onPressed: _proceedAsSoldier,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 6,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Asker Olarak Bilgileri Gir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }

  Widget _buildRelativeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Stunning 2x2 Relationship Cards Grid
        _buildRelationshipCardsGrid(),
        const SizedBox(height: 20),

        // 2. Takip Kodu ile Eşleşme Kartı
        _buildCodeMatchingCard(),
      ],
    );
  }

  Widget _buildRelationshipCardsGrid() {
    final items = [
      {
        'key': 'es',
        'title': 'Eşi / Sevgilisi',
        'subtitle': 'Hasretle bekleyenim 💕',
        'icon': Icons.favorite_rounded,
        'accent': const Color(0xFFF43F5E),
      },
      {
        'key': 'aile',
        'title': 'Ailesi (Anne / Baba)',
        'subtitle': 'Dualarımız seninle 🏡',
        'icon': Icons.family_restroom_rounded,
        'accent': const Color(0xFFF59E0B),
      },
      {
        'key': 'kardes',
        'title': 'Kardeşi',
        'subtitle': 'Canımdan bir parça 🫂',
        'icon': Icons.people_alt_rounded,
        'accent': const Color(0xFF8B5CF6),
      },
      {
        'key': 'arkadas',
        'title': 'Arkadaşı / Devresi',
        'subtitle': 'Tezkereni bekliyoruz 🤝',
        'icon': Icons.handshake_rounded,
        'accent': const Color(0xFF06B6D4),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.pinkAccent, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Asker ile Yakınlık Dereceniz:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 2x2 Grid
        Row(
          children: [
            Expanded(child: _buildRelationshipCard(items[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildRelationshipCard(items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRelationshipCard(items[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildRelationshipCard(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildRelationshipCard(Map<String, dynamic> item) {
    final String key = item['key'] as String;
    final String title = item['title'] as String;
    final String subtitle = item['subtitle'] as String;
    final IconData icon = item['icon'] as IconData;
    final Color accent = item['accent'] as Color;
    final bool isSelected = _selectedRelationship == key;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedRelationship = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 116,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    accent.withValues(alpha: 0.28),
                    const Color(0xFF1E293B).withValues(alpha: 0.9),
                  ]
                : [
                    const Color(0xFF1E293B).withValues(alpha: 0.5),
                    const Color(0xFF0F172A).withValues(alpha: 0.7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Active check badge at top-right
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon pill
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accent.withValues(alpha: 0.4) : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? accent : Colors.white70,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeMatchingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: Colors.pinkAccent, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Askerinizin Takip Kodunu Girin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Askerinizin profil veya ana ekranında bulunan SFK-XXXX takip kodunu girin. Askerinizin şafağı anında ekranınıza yüklenecektir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Code input field
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
            decoration: InputDecoration(
              hintText: 'Örn: SFK-7842',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 1.0,
              ),
              prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Colors.pinkAccent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, color: Colors.pinkAccent),
                tooltip: 'Panodan Yapıştır',
                onPressed: _pasteFromClipboard,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.pinkAccent, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search button
          ElevatedButton(
            onPressed: _isSearching ? null : _searchSoldier,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSearching
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Askeri Bul ve Bilgileri Getir',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),

          // "Askerimden Kod İste" button
          const SizedBox(height: 12),
          Builder(
            builder: (btnContext) {
              return OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text(
                  'Askerimden Kod İste (WhatsApp / SMS)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pinkAccent.shade100,
                  side: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final relLabel = SoldierMatchService.getRelationshipLabel(_selectedRelationship);
                  final message = 'Canım, Şafak Sayar uygulamasını indirdim! Şafağını anlık takip edebilmem için uygulamanın profil ekranındaki Takip Kodunu (SFK-XXXX) bana gönderir misin? 💕 ($relLabel)';
                  RenderBox? box = btnContext.findRenderObject() as RenderBox?;
                  Rect? origin;
                  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
                    origin = box.localToGlobal(Offset.zero) & box.size;
                  } else {
                    final size = MediaQuery.sizeOf(btnContext);
                    origin = Rect.fromLTWH(size.width / 2 - 100, size.height / 2 - 100, 200, 200);
                  }
                  Share.share(message, subject: 'Şafak Takip Kodu', sharePositionOrigin: origin);
                },
              );
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Found soldier preview card
          if (_foundSoldier != null) ...[
            const SizedBox(height: 18),
            _buildFoundSoldierCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildFoundSoldierCard() {
    final name = '${_foundSoldier!['name']} ${_foundSoldier!['surname']}';
    final duty = _foundSoldier!['askerlik_yeri'] ?? '';
    final branch = _foundSoldier!['kuvvet_komutanligi'] ?? '';
    final rank = _foundSoldier!['rutbe'] ?? 'ER';
    final endDateStr = _foundSoldier!['end_date'] ?? '';

    String endDateDisplay = '-';
    if (endDateStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(endDateStr);
        endDateDisplay = '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
      } catch (_) {
        endDateDisplay = endDateStr;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Asker Bulundu!',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rank,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '📍 $duty  •  🎖️ $branch',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '🗓️ Tahmini Terhis: $endDateDisplay',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(color: Colors.white12, height: 24),

          // Follower name input
          Text(
            'Adınız (Askerinizin bildiriminde görünecek):',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _followerNameController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Örn: Ayşe, Canan...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isPairing ? null : _confirmPairing,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isPairing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Bu Askeri Takip Et ve Başla 💕',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
