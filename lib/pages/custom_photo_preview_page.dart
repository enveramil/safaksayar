import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';

class CustomPhotoPreviewPage extends StatefulWidget {
  final String initialPhotoPath;
  final double initialPhotoX;
  final double initialPhotoY;
  final bool isEditingExisting;
  final String backgroundImage;
  final Map<String, String?> profileData;
  final int remainingDays;
  final int elapsedDays;
  final double progressPercent;

  const CustomPhotoPreviewPage({
    super.key,
    required this.initialPhotoPath,
    this.initialPhotoX = 0.0,
    this.initialPhotoY = 0.0,
    this.isEditingExisting = false,
    required this.backgroundImage,
    required this.profileData,
    required this.remainingDays,
    required this.elapsedDays,
    required this.progressPercent,
  });

  @override
  State<CustomPhotoPreviewPage> createState() => _CustomPhotoPreviewPageState();
}

class _CustomPhotoPreviewPageState extends State<CustomPhotoPreviewPage> {
  late String _photoPath;
  late double _tempX;
  late double _tempY;
  late bool _isTempFile;
  int _previewMode = 0; // 0: Şafak Ekranı, 1: Tam Görsel
  bool _isApplying = false;

  bool get _isDefaultTheme =>
      widget.backgroundImage == 'assets/images/img0.webp';

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
    _tempX = widget.initialPhotoX.clamp(-1.0, 1.0);
    _tempY = widget.initialPhotoY.clamp(-1.0, 1.0);
    _isTempFile = !widget.isEditingExisting;
  }

  Future<void> _cleanupTempFileIfNeeded() async {
    if (_isTempFile) {
      try {
        final file = File(_photoPath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _handleCancel() async {
    await _cleanupTempFileIfNeeded();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _pickAnotherPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 88,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final newTempPath =
          '${appDir.path}/preview_header_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedTemp = await File(picked.path).copy(newTempPath);

      await _cleanupTempFileIfNeeded();

      if (mounted) {
        HapticFeedback.selectionClick();
        setState(() {
          _photoPath = savedTemp.path;
          _tempX = 0.0;
          _tempY = 0.0;
          _isTempFile = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleApplyPressed() async {
    if (_isApplying) return;

    final bool isPremium = RevenueCatService.instance.isPremium;
    if (!isPremium) {
      HapticFeedback.mediumImpact();
      await _showProPrivilegeGateSheet();
      return;
    }

    await _commitAndSavePhoto();
  }

  Future<void> _commitAndSavePhoto() async {
    setState(() => _isApplying = true);
    HapticFeedback.heavyImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final appDir = await getApplicationDocumentsDirectory();

      String finalSavedPath = _photoPath;

      if (_isTempFile) {
        final oldSavedPath = prefs.getString('custom_header_photo_path');
        final fileName =
            'custom_header_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final permanentFile =
            await File(_photoPath).copy('${appDir.path}/$fileName');
        finalSavedPath = permanentFile.path;

        // Clean up temp file
        try {
          final tempFile = File(_photoPath);
          if (tempFile.existsSync()) {
            await tempFile.delete();
          }
        } catch (_) {}

        // Clean up previous saved custom photo if different
        if (oldSavedPath != null && oldSavedPath != finalSavedPath) {
          try {
            final oldFile = File(oldSavedPath);
            if (oldFile.existsSync()) {
              await oldFile.delete();
            }
          } catch (_) {}
        }

        _isTempFile = false;
      }

      await prefs.setString('custom_header_photo_path', finalSavedPath);
      await prefs.setDouble('custom_header_photo_x', _tempX);
      await prefs.setDouble('custom_header_photo_y', _tempY);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf kaydedilirken bir hata oluştu: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showProPrivilegeGateSheet() async {
    final bool? goToPaywall = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 14,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),

              // User's Selected Photo Thumbnail + PRO Crown Badge
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 68,
                          height: 84,
                          child: Image.file(
                            File(_photoPath),
                            fit: BoxFit.cover,
                            alignment: Alignment(_tempX, _tempY),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 14,
                            color: Color(0xFF1F1600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO AYRICALIĞI',
                            style: TextStyle(
                              color: Color(0xFF1F1600),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Özel Şafak Fotoğrafı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Şafak kartının arka planına özel fotoğraf ekleme özelliği Şafak Sayar PRO ayrıcalıklarına aittir.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // PRO Perks Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPerkItem(
                      Icons.photo_camera_rounded,
                      'Şafak kartına sevdiğinin veya ikinizin özel fotoğrafını ekleme',
                    ),
                    const SizedBox(height: 10),
                    _buildPerkItem(
                      Icons.wallpaper_rounded,
                      'Tüm özel askeri, bayrak ve vatan temalarına sınırsız erişim',
                    ),
                    const SizedBox(height: 10),
                    _buildPerkItem(
                      Icons.favorite_rounded,
                      'Canlı şafak takip kodu, zaman kapsülü ve sıfır reklam',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary CTA -> Redirect to Paywall
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(
                    Icons.lock_open_rounded,
                    size: 18,
                    color: Color(0xFF1F1600),
                  ),
                  label: const Text(
                    'PRO\'YA GEÇ & FOTOĞRAFI UYGULA',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F1600),
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1F1600),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Önizlemeye Dön',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (goToPaywall == true && mounted) {
      await PremiumPaywallPage.show(context, source: 'home_custom_photo');
      // Kullanıcı Paywall'da PRO üyeliği başlattıysa seçtiği fotoğrafı ve ayarladığı kadrajı otomatik uygula!
      if (mounted && RevenueCatService.instance.isPremium) {
        await _commitAndSavePhoto();
      }
    }
  }

  Widget _buildPerkItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFFFBBF24)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkPage = !_isDefaultTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleCancel();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor:
              _previewMode == 1 ? const Color(0xFF0B0F19) : (isDarkPage ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC)),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Optional App Theme Wallpaper Behind Lower Simulated Cards (Mode 0)
              if (_previewMode == 0 && !isDarkPage)
                Container(color: const Color(0xFFF8FAFC))
              else if (_previewMode == 0 && isDarkPage)
                Image.asset(
                  widget.backgroundImage,
                  fit: BoxFit.cover,
                ),

              // Mode 1: Raw Full-Screen Photo View
              if (_previewMode == 1)
                InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Image.file(
                    File(_photoPath),
                    fit: BoxFit.contain,
                  ),
                ),

              // Mode 0: Simulated Live Home Screen with Interactive Drag-to-Frame Header
              if (_previewMode == 0)
                Column(
                  children: [
                    _buildInteractiveHeroHeaderPreview(context),
                    _buildFramingControlsStrip(isDarkPage),
                    Expanded(
                      child: IgnorePointer(
                        ignoring: true,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: _buildSimulatedHomeCards(isDarkPage),
                        ),
                      ),
                    ),
                  ],
                ),

              // Top Floating Navigation + Mode Selector (when in Mode 1 or overlaid cleanly)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    _buildTopFloatingBar(),
                    const SizedBox(height: 8),
                    _buildModeSelectorBar(),
                  ],
                ),
              ),

              // Bottom Apply Action Dock
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom,
                child: _buildBottomApplyDock(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopFloatingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Cancel / Back Button
        GestureDetector(
          onTap: _handleCancel,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Live Preview Pill
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.56),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'CANLI ÖNİZLEME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Pick Another Photo Button
        GestureDetector(
          onTap: _pickAnotherPhoto,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Değiştir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelectorBar() {
    final modes = [
      (0, Icons.dashboard_customize_rounded, 'Şafak Kartı Görünümü'),
      (1, Icons.image_outlined, 'Tam Fotoğraf'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: modes.map((m) {
              final selected = _previewMode == m.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _previewMode = m.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          m.$2,
                          size: 14,
                          color: selected
                              ? const Color(0xFF0B0F19)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          m.$3,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF0B0F19)
                                : Colors.white70,
                            fontSize: 11.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveHeroHeaderPreview(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final data = widget.profileData;
    final bool isRelative = data['userRole'] == 'yakin';
    final String? name = data['name'];
    final String? surname = data['surname'];
    final String? rutbe = data['rutbe'];
    final String? relationship = data['relationship'];
    final String fullName = name != null && name.isNotEmpty
        ? '${name.toUpperCase()} ${surname?.toUpperCase() ?? ''}'.trim()
        : (isRelative ? 'ASKERİM' : 'ŞAFAK SAYAR');

    final int rem = widget.remainingDays;
    final int atarsa = rem > 1 ? rem - 1 : 0;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final double deltaY = details.delta.dy / 110.0;
          final double deltaX = details.delta.dx / 150.0;
          _tempY = (_tempY - deltaY).clamp(-1.0, 1.0);
          _tempX = (_tempX - deltaX).clamp(-1.0, 1.0);
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(_photoPath)),
            fit: BoxFit.cover,
            alignment: Alignment(_tempX, _tempY),
          ),
          border: Border(
            bottom: BorderSide(
              color: isRelative
                  ? Colors.pinkAccent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Exact same scrim gradient as HomeScreen.buildHeaderSection
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.38),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                top: (statusBarHeight > 0 ? statusBarHeight : 24) + 92,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Name & Rank Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: (isRelative
                                        ? Colors.pinkAccent
                                        : Colors.blueAccent)
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isRelative
                                          ? Colors.pinkAccent
                                          : Colors.blueAccent)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isRelative
                                        ? SoldierMatchService.getRelationshipIcon(
                                            relationship,
                                          )
                                        : Icons.shield_rounded,
                                    size: 12,
                                    color: isRelative
                                        ? Colors.pinkAccent.shade100
                                        : Colors.blueAccent.shade100,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isRelative
                                        ? SoldierMatchService
                                            .getRelationshipLabel(relationship)
                                            .toUpperCase()
                                        : (rutbe != null && rutbe.isNotEmpty
                                                ? rutbe
                                                : 'ER')
                                            .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isRelative
                                          ? Colors.pink.shade100
                                          : Colors.blue.shade100,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Drag Hint Pill inside Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_with_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sürükle & Hizala',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ŞAFAK & ATARSA Dual HUD
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (isRelative
                                        ? const Color(0xFF831843)
                                        : const Color(0xFF1E3A8A))
                                    .withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.50),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isRelative
                                      ? Colors.pinkAccent
                                      : Colors.blueAccent)
                                  .withValues(alpha: 0.45),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isRelative
                                        ? Icons.favorite_rounded
                                        : Icons.flag_rounded,
                                    size: 12,
                                    color: isRelative
                                        ? Colors.pink.shade200
                                        : Colors.blue.shade200,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isRelative ? 'KAVUŞMAYA' : 'ŞAFAK',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isRelative
                                          ? Colors.pink.shade200
                                          : Colors.blue.shade200,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                rem > 0 ? '$rem' : 'Bitti :)',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const Text(
                                'GÜN KALDI',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7C2D12).withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.50),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.45),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 12,
                                    color: Colors.orange.shade200,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isRelative ? 'YARIN ŞAFAK' : 'ATARSA',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.orange.shade200,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                rem == 1 ? 'Doğan Güneş' : '$atarsa',
                                style: TextStyle(
                                  fontSize: rem == 1 ? 20 : 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const Text(
                                'BİR SONRAKİ GÜN',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildFramingControlsStrip(bool isDarkPage) {
    final Color surface = isDarkPage
        ? const Color(0xFF1E293B).withValues(alpha: 0.92)
        : Colors.white;
    final Color borderCol = isDarkPage
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final Color labelCol =
        isDarkPage ? Colors.white70 : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Icon(
            Icons.crop_free_rounded,
            size: 15,
            color: isDarkPage ? Colors.pinkAccent.shade100 : const Color(0xFFE11D48),
          ),
          const SizedBox(width: 7),
          Text(
            'Kadraj:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: labelCol,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                _buildAlignPresetButton(
                  label: 'Üst',
                  selected: _tempY <= -0.65,
                  isDark: isDarkPage,
                  onTap: () => setState(() {
                    _tempY = -0.9;
                    _tempX = 0.0;
                  }),
                ),
                const SizedBox(width: 6),
                _buildAlignPresetButton(
                  label: 'Orta',
                  selected: _tempY.abs() < 0.25 && _tempX.abs() < 0.25,
                  isDark: isDarkPage,
                  onTap: () => setState(() {
                    _tempY = 0.0;
                    _tempX = 0.0;
                  }),
                ),
                const SizedBox(width: 6),
                _buildAlignPresetButton(
                  label: 'Alt',
                  selected: _tempY >= 0.65,
                  isDark: isDarkPage,
                  onTap: () => setState(() {
                    _tempY = 0.9;
                    _tempX = 0.0;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignPresetButton({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE11D48)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedHomeCards(bool isDarkPage) {
    final Color cardBg = isDarkPage
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.white;
    final Color borderCol = isDarkPage
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFE2E8F0);
    final Color textCol = isDarkPage ? Colors.white : const Color(0xFF0F172A);
    final Color subCol = isDarkPage ? Colors.white70 : const Color(0xFF64748B);
    final double pct = widget.progressPercent.clamp(0.0, 1.0);

    return Opacity(
      opacity: 0.88,
      child: Column(
        children: [
          // Simulated Progress Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GÖREV İLERLEMESİ',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: subCol,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '%${(pct * 100).toStringAsFixed(1)} TAMAMLANDI',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isDarkPage
                            ? Colors.tealAccent
                            : Colors.blueAccent.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: isDarkPage
                        ? Colors.white12
                        : Colors.blueGrey.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkPage
                          ? const Color(0xFF10B981)
                          : Colors.blueAccent.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Geçen: ${widget.elapsedDays} Gün',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: subCol,
                      ),
                    ),
                    Text(
                      'Kalan: ${widget.remainingDays} Gün',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomApplyDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ValueListenableBuilder<bool>(
            valueListenable: RevenueCatService.instance.isPremiumNotifier,
            builder: (context, isPremium, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Özel Şafak Fotoğrafı',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isPremium
                                            ? const [
                                                Color(0xFF10B981),
                                                Color(0xFF059669),
                                              ]
                                            : const [
                                                Color(0xFFFFD700),
                                                Color(0xFFF59E0B),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPremium
                                              ? Icons.verified_rounded
                                              : Icons.workspace_premium_rounded,
                                          size: 11,
                                          color: isPremium
                                              ? Colors.white
                                              : const Color(0xFF1F1600),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'PRO',
                                          style: TextStyle(
                                            color: isPremium
                                                ? Colors.white
                                                : const Color(0xFF1F1600),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isPremium
                                    ? 'Kadrajını ayarlayıp şafak kartına hemen uygula'
                                    : 'Fotoğrafını önizle ve hizala • PRO ile şafak kartına uygula',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isApplying ? null : _handleApplyPressed,
                        icon: _isApplying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF0B0F19),
                                ),
                              )
                            : Icon(
                                widget.isEditingExisting
                                    ? Icons.check_circle_rounded
                                    : Icons.check_rounded,
                                size: 20,
                              ),
                        label: Text(
                          widget.isEditingExisting
                              ? 'Kadrajı Kaydet'
                              : 'Şafak Kartıma Uygula',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0B0F19),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

