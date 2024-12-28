import 'package:flutter/material.dart';

class CustomGradientQuestionButton extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final VoidCallback nextQuestion;

  const CustomGradientQuestionButton({
    Key? key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.nextQuestion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: nextQuestion,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 3),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              currentQuestionIndex == totalQuestions - 1
                  ? Icons.restart_alt
                  : Icons.arrow_forward,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              currentQuestionIndex == totalQuestions - 1
                  ? "Başa Dön"
                  : "Sonraki Soru",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
