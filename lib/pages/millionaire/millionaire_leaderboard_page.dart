import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/Services/millionaire_duel_service.dart';
import 'package:safaksayar/models/millionaire_models.dart';
import 'package:safaksayar/pages/millionaire/millionaire_classic_page.dart';
import 'package:safaksayar/pages/millionaire/millionaire_duel_page.dart';

/// Ultra-Extravagant, showy and prestigious Leaderboard for Şafak Milyoneri.
/// Featuring 3D metallic podiums, radiant champion halos, animated glows,
/// luxury badges, and dynamic real-time Firestore synchronization.
class MillionaireLeaderboardPage extends StatefulWidget {
  const MillionaireLeaderboardPage({super.key});

  @override
  State<MillionaireLeaderboardPage> createState() => _MillionaireLeaderboardPageState();
}

class _MillionaireLeaderboardPageState extends State<MillionaireLeaderboardPage>
    with SingleTickerProviderStateMixin {
  // 'questions', 'games', 'money', 'duel'
  String _activeTab = 'questions';

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    MillionaireDuelService.instance.syncPremiumStatus();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onTabChanged(String tabId) {
    if (_activeTab == tabId) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeTab = tabId;
    });
  }

  void _navigateToGame() {
    HapticFeedback.mediumImpact();
    if (_activeTab == 'duel') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MillionaireDuelPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MillionaireClassicPage()),
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
        systemNavigationBarColor: Color(0xFF03050C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF040714),
        body: Stack(
          children: [
            // ==========================================
            // LUXURY BACKGROUND WITH MULTIPLE AMBIENT GLOWS
            // ==========================================
            _buildExtravagantBackground(),

            SafeArea(
              child: Column(
                children: [
                  // ==========================================
                  // GRAND ROYAL APP BAR
                  // ==========================================
                  _buildGrandAppBar(),

                  // ==========================================
                  // 4 HIGH-TECH NEON FILTER TABS
                  // ==========================================
                  _buildExtravagantFilterTabs(),

                  const SizedBox(height: 4),

                  // ==========================================
                  // REAL-TIME STREAM OF ALL FIRESTORE USERS
                  // ==========================================
                  Expanded(
                    child: StreamBuilder<List<LeaderboardEntry>>(
                      stream: MillionaireDuelService.instance.streamAllUsersLeaderboard(sortBy: _activeTab),
                      builder: (context, snapshot) {
                        final list = snapshot.data ?? MillionaireDuelService.instance.getMockLeaderboardSeed();

                        if (list.isEmpty) {
                          return const Center(
                            child: Text(
                              "Henüz sıralamaya giren asker bulunamadı.",
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          );
                        }

                        final top3 = list.take(3).toList();
                        final remaining = list.skip(3).toList();

                        return Stack(
                          children: [
                            CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // ==========================================
                                // EXTRAVAGANT 3D TOP 3 PODIUM
                                // ==========================================
                                if (top3.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                                      child: _buildExtravagantPodium(top3),
                                    ),
                                  ),

                                // Section Title: Elit Askerler
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.shield_rounded, color: Color(0xFFF59E0B), size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "MİLYONERLER KORİDORU",
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Text(
                                            "${list.length} Katılımcı",
                                            style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ==========================================
                                // REMAINING LIST (Ranks 4+)
                                // ==========================================
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final entry = remaining[index];
                                        final rankIndex = index + 4;
                                        return _buildExtravagantRankRow(rankIndex, entry);
                                      },
                                      childCount: remaining.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ==========================================
                            // STICKY BOTTOM USER STATUS CARD
                            // ==========================================
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: _buildExtravagantStickyCard(list),
                            ),
                          ],
                        );
                      },
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

  // ===========================================================================
  // 1. EXTRAVAGANT BACKGROUND WITH AMBIENT PARTICLES AND SPOTLIGHTS
  // ===========================================================================
  Widget _buildExtravagantBackground() {
    return Stack(
      children: [
        // Base Deep Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF090E24),
                Color(0xFF040714),
                Color(0xFF020308),
              ],
            ),
          ),
        ),

        // Radiant Amber Spotlight behind Podium Top
        Positioned(
          top: 110,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 320,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.16 * _glowAnimation.value),
                        const Color(0xFF6366F1).withValues(alpha: 0.08 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Cyber Mesh Grid Line Overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: _CyberGridPainter(),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. GRAND ROYAL APP BAR
  // ===========================================================================
  Widget _buildGrandAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Glass Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),

          const SizedBox(width: 12),

          // Central Crest & Title
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 15),
                    const SizedBox(width: 6),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFF59E0B)],
                      ).createShader(bounds),
                      child: const Text(
                        "ŞAFAK MİLYONERİ",
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 15),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        const Color(0xFFD97706).withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    "✦ PRESTİJ ZAFER ARENASI ✦",
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Pulsing Live Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.7 * _glowAnimation.value),
                            blurRadius: 6 * _glowAnimation.value,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 5),
                const Text(
                  "CANLI",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.6,
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
  // 3. EXTRAVAGANT HIGH-TECH FILTER TABS
  // ===========================================================================
  Widget _buildExtravagantFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1328).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterTabItem(icon: Icons.psychology_rounded, label: "Sorular", tabId: 'questions')),
          Expanded(child: _buildFilterTabItem(icon: Icons.sports_esports_rounded, label: "Oyunlar", tabId: 'games')),
          Expanded(child: _buildFilterTabItem(icon: Icons.monetization_on_rounded, label: "Milyoner", tabId: 'money')),
          Expanded(child: _buildFilterTabItem(icon: Icons.flash_on_rounded, label: "Düello", tabId: 'duel')),
        ],
      ),
    );
  }

  Widget _buildFilterTabItem({
    required IconData icon,
    required String label,
    required String tabId,
  }) {
    final isSelected = _activeTab == tabId;
    return GestureDetector(
      onTap: () => _onTabChanged(tabId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: isSelected ? const Color(0xFF1E1100) : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? const Color(0xFF1E1100) : Colors.white70,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. EXTRAVAGANT 3D TOP 3 PODIUM WIDGET
  // ===========================================================================
  Widget _buildExtravagantPodium(List<LeaderboardEntry> top3) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF080D21).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Columns: 2nd (Silver), 1st (Gold), 3rd (Bronze)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Silver)
              if (second != null)
                Expanded(
                  child: _buildPodiumColumn(
                    entry: second,
                    rank: 2,
                    pillarHeight: 115,
                    primaryColor: const Color(0xFFE2E8F0),
                    accentColor: const Color(0xFF64748B),
                    title: "2. DERECE",
                  ),
                ),

              const SizedBox(width: 8),

              // 1st Place (Gold Champion)
              if (first != null)
                Expanded(
                  child: _buildPodiumColumn(
                    entry: first,
                    rank: 1,
                    pillarHeight: 155,
                    primaryColor: const Color(0xFFFFD54F),
                    accentColor: const Color(0xFFB45309),
                    title: "1. ŞAMPİYON",
                  ),
                ),

              const SizedBox(width: 8),

              // 3rd Place (Bronze)
              if (third != null)
                Expanded(
                  child: _buildPodiumColumn(
                    entry: third,
                    rank: 3,
                    pillarHeight: 98,
                    primaryColor: const Color(0xFFFB923C),
                    accentColor: const Color(0xFF9A3412),
                    title: "3. DERECE",
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Podium Base Inscription Stage
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 12),
                SizedBox(width: 6),
                Text(
                  "❖ TÜRKİYE ŞAFAK MİLYONERİ PRESTİJ KÜRSÜSÜ ❖",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Color(0xFFFDE68A),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. INDIVIDUAL PODIUM COLUMN (AVATAR, CROWN, 3D PILLAR & METALLIC EMBLEM)
  // ===========================================================================
  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required int rank,
    required double pillarHeight,
    required Color primaryColor,
    required Color accentColor,
    required String title,
  }) {
    String metricText;
    IconData metricIcon;

    switch (_activeTab) {
      case 'questions':
        metricText = "${entry.questionsSolved} Soru";
        metricIcon = Icons.psychology_rounded;
        break;
      case 'games':
        metricText = "${entry.gamesPlayed} Oyun";
        metricIcon = Icons.sports_esports_rounded;
        break;
      case 'money':
        metricText = "${_formatMoney(entry.totalEarned)} TL";
        metricIcon = Icons.monetization_on_rounded;
        break;
      case 'duel':
        metricText = "${entry.duelWins} Zafer";
        metricIcon = Icons.flash_on_rounded;
        break;
      default:
        metricText = "${entry.questionsSolved} Soru";
        metricIcon = Icons.psychology_rounded;
    }

    final isGold = rank == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----------------------------------------------------
        // CROWN / MEDAL HEADER WITH ANIMATED AURA
        // ----------------------------------------------------
        if (isGold)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.65),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF451A03), size: 22),
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: rank == 2
                    ? [const Color(0xFFFFFFFF), const Color(0xFF94A3B8)]
                    : [const Color(0xFFFFEDD5), const Color(0xFFC2410C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              rank == 2 ? Icons.military_tech_rounded : Icons.shield_rounded,
              color: rank == 2 ? const Color(0xFF1E293B) : const Color(0xFF431407),
              size: 18,
            ),
          ),

        const SizedBox(height: 6),

        // ----------------------------------------------------
        // AVATAR WITH DUAL METALLIC BORDER & VIP FLAME
        // ----------------------------------------------------
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Ambient Aura for Gold
            if (isGold)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.5 * _glowAnimation.value),
                          blurRadius: 18 * _glowAnimation.value,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Actual Avatar
            Container(
              width: isGold ? 52 : 44,
              height: isGold ? 52 : 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isGold
                      ? [const Color(0xFF2E1C0C), const Color(0xFF1E293B)]
                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                ),
                border: Border.all(
                  color: primaryColor,
                  width: isGold ? 3.0 : 2.2,
                ),
              ),
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : 'A',
                style: TextStyle(
                  fontSize: isGold ? 22 : 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),

            // Mini Badge on Avatar corner
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isGold
                        ? [const Color(0xFFFFD54F), const Color(0xFFD97706)]
                        : (rank == 2
                            ? [const Color(0xFFF1F5F9), const Color(0xFF64748B)]
                            : [const Color(0xFFFED7AA), const Color(0xFF9A3412)]),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  isGold ? "ŞAMPİYON" : (rank == 2 ? "İKİNCİ" : "ÜÇÜNCÜ"),
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: isGold || rank == 2 ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ----------------------------------------------------
        // USER NAME & VIP BADGE
        // ----------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isGold ? 12.5 : 11.5,
              fontWeight: FontWeight.w900,
              color: entry.isPremium ? const Color(0xFFFBBF24) : Colors.white,
              shadows: isGold
                  ? [
                      Shadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        ),

        if (entry.isPremium) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 8),
                SizedBox(width: 2),
                Text(
                  'VIP',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 3),

        // ----------------------------------------------------
        // DYNAMIC METRIC PILL
        // ----------------------------------------------------
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(metricIcon, size: 9.5, color: primaryColor),
              const SizedBox(width: 3),
              Text(
                metricText,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ----------------------------------------------------
        // 3D METALLIC PEDESTAL PILLAR
        // ----------------------------------------------------
        Container(
          height: pillarHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withValues(alpha: isGold ? 0.60 : 0.45),
                accentColor.withValues(alpha: 0.25),
                const Color(0xFF03050C).withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: primaryColor.withValues(alpha: isGold ? 0.9 : 0.6),
              width: isGold ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isGold ? 0.28 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Specular Light Diagonal Sheen
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: CustomPaint(
                    painter: _PillarSpecularPainter(isGold: isGold),
                  ),
                ),
              ),

              // Medallion & Label
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    // Metallic Medallion
                    Container(
                      width: isGold ? 46 : 38,
                      height: isGold ? 46 : 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isGold
                              ? [const Color(0xFFFFF9C4), const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
                              : (rank == 2
                                  ? [const Color(0xFFFFFFFF), const Color(0xFFCBD5E1), const Color(0xFF64748B)]
                                  : [const Color(0xFFFFEDD5), const Color(0xFFFB923C), const Color(0xFF9A3412)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: isGold ? 2.5 : 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        "$rank",
                        style: TextStyle(
                          fontSize: isGold ? 24 : 19,
                          fontWeight: FontWeight.w900,
                          color: isGold
                              ? const Color(0xFF431407)
                              : (rank == 2 ? const Color(0xFF0F172A) : Colors.white),
                          shadows: rank == 3
                              ? [
                                  const Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Laurel Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        isGold ? 3 : (rank == 2 ? 2 : 1),
                        (_) => Icon(Icons.star_rounded, size: 10, color: primaryColor),
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. EXTRAVAGANT RANK ROW (RANKS 4 TO 100)
  // ===========================================================================
  Widget _buildExtravagantRankRow(int rank, LeaderboardEntry entry) {
    String primaryMetric;
    String secondaryMetric;
    IconData metricIcon;

    switch (_activeTab) {
      case 'questions':
        primaryMetric = "${entry.questionsSolved} Soru";
        secondaryMetric = "${entry.gamesPlayed} Oyun • ${_formatMoney(entry.totalEarned)} TL";
        metricIcon = Icons.psychology_rounded;
        break;
      case 'games':
        primaryMetric = "${entry.gamesPlayed} Oyun";
        secondaryMetric = "${entry.questionsSolved} Soru • ${_formatMoney(entry.totalEarned)} TL";
        metricIcon = Icons.sports_esports_rounded;
        break;
      case 'money':
        primaryMetric = "${_formatMoney(entry.totalEarned)} TL";
        secondaryMetric = "${entry.questionsSolved} Soru • ${entry.gamesPlayed} Oyun";
        metricIcon = Icons.monetization_on_rounded;
        break;
      case 'duel':
        primaryMetric = "${entry.duelWins} Zafer";
        secondaryMetric = "${entry.duelPoints} Kupa • ${entry.questionsSolved} Soru";
        metricIcon = Icons.flash_on_rounded;
        break;
      default:
        primaryMetric = "${entry.questionsSolved} Soru";
        secondaryMetric = "${entry.gamesPlayed} Oyun";
        metricIcon = Icons.psychology_rounded;
    }

    final isTop10 = rank <= 10;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: entry.isPremium
              ? [
                  const Color(0xFF2A1C0A).withValues(alpha: 0.75),
                  const Color(0xFF141A35).withValues(alpha: 0.85),
                ]
              : (isTop10
                  ? [
                      const Color(0xFF0F1E3D).withValues(alpha: 0.8),
                      const Color(0xFF0A0F24).withValues(alpha: 0.85),
                    ]
                  : [
                      const Color(0xFF0B1021).withValues(alpha: 0.75),
                      const Color(0xFF070B18).withValues(alpha: 0.85),
                    ]),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isPremium
              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
              : (isTop10
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08)),
          width: entry.isPremium ? 1.4 : (isTop10 ? 1.1 : 0.8),
        ),
        boxShadow: [
          if (entry.isPremium)
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          else if (isTop10)
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // ----------------------------------------------------
          // TACTICAL SHIELD RANK BADGE (NO '#' SYMBOL)
          // ----------------------------------------------------
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isTop10
                  ? const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
                    ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTop10 ? const Color(0xFF38BDF8) : Colors.white12,
                width: 1,
              ),
              boxShadow: isTop10
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              "$rank",
              style: TextStyle(
                fontSize: rank >= 100 ? 10.5 : 12.5,
                fontWeight: FontWeight.w900,
                color: isTop10 ? Colors.white : Colors.white70,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ----------------------------------------------------
          // AVATAR
          // ----------------------------------------------------
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isPremium ? const Color(0xFFB45309) : const Color(0xFF1E293B),
              border: Border.all(
                color: entry.isPremium ? const Color(0xFFFBBF24) : Colors.white24,
                width: 1.2,
              ),
            ),
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : 'A',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          const SizedBox(width: 10),

          // ----------------------------------------------------
          // USER DETAILS & TAGS
          // ----------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: entry.isPremium ? const Color(0xFFFBBF24) : Colors.white,
                        ),
                      ),
                    ),
                    if (entry.isPremium) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 8),
                            SizedBox(width: 2),
                            Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isTop10) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'ELİT',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${entry.rank} • ${entry.city}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: Colors.white54, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ----------------------------------------------------
          // METRICS PILL
          // ----------------------------------------------------
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: isTop10
                      ? LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            const Color(0xFFD97706).withValues(alpha: 0.15),
                          ],
                        )
                      : null,
                  color: isTop10 ? null : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTop10 ? const Color(0xFFF59E0B) : Colors.white12,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(metricIcon, size: 11, color: isTop10 ? const Color(0xFFF59E0B) : Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      primaryMetric,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: isTop10 ? const Color(0xFFF59E0B) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2.5),
              Text(
                secondaryMetric,
                style: const TextStyle(fontSize: 9.5, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. ULTRA-DELUXE STICKY BOTTOM USER CARD WITH DYNAMIC MOTIVATION TRACKER
  // ===========================================================================
  Widget _buildExtravagantStickyCard(List<LeaderboardEntry> list) {
    final myId = MillionaireDuelService.instance.currentUserId;
    final myIndex = list.indexWhere((e) => e.userId == myId);
    final isRanked = myIndex >= 0;
    final myRankStr = isRanked ? "${myIndex + 1}. Sıradasın" : "Sıralama Dışı";
    final myEntry = isRanked ? list[myIndex] : null;

    // Dynamic motivational calculation:
    // Calculate how many more points/questions are needed to overtake the user directly ahead!
    String motivationText = "Yarışmaya başla ve şafak tarihine adını yazdır! 🚀";
    if (isRanked) {
      if (myIndex == 0) {
        motivationText = "👑 Tebrikler! Zirvedeki yerini korumak için yarışa devam et!";
      } else {
        final aheadUser = list[myIndex - 1];
        switch (_activeTab) {
          case 'questions':
            final diff = math.max(1, aheadUser.questionsSolved - (myEntry?.questionsSolved ?? 0) + 1);
            motivationText = "1 üstündeki ${aheadUser.name}'ı geçmeye sadece $diff soru kaldı! 🔥";
            break;
          case 'games':
            final diff = math.max(1, aheadUser.gamesPlayed - (myEntry?.gamesPlayed ?? 0) + 1);
            motivationText = "1 üstündeki ${aheadUser.name}'ı geçmeye sadece $diff oyun kaldı! ⚡";
            break;
          case 'money':
            final diff = math.max(1000, aheadUser.totalEarned - (myEntry?.totalEarned ?? 0) + 1000);
            motivationText = "1 üst sıraya: ${_formatMoney(diff)} TL kazanç kaldı! 💰";
            break;
          case 'duel':
            final diff = math.max(1, aheadUser.duelWins - (myEntry?.duelWins ?? 0) + 1);
            motivationText = "1 üstündeki ${aheadUser.name}'ı geçmeye sadece $diff zafer kaldı! ⚔️";
            break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar / Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF1E1100), size: 18),
          ),

          const SizedBox(width: 10),

          // User info and motivation text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        myRankStr,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        MillionaireDuelService.instance.currentUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  motivationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Extravagant Action Button: "Yarış & Yüksel!"
          GestureDetector(
            onTap: _navigateToGame,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF2E1C0C)),
                        SizedBox(width: 2),
                        Text(
                          "Yarış!",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E1C0C),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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

  // ===========================================================================
  // HELPER: FORMAT LARGE NUMBERS
  // ===========================================================================
  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      final millions = (amount / 1000000).toStringAsFixed(1);
      return "$millions M";
    } else if (amount >= 1000) {
      final thousands = (amount / 1000).toStringAsFixed(0);
      return "$thousands Bin";
    }
    return amount.toString();
  }
}

// =============================================================================
// CUSTOM PAINTERS FOR SPECTACULAR VISUALS
// =============================================================================

/// Draws a specular diagonal sheen across the 3D podium pedestal
class _PillarSpecularPainter extends CustomPainter {
  final bool isGold;
  _PillarSpecularPainter({required this.isGold});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isGold ? 0.28 : 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, 0)
      ..lineTo(0, size.height * 0.75)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws an ultra-subtle cyber mesh background grid
class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
