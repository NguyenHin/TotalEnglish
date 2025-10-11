import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:total_english/widgets/exit_dialog.dart';
import 'package:total_english/widgets/final_score_dialog.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:total_english/widgets/animated_overlay_dialog.dart';

class SpeakingScreen extends StatefulWidget {
  final String lessonId;
  

  const SpeakingScreen({super.key, required this.lessonId,});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  List<QueryDocumentSnapshot> _vocabularyList = [];
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;
  final TextToSpeechService _ttsService = TextToSpeechService();
  String? _speakingHint = '';
  double _micScale = 1.0;
  String _micButtonLabel = 'Nói';
  Timer? _listeningTimer; // Thêm biến Timer
  bool _isLessonCompleted = false; // Theo dõi trạng thái hoàn thành

  // thêm mới 
  bool _showOverlayDialog = false;
  bool _lastAnswerCorrect = false;
  String _lastCorrectWord = '';


  final Set<int> _spokenCorrectly = {}; // Theo dõi các từ đã nói đúng

 final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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
      setState(() {
        _isLoading = false;
      });

      // ⭐ MỚI: auto play từ đầu tiên
      if (_vocabularyList.isNotEmpty) {
        _autoPlayWord(0);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải từ vựng. Lỗi: $error";
      });
      print("Lỗi tải từ vựng cho bài học ${widget.lessonId}: $error");
    }
  }

  // ⭐ MỚI: Hàm auto play word
  Future<void> _autoPlayWord(int index) async {
    if (index < 0 || index >= _vocabularyList.length) return;
    final wordData = _vocabularyList[index].data() as Map<String, dynamic>?;
    final word = wordData?['word'] as String? ?? '';

    if (word.isNotEmpty) {
      _isPlayingNotifier.value = true;
      await _ttsService.speak(word);
      _isPlayingNotifier.value = false;
    }
  }


  void _startListening() async {
  _cancelListeningTimer(); // Hủy timer cũ nếu có

  if (!_isListening) {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
            _micButtonLabel = 'Nói';
            _stopMicPulse();
          });
          _cancelListeningTimer(); // Hủy timer
        } else if (status == 'listening') {
          setState(() {
            _micButtonLabel = 'Đang nghe...';
          });
          _startListeningTimer(); // Reset timer mỗi khi nghe lại
        }
      },
      onError: (error) {
        print("Speech error: $error");
        setState(() {
          _isListening = false;
          _micButtonLabel = 'Nói';
          _stopMicPulse();
        });
        _cancelListeningTimer();
      },
    );

    if (available && !_speech.isListening) {
      await _speech.stop(); // Đảm bảo dừng session trước đó nếu còn kẹt
      await Future.delayed(const Duration(milliseconds: 200)); // Nhẹ để đảm bảo mic sẵn sàng

      setState(() {
        _isListening = true;
        _micButtonLabel = 'Đang nghe...';
      });

      _startMicPulse();
      _recognizedText = '';
      _speech.listen(
        localeId: 'en_US',
        listenMode: stt.ListenMode.confirmation,
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            print("Recognized: $_recognizedText");
            if (result.finalResult) {
              _checkSpokenWord();
            }
          });
        },
      );
      _startListeningTimer(); // Đặt lại timer
    } else {
      setState(() {
        _isListening = false;
        _micButtonLabel = 'Nói';
        _stopMicPulse();
      });
      _cancelListeningTimer();
    }
  } else {
    _stopListening();
  }
}


  void _startListeningTimer() {
    _listeningTimer = Timer(const Duration(seconds: 4), () {
      if (_isListening) {
        _stopListening();
      }
    });
  }

  void _cancelListeningTimer() {
    _listeningTimer?.cancel();
    _listeningTimer = null;
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _micButtonLabel = 'Nói';
      _stopMicPulse();
    });
    _speech.stop();
    _cancelListeningTimer(); // Hủy timer khi dừng thủ công
    _checkSpokenWord();
  }

  void _startMicPulse() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isListening) {
        setState(() {
          _micScale = 1.2;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_isListening) {
            setState(() {
              _micScale = 1.0;
            });
            _startMicPulse();
          }
        });
      }
    });
  }

  void _stopMicPulse() {
    setState(() {
      _micScale = 1.0;
    });
  }

  void _checkSpokenWord() {
    if (_vocabularyList.isEmpty || _currentPage >= _vocabularyList.length) return;

    final wordData = _vocabularyList[_currentPage].data() as Map<String, dynamic>?;
    final correctWord = wordData?['word'] as String? ?? '';
    final spokenWord = _recognizedText.trim().toLowerCase();
    final targetWord = correctWord.toLowerCase();

    bool isCorrect = spokenWord == targetWord;
    String hintMessage = '';

    if (isCorrect) {
      _spokenCorrectly.add(_currentPage);
      hintMessage = 'Đúng! 🎉';

      if (_spokenCorrectly.length == _vocabularyList.length && !_isLessonCompleted) {
        setState(() {
          _isLessonCompleted = true;
        });
        _showFinalScore();
      }
    } else if (spokenWord.isNotEmpty) {
      hintMessage = 'Chưa đúng, thử lại.';
    }

    setState(() {
      _speakingHint = hintMessage;
      _lastAnswerCorrect = isCorrect;
      _lastCorrectWord = correctWord;
      _showOverlayDialog = true;
    });
  }

  Widget _buildSpeakButton() {
    return GestureDetector(
      onTap: _startListening,
      child: Column(
        children: [
          AnimatedScale(
            scale: _micScale,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : const Color(0xFF89B3D4),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.microphone,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _micButtonLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          _speech.stop();
          _cancelListeningTimer();
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        resizeToAvoidBottomInset: true,
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
            
                _buildSpeakingForm(context),

                 if (_showOverlayDialog)   // 👉 Thêm overlay khi nói đúng/sai
                  AnimatedOverlayDialog(
                    correctAnswer: _lastCorrectWord,
                    isCorrect: _lastAnswerCorrect,
                    onContinue: () {
                      setState(() {
                        _showOverlayDialog = false;
                      });

                      if (_lastAnswerCorrect && _currentPage < _vocabularyList.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _autoPlayWord(_currentPage + 1);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakingForm(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_vocabularyList.isEmpty) {
      return const Center(child: Text('Không có từ vựng để luyện nói.'));
    }

     return Positioned.fill( // 👉 dùng fill để fit toàn màn
     child: SafeArea( // 👉 chống tràn tai thỏ
      child: Column(
        children: [
          HeaderLesson(
            title: 'Speaking (${_spokenCorrectly.length}/${_vocabularyList.length})',
            color: const Color(0xFF89B3D4),
          ),
          const SizedBox(height: 16),
           // Dùng Expanded thay cho height fix cứng
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // ❌ không cho vuốt
                itemCount: _vocabularyList.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _recognizedText = '';
                    _speakingHint = '';
                  });
                  _autoPlayWord(index);
                },

              
              itemBuilder: (context, index) {
                final wordData = _vocabularyList[index].data() as Map<String, dynamic>?;
                final word = wordData?['word'] as String? ?? '';
                final phonetic = wordData?['phonetic'] as String? ?? '';
                final isCorrect = _spokenCorrectly.contains(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFFE0F7DE) : const Color(0xFFD3E6F6), // Màu nền khác nhau khi đúng
                      borderRadius: BorderRadius.circular(20),
                      border: isCorrect ? Border.all(color: Colors.green, width: 2) : null, // Viền xanh khi đúng
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            word,
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.w400,
                              color: isCorrect ? Colors.green[800] : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            phonetic,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PlayButton(
                                onPressed: () async => await _autoPlayWord(index),
                                isPlayingNotifier: _isPlayingNotifier, // ⭐ MỚI
                              ),
                              const SizedBox(width: 40),
                              _buildSpeakButton(),
                            ],
                          ),
                      
                          const SizedBox(height: 30),
                          Text(
                            "Bạn đã nói: $_recognizedText",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _speakingHint ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _speakingHint == 'Chưa đúng, thử lại.' ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Image.asset(
                            'assets/icon/no_background.png',
                            width: 210,
                            height: 210,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_vocabularyList.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _spokenCorrectly.contains(index)
                      ? Colors.green
                      : (_currentPage == index ? Colors.blue : Colors.grey.shade400),
                ),
              );
            }),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: MediaQuery.of(context).padding.top + 10, // 👈 auto căn theo notch
      child: IconButton(
        onPressed: () async{
          final shouldExit = await _showExitDialog(context);
          if (shouldExit) {
            _speech.stop();
            _cancelListeningTimer();
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
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

  void _showFinalScore() {
    final total = _vocabularyList.length;
    final correct = _spokenCorrectly.length;

    // Lấy danh sách index sai
    final wrongIndexes = List<int>.generate(total, (i) => i)
        .where((i) => !_spokenCorrectly.contains(i))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinalScoreDialog(
        correct: correct,
        total: total,
        wrongIndexes: wrongIndexes,
        onRetryWrong: () {
          Navigator.pop(context);
          _restartWrongQuestions(wrongIndexes);
        },
        onComplete: () async {
          Navigator.pop(context);
          await updateStreak();

          final percent = (correct / total) * 100;

          // Trả kết quả về LessonMenu
          _safePop({
            'completedActivity': 'speaking',
            'correctCount': correct,
            'totalCount': total,
            'progress': percent,
          });
        },
      ),
    );
  }

  void _restartWrongQuestions(List<int> wrongIndexes) {
    setState(() {
      _currentPage = 0;
      _vocabularyList = wrongIndexes.map((i) => _vocabularyList[i]).toList();
      _spokenCorrectly.clear();
      _recognizedText = '';
      _speakingHint = '';
      _isLessonCompleted = false;
    });

    _pageController.jumpToPage(0);
    _autoPlayWord(0);
  }

  void _safePop([Object? result]) {
    Navigator.pop(context, result);
  }


  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    _speech.cancel();
    _listeningTimer?.cancel(); // Hủy timer khi widget bị dispose
    super.dispose();
  }
}