import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/pages/theme_page.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:safaksayar/pages/ani_defteri_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:safaksayar/Services/notification_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/pages/live_share_simulation_page.dart';

class ProfileScreen extends StatefulWidget {
  final String backgroundImage;
  const ProfileScreen({super.key, required this.backgroundImage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _surname = '';
  String _rutbe = '';
  String _kuvvetKomutanligi = '';
  String _askerlikYeri = '';
  String _memleket = '';
  String _sulusTarihi = '';
  String _terhisTarihi = '';
  int _notifHour = 21;
  int _notifMinute = 0;
  String _userRole = 'asker';
  String? _relationship;
  String _trackingCode = '';
  String _pairedCode = '';
  bool _isPaired = false;

  @override
  void initState() {
    super.initState();
    SoldierMatchService.instance.dataSyncVersion.addListener(_onExternalDataChanged);
    _loadProfileData();
  }

  @override
  void dispose() {
    SoldierMatchService.instance.dataSyncVersion.removeListener(_onExternalDataChanged);
    super.dispose();
  }

  void _onExternalDataChanged() {
    if (mounted) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _name = prefs.getString('name') ?? '';
        _surname = prefs.getString('surname') ?? '';
        _rutbe = prefs.getString('rutbe') ?? '';
        _kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi') ?? '';
        _askerlikYeri = prefs.getString('askerlik_yeri') ?? '';
        _memleket = prefs.getString('memleket') ?? '';
        _sulusTarihi = prefs.getString('sulus_tarihi') ?? '';
        _terhisTarihi = prefs.getString('end_date') ?? '';
        _notifHour = prefs.getInt('notif_hour') ?? 21;
        _notifMinute = prefs.getInt('notif_minute') ?? 0;
        _userRole = prefs.getString('user_role') ?? 'asker';
        _relationship = prefs.getString('relationship');
        _trackingCode = prefs.getString('tracking_code') ?? '';
        _pairedCode = prefs.getString('paired_code') ?? '';
        _isPaired = prefs.getBool('is_paired') ?? false;
      });

      if (_userRole == 'asker' && _trackingCode.isEmpty) {
        final code = await SoldierMatchService.instance.generateOrGetTrackingCode();
        if (mounted) {
          setState(() {
            _trackingCode = code;
          });
        }
      }
    }
  }

  bool get _isDefaultTheme => widget.backgroundImage == 'assets/images/img0.webp';

  Color _getTextColor() {
    return _isDefaultTheme ? Colors.black : Colors.white;
  }

  Color _getCardColor() {
    return _isDefaultTheme
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.45);
  }

  Color _getBorderColor() {
    return _isDefaultTheme
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.15);
  }

  Color _getSubtitleColor() {
    return _isDefaultTheme ? Colors.black54 : Colors.white70;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _isDischarged() {
    if (_terhisTarihi.isEmpty) return false;
    try {
      final terhis = DateTime.parse(_terhisTarihi);
      return DateTime.now().isAfter(terhis);
    } catch (_) {
      return false;
    }
  }

  String _getCommandLogo() {
    switch (_kuvvetKomutanligi.trim().toLowerCase()) {
      case 'kara':
        return 'assets/images/Kara.webp';
      case 'deniz':
        return 'assets/images/Deniz.webp';
      case 'hava':
        return 'assets/images/Hava.webp';
      case 'jandarma':
        return 'assets/images/Jandarma.webp';
      default:
        return 'assets/images/app_logo.png';
    }
  }

  Widget _buildIDCard() {
    final bool isDark = !_isDefaultTheme;
    final String commandLogo = _getCommandLogo();
    final String fullName = _name.isNotEmpty || _surname.isNotEmpty
        ? '${_name.toUpperCase()} ${_surname.toUpperCase()}'
        : 'MİSAFİR KULLANICI';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: _isDefaultTheme
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: isDark ? 0.08 : 0.04,
                child: Image.asset(
                  commandLogo,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.white24, Colors.white12]
                                : [Colors.blueAccent, Colors.blueAccent.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(commandLogo),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_userRole == 'yakin') ...[
                              Text(
                                'TAKİP EDİLEN ASKER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.pinkAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (_userRole == 'yakin'
                                            ? Colors.pinkAccent.withValues(alpha: 0.15)
                                            : Colors.white.withValues(alpha: 0.12))
                                        : (_userRole == 'yakin'
                                            ? Colors.pinkAccent.withValues(alpha: 0.1)
                                            : Colors.blueAccent.withValues(alpha: 0.1)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _userRole == 'yakin'
                                          ? Colors.pinkAccent.withValues(alpha: 0.3)
                                          : (isDark
                                              ? Colors.white12
                                              : Colors.blueAccent.withValues(alpha: 0.2)),
                                    ),
                                  ),
                                  child: Text(
                                    _userRole == 'yakin'
                                        ? SoldierMatchService.getRelationshipLabel(_relationship).toUpperCase()
                                        : (_rutbe.isNotEmpty ? _rutbe.toUpperCase() : 'ASKER'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _userRole == 'yakin'
                                          ? Colors.pinkAccent
                                          : (isDark ? Colors.white : Colors.blueAccent),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (_userRole == 'yakin' && _isPaired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.greenAccent.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _pairedCode.isNotEmpty ? _pairedCode : 'BAĞLI',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.greenAccent,
                                            letterSpacing: 0.5,
                                          ),
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
                  const SizedBox(height: 20),
                  Divider(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.location_on_outlined,
                          _userRole == 'yakin' ? 'ASKERİN BİRLİĞİ' : 'GÖREV YERİ',
                          _askerlikYeri.isNotEmpty ? _askerlikYeri : 'Belirtilmedi',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.home_outlined,
                          'MEMLEKET',
                          _memleket.isNotEmpty ? _memleket : 'Belirtilmedi',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.calendar_month_outlined,
                          'SÜLÜS TARİHİ',
                          _formatDate(_sulusTarihi),
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.verified_user_outlined,
                          _userRole == 'yakin' ? 'KAVUŞMA TARİHİ' : 'TERHİS TARİHİ',
                          _formatDate(_terhisTarihi),
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

  Widget _buildSoldierTrackingManagementCard() {
    final bool isDark = !_isDefaultTheme;
    final code = _trackingCode.isNotEmpty ? _trackingCode : 'SFK-YÜKLENİYOR';

    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        if (!isPremium) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _getCardColor(),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B).withValues(alpha: 0.95), const Color(0xFF0F172A).withValues(alpha: 0.98)]
                    : [Colors.white, const Color(0xFFFAF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.45 : 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Color(0xFF1F1600), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AİLE & EŞ TAKİP KODU',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Sevdiklerinle Canlı Paylaşım',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _getTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 12, color: Color(0xFF1F1600)),
                          SizedBox(width: 3),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F1600),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Masked code (Tıklanınca Simülasyon Önizleme Açılır)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    LiveShareSimulationPage.show(context, initialTab: 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'TR-••••••',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black45,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_fill_rounded, size: 12, color: Color(0xFFF59E0B)),
                              SizedBox(width: 4),
                              Text(
                                'DEMO ÖNİZLE',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sevgilin, eşin veya ailen kendi telefonundan şafağını canlı takip edebilir ve takvimine sürpriz Zaman Kapsülü bırakabilir.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getSubtitleColor(),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          LiveShareSimulationPage.show(context, initialTab: 0);
                        },
                        icon: Icon(
                          Icons.slideshow_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                        ),
                        label: Text(
                          'Simülasyonu Gör',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFFFFBEB),
                          side: BorderSide(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 12,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          PremiumPaywallPage.show(context, source: 'profile_tracking_code');
                        },
                        icon: const Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFF1F1600)),
                        label: const Text(
                          "KİLİDİ AÇ • PRO",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F1600),
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF1F1600),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _getCardColor(),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF1F5F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_location_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AİLE & EŞ TAKİP KODUNUZ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _getTextColor(),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO AKTİF',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bu kodu yakınlarınızla paylaşarak sizi takip etmelerini sağlayın',
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
              const SizedBox(height: 14),
              // Code Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B132B) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EŞLEŞME KODUNUZ',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            code,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Takip kodu kopyalandı: $code'),
                            backgroundColor: Colors.blueAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (btnContext) {
                        return OutlinedButton.icon(
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Kodu Paylaş', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                            side: const BorderSide(color: Colors.blueAccent),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final message = 'Askerlik şafağımı Şafak Sayar uygulamasından anlık takip edebilirsin! Takip Kodum: $code\nUygulamayı indirip bu kodu girmen yeterli.';
                            RenderBox? box = btnContext.findRenderObject() as RenderBox?;
                            Rect? origin;
                            if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
                              origin = box.localToGlobal(Offset.zero) & box.size;
                            } else {
                              final size = MediaQuery.sizeOf(btnContext);
                              origin = Rect.fromLTWH(size.width / 2 - 100, size.height / 2 - 100, 200, 200);
                            }
                            Share.share(message, subject: 'Şafak Takip Kodu: $code', sharePositionOrigin: origin);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.people_alt_rounded, size: 16),
                      label: const Text('Takipçiler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.18),
                        foregroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showFollowersModal(code),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelativeTrackingManagementCard() {
    final bool isDark = !_isDefaultTheme;
    final soldierName = '$_name $_surname'.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _getCardColor(),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFFFF1F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.pinkAccent.withValues(alpha: 0.4) : Colors.pink.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPaired ? 'CANLI ASKER BAĞLANTISI' : 'MANUEL TAKİP MODU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _getTextColor(),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPaired
                          ? 'Asker: $soldierName ($_pairedCode)'
                          : 'Askerinizin takip kodunu girerek canlı bağlantı kurabilirsiniz',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _getSubtitleColor(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isPaired ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isPaired ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPaired ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPaired ? 'CANLI' : 'MANUEL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _isPaired ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isPaired) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Senkronize Et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.pinkAccent.withValues(alpha: 0.18),
                      foregroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final updated = await SoldierMatchService.instance.syncPairedSoldierData();
                      if (updated && mounted) {
                        await _loadProfileData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Asker verileri başarıyla senkronize edildi! 💕'),
                            backgroundColor: Colors.pinkAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link_off_rounded, size: 16),
                    label: const Text('Eşleşmeyi Kaldır', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmUnpair(),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.qr_code_rounded, size: 16),
                label: const Text('Asker Takip Kodu Gir & Eşleş', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showPairingDialog(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmUnpair() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eşleşmeyi Kaldır?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Asker takip kodunuz silinecek ve verileriniz manuel moda geçecektir. Onaylıyor musunuz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eşleşmeyi Kaldır', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SoldierMatchService.instance.unpairSoldier();
      await _loadProfileData();
      NotificationService().scheduleAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eşleşme kaldırıldı. Manuel moddasınız.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPairingDialog() {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: Colors.pinkAccent),
                  SizedBox(width: 8),
                  Text('Asker Kodu ile Eşleş', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Askerinizin size verdiği takip kodunu (örn: SFK-1234) giriniz:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      hintText: 'SFK-XXXX',
                      hintStyle: const TextStyle(color: Colors.white30),
                      errorText: errorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) {
                            setDialogState(() => errorText = 'Lütfen bir kod girin');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            errorText = null;
                          });
                          final soldier = await SoldierMatchService.instance.getSoldierByTrackingCode(code);
                          if (soldier == null) {
                            setDialogState(() {
                              isLoading = false;
                              errorText = 'Asker bulunamadı. Kodu kontrol edin.';
                            });
                            return;
                          }
                          final prefs = await SharedPreferences.getInstance();
                          await SoldierMatchService.instance.pairWithSoldier(
                            code: code,
                            relationship: (_relationship != null && _relationship!.isNotEmpty)
                                ? _relationship!
                                : 'es',
                            followerName: prefs.getString('follower_name') ?? 'Yakını',
                          );
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          await _loadProfileData();
                          NotificationService().scheduleAllNotifications();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${soldier['name']} ${soldier['surname']} ile başarıyla eşleşildi! 💕'),
                                backgroundColor: Colors.pinkAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Eşleş', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFollowersModal(String trackingCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: SoldierMatchService.instance.getFollowers(trackingCode),
          builder: (context, snapshot) {
            final followers = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Şafağını Takip Edenler (${followers.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (followers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.person_add_rounded, color: Colors.white.withValues(alpha: 0.3), size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Henüz seni takip eden kimse yok.\nTakip kodunu eşine, sevgiline veya ailene vererek anlık takip ettirebilirsin!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: followers.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final f = followers[index];
                          final name = f['name'] ?? 'Yakını';
                          final rel = f['relationship'] ?? '';
                          final relLabel = SoldierMatchService.getRelationshipLabel(rel);
                          final icon = SoldierMatchService.getRelationshipIcon(rel);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                              child: Icon(icon, color: Colors.pinkAccent, size: 20),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              relLabel,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    final bool isDark = !_isDefaultTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getSubtitleColor().withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildIDCard(),

            // Soldier Share Code or Relative Sync banner
            if (_userRole == 'asker')
              _buildSoldierTrackingManagementCard()
            else if (_userRole == 'yakin')
              _buildRelativeTrackingManagementCard(),

            // Featured Full-Row Military Themes Showcase Banner
            _buildThemeChangeTile(),

            const SizedBox(height: 4),

            _buildSectionHeader('Hesap & Ayarlar'),
            _buildListTile(
              icon: Icons.edit_note,
              title: _userRole == 'yakin'
                  ? (_isPaired ? 'Asker Bilgilerini Görüntüle' : 'Asker Bilgilerini Düzenle')
                  : 'Bilgileri Güncelle',
              iconColor: Colors.blue,
              onTap: () async {
                await Navigator.of(context).push(_customPageRoute(UserInputPage(), 'UserInputPage'));
                await _loadProfileData();
                SoldierMatchService.instance.notifyDataChanged(pairingChanged: true);
              },
            ),
            _buildNotificationTimeTile(),
            _buildListTile(
              icon: Icons.auto_stories_rounded,
              title: _isDischarged() ? 'Terhis Anı Defteri' : 'Terhis Anı Defteri (Ön İzleme)',
              iconColor: _isDischarged() ? Colors.green : Colors.blueGrey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AniDefteriPage(),
                  ),
                );
              },
            ),


            _buildSectionHeader('Uygulama & Destek'),
            Builder(
              builder: (tileContext) {
                return _buildListTile(
                  icon: Icons.share_outlined,
                  title: 'Uygulamayı Paylaş',
                  iconColor: Colors.green,
                  onTap: () {
                    final String shareLink = Platform.isIOS
                        ? 'https://apps.apple.com/app/id6777999683'
                        : 'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar';
                    final box = tileContext.findRenderObject() as RenderBox?;
                    Rect? sharePositionOrigin;
                    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
                      sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
                    } else {
                      final double screenWidth = MediaQuery.sizeOf(tileContext).width;
                      final double screenHeight = MediaQuery.sizeOf(tileContext).height;
                      sharePositionOrigin = Rect.fromLTWH(
                        screenWidth / 2 - 10,
                        screenHeight / 2 - 10,
                        20,
                        20,
                      );
                    }
                    Share.share(shareLink, sharePositionOrigin: sharePositionOrigin);
                  },
                );
              },
            ),
            _buildListTile(
              icon: Icons.star_outline_rounded,
              title: 'Bizi Değerlendirin',
              iconColor: Colors.amber,
              onTap: () async {
                final InAppReview inAppReview = InAppReview.instance;
                try {
                  if (await inAppReview.isAvailable()) {
                    await inAppReview.requestReview();
                  } else {
                    await inAppReview.openStoreListing(
                      appStoreId: '6777999683',
                    );
                  }
                } catch (e) {
                  final String reviewUrl = Platform.isIOS
                      ? 'https://apps.apple.com/app/id6777999683?action=write-review'
                      : 'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar';
                  final Uri reviewUri = Uri.parse(reviewUrl);
                  if (await canLaunchUrl(reviewUri)) {
                    await launchUrl(reviewUri, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),

            _buildSectionHeader('Kurumsal & Bilgi'),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Gizlilik Politikası',
              iconColor: Colors.teal,
              onTap: () {
                _showPolicyBottomSheet(
                  title: 'Gizlilik Politikası',
                  content: _privacyPolicyContent,
                  icon: Icons.privacy_tip_outlined,
                  accentColor: Colors.teal,
                );
              },
            ),
            _buildListTile(
              icon: Icons.description_outlined,
              title: 'Kullanım Şartları',
              iconColor: Colors.orange,
              onTap: () {
                _showPolicyBottomSheet(
                  title: 'Kullanım Şartları',
                  content: _termsOfUseContent,
                  icon: Icons.description_outlined,
                  accentColor: Colors.orange,
                );
              },
            ),
            _buildSectionHeader('Hesap Yönetimi'),
            _buildListTile(
              icon: Icons.delete_forever_outlined,
              title: 'Hesabımı Sil',
              iconColor: Colors.red,
              onTap: () async {
                await _deleteAccount();
              },
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hesabınızı Silmek İstiyor Musunuz?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bu işlem geri alınamaz. Tüm yerel verileriniz temizlenecek ve hesabınız silinecektir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Hesabı Sil'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Geri tuşu ile kapatılmasını engelle
          child: Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    strokeWidth: 3.5,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hesabınız Siliniyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verileriniz temizleniyor, lütfen bekleyin...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user details before clearing them
      final String userId = prefs.getString('userId') ?? 'Bilinmiyor';
      final String name = prefs.getString('name') ?? '';
      final String surname = prefs.getString('surname') ?? '';
      final String askerlikYeri = prefs.getString('askerlik_yeri') ?? '';
      final String memleket = prefs.getString('memleket') ?? '';

      // Save delete log to Firestore under 'deleted_user'
      await FirebaseFirestore.instance.collection('deleted_user').doc(userId).set({
        'userId': userId,
        'name': name,
        'surname': surname,
        'askerlik_yeri': askerlikYeri,
        'memleket': memleket,
        'deleted_at': FieldValue.serverTimestamp(),
      });

      // Unpair if paired
      if (_userRole == 'yakin' && _isPaired) {
        await SoldierMatchService.instance.unpairSoldier();
      }

      // Clear local SharedPreferences
      await prefs.clear();

      if (mounted) {
        // Pop loading dialog
        Navigator.of(context).pop();

        // Redirect to WelcomeRolePage (welcome & role selection screen)
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'WelcomeRolePage'),
            builder: (context) => const WelcomeRolePage(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error deleting account: $e');
      if (mounted) {
        // Pop loading dialog
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Özel sayfa geçişi için fonksiyon
  PageRouteBuilder _customPageRoute(Widget page, String pageName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: pageName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Sağdan sola başlasın
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  // ─── Askeri Temalar Kullan (Full-Row Featured Showcase Banner) ───────────

  Widget _buildThemeChangeTile() {
    final activeItem = ThemeCatalog.items.cast<ThemeItem?>().firstWhere(
          (item) => item?.assetPath == widget.backgroundImage,
          orElse: () => null,
        );
    final String activeTitle = activeItem?.title ?? 'Klasik Aydınlık';
    final String centerPreviewAsset = !_isDefaultTheme
        ? widget.backgroundImage
        : 'assets/images/img12.webp';

    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        final Color accentColor =
            isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: _isDefaultTheme ? 0.20 : 0.26),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDefaultTheme ? 0.12 : 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.5),
            child: Stack(
              children: [
                // 1. Deep Tactical Full-Row Gradient Base
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B1120),
                          Color(0xFF1E1B4B),
                          Color(0xFF172554),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // 2. Subtle Blended Flag/Sky Texture on Right Side
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 185,
                  child: Opacity(
                    opacity: 0.22,
                    child: Image.asset(
                      'assets/images/img13.webp',
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                    ),
                  ),
                ),

                // 3. Smooth Left-to-Right Scrim so Typography Pops
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF0B1120).withValues(alpha: 0.96),
                          const Color(0xFF131836).withValues(alpha: 0.86),
                          const Color(0xFF0B1120).withValues(alpha: 0.45),
                        ],
                        stops: const [0.0, 0.58, 1.0],
                      ),
                    ),
                  ),
                ),

                // 4. Ambient Accent Glow Behind Card Fan
                Positioned(
                  right: -18,
                  top: -18,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.28),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Interactive Content Row
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.of(context).push(
                        _customPageRoute(const ThemePage(), 'ThemePage'),
                      );
                      _loadProfileData();
                      AdManager().loadInterstitialAd();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          // Left Copy & CTA
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top PRO Ribbon Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPremium
                                          ? [
                                              const Color(0xFF10B981),
                                              const Color(0xFF059669),
                                            ]
                                          : [
                                              const Color(0xFFFFD700),
                                              const Color(0xFFF59E0B),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
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
                                      const SizedBox(width: 4),
                                      Text(
                                        isPremium
                                            ? 'PRO AKTİF • 30 TEMA'
                                            : 'PRO ÖZEL • 30 TEMA',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: isPremium
                                              ? Colors.white
                                              : const Color(0xFF1F1600),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 9),

                                // Magnetic Main Title
                                const Text(
                                  'Askeri Temalar Kullan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Subtitle
                                Text(
                                  !_isDefaultTheme
                                      ? 'Aktif: $activeTitle • Diğer temaları dene'
                                      : 'Al Sancak, JÖH ve Bordo Bereli duvar kağıtlarıyla ekranını özelleştir.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 11.5,
                                    height: 1.32,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 11),

                                // Bottom Mini CTA Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.42),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility_rounded,
                                        size: 13,
                                        color: isPremium
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFFFDE047),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Canlı Önizle & Seç',
                                        style: TextStyle(
                                          color: isPremium
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFFFDE047),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 13,
                                        color: isPremium
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFFFDE047),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Right 3-Card Fanned Wallpaper Preview Deck
                          SizedBox(
                            width: 92,
                            height: 88,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Left Angled Card (Bordo Bereliler)
                                Positioned(
                                  left: 2,
                                  top: 10,
                                  child: Transform.rotate(
                                    angle: -0.20,
                                    child: _buildMiniWallpaperThumb(
                                      assetPath: 'assets/images/img3.webp',
                                      width: 44,
                                      height: 66,
                                      borderColor: Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),

                                // Right Angled Card (JÖH)
                                Positioned(
                                  right: 2,
                                  top: 10,
                                  child: Transform.rotate(
                                    angle: 0.20,
                                    child: _buildMiniWallpaperThumb(
                                      assetPath: 'assets/images/img19.webp',
                                      width: 44,
                                      height: 66,
                                      borderColor: Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),

                                // Center Hero Card (Al Bayrak / Active Theme)
                                Positioned(
                                  top: 4,
                                  child: _buildMiniWallpaperThumb(
                                    assetPath: centerPreviewAsset,
                                    width: 50,
                                    height: 76,
                                    borderColor: isPremium
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFFFD700),
                                    borderWidth: 1.8,
                                    hasGlow: true,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniWallpaperThumb({
    required String assetPath,
    required double width,
    required double height,
    required Color borderColor,
    double borderWidth = 1.1,
    bool hasGlow = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: hasGlow
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: hasGlow ? 10 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          cacheWidth: 180,
        ),
      ),
    );
  }

  // ─── Bildirim Saati Tile & Picker ────────────────────────────────────────

  Widget _buildNotificationTimeTile() {
    final bool isDark = !_isDefaultTheme;
    final String timeLabel =
        '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showNotificationTimePicker,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _getCardColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getBorderColor(), width: 1),
              boxShadow: _isDefaultTheme
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.deepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 22,
                    color: isDark ? Colors.white : Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bildirim Saati',
                        style: TextStyle(
                          color: _getTextColor(),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Her gün $timeLabel\'de bildirim alırsın',
                        style: TextStyle(
                          color: _getSubtitleColor(),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.deepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.deepOrange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.deepOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationTimePicker() {
    final bool isDark = !_isDefaultTheme;
    final Color modalBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    // Temp values that will be committed on "Kaydet"
    int tempHour = _notifHour;
    int tempMinute = _notifMinute;

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: modalBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.alarm_outlined,
                            color: Colors.deepOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Bildirim Saatini Seç',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Kalan askerlik gününü her gün bu saatte hatırlatacağız.',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Time display + stepper
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hour selector
                          _buildTimeColumn(
                            label: 'Saat',
                            value: tempHour,
                            min: 0,
                            max: 23,
                            isDark: isDark,
                            textColor: textColor,
                            onDecrement: () => setModalState(() {
                              tempHour = (tempHour - 1 + 24) % 24;
                            }),
                            onIncrement: () => setModalState(() {
                              tempHour = (tempHour + 1) % 24;
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          // Minute selector
                          _buildTimeColumn(
                            label: 'Dakika',
                            value: tempMinute,
                            min: 0,
                            max: 59,
                            isDark: isDark,
                            textColor: textColor,
                            onDecrement: () => setModalState(() {
                              tempMinute = (tempMinute - 1 + 60) % 60;
                            }),
                            onIncrement: () => setModalState(() {
                              tempMinute = (tempMinute + 1) % 60;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save & Cancel buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              'Vazgeç',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              // Save and reschedule
                              await NotificationService()
                                  .saveNotificationTime(tempHour, tempMinute);
                              if (mounted) {
                                setState(() {
                                  _notifHour = tempHour;
                                  _notifMinute = tempMinute;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✅ Bildirim saati ${tempHour.toString().padLeft(2, '0')}:${tempMinute.toString().padLeft(2, '0')} olarak ayarlandı.',
                                    ),
                                    backgroundColor: Colors.deepOrange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Kaydet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Test notification button
                  const SizedBox(height: 10),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 24),
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: TextButton.icon(
                  //       onPressed: () async {
                  //         Navigator.of(ctx).pop();
                  //         await NotificationService().showTestNotification();
                  //         if (mounted) {
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             SnackBar(
                  //               content: const Text(
                  //                 '🔔 Test bildirimi gönderildi! Görünmüyorsa sistem ayarlarından izni kontrol edin.',
                  //               ),
                  //               backgroundColor: Colors.blueGrey.shade700,
                  //               behavior: SnackBarBehavior.floating,
                  //               duration: const Duration(seconds: 4),
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(12),
                  //               ),
                  //             ),
                  //           );
                  //         }
                  //       },
                  //       icon: const Icon(Icons.notifications_outlined, size: 18),
                  //       label: const Text('Test Bildirimi Gönder'),
                  //       style: TextButton.styleFrom(
                  //         foregroundColor: isDark ? Colors.white54 : Colors.blueGrey,
                  //         padding: const EdgeInsets.symmetric(vertical: 10),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  // const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildTimeColumn({
    required String label,
    required int value,
    required int min,
    required int max,
    required bool isDark,
    required Color textColor,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        IconButton(
          onPressed: onIncrement,
          icon: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.deepOrange,
            size: 30,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            value.toString().padLeft(2, '0'),
            key: ValueKey(value),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 1,
            ),
          ),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.deepOrange,
            size: 30,
          ),
        ),
      ],
    );
  }

  // ─── End Bildirim Saati ───────────────────────────────────────────────────

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {

    final bool isDark = !_isDefaultTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _getCardColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getBorderColor(), width: 1),
              boxShadow: _isDefaultTheme
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : (iconColor ?? Colors.blueAccent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDark ? Colors.white : (iconColor ?? Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPolicyBottomSheet({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
  }) {
    final bool isDark = !_isDefaultTheme;
    final Color modalBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final Color buttonColor = accentColor;

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Container(
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: buttonColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: buttonColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  height: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        content.trim(),
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).padding.bottom + 16.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Okudum, Anladım',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const String _privacyPolicyContent = """
Bu Gizlilik Politikası, Hizmeti kullandığınızda bilgilerinizin toplanması, kullanılması ve ifşası ile ilgili politikalarımızı ve prosedürlerimizi açıklar ve Size gizlilik haklarınız ve yasaların Sizi nasıl koruduğunu anlatır.

Kişisel verilerinizi Hizmeti sağlamak ve geliştirmek için kullanıyoruz. Hizmeti kullanarak, bu Gizlilik Politikasına uygun olarak bilgilerin toplanmasını ve kullanılmasını kabul etmiş olursunuz. Bu Gizlilik Politikası, Ücretsiz Gizlilik Politikası Oluşturucunun yardımıyla oluşturulmuştur.

Yorumlama ve Tanımlar

Yorumlama

İlk harfi büyük harfle yazılmış olan kelimeler, aşağıdaki koşullar altında tanımlanmış anlamlara sahiptir. Aşağıdaki tanımlar, tekil veya çoğul olarak görünseler de aynı anlama sahip olacaktır.

Tanımlar

Bu Gizlilik Politikasının amaçları doğrultusunda:

Hesap, Hizmetimize veya Hizmetimizin bölümlerine erişmeniz için oluşturulan benzersiz bir hesap anlamına gelir.

Bağlı kuruluş, bir tarafı kontrol eden, bir taraf tarafından kontrol edilen veya bir tarafla ortak kontrol altında olan bir varlık anlamına gelir, burada "kontrol", hisselerin, özkaynak hisselerinin veya yöneticilerin veya diğer yönetim otoritelerinin seçimi için oy kullanma hakkına sahip diğer menkul kıymetlerin %50'sinin veya daha fazlasının mülkiyeti anlamına gelir.

Başvuru, Şirket tarafından sağlanan yazılım programı olan Şafak Sayar 2026'e atıfta bulunmaktadır.

Şirket (bu Sözleşmede "Şirket", "Biz", "Bize" veya "Bizim" olarak anılacaktır) Şafak Sayar 2026'i ifade eder.

Ülkeye atıfta bulunuyor: Türkiye

Cihaz, bilgisayar, cep telefonu veya dijital tablet gibi Hizmete erişebilen herhangi bir cihaz anlamına gelir.

Kişisel Veriler, tanımlanmış veya tanımlanabilir bir kişiyle ilgili herhangi bir bilgidir.

Hizmet, Uygulamayı ifade eder.

Hizmet Sağlayıcı, verileri Şirket adına işleyen herhangi bir gerçek veya tüzel kişi anlamına gelir. Hizmeti kolaylaştırmak, Şirket adına Hizmeti sağlamak, Hizmetle ilgili hizmetleri gerçekleştirmek veya Hizmetin nasıl kullanıldığını analiz etmede Şirkete yardımcı olmak için Şirket tarafından istihdam edilen üçüncü taraf şirketleri veya bireyleri ifade eder.

Kullanım Verileri, Hizmetin kullanımıyla veya Hizmet altyapısının kendisinden (örneğin, bir sayfa ziyaretinin süresi) oluşturulan otomatik olarak toplanan verileri ifade eder.

Hizmete erişen veya Hizmeti kullanan kişiyi veya bu kişinin adına Hizmete eriştiği veya Hizmeti kullandığı şirket veya diğer tüzel kişiyi kastediyorsunuz.

Kişisel Verilerinizin Toplama ve Kullanma

Toplanan Veri Türleri

Kişisel Veriler

Hizmetimizi kullanırken, Sizinle iletişim kurmak veya Sizi tanımlamak için kullanılabilecek belirli kişisel olarak tanımlanabilir bilgileri Bize sağlamanızı isteyebiliriz. Kişisel olarak tanımlanabilir bilgiler aşağıdakileri içerebilir, ancak bunlarla sınırlı değildir:

Ad ve soyadı

Kullanım Verileri

Kullanım Verileri

Kullanım Verileri, Hizmeti kullanırken otomatik olarak toplanır.

Kullanım Verileri, Cihazınızın İnternet Protokolü adresi gibi bilgileri içerebilir (örn. IP adresi), tarayıcı türü, tarayıcı sürümü, Hizmetimizin ziyaret ettiğiniz sayfaları, ziyaretinizin saati ve tarihi, bu sayfalarda geçirilen süre, benzersiz cihaz tanımlayıcıları ve diğer teşhis verileri.

Hizmete bir mobil cihaz aracılığıyla veya aracılığıyla eriştiğinizde, kullandığınız mobil cihazın türü, mobil cihazınızın benzersiz kimliği, mobil cihazınızın IP adresi, mobil işletim sisteminiz, kullandığınız mobil İnternet tarayıcısının türü, benzersiz cihaz tanımlayıcıları ve diğer tanılama verileri dahil ancak bunlarla sınırlı olmamak üzere belirli bilgileri otomatik olarak toplayabiliriz.

Hizmetimizi her ziyaret ettiğinizde veya Hizmete bir mobil cihaz üzerinden veya bir mobil cihaz aracılığıyla eriştiğinizde tarayıcınızın gönderdiği bilgileri de toplayabiliriz.

Kişisel Verilerinizin Kullanımı

Şirket, Kişisel Verileri aşağıdaki amaçlar için kullanabilir:

Hizmetimizin kullanımını izlemek de dahil olmak üzere Hizmetimizi sağlamak ve sürdürmek.

Hesabınızı yönetmek için: Hizmet kullanıcısı olarak kaydınızı yönetmek için. Sağladığınız Kişisel Veriler, kayıtlı bir kullanıcı olarak Size sunulan Hizmetin farklı işlevlerine erişmenizi sağlayabilir.

Bir sözleşmenin ifası için: Satın aldığınız ürünler, ürünler veya hizmetler için satın alma sözleşmesinin veya Hizmet aracılığıyla Bizimle yapılan başka herhangi bir sözleşmenin geliştirilmesi, uyumu ve üstlenilmesi.

Sizinle iletişim kurmak için: Bir mobil uygulamanın güncellemelerle ilgili anlık bildirimleri veya güvenlik güncellemeleri de dahil olmak üzere işlevler, ürünler veya sözleşmeli hizmetlerle ilgili bilgilendirici iletişimler gibi e-posta, telefon görüşmeleri, SMS veya diğer eşdeğer elektronik iletişim biçimleriyle sizinle iletişim kurmak için, bunların uygulanması için gerekli veya makul olduğunda.

Bu tür bilgileri almamayı tercih etmediğiniz sürece, daha önce satın aldığınız veya sorguladığınıza benzer sunduğumuz diğer maller, hizmetler ve etkinlikler hakkında Size haberler, özel teklifler ve genel bilgiler sağlamak.

İsteklerinizi yönetmek için: Bize olan isteklerinize katılmak ve yönetmek için.

İş transferleri için: Bilgilerinizi, Hizmet kullanıcılarımız hakkında tarafımızca tutulan Kişisel Verilerin devredilen varlıklar arasında olduğu, devam eden bir işletme olarak veya iflas, tasfiye veya benzer bir işlemin bir parçası olarak birleşme, elden çıkarma, yeniden yapılandırma, yeniden yapılanma, fesih veya varlıklarımızın bir kısmının veya tamamının başka bir satışını veya devrini değerlendirmek veya yürütmek için kullanabiliriz.

Diğer amaçlar için: Bilgilerinizi veri analizi, kullanım eğilimlerini belirleme, promosyon kampanyalarımızın etkinliğini belirleme ve Hizmetimizi, ürünlerimizi, hizmetlerimizi, pazarlamamızı ve deneyiminizi değerlendirmek ve geliştirmek gibi başka amaçlar için kullanabiliriz.

Kişisel bilgilerinizi aşağıdaki durumlarda paylaşabiliriz:

Hizmet Sağlayıcılarla: Hizmetimizin kullanımını izlemek ve analiz etmek, Sizinle iletişim kurmak için kiisel bilgilerinizi Hizmet Sağlayıcılarla paylaşabiliriz.
İş transferleri için: Kişisel bilgilerinizi, herhangi bir birleşme, Şirket varlıklarının satışı, finansman veya işimizin tamamının veya bir kısmının başka bir şirkete satın alınmasıyla bağlantılı olarak veya müzakereler sırasında paylaşabilir veya aktarabiliriz.
İştiraklerle: Bilgilerinizi iştiraklerimizle paylaşabiliriz, bu durumda bu bağlı kuruluşların bu Gizlilik Politikasına uymalarını isteyeceğiz. İştirakler, ana şirketimizi ve kontrol ettiğimiz veya Bizimle ortak kontrol altında olan diğer iştirakleri, ortak girişim ortaklarını veya diğer şirketleri içerir.
İş ortaklarımızla: Size belirli ürünler, hizmetler veya promosyonlar sunmak için bilgilerinizi iş ortaklarımızla paylaşabiliriz.
Diğer kullanıcılarla: Kişisel bilgileri paylaştığınızda veya kamuya açık alanlarda diğer kullanıcılarla başka bir şekilde etkileşimde bulunduğunuzda, bu tür bilgiler tüm kullanıcılar tarafından görüntülenebilir ve dışarıda herkese açık olarak dağıtılabilir.
İzninizle: Kişisel bilgilerinizi sizin izninizle başka herhangi bir amaç için ifşa edebiliriz.
Kişisel Verilerinizin Saklanması

Şirket, Kişisel Verileri yalnızca bu Gizlilik Politikasında belirtilen amaçlar için gerekli olduğu sürece saklayacaktır. Kişisel Verilerinizi yasal yükümlülüklerimize uymak için gerekli ölçüde saklayacak ve kullanacağız (örneğin, yürürlükteki yasalara uymak için verilerinizi saklamamız gerekiyorsa), anlaşmazlıkları çözeceğiz ve yasal anlaşmalarımızı ve politikalarımızı uygulayacağız.

Şirket ayrıca Kullanım Verilerini dahili analiz amacıyla saklayacaktır. Kullanım Verileri, bu verilerin Güvenliğini güçlendirmek veya Hizmetimizin işlevselliğini geliştirmek için kullanılması dışında genellikle daha kısa bir süre için saklanır veya bu verileri daha uzun süreler boyunca saklamakla yasal olarak yükümlüdür.

Kişisel Verilerinizin Aktarımı

Kişisel Veriler de dahil olmak üzere bilgileriniz, Şirketin işletme ofislerinde ve işlemeye dahil olan tarafların bulunduğu diğer yerlerde işlenir. Bu, bu bilgilerin, veri koruma yasalarının Sizin yargı bölgenizden farklı olabileceği eyaletinizin, ilinizin, ülkenizin veya diğer hükümet yargı yetkisinin dışında bulunan bilgisayarlara aktarılabileceği ve bu bilgisayarlarda tutulabileceği anlamına gelir.

Bu Gizlilik Politikasına onay vermeniz ve ardından bu tür bilgileri göndermeniz, bu aktarımı kabul ettiğinizi temsil eder.

Şirket, verilerinizin güvenli bir şekilde ve bu Gizlilik Politikasına uygun olarak işlenmesini sağlamak için makul olarak gerekli tüm adımları atacaktır ve verilerinizin ve diğer kişisel bilgilerinizin güvenliği de dahil olmak üzere yeterli kontroller olmadıkça Kişisel Verilerinizin bir kuruluşa veya ülkeye aktarılması gerçekleşmeyecektir.

Kişisel Verilerinizi Silin

Hakkınızda topladığımız Kişisel Verileri silme veya silinmesine yardımcı olmamızı talep etme hakkına sahipsiniz.

Hizmetimiz Size Hizmet içinden Sizinle ilgili belirli bilgileri silme olanağı verebilir.

Hesabınız varsa hesabınıza giriş yaparak ve kişisel bilgilerinizi yönetmenize olanak tanıyan hesap ayarları bölümünü ziyaret ederek bilgilerinizi istediğiniz zaman güncelleyebilir, değiştirebilir veya silebilirsiniz. Bize sağladığınız herhangi bir kişisel bilgiye erişim talebinde bulunmak, düzeltmek veya silmek için de Bizimle iletişime geçebilirsiniz.

Bununla birlikte, bunu yapmak için yasal bir yükümlülüğümüz veya yasal dayanağımız olduğunda belirli bilgileri saklamamız gerekebileceğini lütfen unutmayın.

Kişisel Verilerinizin Açıklanması

Ticari İşlemler

Şirket bir birleşme, satın alma veya varlık satışına dahil olursa, Kişisel Verileriniz aktarılabilir. Kişisel Verileriniz aktarılmadan ve farklı bir Gizlilik Politikasına tabi olmadan önce bildirimde bulunacağız.

Kolluk kuvvetleri

Belirli koşullar altında, yasalar gereği veya kamu makamlarının (örneğin bir mahkeme veya bir devlet kurumu) geçerli taleplerine yanıt olarak Şirket'in Kişisel Verilerinizi ifşa etmesi gerekebilir.

Diğer yasal gereklilikler

Şirket, Kişisel Verileri, bu tür bir eylemin aşağıdakiler için gerekli olduğuna iyi niyetle inanarak ifşa edebilir:

Yasal bir yükümlülüğe uymak
Şirketin haklarını veya mülkiyetini koruyun ve savunun
Hizmetle bağlantılı olarak olası yanlışları önlemek veya araştırmak
Hizmet Kullanıcılarının veya halkın kişisel güvenliğini koruyun
Yasal sorumluluğa karşı koruyun
Kişisel Verilerinizin Güvenliği

Kişisel Verilerinizin güvenliği Bizim için önemlidir, ancak İnternet üzerinden hiçbir iletim yönteminin veya elektronik depolama yönteminin %100 güvenli olmadığını unutmayın. Kişisel Verilerinizi korumak için ticari olarak kabul edilebilir araçlar kullanmaya çalışsak da, mutlak güvenliğini garanti edemeyiz.

Çocukların Gizliliği

Hizmetimiz 13 yaşın altındaki hiç kimseye hitap etmez. 13 yaşın altındaki hiç kimseden bilerek kişisel olarak tanımlanabilir bilgiler toplamıyoruz. Bir ebeveyn veya vasiyseniz ve çocuğunuzun Bize Kişisel Veriler sağladığının farkındaysanız, lütfen Bizimle iletişime geçin. Ebeveyn izninin doğrulanması olmadan 13 yaşın altındaki herhangi birinden Kişisel Veri topladığımızı fark edersek, bu bilgileri sunucularımızdan kaldırmak için adımlar atarız.

Bilgilerinizi işlemek için yasal bir dayanak olarak rızaya güvenmemiz gerekiyorsa ve ülkeniz bir ebeveynin iznini gerektiriyorsa, bu bilgileri toplamadan ve kullanmadan önce ebeveyninizin onayını isteyebiliriz.

Diğer Web Sitelerine Bağlantılar

Hizmetimiz, Bizim tarafımızdan işletilmeyen diğer web sitelerine bağlantılar içerebilir. Üçüncü taraf bağlantısına tıklarsanız, o üçüncü tarafın sitesine yönlendirileceksiniz. Ziyaret ettiğiniz her sitenin Gizlilik Politikasını gözden geçirmenizi şiddetle tavsiye ederiz.

Herhangi bir üçüncü taraf sitenin veya hizmetinin içeriği, gizlilik politikaları veya uygulamaları üzerinde hiçbir kontrolümüz yoktur ve bunlar için hiçbir sorumluluk kabul etmeziz.

Bu Gizlilik Politikasındaki Değişiklikler

Gizlilik Politikamızı zaman zaman güncelleyebiliriz. Yeni Gizlilik Politikasını bu sayfada yayınlayarak herhangi bir değişikliği Size bildireceğiz.

Değişiklik yürürlüğe girmeden önce e-posta ve/veya Hizmetimiz hakkında belirgin bir bildirim yoluyla size bildireceğiz ve bu Gizlilik Politikası'nın en üstündeki "Son güncelleme" tarihini güncelleyeceğiz.

Herhangi bir değişiklik için bu Gizlilik Politikasını düzenli olarak gözden geçirmeniz önerilir. Bu Gizlilik Politikalarındaki değişiklikler, bu sayfada yayınlandıklarında yürürlüğe girer.

Bize Ulaşın

Bu Gizlilik Politikası hakkında herhangi bir sorunuz varsa, bizimle iletişime geçebilirsiniz:

E-posta ile: bayesatechnology@gmail.com
""";

  static const String _termsOfUseContent = """
ŞAFAK SAYAR 2026 KULLANIM ŞARTLARI

1. Giriş

Şafak Sayar 2026 Mobil Uygulaması ("Uygulama") ve Şafak Sayar ("Web Sitesi") Şafak Sayar 2026 ("Şirket", "Biz") tarafından sağlanır ve işletilir. Uygulamamızı ve/veya Web Sitemizi kullanarak bu Kullanım Şartlarını kabul etmiş olursunuz.

2. Uygulamanın/Web Sitesinin Erişim ve Kullanımı

Uygulamaya/Web Sitesine erişim sağlamak için gerekli tüm düzenlemeleri yapma sorumluluğu size aittir. Uygulamayı/Web Sitesini ve Uygulamada/Web Sitesinde sunduğumuz herhangi bir hizmeti veya materyali tek taraflı olarak bildirimde bulunmaksızın çekme veya değiştirme hakkımızı saklı tutarız. Uygulamanın/Web Sitesinin herhangi bir sebep nedeniyle tamamen veya kısmen belirli bir süre veya sürekli olarak erişilemez olması durumunda hiçbir sorumluluğumuz bulunmamaktadır.

3. Fikri Mülkiyet Hakları

Uygulama ve Web Sitesindeki tüm fikri mülkiyet hakları ve bunlarda yayınlanan materyaller Şafak Sayar 2026 tarafından sahiplenilmektedir. Bu eserler dünya çapındaki telif hakkı yasaları ve antlaşmaları tarafından korunmaktadır. Tüm bu haklar saklıdır.

4. Satın Almalar

Uygulama/Web Sitesi üzerinden sunulan herhangi bir ürün veya hizmeti satın almak isterseniz, Satın Alma işlemine ilişkin belirli bilgileri sağlamanız istenebilir. Satın alma işlemleri Google Play veya App Store'un ödeme altyapısı aracılığıyla gerçekleştirilir.

5. Kullanım Şartlarında Değişiklikler

Bu Kullanım Şartlarını zaman zaman tek taraflı olarak gözden geçirebilir ve güncelleyebiliriz. Kullanım Şartlarının revize edilmiş hali yayınlandıktan sonra Uygulamayı/Web Sitesini kullanmaya devam etmeniz, değişiklikleri kabul ettiğiniz ve bunlara uyduğunuz anlamına gelir. Herhangi bir değişiklikten haberdar olmanız için bu sayfayı düzenli olarak kontrol etmeniz beklenir, çünkü bu değişiklikler size bağlayıcıdır.

6. Bize Ulaşın

Bu Şartlar hakkında herhangi bir sorunuz varsa, lütfen bize bayesatechnology@gmail.com adresinden ulaşın.

Son güncelleme: 20 Aralık 2025

Bu Kullanım Şartları, Şafak Sayar 2026 tarafından sağlanmıştır.
""";
}
