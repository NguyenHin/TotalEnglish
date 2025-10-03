import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Function(String activity, bool isCompleted)? onCompleted;

  const QuizScreen({super.key, required this.lessonId, this.onCompleted});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _quizItems = [];
  List<int?> _currentlyFlippedIndices = [null, null];
  List<bool> _isCardFlipped = [];
  List<bool> _isCardMatched = [];
  bool _isQuizOver = false;
  bool _isLoadingData = true;
  String _loadingErrorMessage = '';
  bool _streakUpdated = false;
  bool _showCompletionDialog = false;

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
        _quizItems.add({'type': 'word', 'value': pair.word, 'match': pair});
        _quizItems.add({'type': 'image', 'value': pair.imagePath, 'match': pair});
      }
      _quizItems.shuffle();

      _isCardFlipped = List.generate(_quizItems.length, (_) => false);
      _isCardMatched = List.generate(_quizItems.length, (_) => false);
      _isQuizOver = false;
      _currentlyFlippedIndices = [null, null];

      setState(() {
        _isLoadingData = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingData = false;
        _loadingErrorMessage = "Lỗi tải dữ liệu quiz: $error";
      });
    }
  }

  void _handleCardTap(int index) {
    if (!_isCardFlipped[index] &&
        _currentlyFlippedIndices[1] == null &&
        !_isCardMatched[index] &&
        !_isQuizOver &&
        !_isLoadingData) {
      setState(() {
        _isCardFlipped[index] = true;
        if (_currentlyFlippedIndices[0] == null) {
          _currentlyFlippedIndices[0] = index;
        } else {
          _currentlyFlippedIndices[1] = index;
          Future.delayed(const Duration(milliseconds: 300), _checkMatch);
        }
      });
    }
  }

  void _checkMatch() {
    final firstIndex = _currentlyFlippedIndices[0];
    final secondIndex = _currentlyFlippedIndices[1];

    if (firstIndex != null && secondIndex != null) {
      final firstItem = _quizItems[firstIndex];
      final secondItem = _quizItems[secondIndex];

      if (firstItem['match'] == secondItem['match']) {
        setState(() {
          _isCardMatched[firstIndex] = true;
          _isCardMatched[secondIndex] = true;
          _currentlyFlippedIndices = [null, null];

          if (!_streakUpdated) {
            _streakUpdated = true;
            updateStreak();
          }

          if (_isCardMatched.every((m) => m)) {
            _isQuizOver = true;
            _showCompletionDialog = true;
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _isCardFlipped[firstIndex] = false;
            _isCardFlipped[secondIndex] = false;
            _currentlyFlippedIndices = [null, null];
          });
        });
      }
    }
  }

  Widget _buildQuizCard(int index) {
    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isCardMatched[index]
              ? const SizedBox.shrink(key: ValueKey('matched'))
              : _isCardFlipped[index]
                  ? Container(
                      key: ValueKey('flipped-$index'),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: _quizItems[index]['type'] == 'word'
                            ? FittedBox(
                                child: Text(
                                  _quizItems[index]['value'],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Image.network(
                                _quizItems[index]['value'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                      ),
                    )
                  : Container(
                      key: ValueKey('unflipped-$index'),
                      decoration: BoxDecoration(
                        color: Colors.blue[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Icon(Icons.question_mark,
                              color: Colors.white, size: 30)),
                    ),
        ),
      ),
    );
  }

  void _resetQuiz() {
    _loadQuizVocabulary(widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onCompleted?.call('quiz', _isQuizOver);
        return true;
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
                    const HeaderLesson(
                      title: 'Mini game',
                      color: Color(0xFFE0A96D),
                    ),
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
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _quizItems.length,
                          itemBuilder: (context, index) => _buildQuizCard(index),
                        ),
                      ),
                    const SizedBox(height: 15),
                    // Nút chơi lại gọn hơn
                    if (!_isQuizOver)
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: SizedBox(
      width: double.infinity, // chiếm toàn chiều ngang
      child: ElevatedButton(
        onPressed: _isLoadingData ? null : _resetQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF89B3D4), // màu xanh nổi bật
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // bo tròn
          ),
          elevation: 5,
        ),
        child: const Text(
          'Chơi lại',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                  onPressed: () {
                    widget.onCompleted?.call('quiz', _isQuizOver);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.chevron_left, size: 28),
                ),
              ),
              // Dialog hiển thị khi hoàn thành
              if (_showCompletionDialog)
                FinalScoreDialog(
                  wrongIndexes: [],        // bỏ nút làm lại
                  onRetryWrong: () {},     // không dùng
                  onComplete: () {
                    widget.onCompleted?.call('quiz', true);
                    setState(() {
                      _showCompletionDialog = false;
                    });
                    Navigator.pop(context);
                  },
                  title: "Trò chơi đã hoàn thành!",  // tiêu đề tùy chỉnh
                  message: null,                       // không hiển thị message, chỉ title
              ),

            ],
          ),
        ),
      ),
    );
  }
}
