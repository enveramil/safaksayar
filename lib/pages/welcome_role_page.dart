import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/widgets/setup_ui.dart';

class WelcomeRolePage extends StatefulWidget {
  final bool isSwitchingRole;
  const WelcomeRolePage({super.key, this.isSwitchingRole = false});

  @override
  State<WelcomeRolePage> createState() => _WelcomeRolePageState();
}

class _WelcomeRolePageState extends State<WelcomeRolePage> with SingleTickerProviderStateMixin {
  static const Color _relativeAccent = Color(0xFFFB7185);

  String _selectedRole = 'asker'; // 'asker' or 'yakin'
  bool _isPairingStage = false;
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

  void _leavePairingStage() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isPairingStage = false;
      _errorMessage = null;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _codeController.text = data.text!.trim().toUpperCase();
        _foundSoldier = null;
        _errorMessage = null;
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
        if (!mounted) return;

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
    final bool isPairingStage = _isPairingStage;
    final bool canGoBack = isPairingStage || widget.isSwitchingRole;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: setupOverlayStyle,
      child: PopScope(
        canPop: !isPairingStage,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leavePairingStage();
        },
        child: Scaffold(
          backgroundColor: SetupColors.background,
          body: SetupBackground(
            accent: _selectedRole == 'yakin' ? _relativeAccent : SetupColors.goldDeep,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            if (canGoBack)
                              SetupBackButton(
                                onPressed: isPairingStage
                                    ? _leavePairingStage
                                    : () => Navigator.of(context).pop(),
                              ),
                            const Spacer(),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 34,
                                height: 34,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: setupTopLayoutBuilder,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(isPairingStage),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            child: isPairingStage ? _buildPairingStage() : _buildRoleStage(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                      child: _buildPrimaryAction(),
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

  Widget _buildPrimaryAction() {
    if (!_isPairingStage) {
      return SetupPrimaryButton(
        label: 'Devam Et',
        onPressed: _selectedRole == 'asker'
            ? _proceedAsSoldier
            : () => setState(() => _isPairingStage = true),
      );
    }
    if (_foundSoldier != null) {
      return SetupPrimaryButton(
        label: 'Bu Askeri Takip Et',
        icon: Icons.favorite_rounded,
        isLoading: _isPairing,
        onPressed: _confirmPairing,
      );
    }
    return SetupPrimaryButton(
      label: 'Askeri Bul',
      icon: Icons.search_rounded,
      isLoading: _isSearching,
      onPressed: _searchSoldier,
    );
  }

  // ==========================================
  // 1. AŞAMA: ROL SEÇİMİ
  // ==========================================
  Widget _buildRoleStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupHeading(
          title: 'Şafak Sayar\'ı kimin için kullanacaksın?',
          subtitle: 'Ekranların ve deneyimin seçimine göre hazırlanacak.',
        ),
        const SizedBox(height: 22),
        _buildRoleCard(
          role: 'asker',
          title: 'Ben Askerim',
          subtitle: 'Vatani görevimi yapıyorum',
          icon: Icons.military_tech_rounded,
          accent: SetupColors.gold,
          benefits: const [
            'Net terhis tarihi ve canlı şafak sayacı',
            'Yakınlarınla paylaşacağın takip kodu',
            'Kuvvetine ve rütbene özel künye',
          ],
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          role: 'yakin',
          title: 'Asker Yakınıyım',
          subtitle: 'Eşi, sevgilisi, ailesi veya arkadaşıyım',
          icon: Icons.favorite_rounded,
          accent: _relativeAccent,
          benefits: const [
            'Takip koduyla askerinin şafağına bağlan',
            'Ona zaman kapsülü ve sürpriz bırak',
            'Tüm PRO özellikler sana ücretsiz',
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required List<String> benefits,
  }) {
    final bool isSelected = _selectedRole == role;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.10) : SetupColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? accent : SetupColors.border,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? accent : SetupColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isSelected ? SetupColors.onGold : SetupColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: SetupColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accent : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? accent : SetupColors.textFaint,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, size: 15, color: SetupColors.onGold)
                        : null,
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          children: benefits.map((benefit) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: accent, size: 16),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. AŞAMA: ASKERE BAĞLANMA
  // ==========================================
  Widget _buildPairingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupHeading(
          title: 'Askerine bağlan',
          subtitle: 'Askerinin profilindeki SFK-XXXX kodunu gir, şafağı ekranına gelsin.',
        ),
        const SizedBox(height: 22),
        const SetupFieldLabel('Yakınlık dereceniz'),
        _buildRelationshipGrid(),
        const SizedBox(height: 18),
        const SetupFieldLabel('Takip kodu'),
        _buildCodeField(),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerLeft, child: _buildRequestCodeButton()),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          SetupErrorBanner(_errorMessage!),
        ],
        if (_foundSoldier != null) ...[
          const SizedBox(height: 10),
          _buildFoundSoldierCard(),
        ],
      ],
    );
  }

  Widget _buildRelationshipGrid() {
    const items = [
      {'key': 'es', 'title': 'Eşi / Sevgilisi', 'icon': Icons.favorite_rounded},
      {'key': 'aile', 'title': 'Annesi / Babası', 'icon': Icons.family_restroom_rounded},
      {'key': 'kardes', 'title': 'Kardeşi', 'icon': Icons.people_alt_rounded},
      {'key': 'arkadas', 'title': 'Arkadaşı / Devresi', 'icon': Icons.handshake_rounded},
    ];

    return SetupChoiceGrid(
      columns: 2,
      children: items.map((item) {
        final String key = item['key'] as String;
        final bool isSelected = _selectedRelationship == key;

        return Semantics(
          button: true,
          selected: isSelected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedRelationship = key;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _relativeAccent.withValues(alpha: 0.13)
                    : SetupColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _relativeAccent : SetupColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 18,
                    color: isSelected ? _relativeAccent : SetupColors.textFaint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item['title'] as String,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCodeField() {
    return Container(
      decoration: setupFieldDecoration(),
      child: TextField(
        controller: _codeController,
        textCapitalization: TextCapitalization.characters,
        cursorColor: SetupColors.gold,
        onChanged: (_) {
          if (_foundSoldier != null || _errorMessage != null) {
            setState(() {
              _foundSoldier = null;
              _errorMessage = null;
            });
          }
        },
        onSubmitted: (_) => _searchSoldier(),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
        decoration: InputDecoration(
          hintText: 'SFK-7842',
          hintStyle: const TextStyle(
            color: SetupColors.textFaint,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
          prefixIcon: const Icon(Icons.qr_code_2_rounded, color: SetupColors.textFaint),
          suffixIcon: IconButton(
            icon: const Icon(Icons.content_paste_rounded, color: SetupColors.gold, size: 20),
            tooltip: 'Panodan Yapıştır',
            onPressed: _pasteFromClipboard,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRequestCodeButton() {
    return Builder(
      builder: (btnContext) {
        return TextButton.icon(
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
          label: const Text(
            'Kod bende yok, askerimden isteyeyim',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(
            foregroundColor: SetupColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: SetupColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SetupColors.green.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: SetupColors.green, size: 19),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Asker bulundu',
                  style: TextStyle(
                    color: SetupColors.greenLight,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rank,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$duty  •  $branch',
            style: const TextStyle(color: SetupColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Tahmini terhis: $endDateDisplay',
            style: const TextStyle(
              color: SetupColors.greenLight,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SetupTextField(
            controller: _followerNameController,
            label: 'Adın (askerinin bildiriminde görünecek)',
            hint: 'Örn: Ayşe',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
