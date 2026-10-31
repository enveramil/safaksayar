import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/Services/millionaire_duel_service.dart';
import 'package:safaksayar/Services/millionaire_rights_service.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/pages/millionaire/millionaire_classic_page.dart';
import 'package:safaksayar/pages/millionaire/millionaire_duel_page.dart';
import 'package:safaksayar/pages/millionaire/millionaire_leaderboard_page.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/widgets/millionaire/millionaire_ladder_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kim Milyoner Olmak İster Grand Hub & Game Arena
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _totalEarned = 0;
  int _duelWins = 0;

  @override
  void initState() {
    super.initState();
    MillionaireRightsService.instance.getRemainingRights();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    await MillionaireDuelService.instance.initUserProfile();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _totalEarned = prefs.getInt('score') ?? 0;
        _duelWins = prefs.getInt('duel_wins') ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF070B19),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF162554),
                  Color(0xFF0A0F24),
                  Color(0xFF03050C),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ==========================================
                // APP BAR
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "KİM MİLYONER OLMAK İSTER",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 22),
                        tooltip: "Para Ağacı & Kurallar",
                        onPressed: () => MillionaireLadderSheet.show(
                          context,
                          currentStep: 1,
                          currentEarned: 0,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // MAIN SCROLLABLE CONTENT
                // ==========================================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HERO BANNER
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/images/milyoner.webp',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                                    ),
                                    child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 60),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "BİLGİNİ SINA, ŞAMPİYON OL!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Askerlik ve genel kültür sorularıyla 5.000.000 TL büyük ödüle koş ya da diğer asker ve yakınlarıyla canlı düellolarda yarış!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // USER STATS BAR
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text("YARIŞMACI", style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Text(
                                    MillionaireDuelService.instance.currentUserName,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                              Container(height: 22, width: 1, color: Colors.white12),
                              ValueListenableBuilder<bool>(
                                valueListenable: RevenueCatService.instance.isPremiumNotifier,
                                builder: (context, isPro, _) {
                                  if (isPro) {
                                    return const Column(
                                      children: [
                                        Text("KLASİK HAK", style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 3),
                                        Text("👑 SINIRSIZ", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                                      ],
                                    );
                                  }
                                  return ValueListenableBuilder<int>(
                                    valueListenable: MillionaireRightsService.instance.remainingRightsNotifier,
                                    builder: (context, rights, _) {
                                      final hasRights = rights > 0;
                                      return Column(
                                        children: [
                                          const Text("GÜNLÜK HAK", style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 3),
                                          Text(
                                            "$rights/3",
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              color: hasRights ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              Container(height: 22, width: 1, color: Colors.white12),
                              Column(
                                children: [
                                  const Text("KAZANILAN", style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Text(
                                    _totalEarned > 0 ? "$_totalEarned TL" : "0 TL",
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                              Container(height: 22, width: 1, color: Colors.white12),
                              Column(
                                children: [
                                  const Text("DÜELLO", style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Text(
                                    _duelWins > 0 ? "$_duelWins Zafer" : "0 Zafer",
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ==========================================
                        // MODE 1: KLASİK YARIŞMA (12 BASAMAK)
                        // ==========================================
                        ValueListenableBuilder<bool>(
                          valueListenable: RevenueCatService.instance.isPremiumNotifier,
                          builder: (context, isPro, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable: MillionaireRightsService.instance.remainingRightsNotifier,
                              builder: (context, rights, _) {
                                final badge = isPro ? "STÜDYO FORMATI • 👑 SINIRSIZ HAK" : "STÜDYO FORMATI • $rights/3 GÜNLÜK HAK";
                                final buttonLabel = (isPro || rights > 0) ? "Yarışmaya Başla ▶" : "Haklar Doldu • PRO'ya Geç 👑";
                                return _buildGameModeCard(
                                  title: "KLASİK YARIŞMA",
                                  subtitle: isPro
                                      ? "12 Basamak • 4 Joker • 5.000.000 TL Hedef (Sınırsız Oyna)"
                                      : "12 Basamak • 4 Joker • 5.000.000 TL Hedef ($rights/3 Hak Kaldı)",
                                  badgeText: badge,
                                  icon: Icons.military_tech_rounded,
                                  accentColor: const Color(0xFFF59E0B),
                                  gradientColors: [const Color(0xFFB45309), const Color(0xFF1E293B)],
                                  buttonLabel: buttonLabel,
                                  onTap: () async {
                                    if (!RevenueCatService.instance.isPremium) {
                                      final remaining = await MillionaireRightsService.instance.getRemainingRights();
                                      if (remaining <= 0) {
                                        if (mounted) {
                                          await PremiumPaywallPage.show(context, source: 'millionaire_classic_limit');
                                        }
                                        if (!mounted || !RevenueCatService.instance.isPremium) {
                                          return;
                                        }
                                      } else {
                                        await MillionaireRightsService.instance.useOneRight();
                                      }
                                    }
                                    if (mounted) {
                                      AdManager.instance.showArenaInterstitialAd();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const MillionaireClassicPage()),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // ==========================================
                        // MODE 2: CANLI 1V1 DÜELLO (ONLINE)
                        // ==========================================
                        ValueListenableBuilder<bool>(
                          valueListenable: RevenueCatService.instance.isPremiumNotifier,
                          builder: (context, isPro, _) {
                            return _buildGameModeCard(
                              title: "CANLI 1v1 DÜELLO",
                              subtitle: "Askerler ve Yakınlarıyla Online Karşılaşma • 5 Hızlı Soru",
                              badgeText: isPro ? "ONLINE ÇOK OYUNCULU • PRO AKTİF" : "ONLINE ÇOK OYUNCULU • 👑 PRO ÖZEL",
                              icon: Icons.flash_on_rounded,
                              accentColor: const Color(0xFF38BDF8),
                              gradientColors: [const Color(0xFF0369A1), const Color(0xFF1E293B)],
                              buttonLabel: "Düello Arenasına Gir ⚔️",
                              onTap: () {
                                AdManager.instance.showArenaInterstitialAd();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MillionaireDuelPage()),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // ==========================================
                        // MODE 3: LİDER TABLOSU (LEADERBOARD)
                        // ==========================================
                        _buildGameModeCard(
                          title: "LİDER TABLOSU",
                          subtitle: "Türkiye Geneli Şampiyonlar • Milyonerler & Düello Zaferleri",
                          badgeText: "ŞAMPİYONLAR LİGİ",
                          icon: Icons.emoji_events_rounded,
                          accentColor: const Color(0xFF10B981),
                          gradientColors: [const Color(0xFF047857), const Color(0xFF1E293B)],
                          buttonLabel: "Sıralamayı Gör 🏆",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MillionaireLeaderboardPage()),
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                      ],
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

  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Icon(icon, color: accentColor, size: 28),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
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
}
