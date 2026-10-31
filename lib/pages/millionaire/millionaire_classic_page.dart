import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:safaksayar/Services/millionaire_duel_service.dart';
import 'package:safaksayar/Services/millionaire_question_bank.dart';
import 'package:safaksayar/Services/millionaire_rights_service.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/models/millionaire_models.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/widgets/millionaire/millionaire_joker_dialogs.dart';
import 'package:safaksayar/widgets/millionaire/millionaire_ladder_sheet.dart';
import 'package:safaksayar/widgets/millionaire/millionaire_option_button.dart';

/// Full authentic Kim Milyoner Olmak İster 12-question classic competition screen.
class MillionaireClassicPage extends StatefulWidget {
  const MillionaireClassicPage({super.key});

  @override
  State<MillionaireClassicPage> createState() => _MillionaireClassicPageState();
}

class _MillionaireClassicPageState extends State<MillionaireClassicPage> {
  late List<MillionaireQuestion> _questions;
  int _currentStepIndex = 0; // 0 to 11 (corresponds to steps 1 to 12)

  // Current Question state
  int? _selectedOptionIndex;
  bool _isAnswerLocked = false;
  bool _isAnswerRevealed = false;
  List<int> _eliminatedOptionIndexes = [];

  // Lifelines (Jokerler)
  bool _joker50Used = false;
  bool _jokerAudienceUsed = false;
  bool _jokerPhoneUsed = false;
  bool _jokerSwitchUsed = false;

  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 30;

  // Confetti
  late ConfettiController _confettiController;

  // Prizes
  int _lastWonPrize = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _startNewGame();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    _questions = MillionaireQuestionBank.instance.getRandomGameLadder();
    _currentStepIndex = 0;
    _joker50Used = false;
    _jokerAudienceUsed = false;
    _jokerPhoneUsed = false;
    _jokerSwitchUsed = false;
    _lastWonPrize = 0;

    _setupQuestionForCurrentStep();
  }

  void _setupQuestionForCurrentStep() {
    _countdownTimer?.cancel();
    setState(() {
      _selectedOptionIndex = null;
      _isAnswerLocked = false;
      _isAnswerRevealed = false;
      _eliminatedOptionIndexes = [];

      final stepConfig = MillionaireLadderStep.ladder[_currentStepIndex];
      _remainingSeconds = stepConfig.timeSeconds;
    });

    if (_remainingSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
          if (_remainingSeconds <= 5) {
            HapticFeedback.selectionClick();
          }
        } else {
          _handleTimeOut();
        }
      });
    }
  }

  void _handleTimeOut() {
    _countdownTimer?.cancel();
    if (_isAnswerLocked || _isAnswerRevealed) return;

    HapticFeedback.heavyImpact();
    final guaranteed = MillionaireLadderStep.getGuaranteedPrize(_currentStepIndex + 1);

    // Submit score
    MillionaireDuelService.instance.submitClassicScore(
      earnedAmount: guaranteed,
      wonMillion: false,
    );

    _showResultDialog(
      title: "Süre Doldu! ⏰",
      message: "Verilen süre içerisinde cevap veremediniz.",
      earnedPrize: guaranteed,
      isVictory: false,
    );
  }

  // ==========================================
  // JOKER ACTIONS
  // ==========================================
  void _useJoker50() {
    if (_joker50Used || _isAnswerLocked) return;
    HapticFeedback.mediumImpact();

    final currentQ = _questions[_currentStepIndex];
    final wrongOptions = [0, 1, 2, 3].where((i) => i != currentQ.correctIndex).toList()..shuffle();

    setState(() {
      _joker50Used = true;
      _eliminatedOptionIndexes = wrongOptions.take(2).toList();
    });
  }

  void _useJokerAudience() {
    if (_jokerAudienceUsed || _isAnswerLocked) return;
    setState(() {
      _jokerAudienceUsed = true;
    });
    MillionaireJokerDialogs.showAudienceJoker(
      context,
      question: _questions[_currentStepIndex],
      eliminatedOptions: _eliminatedOptionIndexes,
    );
  }

  void _useJokerPhone() {
    if (_jokerPhoneUsed || _isAnswerLocked) return;
    setState(() {
      _jokerPhoneUsed = true;
    });
    MillionaireJokerDialogs.showPhoneJoker(
      context,
      question: _questions[_currentStepIndex],
      eliminatedOptions: _eliminatedOptionIndexes,
    );
  }

  void _useJokerSwitch() {
    if (_jokerSwitchUsed || _isAnswerLocked) return;
    HapticFeedback.heavyImpact();

    // Replace with a new question matching same difficulty
    final currentQ = _questions[_currentStepIndex];
    final alternatives = MillionaireQuestionBank.instance
        .getRandomGameLadder()
        .where((q) => q.difficulty == currentQ.difficulty && q.id != currentQ.id)
        .toList();

    if (alternatives.isNotEmpty) {
      setState(() {
        _jokerSwitchUsed = true;
        _questions[_currentStepIndex] = alternatives.first;
        _eliminatedOptionIndexes = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Soru değiştirildi! Yeni sorunuz geldi."),
          backgroundColor: Color(0xFF2563EB),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ==========================================
  // ANSWER FLOW
  // ==========================================
  void _onOptionSelected(int index) {
    if (_isAnswerLocked || _eliminatedOptionIndexes.contains(index)) return;

    setState(() {
      _selectedOptionIndex = index;
    });

    // Confirmation / Lock-in dramatic delay
    _lockInAnswer(index);
  }

  Future<void> _lockInAnswer(int selectedIndex) async {
    setState(() {
      _isAnswerLocked = true;
    });
    _countdownTimer?.cancel();

    // Dramatic pause (1.2 seconds) simulating "Son kararın mı?" suspense
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final currentQ = _questions[_currentStepIndex];
    final isCorrect = selectedIndex == currentQ.correctIndex;

    setState(() {
      _isAnswerRevealed = true;
    });

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      // Dynamically record question solved in Firestore
      MillionaireDuelService.instance.recordQuestionSolved();
      final stepItem = MillionaireLadderStep.ladder[_currentStepIndex];
      _lastWonPrize = stepItem.prizeAmount;

      // Check if 12th question (5.000.000 TL Milyoner!)
      if (_currentStepIndex == 11) {
        _confettiController.play();
        MillionaireDuelService.instance.submitClassicScore(
          earnedAmount: 5000000,
          wonMillion: true,
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          _showResultDialog(
            title: "MİLYONER OLDUNUZ! 👑",
            message: "12 sorunun tamamını doğru bilerek 5.000.000 TL Büyük Ödülü kazandınız!",
            earnedPrize: 5000000,
            isVictory: true,
          );
        }
      } else {
        // Advance to next ladder step after 1.4s
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          setState(() {
            _currentStepIndex++;
          });
          _setupQuestionForCurrentStep();
        }
      }
    } else {
      HapticFeedback.vibrate();
      final guaranteed = MillionaireLadderStep.getGuaranteedPrize(_currentStepIndex + 1);

      MillionaireDuelService.instance.submitClassicScore(
        earnedAmount: guaranteed,
        wonMillion: false,
      );

      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        _showResultDialog(
          title: "Elendiniz 😔",
          message: "Maalesef yanlış cevap verdiniz. Doğru cevap: ${currentQ.options[currentQ.correctIndex]}",
          earnedPrize: guaranteed,
          isVictory: false,
        );
      }
    }
  }

  // ==========================================
  // WALK AWAY (ÇEKİL)
  // ==========================================
  Future<void> _handleWalkAway() async {
    // If the game has already concluded, allow tapping exit to return to menu
    if (_isAnswerRevealed) {
      Navigator.pop(context);
      return;
    }
    if (_isAnswerLocked) return;

    final currentPrize = _lastWonPrize;
    if (currentPrize == 0) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await MillionaireJokerDialogs.showWalkAwayDialog(
      context,
      currentPrize: currentPrize,
    );

    if (confirmed && mounted) {
      _countdownTimer?.cancel();
      _confettiController.play();

      MillionaireDuelService.instance.submitClassicScore(
        earnedAmount: currentPrize,
        wonMillion: false,
      );

      _showResultDialog(
        title: "Tebrikler! 💰",
        message: "Yarışmadan başarıyla çekildiniz ve kazandığınız tutarı garanti altına aldınız.",
        earnedPrize: currentPrize,
        isVictory: true,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required int earnedPrize,
    required bool isVictory,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: isVictory ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            width: 2,
          ),
        ),
        title: Center(
          child: Column(
            children: [
              Icon(
                isVictory ? Icons.military_tech_rounded : Icons.info_outline_rounded,
                size: 48,
                color: isVictory ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text(
                    "KAZANDIĞINIZ TOPLAM ÖDÜL",
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$earnedPrize TL",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isVictory ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: RevenueCatService.instance.isPremiumNotifier,
              builder: (context, isPro, _) {
                if (isPro) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 15),
                        SizedBox(width: 6),
                        Text(
                          "PRO Üyelik: Sınırsız Oynama Hakkı",
                          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
                return ValueListenableBuilder<int>(
                  valueListenable: MillionaireRightsService.instance.remainingRightsNotifier,
                  builder: (context, rights, _) {
                    final hasRights = rights > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasRights ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: hasRights ? Colors.white24 : const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasRights ? Icons.favorite_rounded : Icons.info_outline_rounded,
                            color: hasRights ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasRights ? "Kalan Günlük Hak: $rights/3" : "Günlük 3 Yarışma Hakkınız Doldu",
                            style: TextStyle(
                              color: hasRights ? Colors.white70 : const Color(0xFFFCA5A5),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text("Ana Menü", style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (!RevenueCatService.instance.isPremium) {
                      final remaining = await MillionaireRightsService.instance.getRemainingRights();
                      if (remaining <= 0) {
                        // Open paywall cleanly without closing the dialog or trapping the user
                        await PremiumPaywallPage.show(context, source: 'millionaire_classic_retry_limit');
                        // If user upgraded to PRO while on the paywall screen:
                        if (RevenueCatService.instance.isPremium) {
                          if (mounted) {
                            Navigator.pop(ctx);
                            _startNewGame();
                          }
                        }
                        // If they returned without PRO, the dialog stays open,
                        // allowing them to tap "Ana Menü" to exit or try again.
                        return;
                      }
                      await MillionaireRightsService.instance.useOneRight();
                    }
                    Navigator.pop(ctx);
                    _startNewGame();
                  },
                  child: const Text("Yeniden Oyna", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OptionState _getOptionState(int index) {
    if (_eliminatedOptionIndexes.contains(index)) {
      return OptionState.disabled;
    }

    if (_isAnswerRevealed) {
      final currentQ = _questions[_currentStepIndex];
      if (index == currentQ.correctIndex) {
        return OptionState.correct;
      }
      if (index == _selectedOptionIndex) {
        return OptionState.wrong;
      }
      return OptionState.normal;
    }

    if (_isAnswerLocked && index == _selectedOptionIndex) {
      return OptionState.selected;
    }

    if (!_isAnswerLocked && index == _selectedOptionIndex) {
      return OptionState.selected;
    }

    return OptionState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentStepIndex];
    final stepConfig = MillionaireLadderStep.ladder[_currentStepIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          _countdownTimer?.cancel();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF070B19),
          body: Stack(
        children: [
          // Background Studio Atmosphere
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.1,
                colors: [
                  Color(0xFF162554),
                  Color(0xFF090E20),
                  Color(0xFF04060E),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // TOP BAR: ÇEKİL + STEP BADGE + PARA AĞACI
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // Exit / Walk Away button
                      InkWell(
                        onTap: _handleWalkAway,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _lastWonPrize > 0 ? "Çekil (${_lastWonPrize} TL)" : "Ayrıl",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Current Step Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                        ),
                        child: Text(
                          "${stepConfig.step}/12 • ${stepConfig.prizeFormatted}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Para Ağacı button
                      IconButton(
                        icon: const Icon(Icons.leaderboard_rounded, color: Colors.amberAccent, size: 26),
                        tooltip: "Para Ağacı",
                        onPressed: () => MillionaireLadderSheet.show(
                          context,
                          currentStep: _currentStepIndex + 1,
                          currentEarned: _lastWonPrize,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 4 JOKERLER BAR
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildJokerButton(
                        label: "%50",
                        icon: Icons.pie_chart_outline_rounded,
                        isUsed: _joker50Used,
                        onTap: _useJoker50,
                      ),
                      _buildJokerButton(
                        label: "Seyirci",
                        icon: Icons.groups_rounded,
                        isUsed: _jokerAudienceUsed,
                        onTap: _useJokerAudience,
                      ),
                      _buildJokerButton(
                        label: "Telefon",
                        icon: Icons.phone_in_talk_rounded,
                        isUsed: _jokerPhoneUsed,
                        onTap: _useJokerPhone,
                      ),
                      _buildJokerButton(
                        label: "Değiştir",
                        icon: Icons.swap_horiz_rounded,
                        isUsed: _jokerSwitchUsed,
                        onTap: _useJokerSwitch,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ==========================================
                // TIMER OR UNLIMITED BADGE
                // ==========================================
                Center(
                  child: _remainingSeconds > 0
                      ? Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F172A),
                            border: Border.all(
                              color: _remainingSeconds <= 5
                                  ? const Color(0xFFEF4444)
                                  : (_remainingSeconds <= 12 ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8)),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_remainingSeconds <= 5
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF38BDF8))
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            "$_remainingSeconds",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _remainingSeconds <= 5
                                  ? const Color(0xFFEF4444)
                                  : Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.all_inclusive_rounded, color: Colors.amberAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Limitsiz Süre (Baraj Üstü)",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 12),

                // ==========================================
                // QUESTION CARD
                // ==========================================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hexagonal metallic question box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1A3C),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentQ.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentQ.question,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ==========================================
                        // OPTIONS (A, B, C, D)
                        // ==========================================
                        Expanded(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return MillionaireOptionButton(
                                index: index,
                                text: currentQ.options[index],
                                state: _getOptionState(index),
                                onTap: _isAnswerLocked ? null : () => _onOptionSelected(index),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildJokerButton({
    required String label,
    required IconData icon,
    required bool isUsed,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isUsed ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isUsed ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUsed ? Colors.white12 : const Color(0xFF38BDF8),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isUsed ? Colors.white30 : const Color(0xFF38BDF8), size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isUsed ? Colors.white30 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
