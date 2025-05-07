import 'package:flutter/material.dart';
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Định nghĩa model cho một cặp từ và ảnh
class MatchingPair {
  final String word;
  final String imagePath;

  MatchingPair({required this.word, required this.imagePath});
}

class QuizScreen extends StatefulWidget {
  final String lessonId;
  final Function(String activity, bool isCompleted)? onCompleted; // Thêm callback onCompleted

  const QuizScreen({super.key, required this.lessonId, this.onCompleted});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _quizItems = []; // Danh sách các mục (từ hoặc ảnh) trong trò chơi
  List<int?> _currentlyFlippedIndices = [null, null]; // Danh sách index của hai ô đang được lật
  List<bool> _isCardFlipped = []; // Trạng thái lật của từng ô
  List<bool> _isCardMatched = []; // Trạng thái khớp của từng ô
  bool _isQuizOver = false; // Trạng thái trò chơi đã kết thúc
  bool _isLoadingData = true; // Trạng thái đang tải dữ liệu
  String _loadingErrorMessage = ''; // Thông báo lỗi khi tải dữ liệu

  @override
  void initState() {
    super.initState();
    _loadQuizVocabulary(widget.lessonId);
  }

  // Tải danh sách từ vựng cho quiz từ Firestore
  Future<void> _loadQuizVocabulary(String lessonId) async {
    setState(() {
      _isLoadingData = true;
      _loadingErrorMessage = '';
    });
    try {
      final vocabularySnapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .collection('vocabulary')
          .get();

      final List<MatchingPair> vocabularyPairs = vocabularySnapshot.docs
          .map((doc) => MatchingPair(
                word: doc.data()['word'] as String? ?? '',
                imagePath: doc.data()['imageURL'] as String? ?? '',
              ))
          .where((pair) => pair.word.isNotEmpty && pair.imagePath.isNotEmpty)
          .toList();

      vocabularyPairs.shuffle();
      final selectedPairs = vocabularyPairs.take(10).toList();

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

  // Làm mới trò chơi
  void _resetQuiz() {
    _loadQuizVocabulary(widget.lessonId);
  }

  // Xử lý sự kiện lật một ô
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
          // Delay ngắn trước khi kiểm tra khớp
          Future.delayed(const Duration(milliseconds: 300), _checkMatch);
        }
      });
    }
  }

  // Kiểm tra xem hai ô đã lật có khớp nhau không
  void _checkMatch() {
    final firstIndex = _currentlyFlippedIndices[0];
    final secondIndex = _currentlyFlippedIndices[1];

    if (firstIndex != null && secondIndex != null) {
      final firstItem = _quizItems[firstIndex];
      final secondItem = _quizItems[secondIndex];

      if (firstItem['match'] == secondItem['match']) {
        // Tìm thấy cặp khớp
        setState(() {
          _isCardMatched[firstIndex] = true;
          _isCardMatched[secondIndex] = true;
          _currentlyFlippedIndices = [null, null];
          if (_isCardMatched.every((matched) => matched)) {
            _isQuizOver = true;
            updateStreak(); //update streak khi hoan thanh
            // **Vẫn không gọi onCompleted ở đây**
          }
        });
      } else {
        // Không khớp, lật lại sau một khoảng thời gian
        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            _isCardFlipped[firstIndex] = false;
            _isCardFlipped[secondIndex] = false;
            _currentlyFlippedIndices = [null, null];
          });
        });
      }
    }
  }

  // Xây dựng giao diện cho một ô
  Widget _buildQuizCard(BuildContext context, int index) {
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
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FittedBox(
                                  child: Text(
                                    _quizItems[index]['value'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(
                                  _quizItems[index]['value'],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.image_not_supported)),
                                ),
                              ),
                      ),
                    )
                  : Container(
                      key: ValueKey('unflipped-$index'),
                      decoration: BoxDecoration(
                        color: Colors.blue[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Icon(Icons.question_mark, color: Colors.white, size: 30)),
                    ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.onCompleted != null) {
          widget.onCompleted!('quiz', _isQuizOver); // Gọi với true nếu đã hoàn thành
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 55),
                    const HeaderLesson(
                      title: 'Quiz',
                      color: Color(0xFFE0A96D),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoadingData)
                      const Center(child: CircularProgressIndicator())
                    else if (_loadingErrorMessage.isNotEmpty)
                      Center(child: Text(_loadingErrorMessage, style: const TextStyle(color: Colors.red)))
                    else
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _quizItems.length,
                          itemBuilder: (context, index) => _buildQuizCard(context, index),
                        ),
                      ),
                    if (_isQuizOver)
                      Column(
                        children: [
                          const Text(
                            '✨ Chúc mừng bạn đã hoàn thành! ✨',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _isLoadingData ? null : _resetQuiz,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF89B3D4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Chơi lại',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  if (widget.onCompleted != null) {
                                    widget.onCompleted!('quiz', true);
                                  }
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF89B3D4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Về bài học',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: _isLoadingData ? null : _resetQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF89B3D4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Chơi lại',
                          style: TextStyle(color: Colors.white),
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
                    if (widget.onCompleted != null) {
                      widget.onCompleted!('quiz', _isQuizOver); // Gọi với true nếu đã hoàn thành
                    }
                    Navigator.pop(context);
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