import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';
 // Đảm bảo đường dẫn đúng

class ListeningScreen extends StatefulWidget {
  final String lessonId;

  const ListeningScreen({super.key, required this.lessonId});

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
  String? _vocabularyHint = '';
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isLoading = true;
  String? _errorMessage;

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
      print("Lỗi tải từ vựng cho bài học ${widget.lessonId}: $error");
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
    // THÊM DÒNG NÀY VÀO ĐÂY ĐỂ XÁO TRỘN DANH SÁCH
    _selectedWords.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
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
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () {
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
          const HeaderLesson(
            title: 'Listening',
            color: Color(0xFF89B3D4),
          ),
          const SizedBox(height: 20),
          Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              _vocabularyHint ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _vocabularyHint == 'Không đúng, thử lại.' ? Colors.red : Colors.green,
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
                  _controller.clear();
                  _vocabularyHint = '';
                });
              },
              itemBuilder: (context, index) {
                final wordData = _selectedWords[index].data() as Map<String, dynamic>?;
                final wordToSpeak = wordData?['word'] as String? ?? '';
                return Column(
                  children: [
                    PlayButton(
                      onPressed: () {
                        if (wordToSpeak.isNotEmpty) {
                          _ttsService.speak(wordToSpeak);
                        } else {
                          print("Không có từ để phát âm ở trang này.");
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
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập từ vào đây',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 30,
                          ),
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
                      child: const Text(
                        "Kiểm tra",
                        style: TextStyle(
                          color: Colors.white,
                        ),
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
                  color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
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

  void _checkAnswer() {
    if (_selectedWords.isNotEmpty && _currentPage < _selectedWords.length) {
      final correctWord = (_selectedWords[_currentPage].data() as Map<String, dynamic>?)?['word']?.toString().toLowerCase() ?? '';
      final correctMeaning = (_selectedWords[_currentPage].data() as Map<String, dynamic>?)?['meaning']?.toString() ?? '';
      final userAnswer = _controller.text.trim().toLowerCase();

      setState(() {
        if (userAnswer == correctWord) {
          _vocabularyHint = '$correctWord : $correctMeaning';
        } else {
          _vocabularyHint = 'Không đúng, thử lại.';
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    _ttsService.stop();
    super.dispose();
  }
}