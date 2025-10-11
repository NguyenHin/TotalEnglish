import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flip_card/flip_card.dart';
import 'package:total_english/widgets/exit_dialog.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/final_score_dialog.dart';
import 'package:total_english/services/streak_services.dart';

class MatchingPair {
  final String word;
  final String imagePath;

  MatchingPair({required this.word, required this.imagePath});
}

class QuizScreen extends StatefulWidget {
  final String lessonId;
  final Function(Map<String, dynamic> result)? onCompleted;

  const QuizScreen({
    super.key,
    required this.lessonId,
    this.onCompleted,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _quizItems = [];
  List<int?> _currentlyFlippedIndices = [null, null];
  List<bool> _isCardFlipped = [];
  List<bool> _isCardMatched = [];
  bool _isLoadingData = true;
  String _loadingErrorMessage = '';
  final Color _themeColor = const Color(0xFFD3E6F6);

  @override
  void initState() {
    super.initState();
    _loadQuizVocabulary(widget.lessonId);
  }

  Future<void> _loadQuizVocabulary(String lessonId) async {
    setState(() {
      _isLoadingData = true;
      _loadingErrorMessage = '';
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .collection('vocabulary')
          .get();

      final vocabPairs = snapshot.docs
          .map((doc) => MatchingPair(
                word: doc.data()['word'] ?? '',
                imagePath: doc.data()['imageURL'] ?? '',
              ))
          .where((pair) => pair.word.isNotEmpty && pair.imagePath.isNotEmpty)
          .toList();

      vocabPairs.shuffle();
      final selectedPairs = vocabPairs.take(10).toList();

      _quizItems = [];
      for (final pair in selectedPairs) {
        _quizItems.add({
          'type': 'word',
          'value': pair.word,
          'match': pair,
          'flipCardKey': GlobalKey<FlipCardState>()
        });
        _quizItems.add({
          'type': 'image',
          'value': pair.imagePath,
          'match': pair,
          'flipCardKey': GlobalKey<FlipCardState>()
        });
      }
      _quizItems.shuffle();

      _isCardFlipped = List.generate(_quizItems.length, (_) => false);
      _isCardMatched = List.generate(_quizItems.length, (_) => false);
      _currentlyFlippedIndices = [null, null];

      setState(() => _isLoadingData = false);
    } catch (error) {
      setState(() {
        _isLoadingData = false;
        _loadingErrorMessage = "Lỗi tải dữ liệu quiz: $error";
      });
    }
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExitDialog(
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    return result ?? false;
  }

  void _handleCardTap(int index) {
    if (!_isCardFlipped[index] &&
        _currentlyFlippedIndices[1] == null &&
        !_isCardMatched[index] &&
        !_isLoadingData) {
      (_quizItems[index]['flipCardKey'] as GlobalKey<FlipCardState>)
          .currentState
          ?.toggleCard();

      setState(() {
        _isCardFlipped[index] = true;
        if (_currentlyFlippedIndices[0] == null) {
          _currentlyFlippedIndices[0] = index;
        } else {
          _currentlyFlippedIndices[1] = index;
          Future.delayed(const Duration(milliseconds: 500), _checkMatch);
        }
      });
    }
  }

  void _checkMatch() {
    final firstIndex = _currentlyFlippedIndices[0];
    final secondIndex = _currentlyFlippedIndices[1];

    if (firstIndex == null || secondIndex == null) return;

    final firstItem = _quizItems[firstIndex];
    final secondItem = _quizItems[secondIndex];

    if (firstItem['match'] == secondItem['match']) {
      setState(() {
        _isCardMatched[firstIndex] = true;
        _isCardMatched[secondIndex] = true;
        _currentlyFlippedIndices = [null, null];

        // ✅ Khi tất cả đã khớp → coi như hoàn thành game
        if (_isCardMatched.every((m) => m)) {
          _showFinalScore();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        (_quizItems[firstIndex]['flipCardKey'] as GlobalKey<FlipCardState>)
            .currentState
            ?.toggleCard();
        (_quizItems[secondIndex]['flipCardKey'] as GlobalKey<FlipCardState>)
            .currentState
            ?.toggleCard();

        setState(() {
          _isCardFlipped[firstIndex] = false;
          _isCardFlipped[secondIndex] = false;
          _currentlyFlippedIndices = [null, null];
        });
      });
    }
  }

  void _showFinalScore() async {
    final totalPairs = _quizItems.length ~/ 2;
    final correct = totalPairs;
    const progress = 100.0;

    await updateStreak();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinalScoreDialog(
        correct: correct,
        total: totalPairs,
        wrongIndexes: const [],
        onRetryWrong: _resetQuiz, // ✅ chỉ là chơi lại toàn bộ
        onComplete: () {
          Navigator.pop(context); // đóng dialog

          // ✅ Trả kết quả về LessonMenu
          Navigator.pop(context, {
            'completedActivity': 'quiz',
            'correctCount': correct,
            'totalCount': totalPairs,
            'progress': progress,
          });
        },
      ),
    );
  }


  


  void _resetQuiz() {
    _loadQuizVocabulary(widget.lessonId);
  }

  Widget _buildQuizCard(int index) {
    final item = _quizItems[index];
    final isMatched = _isCardMatched[index];

    if (isMatched) {
      return const SizedBox.shrink();
    }

    final Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Center(
        child: item['type'] == 'word'
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: FittedBox(
                  child: Text(
                    item['value'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.network(
                  item['value'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported,
                          size: 36, color: Colors.black),
                ),
              ),
      ),
    );

    final Widget cardCover = Container(
      decoration: BoxDecoration(
        color: _themeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
      ),
      child: const Center(
        child: Icon(Icons.psychology_alt, color: Colors.white, size: 36),
      ),
    );

    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: FlipCard(
        key: item['flipCardKey'],
        direction: FlipDirection.HORIZONTAL,
        flipOnTouch: false,
        speed: 400,
        front: cardCover,
        back: cardContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          Navigator.pop(context); // không gửi kết quả (vì chưa hoàn thành)
        }
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 55),
                    HeaderLesson(title: 'Mini game', color: _themeColor),
                    const SizedBox(height: 20),
                    if (_isLoadingData)
                      const Center(child: CircularProgressIndicator())
                    else if (_loadingErrorMessage.isNotEmpty)
                      Center(
                        child: Text(
                          _loadingErrorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _quizItems.length,
                          itemBuilder: (context, index) =>
                              _buildQuizCard(index),
                        ),
                      ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingData ? null : _resetQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF89B3D4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Chơi lại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 30,
                left: 10,
                child: IconButton(
                  onPressed: () async {
                    final shouldExit = await _showExitDialog(context);
                    if (shouldExit) {
                      Navigator.pop(context);
                    }
                  },

                  icon: const Icon(Icons.chevron_left, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
