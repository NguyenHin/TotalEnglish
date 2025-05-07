import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';

class ListeningScreen extends StatefulWidget {
  final String lessonId;
  final Function(String activity, bool isCompleted)? onCompleted; // Thêm callback onCompleted

  const ListeningScreen({super.key, required this.lessonId, this.onCompleted});

  @override
  _ListeningScreenState createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  List<QueryDocumentSnapshot> _vocabularyList = [];
  List<QueryDocumentSnapshot> _selectedWords = [];
  List<String?> _vocabularyHints = []; // List để lưu hint cho mỗi trang
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLessonCompleted = false; // Theo dõi trạng thái hoàn thành của bài học
  final Set<int> _answeredCorrectly = {}; // ✅ Từ đã trả lời đúng

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .collection('vocabulary')
          .get();

      _vocabularyList = snapshot.docs;
      _selectRandomWords();

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải từ vựng. Lỗi: $error";
      });
    }
  }

  void _selectRandomWords() {
    if (_vocabularyList.length <= 10) {
      _selectedWords = List.from(_vocabularyList);
    } else {
      final random = Random();
      final selectedIndices = <int>{};
      while (selectedIndices.length < 10) {
        selectedIndices.add(random.nextInt(_vocabularyList.length));
      }
      _selectedWords = selectedIndices.map((index) => _vocabularyList[index]).toList();
    }
    _selectedWords.shuffle(); // 🔄 Shuffle
    _vocabularyHints = List.generate(_selectedWords.length, (_) => null); // Khởi tạo list hint cho từng trang
  }

  void _checkAnswer() async {
    if (_selectedWords.isNotEmpty && _currentPage < _selectedWords.length) {
      final correctWord = (_selectedWords[_currentPage].data() as Map<String, dynamic>?)?['word']?.toString().toLowerCase() ?? '';
      final correctMeaning = (_selectedWords[_currentPage].data() as Map<String, dynamic>?)?['meaning']?.toString() ?? '';
      final userAnswer = _controller.text.trim().toLowerCase();

      setState(() {
      if (userAnswer == correctWord) {
        if (!_answeredCorrectly.contains(_currentPage)) {
          _answeredCorrectly.add(_currentPage); // ✅ chỉ thêm nếu chưa đúng trước đó
          _updateProgress(); // ✅ cập nhật tiến độ
        }

        _vocabularyHints[_currentPage] = '$correctWord : $correctMeaning';
        updateStreak(); // 🔁
      } else {
        _vocabularyHints[_currentPage] = 'Không đúng, thử lại.';
      }
    });

      // Kiểm tra nếu đã hoàn thành tất cả các câu hỏi
      if (_currentPage == _selectedWords.length - 1 && _answeredCorrectly.length == _selectedWords.length) {
        setState(() {
          _isLessonCompleted = true;
        });
        await _completeLesson();
        // Gọi callback onCompleted khi hoàn thành
        if (widget.onCompleted != null) {
          widget.onCompleted!('listening', true);
        }
      }
    }
  }

  Future<void> _updateProgress() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final progressRef = FirebaseFirestore.instance.collection('user_progress').doc(userId);
    final snapshot = await progressRef.get();

    final currentCorrect = snapshot.data()?['correctAnswersCount'] ?? 0;
    final totalQuestions = _selectedWords.length;

    final newCorrect = currentCorrect + 1;
    final newProgress = (newCorrect / totalQuestions) * 100;

    await progressRef.update({
      'correctAnswersCount': newCorrect,
      'progress': newProgress,
    });
  }

  Future<void> _completeLesson() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final progressRef = FirebaseFirestore.instance.collection('user_progress').doc(userId);

    await progressRef.set({
      widget.lessonId: {
        'listening': 25,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.onCompleted != null && !_isLessonCompleted) {
          widget.onCompleted!('listening', false);
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                _buildBackButton(context),
                _buildListeningForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () {
          if (widget.onCompleted != null && !_isLessonCompleted) {
            widget.onCompleted!('listening', false);
          }
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  Widget _buildListeningForm(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_selectedWords.isEmpty) {
      return const Center(child: Text('Không có từ vựng cho bài luyện nghe.'));
    }

    return Positioned(
      top: 100,
      left: 22,
      right: 22,
      child: Column(
        children: [
          HeaderLesson(
            title: 'Listening (${_answeredCorrectly.length}/${_selectedWords.length})', // Hiển thị số câu đúng
            color: const Color(0xFF89B3D4),
          ),
          const SizedBox(height: 20),
          Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              _vocabularyHints[_currentPage] ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _vocabularyHints[_currentPage] == 'Không đúng, thử lại.' ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _selectedWords.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _controller.clear(); // Xóa nội dung trong TextField khi chuyển trang
                  // Không xóa hint khi chuyển trang, chỉ cần ẩn hint nếu chưa trả lời đúng
                });
              },
              itemBuilder: (context, index) {
                final wordData = _selectedWords[index].data() as Map<String, dynamic>?;
                final wordToSpeak = wordData?['word'] as String? ?? '';
                final isCorrect = _answeredCorrectly.contains(index);

                return Column(
                  children: [
                    PlayButton(
                      onPressed: () {
                        if (wordToSpeak.isNotEmpty) {
                          _ttsService.speak(wordToSpeak);
                        }
                      },
                      label: "Bấm vào đây để nghe",
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: 265,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F9FD),
                        borderRadius: BorderRadius.circular(20),
                        border: isCorrect ? Border.all(color: Colors.green, width: 2) : null, // Viền xanh nếu đúng
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: (_) {
                          // Khi người dùng bắt đầu nhập lại, ẩn đi hint chỉ cho trang hiện tại
                          if (_vocabularyHints[_currentPage] != '' && _controller.text.isNotEmpty) {
                            setState(() {
                              _vocabularyHints[_currentPage] = ''; // Ẩn hint khi người dùng nhập lại
                            });
                          }
                        },
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: InputDecoration(
                          hintText: isCorrect
                            ? ((_selectedWords[index].data() as Map<String, dynamic>?)?['word']?.toString() ?? '')
                            : 'Nhập từ vào đây',
                          hintStyle: TextStyle(color: isCorrect ? Colors.green : Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 30),
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF89B3D4),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Kiểm tra", // Đổi lại thành "Kiểm tra"
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_selectedWords.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _answeredCorrectly.contains(index)
                      ? Colors.green
                      : (_currentPage == index ? Colors.blue : Colors.grey.shade400),
                ),
              );
            }),
          ),
          const SizedBox(height: 15),
          Image.asset(
            'assets/icon/no_background.png',
            width: 200,
            height: 200,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    _ttsService.stop();
    super.dispose();
  }
}