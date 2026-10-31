import 'package:cloud_firestore/cloud_firestore.dart';

/// Question difficulty tiers for Kim Milyoner Olmak İster
enum QuestionDifficulty {
  easy, // 1.000 TL - 5.000 TL (Baraj 1)
  medium, // 7.500 TL - 50.000 TL (Baraj 2)
  hard, // 100.000 TL - 5.000.000 TL (Milyoner)
}

/// Model representing a single question in the competition
class MillionaireQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final QuestionDifficulty difficulty;
  final String category;
  final String? explanation;

  const MillionaireQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.category,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'difficulty': difficulty.index,
      'category': category,
      'explanation': explanation,
    };
  }

  factory MillionaireQuestion.fromMap(Map<String, dynamic> map) {
    return MillionaireQuestion(
      id: map['id']?.toString() ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      difficulty: QuestionDifficulty.values[(map['difficulty'] as num?)?.toInt() ?? 0],
      category: map['category'] ?? 'Genel Kültür',
      explanation: map['explanation'],
    );
  }
}

/// Ladder step definition for the 12-question TV show format
class MillionaireLadderStep {
  final int step; // 1 to 12
  final int prizeAmount; // e.g. 1000, 2000, ..., 5000000
  final String prizeFormatted; // '1.000 TL'
  final bool isBaraj; // 2.000 TL (1. Baraj), 50.000 TL (2. Baraj), 5.000.000 TL (Büyük Ödül)
  final int timeSeconds; // 30s, 45s, or unlimited (0)

  const MillionaireLadderStep({
    required this.step,
    required this.prizeAmount,
    required this.prizeFormatted,
    required this.isBaraj,
    required this.timeSeconds,
  });

  static const List<MillionaireLadderStep> ladder = [
    MillionaireLadderStep(step: 1, prizeAmount: 1000, prizeFormatted: '1.000 TL', isBaraj: false, timeSeconds: 30),
    MillionaireLadderStep(step: 2, prizeAmount: 2000, prizeFormatted: '2.000 TL', isBaraj: true, timeSeconds: 30), // 1. Baraj
    MillionaireLadderStep(step: 3, prizeAmount: 3000, prizeFormatted: '3.000 TL', isBaraj: false, timeSeconds: 45),
    MillionaireLadderStep(step: 4, prizeAmount: 5000, prizeFormatted: '5.000 TL', isBaraj: false, timeSeconds: 45),
    MillionaireLadderStep(step: 5, prizeAmount: 10000, prizeFormatted: '10.000 TL', isBaraj: false, timeSeconds: 45),
    MillionaireLadderStep(step: 6, prizeAmount: 20000, prizeFormatted: '20.000 TL', isBaraj: false, timeSeconds: 45),
    MillionaireLadderStep(step: 7, prizeAmount: 50000, prizeFormatted: '50.000 TL', isBaraj: true, timeSeconds: 0), // 2. Baraj (Limitsiz süre)
    MillionaireLadderStep(step: 8, prizeAmount: 100000, prizeFormatted: '100.000 TL', isBaraj: false, timeSeconds: 0),
    MillionaireLadderStep(step: 9, prizeAmount: 250000, prizeFormatted: '250.000 TL', isBaraj: false, timeSeconds: 0),
    MillionaireLadderStep(step: 10, prizeAmount: 500000, prizeFormatted: '500.000 TL', isBaraj: false, timeSeconds: 0),
    MillionaireLadderStep(step: 11, prizeAmount: 1000000, prizeFormatted: '1.000.000 TL', isBaraj: false, timeSeconds: 0),
    MillionaireLadderStep(step: 12, prizeAmount: 5000000, prizeFormatted: '5.000.000 TL', isBaraj: true, timeSeconds: 0), // Büyük Ödül
  ];

  /// Calculates guaranteed money if user fails at given step
  static int getGuaranteedPrize(int failedAtStep) {
    if (failedAtStep > 7) {
      return 50000; // 2. Baraj
    } else if (failedAtStep > 2) {
      return 2000; // 1. Baraj
    }
    return 0;
  }
}

/// Player state in 1v1 online duel
class DuelPlayer {
  final String userId;
  final String name;
  final String role; // 'asker' or 'yakin'
  final String rank; // e.g. 'Çavuş', 'Asker Eşi', etc.
  final String city;
  final int score;
  final int correctAnswers;
  final bool isCompleted;
  final bool isReady; // Whether player is ready in the lobby room
  final List<int?> answers; // Chosen option indexes for each question

  const DuelPlayer({
    required this.userId,
    required this.name,
    required this.role,
    required this.rank,
    required this.city,
    this.score = 0,
    this.correctAnswers = 0,
    this.isCompleted = false,
    this.isReady = false,
    this.answers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'rank': rank,
      'city': city,
      'score': score,
      'correctAnswers': correctAnswers,
      'isCompleted': isCompleted,
      'isReady': isReady,
      'answers': answers,
    };
  }

  factory DuelPlayer.fromMap(Map<String, dynamic> map) {
    return DuelPlayer(
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Yarışmacı',
      role: map['role'] ?? 'asker',
      rank: map['rank'] ?? 'ER',
      city: map['city'] ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      isReady: map['isReady'] ?? false,
      answers: (map['answers'] as List<dynamic>?)?.map((e) => e as int?).toList() ?? [],
    );
  }
}

/// Room model for 1v1 real-time online duel
class DuelRoom {
  final String id;
  final String roomCode; // 6-digit alphanumeric room code (e.g. DL-7821)
  final String status; // 'waiting', 'active', 'completed', 'cancelled'
  final DuelPlayer player1;
  final DuelPlayer? player2;
  final List<MillionaireQuestion> questions;
  final DateTime createdAt;
  final String? winnerId; // userId of the winner, or 'tie'

  const DuelRoom({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.player1,
    this.player2,
    required this.questions,
    required this.createdAt,
    this.winnerId,
  });

  bool get isBothReady => player1.isReady && (player2?.isReady ?? false);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomCode': roomCode,
      'status': status,
      'player1': player1.toMap(),
      'player2': player2?.toMap(),
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'winnerId': winnerId,
    };
  }

  factory DuelRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    final rawQuestions = (data['questions'] as List<dynamic>?) ?? [];
    final questionsList = rawQuestions
        .map((q) => MillionaireQuestion.fromMap(q as Map<String, dynamic>))
        .toList();

    final roomCode = data['roomCode'] ?? (doc.id.length >= 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id);

    return DuelRoom(
      id: doc.id,
      roomCode: roomCode,
      status: data['status'] ?? 'waiting',
      player1: DuelPlayer.fromMap(data['player1'] as Map<String, dynamic>? ?? {}),
      player2: data['player2'] != null
          ? DuelPlayer.fromMap(data['player2'] as Map<String, dynamic>)
          : null,
      questions: questionsList,
      createdAt: created,
      winnerId: data['winnerId'],
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final String role; // 'asker' or 'yakin'
  final String rank; // 'ÇAVUŞ', 'Asker Eşi', etc.
  final String city;
  final int totalEarned; // Total prize money won (in TL)
  final int questionsSolved; // Total questions answered correctly
  final int gamesPlayed;
  final int millionaireCount; // Times reached 5.000.000 TL
  final int duelWins; // Total 1v1 duel victories
  final int duelPoints; // Duel rating (cups)
  final bool isPremium; // VIP / PRO badge flag
  final DateTime lastActive;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.rank,
    required this.city,
    required this.totalEarned,
    this.questionsSolved = 0,
    this.gamesPlayed = 0,
    this.millionaireCount = 0,
    this.duelWins = 0,
    this.duelPoints = 1000,
    this.isPremium = false,
    required this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'rank': rank,
      'city': city,
      'totalEarned': totalEarned,
      'questionsSolved': questionsSolved,
      'gamesPlayed': gamesPlayed,
      'millionaireCount': millionaireCount,
      'duelWins': duelWins,
      'duelPoints': duelPoints,
      'isPremium': isPremium,
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime active = DateTime.now();
    if (data['lastActive'] is Timestamp) {
      active = (data['lastActive'] as Timestamp).toDate();
    } else if (data['updated_at'] is Timestamp) {
      active = (data['updated_at'] as Timestamp).toDate();
    }

    final quizStats = data['quiz_stats'] as Map<String, dynamic>? ?? {};

    // Get name, support both direct fields and user profile fields
    String resolvedName = data['name'] ?? '';
    if (data['surname'] != null && (data['surname'] as String).isNotEmpty) {
      resolvedName = '$resolvedName ${data['surname']}';
    }
    if (resolvedName.trim().isEmpty) {
      resolvedName = data['fullName'] ?? 'Mehmetçik';
    }

    // Role & Rank
    final role = data['user_role'] ?? data['role'] ?? 'asker';
    final rank = data['rutbe'] ?? data['rank'] ?? (role == 'asker' ? 'ER' : 'Asker Yakını');
    final city = data['memleket'] ?? data['askerlik_yeri'] ?? data['city'] ?? 'Türkiye';

    final isPrem = data['isPremium'] == true ||
        data['is_premium'] == true ||
        quizStats['isPremium'] == true ||
        quizStats['is_premium'] == true;

    return LeaderboardEntry(
      userId: doc.id,
      name: resolvedName.trim(),
      role: role,
      rank: rank,
      city: city,
      totalEarned: (data['totalEarned'] ?? quizStats['totalEarned'] as num?)?.toInt() ?? 0,
      questionsSolved: (data['questionsSolved'] ?? quizStats['questionsSolved'] as num?)?.toInt() ?? 0,
      gamesPlayed: (data['gamesPlayed'] ?? quizStats['gamesPlayed'] as num?)?.toInt() ?? 0,
      millionaireCount: (data['millionaireCount'] ?? quizStats['millionaireCount'] as num?)?.toInt() ?? 0,
      duelWins: (data['duelWins'] ?? quizStats['duelWins'] as num?)?.toInt() ?? 0,
      duelPoints: (data['duelPoints'] ?? quizStats['duelPoints'] as num?)?.toInt() ?? 1000,
      isPremium: isPrem,
      lastActive: active,
    );
  }
}
