import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:safaksayar/widgets/custom_question_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int selectedOption = -1; // Kullanıcının seçtiği seçenek
  bool isCorrect = false; // Doğru cevap mı?
  bool showAnswer = false; // Cevap gösteriliyor mu?
  late ConfettiController _confettiController;
  int score = 0; // Kullanıcı puanı
  late List<Map<String, dynamic>> questions; // Rastgele sorular

  // Soruların listesi
  final List<Map<String, dynamic>> allQuestions = [
    {
      "question": "Hasbihal, ne demektir?",
      "options": ["Gürültü", "Geçmiş", "Sohbet", "Özlem"],
      "answerIndex": 2,
    },
    {
      "question": '"Azı dişi" hangisinin eş anlamlısıdır?',
      "options": ["Sindirici diş", "Öğütücü diş", "Koparıcı diş", "Kesici diş"],
      "answerIndex": 1,
    },
    {
      "question": 'Hangisi "bıkmak" anlamına gelir?',
      "options": [
        "Hizaya gelmek",
        "Kıvamına gelmek",
        "Gına gelmek",
        "Yola gelmek"
      ],
      "answerIndex": 2,
    },
    {
      "question":
          '"Mavi, lacivert, mor ve bu renklerin tonları" hangisinin sözlük tanımıdır?',
      "options": [
        "Sıcak renkler",
        "Soğuk renkler",
        "Ilık renkler",
        "Serin renkler"
      ],
      "answerIndex": 1,
    },
    {
      "question": '"Siklamen" adlı bitkinin diğer adı nedir?',
      "options": ["Tavşankulağı", "Aslanağzı", "Kasımpatı", "Kaynanadili"],
      "answerIndex": 0,
    },
    {
      "question":
          'Azerbaycan bayrağının eşit genişlikteki üç yatay parçasının yukarıdan aşağıya, doğru sıralaması nasıldır?',
      "options": [
        "Kırmızı, mavi, yeşil",
        "Mavi, yeşil, kırmızı",
        "Yeşil, kırmızı, mavi",
        "Mavi, kırmızı, yeşil"
      ],
      "answerIndex": 3,
    },
    {
      "question":
          'Hangisi atletizmde "dekatlon"da yarışan sporcuların mücadele ettikleri dallardan biri değildir?',
      "options": ["Cirit atma", "Yüzme", "100 metre koşusu", "Sırıkla atlama"],
      "answerIndex": 1,
    },
    {
      "question": "Altay Dağları'na tırmanan bir dağcı hangisinde olabilir?",
      "options": ["İzmir", "Kahire", "Bombay", "Moğolistan"],
      "answerIndex": 3,
    },
    {
      "question": "Kaçkar Dağı, hangi coğrafi bölgenin en yüksek dağıdır?",
      "options": ["Ege", "Marmara", "Akdeniz", "Karadeniz"],
      "answerIndex": 3,
    },
    {
      "question": "Türkiye'nin nüfusu en az olan bölgesi hangisidir?",
      "options": [
        "Karadeniz Bölgesi",
        "Ege Bölgesi",
        "Doğu Anadolu Bölgesi",
        "Güneydoğu Anadolu Bölgesi"
      ],
      "answerIndex": 2,
    },
    {
      "question":
          "Türkçeye Fransızcadan geçen 'doktor' kelimesinin kökeninin anlamı nedir?",
      "options": ["Gözlemlemek", "Araştırmak", "Öğretmek", "Tedavi etmek"],
      "answerIndex": 2,
    },
    {
      "question": '"Bonjur" hangi anlamda kullanılan bir sözdür?',
      "options": [
        "Günaydın, merhaba",
        "Güle güle, görüşürüz",
        "Kendine iyi bak, hoşça kal",
        "İyi uykular, tatlı rüyalar"
      ],
      "answerIndex": 0,
    },
    {
      "question":
          'Fen bilimleri derslerinde "camın kırılması, buzun erimesi, kâğıdın yırtılması" hangisine örnek olarak gösterilir?',
      "options": [
        "Kimyasal değişim",
        "Fiziksel değişim",
        "Zihniyet değişimi",
        "Hava değişimi"
      ],
      "answerIndex": 1,
    },
    {
      "question":
          'Futbolda, özellikle anlaşmazlıklara sebep olan pozisyonları engellemeyi hedefleyerek kullanılan sistemin "VAR" şeklinde kısaltmasının açılımı nedir?',
      "options": [
        "Video yardımcı hakem",
        "Video araştırma raporlama",
        "Video inceleme odası",
        "Video analiz rehberi"
      ],
      "answerIndex": 0,
    },
    {
      "question": 'Hangi iki Osmanlı padişahı kardeş değildir?',
      "options": [
        "II. Mustafa ve III. Ahmed",
        "III. Selim ve II. Mahmud",
        "Abdülmecid ve Abdülaziz",
        "V. Mehmed ve V. Murad"
      ],
      "answerIndex": 1,
    },
    {
      "question":
          '4 yanlışın 1 doğruyu götürdüğü 100 soruluk çoktan seçmeli bir sınavda 9 boşu ve 8 yanlışı olan birinin neti kaçtır?',
      "options": ["83", "81", "79", "77"],
      "answerIndex": 1,
    },
    {
      "question":
          "Osmanlı Devleti'nde tahtta en kısa süre kalan padişah kimdir?",
      "options": ["II. Mustafa", "III. Selim", "IV. Mehmed", "V. Murad"],
      "answerIndex": 3,
    },
    {
      "question": "Türkiye'nin en az ilçesi olan ili hangisidir?",
      "options": ["Tokat", "Kırıkkale", "Uşak", "Bayburt"],
      "answerIndex": 3,
    },
    {
      "question":
          "100 metre koşusunda koşucuların vücudunun ilk olarak hangi kısmının bitiş çizgisini geçtiği an, yarışı tamamladıkları kabul edilir?",
      "options": ["Ayak", "Kol", "Kafa", "Gövde"],
      "answerIndex": 3,
    },

    // Buraya 100+ soru ekleyebilirsiniz
  ];

  int currentQuestionIndex = 0; // Şu anki soru

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadScore();
    _shuffleQuestions(); // Soruları rastgele sırala
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Soruları karıştır
  void _shuffleQuestions() {
    questions = List<Map<String, dynamic>>.from(allQuestions);
    questions.shuffle(Random());
  }

  void checkAnswer(int index) {
    setState(() {
      selectedOption = index;
      showAnswer = true;
      isCorrect = index == questions[currentQuestionIndex]['answerIndex'];

      if (isCorrect) {
        score += 10; // Doğru cevap için 10 puan ekle
        _saveScore(); // Güncellenen puanı kaydet
        _confettiController.play();
      }
    });
  }

  void nextQuestion() {
    setState(() {
      // Son soruya geldiğinde başa döner
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        currentQuestionIndex =
            0; // İsterseniz sona geldiğinde "Tebrikler" ekranı gösterebilirsiniz
        _shuffleQuestions();
      }

      // Varsayılan değerlere sıfırla
      selectedOption = -1;
      showAnswer = false;
      isCorrect = false;
    });
  }

  // Puanı yükleme
  Future<void> _loadScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('score') ??
          0; // Kaydedilmiş puanı yükle veya sıfırdan başlat
    });
  }

  // Puanı kaydetme
  Future<void> _saveScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', score);
  }

  // Puanı sıfırlama fonksiyonu
  Future<void> _resetScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      score = 0; // Puanı sıfırla
    });
    await prefs.setInt('score', 0); // SharedPreferences'ta sıfır olarak kaydet
  }

  Future<void> _showResetConfirmationDialog() async {
    bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Puanı Sıfırla"),
          content: Text("Puanlar silinecek. Emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Hayır
              child: Text("Hayır"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Evet
              child: Text("Evet"),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      _resetScore(); // Kullanıcı onayladıysa puanı sıfırla
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Soru-Cevap"),
        backgroundColor: Colors.blueAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "Puan: $score",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            onPressed: _showResetConfirmationDialog,
            icon: Icon(Icons.refresh), // Sıfırlama simgesi
            tooltip: "Puanı Sıfırla",
          ),
        ],
      ),
      body: Column(
        children: [
          // Soru
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              currentQuestion['question'],
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // Şıklar
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion['options'].length,
              itemBuilder: (context, index) {
                bool isSelected = selectedOption == index;
                bool isCorrectOption =
                    showAnswer && index == currentQuestion['answerIndex'];

                return GestureDetector(
                  onTap: showAnswer ? null : () => checkAnswer(index),
                  child: Card(
                    color: isSelected
                        ? (isCorrect ? Colors.green : Colors.red)
                        : (isCorrectOption ? Colors.green : Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        currentQuestion['options'][index],
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Konfeti Efekti
          if (showAnswer && isCorrect)
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ),

          // Cevap Geri Bildirimi
          if (showAnswer)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isCorrect
                    ? "Doğru Cevap!"
                    : "Yanlış Cevap! Doğru: ${currentQuestion['options'][currentQuestion['answerIndex']]}",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ),

          // Yeni Soru Butonu
          if (showAnswer)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomGradientQuestionButton(
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.length,
                nextQuestion: nextQuestion,
              ),
            ),
        ],
      ),
    );
  }
}
