import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safaksayar/Services/millionaire_duel_service.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/models/millionaire_models.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/widgets/millionaire/millionaire_option_button.dart';

/// 1v1 Live Online Military Quiz Duel Screen with Dedicated Room Lobby.
/// Only starts when two genuine human players are present in the room and both are ready.
class MillionaireDuelPage extends StatefulWidget {
  final String? joinedDuelId;

  const MillionaireDuelPage({super.key, this.joinedDuelId});

  @override
  State<MillionaireDuelPage> createState() => _MillionaireDuelPageState();
}

class _MillionaireDuelPageState extends State<MillionaireDuelPage> with TickerProviderStateMixin {
  // Room State
  bool _isLoading = true;
  bool _isLeavingLocally = false;
  DuelRoom? _duelRoom;
  bool _isPlayer1 = true;
  StreamSubscription<DuelRoom?>? _roomSubscription;

  // Lobby & Countdown
  bool _isGameActive = false;
  bool _isStartingCountdown = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  late AnimationController _radarController;

  // Active match state
  int _currentQuestionIndex = 0; // 0 to 4 (5 questions)
  int? _selectedOptionIndex;
  bool _isAnswerLocked = false;
  bool _isAnswerRevealed = false;

  // Player stats
  int _myScore = 0;
  int _myCorrectCount = 0;
  final List<bool?> _myAnswers = [null, null, null, null, null];

  // Opponent stats
  int _oppScore = 0;
  int _oppCorrectCount = 0;
  final List<bool?> _oppAnswers = [null, null, null, null, null];

  // Question Timer
  Timer? _questionTimer;
  int _remainingSeconds = 15;

  // Confetti
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumStatusChanged);

    if (RevenueCatService.instance.isPremium) {
      _startDuelInit();
    } else {
      _isLoading = false;
    }
  }

  void _startDuelInit() {
    if (widget.joinedDuelId != null) {
      _joinExistingRoom(widget.joinedDuelId!);
    } else {
      _initOrFindRoom();
    }
  }

  void _onPremiumStatusChanged() {
    if (!mounted) return;
    setState(() {});
    final bool isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrentRoute &&
        RevenueCatService.instance.isPremium &&
        _duelRoom == null &&
        !_isGameActive &&
        !_isLoading) {
      _startDuelInit();
    }
  }

  @override
  void dispose() {
    RevenueCatService.instance.isPremiumNotifier.removeListener(_onPremiumStatusChanged);
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    _roomSubscription?.cancel();
    _radarController.dispose();
    _confettiController.dispose();

    // If leaving while still waiting as host or guest in lobby, leave room
    if (!_isLeavingLocally && !_isGameActive && _duelRoom != null) {
      _isLeavingLocally = true;
      MillionaireDuelService.instance.leaveOrCancelDuelRoom(
        roomId: _duelRoom!.id,
        isPlayer1: _isPlayer1,
      );
    }

    super.dispose();
  }

  // ==========================================
  // ROOM INITIALIZATION & STREAMING
  // ==========================================
  Future<void> _initOrFindRoom() async {
    setState(() => _isLoading = true);
    final room = await MillionaireDuelService.instance.findAvailableRoomOrCreate();
    if (!mounted) return;

    final isP1 = room.player1.userId == MillionaireDuelService.instance.currentUserId;
    setState(() {
      _duelRoom = room;
      _isPlayer1 = isP1;
      _isLoading = false;
    });

    _listenToLiveRoom(room.id);
  }

  Future<void> _joinExistingRoom(String roomId) async {
    setState(() => _isLoading = true);
    final room = await MillionaireDuelService.instance.joinDuelRoom(roomId);
    if (!mounted) return;

    if (room != null) {
      final isP1 = room.player1.userId == MillionaireDuelService.instance.currentUserId;
      setState(() {
        _duelRoom = room;
        _isPlayer1 = isP1;
        _isLoading = false;
      });

      _listenToLiveRoom(room.id);
    } else {
      _showRoomUnavailableDialog();
    }
  }

  void _listenToLiveRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = MillionaireDuelService.instance.streamDuelRoom(roomId).listen((updatedRoom) {
      if (!mounted || _isLeavingLocally) return;

      if (updatedRoom == null || updatedRoom.status == 'cancelled') {
        _handleRoomCancelledByOther();
        return;
      }

      // Detect if opponent joined the room in lobby
      if (!_isGameActive) {
        final hadOpponentBefore = _duelRoom?.player2 != null;
        final hasOpponentNow = updatedRoom.player2 != null;

        if (!hadOpponentBefore && hasOpponentNow && _isPlayer1) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚔️ ${updatedRoom.player2!.name} odaya katıldı!"),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        setState(() {
          _duelRoom = updatedRoom;
        });

        // If both players are marked ready or status turned active, initiate countdown!
        if ((updatedRoom.isBothReady || updatedRoom.status == 'active') &&
            !_isStartingCountdown &&
            !_isGameActive) {
          _startMatchCountdown();
        }
      } else {
        // In-game: Sync opponent progress in real-time
        setState(() {
          _duelRoom = updatedRoom;
          final opp = _isPlayer1 ? updatedRoom.player2 : updatedRoom.player1;
          if (opp != null) {
            _oppScore = opp.score;
            _oppCorrectCount = opp.correctAnswers;

            for (int i = 0; i < opp.answers.length && i < 5; i++) {
              final optIndex = opp.answers[i];
              if (optIndex != null) {
                _oppAnswers[i] = optIndex == updatedRoom.questions[i].correctIndex;
              }
            }
          }
        });
      }
    });
  }

  void _handleRoomCancelledByOther() {
    _roomSubscription?.cancel();
    if (!mounted || _isLeavingLocally) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Text(
          "Düello Odası Kapandı",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Oda kurucusu odadan ayrıldı veya bu düello iptal edildi.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Tamam", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRoomUnavailableDialog() {
    if (!mounted || _isLeavingLocally) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Text(
          "Odaya Katılınamadı",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Bu düello odası dolu, süresi dolmuş veya kapatılmış olabilir.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Tamam", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOBBY ACTIONS
  // ==========================================
  Future<void> _toggleReady() async {
    if (_duelRoom == null) return;

    // Both players must exist before setting ready
    if (_duelRoom!.player2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Odaya henüz bir rakip katılmadı. Rakip gelene kadar bekleyin."),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final myCurrentReady = _isPlayer1 ? _duelRoom!.player1.isReady : (_duelRoom!.player2?.isReady ?? false);
    HapticFeedback.mediumImpact();

    await MillionaireDuelService.instance.setPlayerReady(
      roomId: _duelRoom!.id,
      isPlayer1: _isPlayer1,
      isReady: !myCurrentReady,
    );
  }

  void _startMatchCountdown() {
    setState(() {
      _isStartingCountdown = true;
      _countdownSeconds = 3;
    });

    HapticFeedback.heavyImpact();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
        HapticFeedback.selectionClick();
      } else {
        _countdownTimer?.cancel();
        setState(() {
          _isStartingCountdown = false;
          _isGameActive = true;
        });
        HapticFeedback.heavyImpact();
        _startQuestionRound();
      }
    });
  }

  void _copyRoomCode() {
    if (_duelRoom == null) return;
    Clipboard.setData(ClipboardData(text: _duelRoom!.roomCode));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📋 Oda Kodu Kopyalandı: ${_duelRoom!.roomCode}"),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareRoomCode([BuildContext? targetContext]) {
    if (_duelRoom == null) return;
    final code = _duelRoom!.roomCode;
    final shareText = "⚔️ Kim Milyoner Olmak İster düello odama katıl! Oda Kodu: $code\nŞafak Sayar uygulamasını aç ve düelloya gir!";

    try {
      final ctx = targetContext ?? context;
      final box = ctx.findRenderObject() as RenderBox?;
      Rect? origin;
      if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      } else {
        final size = MediaQuery.sizeOf(ctx);
        origin = Rect.fromLTWH(size.width / 2 - 100, size.height / 2 - 100, 200, 200);
      }

      Share.share(
        shareText,
        subject: "Canlı Asker Düellosu: $code",
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[Share] Error sharing room code: $e');
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("📋 Oda Kodu Kopyalandı: $code"),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showOpenRoomsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final codeController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Açık Düello Odaları & Kod ile Katıl",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),

              // Room Code Join Form
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Örn: DL-4819",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final code = codeController.text.trim();
                      if (code.isNotEmpty) {
                        Navigator.pop(ctx);
                        await _switchRoom(code);
                      }
                    },
                    child: const Text("Katıl", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                "Şu An Bekleyen Gerçek Kullanıcılar:",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Open waiting rooms stream
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: StreamBuilder<List<DuelRoom>>(
                  stream: MillionaireDuelService.instance.streamOpenWaitingRooms(),
                  builder: (context, snapshot) {
                    final rooms = snapshot.data ?? [];
                    if (rooms.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Şu an bekleyen başka açık oda yok.\nKendi odanda rakip bekleyebilir veya kodunu arkadaşınla paylaşabilirsin.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF2563EB),
                                child: Text(
                                  room.player1.name.isNotEmpty ? room.player1.name[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.player1.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      "${room.player1.rank} • ${room.player1.city}",
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _switchRoom(room.id);
                                },
                                child: const Text("Meydan Oku ⚔️", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchRoom(String roomIdOrCode) async {
    // Leave previous room if host
    if (_duelRoom != null) {
      await MillionaireDuelService.instance.leaveOrCancelDuelRoom(
        roomId: _duelRoom!.id,
        isPlayer1: _isPlayer1,
      );
    }
    _roomSubscription?.cancel();
    await _joinExistingRoom(roomIdOrCode);
  }

  void _leaveRoomNow() {
    if (_isLeavingLocally) return;
    _isLeavingLocally = true;
    _roomSubscription?.cancel();

    if (_duelRoom != null) {
      MillionaireDuelService.instance.leaveOrCancelDuelRoom(
        roomId: _duelRoom!.id,
        isPlayer1: _isPlayer1,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmLeaveRoom() {
    if (_isLeavingLocally) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text("Odadan Ayrıl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          _isPlayer1
              ? "Odadan ayrılırsanız düello odası kapatılacaktır. Devam etmek istiyor musunuz?"
              : "Odadan ayrılmak istediğinizden emin misiniz?",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx);
              _leaveRoomNow();
            },
            child: const Text("Ayrıl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GAMEPLAY ROUNDS (5 QUESTIONS)
  // ==========================================
  void _startQuestionRound() {
    _questionTimer?.cancel();
    setState(() {
      _selectedOptionIndex = null;
      _isAnswerLocked = false;
      _isAnswerRevealed = false;
      _remainingSeconds = 15;
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 3) {
          HapticFeedback.selectionClick();
        }
      } else {
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    _questionTimer?.cancel();
    if (_isAnswerLocked || _isAnswerRevealed) return;
    _lockAndEvaluate(-1); // -1 = no option chosen
  }

  void _onOptionSelected(int index) {
    if (_isAnswerLocked || _isAnswerRevealed) return;
    _lockAndEvaluate(index);
  }

  Future<void> _lockAndEvaluate(int chosenIndex) async {
    _questionTimer?.cancel();
    setState(() {
      _selectedOptionIndex = chosenIndex;
      _isAnswerLocked = true;
    });

    // Brief 800ms suspense
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final currentQ = _duelRoom!.questions[_currentQuestionIndex];
    final isCorrect = chosenIndex == currentQ.correctIndex;
    final gainedPoints = isCorrect ? (1000 + (_remainingSeconds * 40)) : 0;

    setState(() {
      _isAnswerRevealed = true;
      _myAnswers[_currentQuestionIndex] = isCorrect;
      if (isCorrect) {
        _myCorrectCount++;
        _myScore += gainedPoints;
      }
    });

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      MillionaireDuelService.instance.recordQuestionSolved();
    } else {
      HapticFeedback.vibrate();
    }

    final isLastQuestion = _currentQuestionIndex == 4;

    // Sync answer to Firestore room in real-time
    if (_duelRoom != null) {
      final myAnswerIndexes = List<int?>.filled(5, null);
      for (int i = 0; i <= _currentQuestionIndex; i++) {
        myAnswerIndexes[i] = _selectedOptionIndex;
      }

      await MillionaireDuelService.instance.updatePlayerProgress(
        roomId: _duelRoom!.id,
        isPlayer1: _isPlayer1,
        score: _myScore,
        correctAnswers: _myCorrectCount,
        isCompleted: isLastQuestion,
        answers: myAnswerIndexes,
      );
    }

    // Advance to next round or finish duel
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    if (!isLastQuestion) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionRound();
    } else {
      _finishDuel();
    }
  }

  Future<void> _finishDuel() async {
    _questionTimer?.cancel();
    final isVictory = _myScore > _oppScore;

    if (isVictory) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
    }

    // Submit to Firestore leaderboard
    await MillionaireDuelService.instance.submitDuelResult(
      duelId: _duelRoom?.id ?? 'duel',
      won: isVictory,
      score: _myScore,
    );

    // Finalize room in Firestore
    if (_duelRoom != null) {
      final winnerId = isVictory
          ? MillionaireDuelService.instance.currentUserId
          : (_oppScore > _myScore ? (_isPlayer1 ? _duelRoom!.player2?.userId ?? 'opp' : _duelRoom!.player1.userId) : 'tie');

      await MillionaireDuelService.instance.finalizeDuel(
        roomId: _duelRoom!.id,
        winnerId: winnerId,
      );
    }

    if (!mounted) return;
    _showDuelResultDialog(isVictory);
  }

  void _showDuelResultDialog(bool isVictory) {
    final isTie = _myScore == _oppScore;
    final opponentName = _isPlayer1
        ? (_duelRoom?.player2?.name ?? "Rakip")
        : (_duelRoom?.player1.name ?? "Rakip");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: isVictory
                ? const Color(0xFF10B981)
                : (isTie ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
            width: 2,
          ),
        ),
        title: Center(
          child: Column(
            children: [
              Icon(
                isVictory
                    ? Icons.emoji_events_rounded
                    : (isTie ? Icons.handshake_rounded : Icons.military_tech_rounded),
                size: 54,
                color: isVictory ? const Color(0xFFF59E0B) : Colors.white70,
              ),
              const SizedBox(height: 8),
              Text(
                isVictory ? "ZAFER SENİN! 🏆" : (isTie ? "BERABERE! 🤝" : "MAĞLUBİYET ⚔️"),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isVictory ? const Color(0xFFF59E0B) : Colors.white,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("SEN", style: TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        "$_myScore P",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                      Text("$_myCorrectCount/5 Doğru", style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    ],
                  ),
                  const Text("VS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white24)),
                  Column(
                    children: [
                      Text(
                        opponentName,
                        style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$_oppScore P",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                      ),
                      Text("$_oppCorrectCount/5 Doğru", style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isVictory ? "+25 Kupa Kazanıldı!" : "+5 Kupa Katılım Puanı",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Çıkış", style: TextStyle(color: Colors.white70)),
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
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isGameActive = false;
                      _isStartingCountdown = false;
                      _currentQuestionIndex = 0;
                      _myScore = 0;
                      _myCorrectCount = 0;
                      _oppScore = 0;
                      _oppCorrectCount = 0;
                      for (int i = 0; i < 5; i++) {
                        _myAnswers[i] = null;
                        _oppAnswers[i] = null;
                      }
                    });
                    _initOrFindRoom();
                  },
                  child: const Text("Yeni Oda Kur", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OptionState _getOptionState(int index) {
    if (_isAnswerRevealed) {
      final currentQ = _duelRoom!.questions[_currentQuestionIndex];
      if (index == currentQ.correctIndex) {
        return OptionState.correct;
      }
      if (index == _selectedOptionIndex) {
        return OptionState.wrong;
      }
      return OptionState.normal;
    }

    if (_selectedOptionIndex == index) {
      return OptionState.selected;
    }

    return OptionState.normal;
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
      child: PopScope(
        canPop: !RevenueCatService.instance.isPremium || _duelRoom == null,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (!RevenueCatService.instance.isPremium || _duelRoom == null) {
            Navigator.pop(context);
            return;
          }
          _confirmLeaveRoom();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF070B19),
          body: Stack(
            children: [
              // Ambient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.3,
                    colors: [
                      Color(0xFF162554),
                      Color(0xFF0A0F24),
                      Color(0xFF03050C),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: !RevenueCatService.instance.isPremium
                    ? _buildDuelProGateState()
                    : (_isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                          )
                        : (_isGameActive ? _buildLiveDuelState() : _buildRoomLobbyState())),
              ),

              // 3-2-1 Countdown Overlay
              if (_isStartingCountdown) _buildCountdownOverlay(),

              // Confetti
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

  // ==========================================
  // PRO REQUIREMENT LOBBY GATE (NON-PRO STATE)
  // ==========================================
  Widget _buildDuelProGateState() {
    return Column(
      children: [
        // App Bar
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
                "CANLI 1v1 DÜELLO",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 14),
                    SizedBox(width: 4),
                    Text(
                      "PRO ÖZEL",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Radar & Head-to-Head Arena Visual
                SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Radar Wave Rings
                      AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, child) {
                          final value = _radarController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120 + (value * 90),
                                height: 120 + (value * 90),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: (1 - value) * 0.45),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 90 + (value * 60),
                                height: 90 + (value * 60),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: (1 - value) * 0.35),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Combatant 1 (User), VS Emblem, Combatant 2 (Opponent)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Player (You)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("SİZ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ],
                          ),

                          const SizedBox(width: 16),

                          // VS Emblem
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "VS",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Opponent (Comrade in Arms)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFB45309), Color(0xFF0F172A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.shield_rounded, color: Color(0xFFF59E0B), size: 32),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Text("RAKİP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Title & Subtitle
                const Text(
                  "CANLI 1v1 DÜELLO ARENASI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "81 ildeki asker arkadaşların ve yakınlarınla gerçek zamanlı online bilgi düellosunda yarış! Canlı düello özelliği Şafak Sayar PRO üyelerine özeldir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                // PRO Features Checklist
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildDuelProFeatureRow(
                        icon: Icons.flash_on_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: "Gerçek Zamanlı 1v1 Karşılaşma",
                        desc: "Aynı anda 5 soru, saniyelik hamleler ve anlık skor tablosu.",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      _buildDuelProFeatureRow(
                        icon: Icons.military_tech_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: "Askeri Rütbe & Zafer Sistemi",
                        desc: "Kazandıkça Er'den Mareşal'e kadar askeri rütbeni yükselt.",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      _buildDuelProFeatureRow(
                        icon: Icons.meeting_room_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: "Özel Oda Kur & Meydan Oku",
                        desc: "Oda koduyla tertibine ya da sevdiklerine anında meydan oku.",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      _buildDuelProFeatureRow(
                        icon: Icons.all_inclusive_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: "Klasik Modda Sınırsız Hak",
                        desc: "Günlük hak sınırı olmadan dilediğin kadar yarış.",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // High Impact CTA Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        await PremiumPaywallPage.show(context, source: 'millionaire_duel_lobby');
                        if (mounted &&
                            RevenueCatService.instance.isPremium &&
                            _duelRoom == null &&
                            !_isGameActive &&
                            !_isLoading) {
                          setState(() {});
                          _startDuelInit();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "PRO'YA GEÇ VE DÜELLOYA BAŞLA 👑",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Guarantee Text
                const Text(
                  "İstediğiniz an kolayca iptal edebilirsiniz • Tüm PRO özellikler dahil",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),

                const SizedBox(height: 16),

                // Dismiss Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Şimdilik Geri Dön", style: TextStyle(color: Colors.white60, fontSize: 13)),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuelProFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.white60, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 1. DÜELLO ODASI (LOBBY UI)
  // ==========================================
  Widget _buildRoomLobbyState() {
    final host = _duelRoom?.player1;
    final opponent = _duelRoom?.player2;
    final myPlayer = _isPlayer1 ? host : opponent;
    final myIsReady = myPlayer?.isReady ?? false;
    final opponentIsReady = _isPlayer1 ? (opponent?.isReady ?? false) : (host?.isReady ?? false);
    final hasOpponent = opponent != null;

    return Column(
      children: [
        // Top App Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                onPressed: _confirmLeaveRoom,
              ),
              Column(
                children: [
                  const Text(
                    "DÜELLO ODASI ⚔️",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "CANLI BEKLEME SALONU",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8)),
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: "Açık Odalar & Kod",
                icon: const Icon(Icons.meeting_room_rounded, color: Color(0xFF38BDF8), size: 24),
                onPressed: _showOpenRoomsModal,
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Room Code Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "DÜELLO ODA KODU",
                            style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _duelRoom?.roomCode ?? "DL-....",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF59E0B),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: "Kodu Kopyala",
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                            icon: const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 18),
                            onPressed: _copyRoomCode,
                          ),
                          const SizedBox(width: 6),
                          Builder(
                            builder: (btnCtx) => ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: const Text("Paylaş", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => _shareRoomCode(btnCtx),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Player Podiums (VS Battle Layout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player 1 (Host)
                    Expanded(
                      child: _buildPlayerLobbyCard(
                        player: host,
                        isHost: true,
                        isMe: _isPlayer1,
                        isReady: host?.isReady ?? false,
                      ),
                    ),

                    // VS Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 36),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F172A),
                              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                            ),
                            child: const Text(
                              "VS",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Player 2 (Challenger)
                    Expanded(
                      child: hasOpponent
                          ? _buildPlayerLobbyCard(
                              player: opponent,
                              isHost: false,
                              isMe: !_isPlayer1,
                              isReady: opponent.isReady,
                            )
                          : _buildEmptyOpponentSlot(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Status Message Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C44),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasOpponent
                          ? (opponentIsReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                          : const Color(0xFF38BDF8),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasOpponent
                            ? (opponentIsReady ? Icons.check_circle_rounded : Icons.hourglass_top_rounded)
                            : Icons.radar_rounded,
                        color: hasOpponent
                            ? (opponentIsReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                            : const Color(0xFF38BDF8),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          !hasOpponent
                              ? "Canlı rakip bekleniyor...\nAktif kullanıcılara bildirim gönderildi."
                              : (!opponentIsReady
                                  ? "${_isPlayer1 ? (opponent.name) : (host?.name ?? 'Ev Sahibi')} odaya katıldı! Hazır olması bekleniyor..."
                                  : "Rakip HAZIR! Sen de 'HAZIRIM' butonuna bastığında düello başlayacak!"),
                          style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rules reminder
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Yarışma kuralı: Her iki taraf da hazır olunca 5 soruluk düello aynı anda başlar. Sahte veya bot kullanıcı yoktur.",
                          style: TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Ready Button Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myIsReady ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    foregroundColor: myIsReady ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  icon: Icon(myIsReady ? Icons.check_circle_rounded : Icons.thumb_up_alt_rounded),
                  label: Text(
                    myIsReady ? "HAZIRSINIZ ✅ (Vazgeçmek için dokun)" : "HAZIRIM 👍",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  onPressed: _toggleReady,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _confirmLeaveRoom,
                child: const Text("Odadan Ayrıl / Odayı Kapat", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerLobbyCard({
    required DuelPlayer? player,
    required bool isHost,
    required bool isMe,
    required bool isReady,
  }) {
    final name = player?.name ?? 'Yarışmacı';
    final rank = player?.rank ?? 'Asker';
    final city = player?.city ?? 'Türkiye';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A3C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady ? const Color(0xFF10B981) : (isMe ? const Color(0xFF38BDF8) : Colors.white24),
          width: isReady ? 2 : 1,
        ),
        boxShadow: [
          if (isReady)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 14,
            ),
        ],
      ),
      child: Column(
        children: [
          // Role & Host Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("KURUCU 👑", style: TextStyle(fontSize: 8.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("SEN", style: TextStyle(fontSize: 8.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: isReady ? const Color(0xFF10B981) : const Color(0xFF1E293B),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isReady ? const Color(0xFF10B981) : Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            rank,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
          ),
          Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: Colors.white38),
          ),

          const SizedBox(height: 12),

          // Ready Status Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isReady ? const Color(0xFF10B981) : Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                isReady ? "HAZIR ✅" : "BEKLİYOR ⏳",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isReady ? Colors.white : Colors.white60,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOpponentSlot() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1024),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text("RAKİP YUVASI", style: TextStyle(fontSize: 8.5, color: Colors.white60, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 14),

          // Radar animation
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3 + (0.7 * _radarController.value)),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.radar_rounded, color: Color(0xFF38BDF8), size: 28),
              );
            },
          ),

          const SizedBox(height: 12),

          const Text(
            "Canlı Rakip\nBekleniyor...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),

          const SizedBox(height: 16),

          Builder(
            builder: (btnCtx) => OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _shareRoomCode(btnCtx),
              child: const Text("Davet Et 📲", style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3-2-1 COUNTDOWN OVERLAY
  // ==========================================
  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "HER İKİ YARIŞMACI DA HAZIR! 🎯",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedScale(
              scale: 1.3,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
                  ),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Text(
                  _countdownSeconds > 0 ? "$_countdownSeconds" : "BAŞLA!",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "5 Soruluk Canlı Asker Düellosu Başlıyor! ⚔️",
              style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. ACTIVE 1V1 DUEL STATE (GAMEPLAY)
  // ==========================================
  Widget _buildLiveDuelState() {
    final currentQ = _duelRoom!.questions[_currentQuestionIndex];
    final opponent = _isPlayer1 ? _duelRoom!.player2 : _duelRoom!.player1;
    final opponentName = opponent?.name ?? "Rakip";
    final opponentRank = opponent?.rank ?? "Asker";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TOP 1V1 SCOREBOARD HUD
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1A3C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: You
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MillionaireDuelService.instance.currentUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      MillionaireDuelService.instance.currentUserRank,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_myScore P",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          _buildProgressDot(_myAnswers[i]),
                      ],
                    ),
                  ],
                ),
              ),

              // Center: Timer & VS Badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "SORU ${_currentQuestionIndex + 1}/5",
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A),
                      border: Border.all(
                        color: _remainingSeconds <= 4 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      "$_remainingSeconds",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _remainingSeconds <= 4 ? const Color(0xFFEF4444) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Right: Opponent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      opponentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      opponentRank,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFF43F5E), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_oppScore P",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < 5; i++)
                          _buildProgressDot(_oppAnswers[i]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // QUESTION CARD
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1A3C),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white10,
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
                      const SizedBox(height: 10),
                      Text(
                        currentQ.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Options (A, B, C, D)
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
    );
  }

  Widget _buildProgressDot(bool? status) {
    Color color;
    if (status == null) {
      color = Colors.white24;
    } else if (status) {
      color = const Color(0xFF10B981);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
