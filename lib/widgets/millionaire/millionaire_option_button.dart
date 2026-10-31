import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum OptionState {
  normal,
  selected, // Amber/Gold pulse
  correct, // Emerald Green
  wrong, // Crimson Red
  disabled, // Faded by 50-50 joker
}

/// Authentic Kim Milyoner Olmak İster option button with metallic gradient,
/// distinct letter badge, and animated state transitions.
class MillionaireOptionButton extends StatelessWidget {
  final int index; // 0: A, 1: B, 2: C, 3: D
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  const MillionaireOptionButton({
    super.key,
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  static const List<String> optionLetters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    if (state == OptionState.disabled) {
      return Opacity(
        opacity: 0.15,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Text(
                "${optionLetters[index]}:",
                style: const TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "---",
                  style: TextStyle(color: Colors.white24, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color bgColor;
    Color borderColor;
    Color letterColor;
    List<BoxShadow> shadows = [];

    switch (state) {
      case OptionState.normal:
        bgColor = const Color(0xFF131D3B);
        borderColor = const Color(0xFF2563EB).withValues(alpha: 0.6);
        letterColor = const Color(0xFFF59E0B);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ];
        break;
      case OptionState.selected:
        bgColor = const Color(0xFFB45309);
        borderColor = const Color(0xFFFBBF24);
        letterColor = Colors.white;
        shadows = [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ];
        break;
      case OptionState.correct:
        bgColor = const Color(0xFF047857);
        borderColor = const Color(0xFF34D399);
        letterColor = Colors.white;
        shadows = [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.6),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ];
        break;
      case OptionState.wrong:
        bgColor = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFF87171);
        letterColor = Colors.white;
        shadows = [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.6),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ];
        break;
      case OptionState.disabled:
        bgColor = Colors.transparent;
        borderColor = Colors.transparent;
        letterColor = Colors.transparent;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: state == OptionState.normal ? 1.5 : 2.2),
              boxShadow: shadows,
            ),
            child: Row(
              children: [
                // Option Letter Badge (A, B, C, D)
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: state == OptionState.normal
                        ? const Color(0xFF1E293B)
                        : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: letterColor.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    optionLetters[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: letterColor,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Option Text
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),

                // State Indicator Icon
                if (state == OptionState.correct)
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22)
                else if (state == OptionState.wrong)
                  const Icon(Icons.cancel_rounded, color: Colors.white, size: 22)
                else if (state == OptionState.selected)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
