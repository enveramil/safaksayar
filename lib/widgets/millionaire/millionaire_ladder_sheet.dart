import 'package:flutter/material.dart';
import 'package:safaksayar/models/millionaire_models.dart';

/// Modal bottom sheet displaying the authentic 12-step Millionaire Money Ladder (Para Ağacı)
class MillionaireLadderSheet extends StatelessWidget {
  final int currentStep; // 1-indexed (1 to 12)
  final int currentEarned;

  const MillionaireLadderSheet({
    super.key,
    required this.currentStep,
    required this.currentEarned,
  });

  static void show(BuildContext context, {required int currentStep, required int currentEarned}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MillionaireLadderSheet(
        currentStep: currentStep,
        currentEarned: currentEarned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guaranteed = MillionaireLadderStep.getGuaranteedPrize(currentStep);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1021),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFD97706), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PARA AĞACI",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "12 Basamak • 5.000.000 TL Hedef",
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Current guaranteed summary pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("GARANTİ BARAJ", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                      guaranteed > 0 ? "$guaranteed TL" : "0 TL",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Column(
                  children: [
                    const Text("ŞU ANKİ ÖDÜL", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                      currentEarned > 0 ? "$currentEarned TL" : "0 TL",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Ladder list (Reverse ordered so 5M is at the top)
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shrinkWrap: true,
              itemCount: MillionaireLadderStep.ladder.length,
              itemBuilder: (context, index) {
                // Reverse: 12 down to 1
                final stepItem = MillionaireLadderStep.ladder[MillionaireLadderStep.ladder.length - 1 - index];
                final isCurrent = stepItem.step == currentStep;
                final isPassed = stepItem.step < currentStep;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2.5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                        : (isPassed ? const Color(0xFF1E293B).withValues(alpha: 0.4) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFFF59E0B)
                          : (stepItem.isBaraj ? Colors.amber.withValues(alpha: 0.3) : Colors.white10),
                      width: isCurrent ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Step Number
                      Container(
                        width: 28,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${stepItem.step}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isCurrent
                                ? const Color(0xFFF59E0B)
                                : (stepItem.isBaraj ? Colors.amberAccent : Colors.white54),
                          ),
                        ),
                      ),

                      // Baraj / Star icon
                      if (stepItem.isBaraj)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            stepItem.step == 12 ? Icons.military_tech_rounded : Icons.shield_rounded,
                            size: 16,
                            color: isCurrent ? const Color(0xFFF59E0B) : Colors.amberAccent,
                          ),
                        ),

                      // Label if Baraj
                      if (stepItem.isBaraj)
                        Text(
                          stepItem.step == 12
                              ? "BÜYÜK ÖDÜL"
                              : (stepItem.step == 7 ? "2. BARAJ" : "1. BARAJ"),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isCurrent ? const Color(0xFFF59E0B) : Colors.amberAccent.withValues(alpha: 0.8),
                          ),
                        ),

                      const Spacer(),

                      // Prize Amount
                      Text(
                        stepItem.prizeFormatted,
                        style: TextStyle(
                          fontSize: isCurrent ? 15 : 13.5,
                          fontWeight: isCurrent || stepItem.isBaraj ? FontWeight.w900 : FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isCurrent
                              ? const Color(0xFFF59E0B)
                              : (isPassed
                                  ? Colors.white70
                                  : (stepItem.isBaraj ? Colors.white : Colors.white54)),
                        ),
                      ),

                      // Status check
                      const SizedBox(width: 8),
                      if (isPassed)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16)
                      else if (isCurrent)
                        const Icon(Icons.arrow_back_rounded, color: Color(0xFFF59E0B), size: 16)
                      else
                        const SizedBox(width: 16),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
