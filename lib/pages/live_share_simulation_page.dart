import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interactive pre-PRO simulation & live preview for:
/// 1) Live Şafak Tracking (how the soldier's loved one sees the countdown & notifications on their phone)
/// 2) Surprise Time Capsule (how locked voice notes, photos & letters behave before and at 00:00 unlock)
class LiveShareSimulationPage extends StatefulWidget {
  final int initialTab; // 0: Canlı Şafak Takibi, 1: Zaman Kapsülü

  const LiveShareSimulationPage({
    super.key,
    this.initialTab = 0,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTab = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'LiveShareSimulationPage'),
        builder: (_) => LiveShareSimulationPage(initialTab: initialTab),
      ),
    );
  }

  @override
  State<LiveShareSimulationPage> createState() =>
      _LiveShareSimulationPageState();
}

class _LiveShareSimulationPageState extends State<LiveShareSimulationPage>
    with TickerProviderStateMixin {
  late int _activeTab; // 0 = Canlı Takip, 1 = Zaman Kapsülü
  int _selectedPersona = 0; // 0 = Sevgilim / Eşim, 1 = Annem & Ailem

  // Personalized soldier context from SharedPreferences
  String _soldierFullName = 'MEHMETÇİK';
  String _soldierFirstName = 'Askerim';
  String _soldierRank = 'ER';
  String _soldierPlace = 'Kışla Görevi';
  String _trackingCode = '';
  String _dischargeDateFormatted = 'Yakında';
  double _progressRatio = 0.58;

  // Live ticking countdown inside simulation
  Duration _liveRemaining = const Duration(
    days: 78,
    hours: 14,
    minutes: 36,
    seconds: 42,
  );
  int _simulatedBonusDaysDropped = 0;
  Timer? _countdownTicker;

  // Simulated push banner inside mocked phone
  String? _pushBannerTitle;
  String? _pushBannerBody;
  IconData _pushBannerIcon = Icons.notifications_active_rounded;
  Color _pushBannerAccent = const Color(0xFFEC4899);
  Timer? _pushBannerDismissTimer;

  // Time Capsule simulation state
  int _selectedCapsuleIndex = 0;
  bool _isCapsuleUnlocked = false;
  String? _lockFeedbackMessage;
  bool _isVoicePlaying = false;
  int _voiceElapsedSec = 0;
  final int _voiceTotalSec = 24;
  Timer? _voiceTimer;

  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _waveController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _hydrateUserData();

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_liveRemaining.inSeconds > 0) {
        setState(() {
          _liveRemaining -= const Duration(seconds: 1);
        });
      }
    });

    // Show a welcoming live sync banner automatically shortly after opening
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _activeTab != 0) return;
      _triggerSimulatedPush(
        title: _selectedPersona == 0
            ? '💕 Canlı Şafak Bağlantısı Aktif'
            : '🇹🇷 Aile Şafak Takibi Aktif',
        body: _selectedPersona == 0
            ? '$_soldierFirstName ile şafak sayacınız saniyesi saniyesine eşitlendi.'
            : 'Oğlunuz $_soldierFirstName için kalan gün ve terhis tarihi canlı izleniyor.',
        icon: Icons.sync_rounded,
        accent: _selectedPersona == 0
            ? const Color(0xFFEC4899)
            : const Color(0xFF10B981),
      );
    });
  }

  Future<void> _hydrateUserData() async {
    final prefs =
        SoldierMatchService.instance.cachedPrefs ??
        await SharedPreferences.getInstance();

    final String rawName = (prefs.getString('name') ?? '').trim();
    final String rawSurname = (prefs.getString('surname') ?? '').trim();
    final String rank = (prefs.getString('rutbe') ?? 'ER').trim();
    final String place = (prefs.getString('askerlik_yeri') ?? '').trim();
    final String sulusStr = (prefs.getString('sulus_tarihi') ?? '').trim();
    final String endStr = (prefs.getString('end_date') ?? '').trim();
    String code = (prefs.getString('tracking_code') ?? '').trim();

    if (code.isEmpty) {
      code = await SoldierMatchService.instance.generateOrGetTrackingCode();
    }

    Duration calcRemaining = _liveRemaining;
    double calcRatio = 0.58;
    String formattedEnd = 'Terhis Günü';

    final DateTime now = DateTime.now();
    final DateTime? parsedEnd =
        endStr.isNotEmpty ? DateTime.tryParse(endStr) : null;
    final DateTime? parsedStart =
        sulusStr.isNotEmpty ? DateTime.tryParse(sulusStr) : null;

    if (parsedEnd != null) {
      if (parsedEnd.isAfter(now)) {
        calcRemaining = parsedEnd.difference(now);
      } else {
        calcRemaining = const Duration(
          days: 42,
          hours: 9,
          minutes: 18,
          seconds: 35,
        );
      }
      formattedEnd =
          '${parsedEnd.day.toString().padLeft(2, '0')}.${parsedEnd.month.toString().padLeft(2, '0')}.${parsedEnd.year}';

      if (parsedStart != null && parsedEnd.isAfter(parsedStart)) {
        final totalSec = parsedEnd.difference(parsedStart).inSeconds;
        final elapsedSec = now.difference(parsedStart).inSeconds;
        if (totalSec > 0) {
          calcRatio = (elapsedSec / totalSec).clamp(0.08, 0.96);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      final fullName = '$rawName $rawSurname'.trim();
      _soldierFullName =
          fullName.isNotEmpty ? fullName.toUpperCase() : 'MEHMETÇİK';
      _soldierFirstName = rawName.isNotEmpty ? rawName : 'Askerin';
      _soldierRank = rank.isNotEmpty ? rank.toUpperCase() : 'ER';
      _soldierPlace = place.isNotEmpty ? place : 'Birlik Görevi';
      _trackingCode = code;
      _liveRemaining = calcRemaining;
      _dischargeDateFormatted = formattedEnd;
      _progressRatio = calcRatio;
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _pushBannerDismissTimer?.cancel();
    _voiceTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    _waveController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerSimulatedPush({
    required String title,
    required String body,
    required IconData icon,
    required Color accent,
  }) {
    HapticFeedback.mediumImpact();
    _pushBannerDismissTimer?.cancel();
    setState(() {
      _pushBannerTitle = title;
      _pushBannerBody = body;
      _pushBannerIcon = icon;
      _pushBannerAccent = accent;
    });
    _pushBannerDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _pushBannerTitle = null;
        });
      }
    });
  }

  void _simulateSafakDrop() {
    final int currentDays =
        math.max(1, _liveRemaining.inDays - _simulatedBonusDaysDropped - 1);
    setState(() {
      _simulatedBonusDaysDropped += 1;
    });
    _triggerSimulatedPush(
      title: '🌅 Günaydın! Şafak Bir Gün Daha Düştü',
      body: _selectedPersona == 0
          ? '$_soldierFirstName ile kavuşmanıza artık sadece $currentDays gün kaldı! 💕'
          : 'Gözünüz aydın! $_soldierFirstName için şafak $currentDays güne düştü 🇹🇷',
      icon: Icons.wb_sunny_rounded,
      accent: const Color(0xFFF59E0B),
    );
  }

  void _simulateLeaveSync() {
    setState(() {
      _simulatedBonusDaysDropped += 3;
      _progressRatio = (_progressRatio + 0.05).clamp(0.08, 0.98);
    });
    _triggerSimulatedPush(
      title: '⚡ Canlı İzin Güncellemesi Yansıdı!',
      body:
          '$_soldierFirstName 3 gün izin ekledi; telefonunuzdaki terhis sayacı otomatik öne çekildi.',
      icon: Icons.bolt_rounded,
      accent: const Color(0xFF10B981),
    );
  }

  void _tryEarlyOpenLockedCapsule() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    final preset = _capsulePresets[_selectedCapsuleIndex];
    setState(() {
      _lockFeedbackMessage =
          '🔐 Mühür Korumalı! Bu sürpriz yalnızca "${preset['targetBadge']}" günü saat 00:00 olduğunda açılır.';
    });
  }

  void _unlockSimulatedCapsule() {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    setState(() {
      _isCapsuleUnlocked = true;
      _lockFeedbackMessage = null;
      _isVoicePlaying = true;
      _voiceElapsedSec = 0;
    });
    _startSimulatedVoicePlayback();
  }

  void _startSimulatedVoicePlayback() {
    _voiceTimer?.cancel();
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isVoicePlaying) {
        timer.cancel();
        return;
      }
      if (_voiceElapsedSec < _voiceTotalSec) {
        setState(() {
          _voiceElapsedSec++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isVoicePlaying = false;
          _voiceElapsedSec = 0;
        });
      }
    });
  }

  void _toggleVoicePlayback() {
    HapticFeedback.selectionClick();
    setState(() {
      _isVoicePlaying = !_isVoicePlaying;
    });
    if (_isVoicePlaying) {
      _startSimulatedVoicePlayback();
    } else {
      _voiceTimer?.cancel();
    }
  }

  List<Map<String, String>> get _capsulePresets => [
        {
          'chip': '💖 Şafak 50',
          'targetBadge': 'Şafak 50 Sabahı',
          'sender': 'Sevgilinden Sürpriz Kapsül',
          'voiceQuote':
              '«Canım askerim, bugün şafak 50\'ye düştü! Gece nöbetinde sesimi duyup gülümse istedim, seni çok seviyorum...»',
          'letter':
              'Sen orada vatan nöbetindeyken ben de burada her sabah takvimden bir gün daha eksiltiyorum. En zor kısmını geride bıraktık, sağ salim kollarıma döneceğin günü sabırsızlıkla bekliyorum.',
          'photoCaption': 'Birlikte Son Kahvemiz • Saklanan Anı Karesi',
        },
        {
          'chip': '🏡 Plaka 81',
          'targetBadge': 'Şafak 81 (Plakalara Giriş)',
          'sender': 'Annenden & Ailenden Kapsül',
          'voiceQuote':
              '«Aslan oğlum, bugün plakalara düştün! Baban da ben de seninle gurur duyuyoruz, dualarımız hep seninle...»',
          'letter':
              'Güzel evladım, odan da sevdiğin yemekler de seni bekliyor. Plakaları birer birer bitirip hayırlısıyla kapımızdan içeri gireceğin sabahı iple çekiyoruz. Allah ayağına taş değdirmesin.',
          'photoCaption': 'Uğurlama Günü Aile Hatırası • Evimizden Kare',
        },
        {
          'chip': '🇹🇷 Terhis Sabahı',
          'targetBadge': 'Şafak Doğan Güneş (00:00)',
          'sender': 'Kavuşma Sabahı Özel Mühür',
          'voiceQuote':
              '«Bitti sevgilim! O büyük sabah geldi, bavulunu topla; kapıda seni bekliyorum!»',
          'letter':
              'Aylardır ikimizin de telefonunda saniye saniye saydığımız o hasret bu sabah sona erdi. Görevini onurla tamamladın, hoş geldin yeni hayatımıza!',
          'photoCaption': 'Kavuşma Bileti & İlk Gün Planımız',
        },
      ];

  @override
  Widget build(BuildContext context) {
    final Color personaAccent = _selectedPersona == 0
        ? const Color(0xFFEC4899)
        : const Color(0xFF10B981);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: Stack(
          children: [
            // Ambient luxury background glow
            Positioned(
              top: -90,
              left: -50,
              right: -50,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        (_activeTab == 0
                                ? personaAccent
                                : const Color(0xFFE11D48))
                            .withValues(alpha: 0.22),
                        const Color(0xFF4F46E5).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      radius: 0.85,
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildModeSegmentedControl(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _activeTab == 0
                          ? _buildLiveTrackingTab(personaAccent)
                          : _buildTimeCapsuleTab(),
                    ),
                  ),
                  _buildStickyBottomProDock(),
                ],
              ),
            ),

            // Confetti burst for capsule unlock celebration
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.06,
                  numberOfParticles: 24,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.22,
                  colors: const [
                    Color(0xFFFFD700),
                    Color(0xFFEC4899),
                    Color(0xFF10B981),
                    Color(0xFF38BDF8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.45, end: 1.0)
                          .animate(_pulseController),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'CANLI SİMÜLASYON ÖNİZLEME',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Sevdiklerinle Canlı Paylaşım Deneyimi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildModeTabButton(
                index: 0,
                icon: Icons.phonelink_ring_rounded,
                label: 'Canlı Şafak Takibi',
              ),
            ),
            Expanded(
              child: _buildModeTabButton(
                index: 1,
                icon: Icons.lock_clock_rounded,
                label: 'Zaman Kapsülü',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _activeTab == index;
    return GestureDetector(
      onTap: () {
        if (_activeTab == index) return;
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: index == 0
                      ? [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
                      : [const Color(0xFFE11D48), const Color(0xFF7C3AED)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 0: LIVE RELATIVE PHONE TRACKING SIMULATION
  // ===========================================================================
  Widget _buildLiveTrackingTab(Color personaAccent) {
    final int displayedDays =
        math.max(0, _liveRemaining.inDays - _simulatedBonusDaysDropped);
    final String hours =
        _liveRemaining.inHours.remainder(24).toString().padLeft(2, '0');
    final String mins =
        _liveRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String secs =
        _liveRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return SingleChildScrollView(
      key: const ValueKey('tab_tracking'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Persona Switcher ("Kimin Telefonundan Bakıyorsun?")
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kimin ekranını önizliyorsun?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildPersonaChip(
                index: 0,
                label: '💕 Sevgilim / Eşim',
                accent: const Color(0xFFEC4899),
              ),
              const SizedBox(width: 6),
              _buildPersonaChip(
                index: 1,
                label: '🏡 Ailem',
                accent: const Color(0xFF10B981),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Realistic Phone Frame Mockup
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0B1120)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: personaAccent.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: personaAccent.withValues(alpha: 0.16),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            child: Column(
              children: [
                // Simulated iPhone Dynamic Island + Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '09:41',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: personaAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'CANLI',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.wifi_rounded, color: Colors.white70, size: 13),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full_rounded, color: Colors.white70, size: 14),
                      ],
                    ),
                  ],
                ),

                // Animated Simulated iOS Push Notification Banner
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: _pushBannerTitle == null
                      ? const SizedBox(height: 10)
                      : Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _pushBannerAccent.withValues(alpha: 0.55),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _pushBannerAccent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _pushBannerIcon,
                                  color: _pushBannerAccent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pushBannerTitle!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _pushBannerBody ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Phone Screen Header: Tracked Soldier Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              personaAccent,
                              personaAccent.withValues(alpha: 0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _selectedPersona == 0
                              ? Icons.favorite_rounded
                              : Icons.shield_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPersona == 0
                                  ? 'ASKERİMİN CANLI ŞAFAĞI'
                                  : 'EVLADIMIZIN CANLI ŞAFAĞI',
                              style: TextStyle(
                                color: personaAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_soldierRank $_soldierFullName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _soldierPlace,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'BAĞLI 🟢',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Live Ticking Countdown Digits inside Loved-One's Phone
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        personaAccent.withValues(alpha: 0.16),
                        const Color(0xFF0F172A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: personaAccent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedPersona == 0
                            ? 'KAVUŞMAMIZA KALAN SÜRE'
                            : 'TERHİSE KALAN SÜRE',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSimTimeBox('$displayedDays', 'GÜN', personaAccent),
                          _buildTimeColon(),
                          _buildSimTimeBox(hours, 'SAAT', Colors.white),
                          _buildTimeColon(),
                          _buildSimTimeBox(mins, 'DAK', Colors.white),
                          _buildTimeColon(),
                          _buildSimTimeBox(secs, 'SAN', personaAccent),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressRatio,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(personaAccent),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '%${(_progressRatio * 100).toInt()} Tamamlandı',
                            style: TextStyle(
                              color: personaAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Kavuşma: $_dischargeDateFormatted',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Mini Time Capsule Shortcut Inside Mocked Phone
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _activeTab = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFFF472B6),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Takvimine Sürpriz Zaman Kapsülü Bırakabilir 💌',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'Dene →',
                          style: TextStyle(
                            color: Color(0xFFF472B6),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Simulation Trigger Buttons
          const Text(
            'CANLI SENARYOLARI DOKUNARAK TEST ET:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSimActionButton(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Şafak Düştü Bildirimi',
                  accent: const Color(0xFFF59E0B),
                  onTap: _simulateSafakDrop,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSimActionButton(
                  icon: Icons.bolt_rounded,
                  label: 'İzin Düştü Senkronu',
                  accent: const Color(0xFF10B981),
                  onTap: _simulateLeaveSync,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaChip({
    required int index,
    required String label,
    required Color accent,
  }) {
    final bool selected = _selectedPersona == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPersona = index;
          _simulatedBonusDaysDropped = 0;
        });
        _triggerSimulatedPush(
          title: index == 0
              ? '💕 Sevgili / Eş Görünümü Seçildi'
              : '🏡 Anne & Aile Görünümü Seçildi',
          body: index == 0
              ? 'Sevgilinin telefonunda şafağın her saniye böyle canlı akar.'
              : 'Ailen kendi telefonundan kalan gününü reklamsız ve canlı takip eder.',
          icon: index == 0 ? Icons.favorite_rounded : Icons.home_rounded,
          accent: accent,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSimTimeBox(String value, String unit, Color valueColor) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColon() {
    return const Text(
      ':',
      style: TextStyle(
        color: Colors.white38,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildSimActionButton({
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: SURPRISE TIME CAPSULE INTERACTIVE SIMULATION
  // ===========================================================================
  Widget _buildTimeCapsuleTab() {
    final preset = _capsulePresets[_selectedCapsuleIndex];

    return SingleChildScrollView(
      key: const ValueKey('tab_capsule'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Milestone Capsule Selector Chips
          const Text(
            'Örnek bir şafak günü seçip kapsülü dene:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_capsulePresets.length, (i) {
              final bool selected = _selectedCapsuleIndex == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _voiceTimer?.cancel();
                      setState(() {
                        _selectedCapsuleIndex = i;
                        _isCapsuleUnlocked = false;
                        _isVoicePlaying = false;
                        _voiceElapsedSec = 0;
                        _lockFeedbackMessage = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE11D48).withValues(alpha: 0.24)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFF43F5E)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _capsulePresets[i]['chip']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          if (!_isCapsuleUnlocked)
            _buildLockedCapsuleSimulationCard(preset)
          else
            _buildUnlockedCapsuleSimulationCard(preset),
        ],
      ),
    );
  }

  Widget _buildLockedCapsuleSimulationCard(Map<String, String> preset) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double dx =
            math.sin(_shakeController.value * math.pi * 4) * 7.0 * (1.0 - _shakeController.value);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F1638), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE11D48).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '🔒 HEDEF TARİHE KADAR MÜHÜRLÜ • ${preset['targetBadge']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFF7C3AED)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              preset['sender']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'İçinde 1 Sesli Mesaj (0:24), 1 Anı Fotoğrafı ve 1 Mektup gizli.\nTakvimde kilitli görünür; o sabah saat 00:00 olmadan kimse açamaz!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _buildSealedContentPill(Icons.mic_rounded, '0:24 Ses'),
                _buildSealedContentPill(Icons.photo_rounded, '1 Fotoğraf'),
                _buildSealedContentPill(Icons.mail_rounded, '1 Mektup'),
              ],
            ),
            if (_lockFeedbackMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _lockFeedbackMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _tryEarlyOpenLockedCapsule,
                    icon: const Icon(Icons.lock_outline_rounded, size: 15),
                    label: const Text(
                      'Erken Açmayı Dene',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _unlockSimulatedCapsule,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text(
                      'O Günü Simüle Et',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSealedContentPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF472B6), size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedCapsuleSimulationCard(Map<String, String> preset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.50),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔓 SAAT 00:00 • MÜHÜR AÇILDI (${preset['targetBadge']})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _voiceTimer?.cancel();
                  setState(() {
                    _isCapsuleUnlocked = false;
                    _isVoicePlaying = false;
                  });
                },
                child: const Text(
                  'Kilitle ↺',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 1. Simulated Voice Recording Player with Animated Waveform
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleVoicePlayback,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVoicePlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(18, (barIdx) {
                              final double progress =
                                  _voiceElapsedSec / _voiceTotalSec;
                              final bool played = (barIdx / 18) <= progress;
                              final double animFactor = _isVoicePlaying
                                  ? (0.45 +
                                      0.55 *
                                          math.sin(
                                            (_waveController.value * math.pi * 2) +
                                                barIdx * 0.7,
                                          ).abs())
                                  : 0.45;
                              final double barHeight =
                                  (8 + (barIdx % 4) * 5) * animFactor;
                              return Container(
                                width: 3.2,
                                height: barHeight.clamp(5.0, 24.0),
                                decoration: BoxDecoration(
                                  color: played
                                      ? const Color(0xFFF472B6)
                                      : Colors.white30,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '0:${_voiceElapsedSec.toString().padLeft(2, '0')} / 0:24',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preset['voiceQuote']!,
                  style: const TextStyle(
                    color: Color(0xFFFCE7F3),
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Simulated Memory Photo Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.22),
                  const Color(0xFFEC4899).withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_camera_back_rounded,
                    color: Colors.amberAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SAKLI ANI FOTOĞRAFI AÇILDI',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset['photoCaption']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Emotional Sealed Letter
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mark_email_read_rounded, color: Color(0xFF38BDF8), size: 15),
                    SizedBox(width: 6),
                    Text(
                      'MÜHÜRLÜ ŞAFAK MEKTUBU',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  preset['letter']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STICKY BOTTOM CONVERSION / INSTANT UNLOCK DOCK
  // ===========================================================================
  Widget _buildStickyBottomProDock() {
    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        final double bottomPad = MediaQuery.of(context).padding.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1120).withValues(alpha: 0.97),
            border: Border(
              top: BorderSide(
                color: isPremium
                    ? const Color(0xFF10B981).withValues(alpha: 0.40)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.30),
              ),
            ),
          ),
          child: isPremium
              ? _buildUnlockedCodeReadyDock()
              : _buildLockedUpgradeDock(),
        );
      },
    );
  }

  Widget _buildLockedUpgradeDock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFBBF24),
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kendi takip kodunu açıp sevgilini veya aileni hemen davet et.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'TR-••••••',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              HapticFeedback.heavyImpact();
              await PremiumPaywallPage.show(
                context,
                source: _activeTab == 1
                    ? 'capsule_simulation_preview'
                    : 'tracking_simulation_preview',
              );
            },
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF1F1600),
              size: 19,
            ),
            label: const Text(
              "PRO'YA GEÇ & CANLI PAYLAŞIMI AÇ",
              style: TextStyle(
                color: Color(0xFF1F1600),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF1F1600),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
              shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedCodeReadyDock() {
    final String code = _trackingCode.isNotEmpty ? _trackingCode : 'SFK-HAZIR';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 17,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'PRO AKTİF • PAYLAŞIM KODUNUZ:',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Takip kodu kopyalandı: $code'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text(
                  'Kopyala',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF34D399),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Builder(
                builder: (shareCtx) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final shareText =
                          '🇹🇷 Selam! Şafak Sayar uygulamasında şafağımı canlı takip edebilir ve takvimime sürpriz Zaman Kapsülü (ses, fotoğraf, mektup) bırakabilirsin!\n\nTakip Kodum: $code\n\nUygulamayı açıp "Asker Yakınıyım" seçeneğinden bu kodu girmen yeterli! 💕';
                      final box = shareCtx.findRenderObject() as RenderBox?;
                      final Rect origin =
                          (box != null && box.hasSize && box.size.width > 0)
                              ? (box.localToGlobal(Offset.zero) & box.size)
                              : const Rect.fromLTWH(100, 100, 160, 48);
                      Share.share(shareText, sharePositionOrigin: origin);
                    },
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text(
                      'Sevdiklerine Gönder',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

