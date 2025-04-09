import 'package:flutter/material.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'dart:async';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _quizFinished = false;
  bool _answerSelected = false;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  final List<Map<String, Object>> _questions = const [
    {
      'questionText': '1. What is your name?',
      'answers': [
        {'text': 'A. My name is John.', 'isCorrect': true},
        {'text': 'B. His name is John.', 'isCorrect': false},
        {'text': 'C. Her name is John.', 'isCorrect': false},
      ],
    },
    {
      'questionText': '2. How old are you?',
      'answers': [
        {'text': 'A. I am five years old.', 'isCorrect': false},
        {'text': 'B. I am seven years old.', 'isCorrect': true},
        {'text': 'C. She is seven years old.', 'isCorrect': false},
      ],
    },
    {
      'questionText': '3. Where are you from?',
      'answers': [
        {'text': 'A. I am from Vietnam.', 'isCorrect': true},
        {'text': 'B. He is from Vietnam.', 'isCorrect': false},
        {'text': 'C. They are from Vietnam.', 'isCorrect': false},
      ],
    },
    {
      'questionText': '4. What do you like to do?',
      'answers': [
        {'text': 'A. I like playing football.', 'isCorrect': true},
        {'text': 'B. He likes playing football.', 'isCorrect': false},
        {'text': 'C. They like playing football.', 'isCorrect': false},
      ],
    },
    {
      'questionText': '5. Nice to meet you.',
      'answers': [
        {'text': 'A. Nice to meet you too.', 'isCorrect': true},
        {'text': 'B. Goodbye.', 'isCorrect': false},
        {'text': 'C. See you later.', 'isCorrect': false},
      ],
    },
  ];
  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsedTime = _elapsedTime + const Duration(milliseconds: 100);
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _answerQuestion(bool isCorrect) {
    if (!_answerSelected) {
      setState(() {
        _answerSelected = true;
        if (isCorrect) {
          _correctAnswers++;
          _showSnackBar('✅ Correct!', isCorrect: true);
          _animateCorrectAnswer();
        } else {
          _showSnackBar('❌ Incorrect!', isCorrect: false);
        }
      });
    }
  }
  void _animateCorrectAnswer() {
    _animationController?.reset();
    _animationController?.forward();
  }

  void _showSnackBar(String message, {required bool isCorrect}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isCorrect ? Colors.green[400] : Colors.red[400],
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  void _nextQuestion() {
    setState(() {
      _answerSelected = false;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _quizFinished = true;
        _timer?.cancel();
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _quizFinished = false;
      _answerSelected = false;
      _elapsedTime = Duration.zero;
      _startTimer();
    });
  }
  String _getCongratulatoryMessage() {
    double percentage = _correctAnswers / _questions.length;
    if (percentage >= 0.8) {
      return '✨ Tuyệt vời! Bạn đã làm rất tốt! ✨';
    } else if (percentage >= 0.5) {
      return '👍 Chúc mừng bạn! Hãy cố gắng hơn nữa nhé! 👍';
    } else {
      return '💪 Đừng lo lắng! Hãy ôn tập và thử lại nhé! 💪';
    }
  }

  TextStyle _getCongratulatoryTextStyle() {
    double percentage = _correctAnswers / _questions.length;
    if (percentage >= 0.8) {
      return const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: Colors.amber,
      );
    } else if (percentage >= 0.5) {
      return const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: Colors.lightBlue,
      );
    } else {
      return const TextStyle(
        fontSize: 18,
        color: Colors.orangeAccent,
      );
    }
  }

  Color _getScoreColor() {
    double percentage = _correctAnswers / _questions.length;
    if (percentage >= 0.7) {
      return Colors.green[600]!;
    } else {
      return Colors.red[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeaderLesson(
                title: 'Quiz Finished!',
                color: Color(0xFF89B3D4),
              ),
              const SizedBox(height: 30),
              Text(
                'Your score:',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '$_correctAnswers / ${_questions.length}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _getCongratulatoryMessage(),
                textAlign: TextAlign.center,
                style: _getCongratulatoryTextStyle(),
              ),
              const SizedBox(height: 15),
              Text(
                'Time taken: ${_formatTime(_elapsedTime)}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _resetQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90DA95),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                ),
                child: const Text('Restart Quiz', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Lessons', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
              ),
            ],
          ),
        ),
      );
    }
    final currentQuestion = _questions[_currentQuestionIndex];
    final answers = currentQuestion['answers'] as List<Map<String, Object>>;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFE),
      body: Stack(
        children: [
          _buildBackButton(context),
          _buildHeaderLesson(),
          Positioned(
            top: 180,
            left: 20,
            right: 20,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentQuestion['questionText'] as String,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 35),
                  ...answers.map((answer) {
                    return ScaleTransition(
                      scale: _scaleAnimation!,
                      child: _buildAnswerButton(
                        context,
                        answer['text'].toString().substring(3).trim(),
                        isCorrect: answer['isCorrect'] as bool,
                        onPressed: _answerSelected
                            ? null
                            : () => _answerQuestion(answer['isCorrect'] as bool),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 25),
                  if (_answerSelected)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAC10D5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Next', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatTime(_elapsedTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF455A64)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nút quay lại
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 10,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 26, color: Color(0xFF546E7A)),
      ),
    );
  }

  // Tiêu đề bài học
  Widget _buildHeaderLesson() {
    return const Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: HeaderLesson(
        title: 'Quiz Time!',
        color: Color(0xFF89B3D4),
      ),
    );
  }
  // Button đáp án
  Widget _buildAnswerButton(
      BuildContext context,
      String text, {
        bool isCorrect = false,
        VoidCallback? onPressed,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFF80CBC4)),
          ),
          elevation: 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF37474F)),
                textAlign: TextAlign.left,
              ),
            ),
            if (_answerSelected && onPressed == null)
              Icon(
                isCorrect ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                color: isCorrect ? Colors.green[400] : Colors.red[400],
              ),
          ],
        ),
      ),
    );
  }
}