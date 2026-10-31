import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:safaksayar/Services/millionaire_question_bank.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/models/millionaire_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing online 1v1 duels, matchmaking queue,
/// and live Firestore Leaderboard for Kim Milyoner Olmak İster.
class MillionaireDuelService {
  static final MillionaireDuelService instance = MillionaireDuelService._internal();
  MillionaireDuelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Active user cached profile
  String? _userId;
  String? _userName;
  String? _userRole;
  String? _userRank;
  String? _userCity;

  /// Loads current user profile from local SharedPreferences
  Future<void> initUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? prefs.getString('user_id');
    if (_userId == null || _userId!.isEmpty) {
      _userId = 'usr_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
      await prefs.setString('userId', _userId!);
      await prefs.setString('user_id', _userId!);
    }

    _userName = prefs.getString('name');
    if (_userName == null || _userName!.isEmpty) {
      _userName = 'Mehmetçik';
    }

    _userRole = prefs.getString('user_role') ?? 'asker';
    final relationship = prefs.getString('relationship');
    final rutbe = prefs.getString('rutbe') ?? 'ER';

    if (_userRole == 'yakin') {
      _userRank = relationship ?? 'Asker Yakını';
    } else {
      _userRank = rutbe;
    }

    _userCity = prefs.getString('memleket') ?? prefs.getString('askerlik_yeri') ?? 'Ankara';
    if (_userCity!.isEmpty) _userCity = 'Ankara';
  }

  String get currentUserId => _userId ?? 'me';
  String get currentUserName => _userName ?? 'Mehmetçik';
  String get currentUserRole => _userRole ?? 'asker';
  String get currentUserRank => _userRank ?? 'ER';
  String get currentUserCity => _userCity ?? 'Ankara';

  /// Syncs current VIP/PRO status to leaderboard document
  Future<void> syncPremiumStatus() async {
    await initUserProfile();
    if (_userId == null) return;
    try {
      final isPrem = RevenueCatService.instance.isPremium;
      final canWriteRootPremium =
          RevenueCatService.instance.hasVerifiedStatus || isPrem;
      await _firestore.collection('quiz_leaderboard').doc(_userId).set({
        'userId': _userId,
        if (_userName != null && _userName!.isNotEmpty) 'name': _userName,
        if (_userRole != null && _userRole!.isNotEmpty) 'role': _userRole,
        if (_userRank != null && _userRank!.isNotEmpty) 'rank': _userRank,
        if (_userCity != null && _userCity!.isNotEmpty) 'city': _userCity,
        if (canWriteRootPremium) 'isPremium': isPrem,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (canWriteRootPremium) {
        await _firestore.collection('users').doc(_userId).set({
          'isPremium': isPrem,
          'quiz_stats': {
            'isPremium': isPrem,
          }
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  // ==========================================
  // LEADERBOARD METHODS
  // ==========================================

  /// Records a single question answered correctly in real-time
  Future<void> recordQuestionSolved() async {
    await initUserProfile();
    if (_userId == null) return;

    try {
      final isPrem = RevenueCatService.instance.isPremium;
      final canWriteRootPremium =
          RevenueCatService.instance.hasVerifiedStatus || isPrem;
      final leaderDoc = _firestore.collection('quiz_leaderboard').doc(_userId);
      await leaderDoc.set({
        'userId': _userId,
        'name': _userName,
        'role': _userRole,
        'rank': _userRank,
        'city': _userCity,
        if (canWriteRootPremium) 'isPremium': isPrem,
        'questionsSolved': FieldValue.increment(1),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync to users collection (preserve existing isPremium if not yet verified)
      await _firestore.collection('users').doc(_userId).set({
        if (canWriteRootPremium) 'isPremium': isPrem,
        'quiz_stats': {
          'questionsSolved': FieldValue.increment(1),
          if (canWriteRootPremium) 'isPremium': isPrem,
          'lastActive': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[MillionaireDuel] Error recording solved question: $e');
    }
  }

  /// Submits the result of a classic solo game
  Future<void> submitClassicScore({
    required int earnedAmount,
    required bool wonMillion,
  }) async {
    await initUserProfile();
    if (_userId == null) return;

    try {
      final isPrem = RevenueCatService.instance.isPremium;
      final canWriteRootPremium =
          RevenueCatService.instance.hasVerifiedStatus || isPrem;
      final userDocRef = _firestore.collection('quiz_leaderboard').doc(_userId);
      await userDocRef.set({
        'userId': _userId,
        'name': _userName,
        'role': _userRole,
        'rank': _userRank,
        'city': _userCity,
        if (canWriteRootPremium) 'isPremium': isPrem,
        'totalEarned': FieldValue.increment(earnedAmount),
        'gamesPlayed': FieldValue.increment(1),
        'millionaireCount': wonMillion ? FieldValue.increment(1) : FieldValue.increment(0),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync to users collection (preserve existing isPremium if not yet verified)
      await _firestore.collection('users').doc(_userId).set({
        if (canWriteRootPremium) 'isPremium': isPrem,
        'quiz_stats': {
          'totalEarned': FieldValue.increment(earnedAmount),
          'gamesPlayed': FieldValue.increment(1),
          'millionaireCount': wonMillion ? FieldValue.increment(1) : FieldValue.increment(0),
          if (canWriteRootPremium) 'isPremium': isPrem,
          'lastActive': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[MillionaireDuel] Error submitting classic score: $e');
    }
  }

  /// Submits the result of a 1v1 online duel
  Future<void> submitDuelResult({
    required String duelId,
    required bool won,
    required int score,
  }) async {
    await initUserProfile();
    if (_userId == null) return;

    try {
      final isPrem = RevenueCatService.instance.isPremium;
      final canWriteRootPremium =
          RevenueCatService.instance.hasVerifiedStatus || isPrem;
      final pointsGain = won ? 25 : 5;
      final userDocRef = _firestore.collection('quiz_leaderboard').doc(_userId);
      await userDocRef.set({
        'userId': _userId,
        'name': _userName,
        'role': _userRole,
        'rank': _userRank,
        'city': _userCity,
        if (canWriteRootPremium) 'isPremium': isPrem,
        'gamesPlayed': FieldValue.increment(1),
        'duelWins': won ? FieldValue.increment(1) : FieldValue.increment(0),
        'duelPoints': FieldValue.increment(pointsGain),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync to users collection (preserve existing isPremium if not yet verified)
      await _firestore.collection('users').doc(_userId).set({
        if (canWriteRootPremium) 'isPremium': isPrem,
        'quiz_stats': {
          'gamesPlayed': FieldValue.increment(1),
          'duelWins': won ? FieldValue.increment(1) : FieldValue.increment(0),
          'duelPoints': FieldValue.increment(pointsGain),
          if (canWriteRootPremium) 'isPremium': isPrem,
          'lastActive': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[MillionaireDuel] Error submitting duel result: $e');
    }
  }

  /// Streams ALL users from Firestore DB merged dynamically with quiz stats.
  /// Any user who plays more and solves more questions dynamically rises to the top!
  Stream<List<LeaderboardEntry>> streamAllUsersLeaderboard({String sortBy = 'questions'}) {
    // Realtime stream of quiz_leaderboard
    return _firestore.collection('quiz_leaderboard').snapshots().asyncMap((quizSnapshot) async {
      final userMap = <String, LeaderboardEntry>{};

      // 1. First fetch or listen to all registered users from 'users' collection
      try {
        final usersSnapshot = await _firestore.collection('users').limit(100).get();
        for (final doc in usersSnapshot.docs) {
          final entry = LeaderboardEntry.fromFirestore(doc);
          if (entry.name.isNotEmpty) {
            userMap[doc.id] = entry;
          }
        }
      } catch (e) {
        debugPrint('[MillionaireDuel] Note on users fetch: $e');
      }

      // 2. Merge/update with quiz_leaderboard documents
      for (final doc in quizSnapshot.docs) {
        final entry = LeaderboardEntry.fromFirestore(doc);
        userMap[doc.id] = entry;
      }

      // 3. Fallback to rich seeds if no users yet
      if (userMap.isEmpty) {
        for (final seed in getMockLeaderboardSeed()) {
          userMap[seed.userId] = seed;
        }
      }

      final list = userMap.values.toList();

      // 4. Sort dynamically according to active filter
      list.sort((a, b) {
        switch (sortBy) {
          case 'questions':
            // Kim daha çok soru çözerse ilk sırada
            final cmp = b.questionsSolved.compareTo(a.questionsSolved);
            if (cmp != 0) return cmp;
            return b.totalEarned.compareTo(a.totalEarned);
          case 'games':
            // Kim daha çok oynarsa ilk sırada
            final cmp = b.gamesPlayed.compareTo(a.gamesPlayed);
            if (cmp != 0) return cmp;
            return b.questionsSolved.compareTo(a.questionsSolved);
          case 'money':
            // En çok para kazananlar
            final cmp = b.totalEarned.compareTo(a.totalEarned);
            if (cmp != 0) return cmp;
            return b.questionsSolved.compareTo(a.questionsSolved);
          case 'duel':
            // Düello şampiyonları
            final cmp = b.duelWins.compareTo(a.duelWins);
            if (cmp != 0) return cmp;
            return b.duelPoints.compareTo(a.duelPoints);
          default:
            return b.questionsSolved.compareTo(a.questionsSolved);
        }
      });

      return list;
    }).handleError((e) {
      debugPrint('[MillionaireDuel] Stream error, fallback to seed: $e');
      return getMockLeaderboardSeed();
    });
  }

  /// High quality seed leaderboard if Firestore collection is newly created or offline
  List<LeaderboardEntry> getMockLeaderboardSeed() {
    final now = DateTime.now();
    return [
      LeaderboardEntry(
        userId: 'bot_1',
        name: 'Mustafa Çavuş',
        role: 'asker',
        rank: 'ÇAVUŞ (Komando)',
        city: 'Hakkari',
        totalEarned: 15450000,
        gamesPlayed: 14,
        millionaireCount: 3,
        duelWins: 42,
        duelPoints: 2050,
        lastActive: now.subtract(const Duration(minutes: 15)),
      ),
      LeaderboardEntry(
        userId: 'bot_2',
        name: 'Selin & Teğmen Emre',
        role: 'yakin',
        rank: 'Asker Eşi',
        city: 'İzmir',
        totalEarned: 11250000,
        gamesPlayed: 12,
        millionaireCount: 2,
        duelWins: 38,
        duelPoints: 1950,
        lastActive: now.subtract(const Duration(minutes: 42)),
      ),
      LeaderboardEntry(
        userId: 'bot_3',
        name: 'Bahriyeli Burak',
        role: 'asker',
        rank: 'ASTSUBAY',
        city: 'Gölcük',
        totalEarned: 8750000,
        gamesPlayed: 9,
        millionaireCount: 1,
        duelWins: 29,
        duelPoints: 1725,
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
      LeaderboardEntry(
        userId: 'bot_4',
        name: 'Büşra & Ali',
        role: 'yakin',
        rank: 'Asker Sevgilisi',
        city: 'Ankara',
        totalEarned: 6500000,
        gamesPlayed: 8,
        millionaireCount: 1,
        duelWins: 24,
        duelPoints: 1600,
        lastActive: now.subtract(const Duration(hours: 2)),
      ),
      LeaderboardEntry(
        userId: 'bot_5',
        name: 'Piyade Er Serdar',
        role: 'asker',
        rank: 'ER',
        city: 'Edirne',
        totalEarned: 5200000,
        gamesPlayed: 7,
        millionaireCount: 1,
        duelWins: 21,
        duelPoints: 1525,
        lastActive: now.subtract(const Duration(hours: 3)),
      ),
      LeaderboardEntry(
        userId: 'bot_6',
        name: 'Havacı Onbaşı Kerem',
        role: 'asker',
        rank: 'ONBAŞI',
        city: 'Eskişehir',
        totalEarned: 3850000,
        gamesPlayed: 6,
        millionaireCount: 0,
        duelWins: 18,
        duelPoints: 1450,
        lastActive: now.subtract(const Duration(hours: 4)),
      ),
      LeaderboardEntry(
        userId: 'bot_7',
        name: 'Ayşe Teyze',
        role: 'yakin',
        rank: 'Asker Annesi',
        city: 'Konya',
        totalEarned: 2750000,
        gamesPlayed: 5,
        millionaireCount: 0,
        duelWins: 14,
        duelPoints: 1350,
        lastActive: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  // ==========================================
  // 1V1 MULTIPLAYER DUEL SYSTEM (HUMAN ONLY)
  // ==========================================

  /// Creates human player model for current user
  DuelPlayer getCurrentPlayer({bool isReady = false}) {
    return DuelPlayer(
      userId: currentUserId,
      name: currentUserName,
      role: currentUserRole,
      rank: currentUserRank,
      city: currentUserCity,
      score: 0,
      correctAnswers: 0,
      isCompleted: false,
      isReady: isReady,
      answers: [],
    );
  }

  /// Creates a new waiting duel room in Firestore
  Future<DuelRoom> createWaitingRoom() async {
    await initUserProfile();
    final player = getCurrentPlayer(isReady: false);
    final roomCode = 'DL-${1000 + _random.nextInt(9000)}';

    final questions = MillionaireQuestionBank.instance.getDuelQuestions(count: 5);
    final newDocRef = _firestore.collection('quiz_duels').doc();

    final room = DuelRoom(
      id: newDocRef.id,
      roomCode: roomCode,
      status: 'waiting',
      player1: player,
      player2: null,
      questions: questions,
      createdAt: DateTime.now(),
    );

    await newDocRef.set({
      ...room.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return room;
  }

  /// Automatically searches for an existing open waiting room created by another real user.
  /// If found, joins it as Player 2.
  /// If none exists, creates a fresh waiting room as Host (Player 1).
  Future<DuelRoom> findAvailableRoomOrCreate() async {
    await initUserProfile();
    try {
      final snapshot = await _firestore
          .collection('quiz_duels')
          .where('status', isEqualTo: 'waiting')
          .limit(15)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final p1 = data['player1'] as Map<String, dynamic>?;
        final p2 = data['player2'];

        // Room must have been created by another real human and still have an empty slot
        if (p1 != null && p1['userId'] != currentUserId && p2 == null) {
          final joined = await joinDuelRoom(doc.id);
          if (joined != null) {
            return joined;
          }
        }
      }
    } catch (e) {
      debugPrint('[MillionaireDuel] Error searching for open room: $e');
    }

    // No open room from another user found; create a new waiting room
    return await createWaitingRoom();
  }

  /// Backward-compatible alias for matchmaking
  Future<DuelRoom> findOrCreateDuel({bool forceBot = false}) => findAvailableRoomOrCreate();

  /// Cancels a waiting room (convenience wrapper)
  Future<void> cancelDuelRoom(String roomId) => leaveOrCancelDuelRoom(roomId: roomId, isPlayer1: true);

  /// Joins an existing duel room by Document ID or 6-digit Room Code
  Future<DuelRoom?> joinDuelRoom(String roomIdOrCode) async {
    await initUserProfile();
    final player = getCurrentPlayer(isReady: false);
    final cleaned = roomIdOrCode.trim().toUpperCase();

    try {
      DocumentSnapshot? targetDoc;

      // 1. Try finding by document ID
      final directDoc = await _firestore.collection('quiz_duels').doc(roomIdOrCode.trim()).get();
      if (directDoc.exists) {
        targetDoc = directDoc;
      } else {
        // 2. Try finding by roomCode
        final query = await _firestore
            .collection('quiz_duels')
            .where('roomCode', isEqualTo: cleaned)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          targetDoc = query.docs.first;
        }
      }

      if (targetDoc == null || !targetDoc.exists) {
        return null;
      }

      final room = DuelRoom.fromFirestore(targetDoc);
      if (room.status == 'completed' || room.status == 'cancelled') {
        return null;
      }

      // If user is already player1
      if (room.player1.userId == currentUserId) {
        return room;
      }

      // If user is already player2
      if (room.player2?.userId == currentUserId) {
        return room;
      }

      // If room is full with another player
      if (room.player2 != null && room.player2!.userId != currentUserId) {
        return null; // Room full
      }

      // Join as player 2
      await targetDoc.reference.update({
        'player2': player.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return DuelRoom(
        id: targetDoc.id,
        roomCode: room.roomCode,
        status: room.status,
        player1: room.player1,
        player2: player,
        questions: room.questions,
        createdAt: room.createdAt,
      );
    } catch (e) {
      debugPrint('[MillionaireDuel] Error joining room: $e');
      return null;
    }
  }

  /// Toggles ready state for a player.
  /// When both players become ready, automatically transitions room status to 'active'.
  Future<void> setPlayerReady({
    required String roomId,
    required bool isPlayer1,
    required bool isReady,
  }) async {
    try {
      final docRef = _firestore.collection('quiz_duels').doc(roomId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final room = DuelRoom.fromFirestore(doc);
      final otherPlayerReady = isPlayer1
          ? (room.player2?.isReady ?? false)
          : room.player1.isReady;

      final willBothBeReady = isReady && otherPlayerReady && room.player2 != null;

      final key = isPlayer1 ? 'player1.isReady' : 'player2.isReady';
      final updates = <String, dynamic>{
        key: isReady,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (willBothBeReady) {
        updates['status'] = 'active';
      }

      await docRef.update(updates);
    } catch (e) {
      debugPrint('[MillionaireDuel] Error setting player ready: $e');
    }
  }

  /// Leaves or cancels a duel room
  Future<void> leaveOrCancelDuelRoom({
    required String roomId,
    required bool isPlayer1,
  }) async {
    try {
      final docRef = _firestore.collection('quiz_duels').doc(roomId);
      if (isPlayer1) {
        // Host left -> cancel room
        await docRef.update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Player 2 left -> remove player2, keep room open for another real opponent
        await docRef.update({
          'player2': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[MillionaireDuel] Error leaving/cancelling room: $e');
    }
  }

  /// Streams currently open waiting rooms created by real users (status == 'waiting')
  Stream<List<DuelRoom>> streamOpenWaitingRooms() {
    return _firestore
        .collection('quiz_duels')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DuelRoom.fromFirestore(doc))
          .where((room) => room.player1.userId != currentUserId && room.player2 == null)
          .toList();
    }).handleError((e) {
      debugPrint('[MillionaireDuel] Stream waiting rooms error: $e');
      return <DuelRoom>[];
    });
  }

  /// Real-time stream of duel room state
  Stream<DuelRoom?> streamDuelRoom(String roomId) {
    if (roomId.startsWith('bot_room_')) {
      return const Stream.empty();
    }
    return _firestore.collection('quiz_duels').doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DuelRoom.fromFirestore(doc);
    });
  }

  /// Updates player answer and score in real-time
  Future<void> updatePlayerProgress({
    required String roomId,
    required bool isPlayer1,
    required int score,
    required int correctAnswers,
    required bool isCompleted,
    required List<int?> answers,
  }) async {
    if (roomId.startsWith('bot_room_')) return;

    try {
      final key = isPlayer1 ? 'player1' : 'player2';
      await _firestore.collection('quiz_duels').doc(roomId).update({
        '$key.score': score,
        '$key.correctAnswers': correctAnswers,
        '$key.isCompleted': isCompleted,
        '$key.answers': answers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[MillionaireDuel] Error updating progress: $e');
    }
  }

  /// Finalizes duel room and declares the winner
  Future<void> finalizeDuel({
    required String roomId,
    required String winnerId,
  }) async {
    if (roomId.startsWith('bot_room_')) return;

    try {
      await _firestore.collection('quiz_duels').doc(roomId).update({
        'status': 'completed',
        'winnerId': winnerId,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[MillionaireDuel] Error finalizing duel: $e');
    }
  }
}
