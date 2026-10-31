import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/models/millionaire_models.dart';

/// Interactive dialogs for Kim Milyoner Olmak İster Lifelines (Jokerler)
class MillionaireJokerDialogs {
  // ==========================================
  // SEYİRCİ JOKERİ (ASK THE AUDIENCE)
  // ==========================================
  static Future<void> showAudienceJoker(
    BuildContext context, {
    required MillionaireQuestion question,
    required List<int> eliminatedOptions,
  }) async {
    HapticFeedback.mediumImpact();

    // Generate realistic audience distribution
    final random = Random();
    final correct = question.correctIndex;

    int correctWeight;
    switch (question.difficulty) {
      case QuestionDifficulty.easy:
        correctWeight = 60 + random.nextInt(20); // 60-80%
        break;
      case QuestionDifficulty.medium:
        correctWeight = 45 + random.nextInt(20); // 45-65%
        break;
      case QuestionDifficulty.hard:
        correctWeight = 36 + random.nextInt(22); // 36-58%
        break;
    }

    final availableOptions = [0, 1, 2, 3].where((i) => !eliminatedOptions.contains(i)).toList();
    int remaining = 100 - correctWeight;
    final otherOptions = availableOptions.where((i) => i != correct).toList();

    final percentages = <int, int>{};
    percentages[correct] = correctWeight;

    for (int i = 0; i < otherOptions.length; i++) {
      final opt = otherOptions[i];
      if (i == otherOptions.length - 1) {
        percentages[opt] = max(0, remaining);
      } else {
        final share = remaining > 0 ? random.nextInt(remaining) : 0;
        percentages[opt] = share;
        remaining -= share;
      }
    }

    // Set 0 for eliminated options
    for (final opt in eliminatedOptions) {
      percentages[opt] = 0;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.groups_rounded, color: Color(0xFF38BDF8), size: 28),
            SizedBox(width: 10),
            Text(
              "Seyirci Oylaması",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Stüdyodaki seyircilerin butonlarıyla verdikleri oy oranları:",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 4; i++)
                  _buildAudienceBar(
                    optionLetter: ['A', 'B', 'C', 'D'][i],
                    percent: percentages[i] ?? 0,
                    isEliminated: eliminatedOptions.contains(i),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Teşekkürler",
              style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAudienceBar({
    required String optionLetter,
    required int percent,
    required bool isEliminated,
  }) {
    final barHeight = (percent * 1.5).toDouble().clamp(4.0, 150.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isEliminated ? "-" : "%$percent",
          style: TextStyle(
            color: isEliminated ? Colors.white30 : const Color(0xFF38BDF8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 150,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            width: 38,
            height: isEliminated ? 0 : barHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEliminated
                    ? [Colors.grey, Colors.grey.shade700]
                    : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                if (!isEliminated)
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            optionLetter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TELEFON JOKERİ (PHONE A FRIEND)
  // ==========================================
  static Future<void> showPhoneJoker(
    BuildContext context, {
    required MillionaireQuestion question,
    required List<int> eliminatedOptions,
  }) async {
    HapticFeedback.heavyImpact();

    final correctLetter = ['A', 'B', 'C', 'D'][question.correctIndex];
    final letters = ['A', 'B', 'C', 'D'];

    // Select random simulated contact
    final contacts = [
      {'name': 'Mustafa Çavuş (Komando)', 'sub': 'Asker Arkadaşı', 'role': 'asker'},
      {'name': 'Gülşah Hanım', 'sub': 'Asker Eşi', 'role': 'yakin'},
      {'name': 'Prof. Dr. Halil', 'sub': 'Üniversite Hocası', 'role': 'expert'},
      {'name': 'Ali & Ayşe', 'sub': 'Tertip / Devre', 'role': 'asker'},
    ];
    final contact = contacts[Random().nextInt(contacts.length)];

    // Simulation advice logic
    final isConfident = question.difficulty != QuestionDifficulty.hard || Random().nextDouble() > 0.3;
    final advisedLetter = isConfident
        ? correctLetter
        : letters.where((l) => !eliminatedOptions.map((e) => letters[e]).contains(l)).first;

    final adviceText = isConfident
        ? "Selam dostum! Soruya baktım, cevaptan oldukça eminim. Bence doğru cevap kesinlikle **$advisedLetter** şıkkı! Başarılar, dualarımız seninle!"
        : "Merhaba! Biraz zor bir soru ama aklımda kalan bilgilere göre galiba **$advisedLetter** şıkkı daha mantıklı geliyor. Yine de son kararı sana bırakıyorum dostum!";

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0x2210B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    contact['sub']!,
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: Colors.white38, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adviceText,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, color: Colors.white54, size: 16),
                SizedBox(width: 6),
                Text(
                  "30 saniyelik görüşme sona erdi",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Teşekkürler, Kapat", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÇEKİLME ONAY DİYALOĞU (WALK AWAY)
  // ==========================================
  static Future<bool> showWalkAwayDialog(
    BuildContext context, {
    required int currentPrize,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: Color(0xFFF59E0B), size: 26),
            SizedBox(width: 10),
            Text(
              "Çekilmek İstiyor musunuz?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Yanlış cevap verirseniz baraj ödülüne düşersiniz. Şimdi çekilirseniz kazandığınız bu ödülü güvenceye alırsınız:",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Column(
                children: [
                  const Text(
                    "ALACAĞINIZ NAKİT ÖDÜL",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$currentPrize TL",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yarışmaya Devam Et", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Çekil ve Ödülü Al", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
