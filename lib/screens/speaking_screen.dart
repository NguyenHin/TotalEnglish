import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:total_english/services/record_service.dart';
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:total_english/widgets/exit_dialog.dart';
import 'package:total_english/widgets/final_score_dialog.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';
import 'package:total_english/widgets/animated_overlay_dialog.dart';

class SpeakingScreen extends StatefulWidget {
  final String lessonId;
  const SpeakingScreen({super.key, required this.lessonId});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final _ttsService = TextToSpeechService();
  final _recordService = RecordService();
  final _pageController = PageController();
  //muốn rebuild  giao diện (nút Play), không cần gọi setState cho cả màn hình.
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  List<QueryDocumentSnapshot> _vocabularyList = [];
  final Set<int> _spokenCorrectly = {};
  bool _isLessonCompleted = false;

  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  bool _showOverlayDialog = false;

  String _lastCorrectWord = '';
  Widget? _highlightWidget;

  String? _currentFilePath;

  final ValueNotifier<double> _micScaleNotifier = ValueNotifier(1.0);

  OverlayResultType _lastResultType = OverlayResultType.wrong;

  Timer? _micTimer;


  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .collection('vocabulary')
          .get();

      setState(() {
        _vocabularyList = snapshot.docs;
        _isLoading = false;
      });

      if (_vocabularyList.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _autoPlayWord(0);
      });
    }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải từ vựng: $e';
      });
    }
  }

  Future<void> _autoPlayWord(int index) async {
    // Kiểm tra nếu đang ghi âm thì không cho phát âm thanh
  if (_recordService.isRecording) return;

    if (index < 0 || index >= _vocabularyList.length) return;
    final data = _vocabularyList[index].data() as Map<String, dynamic>? ?? {};
    final word = data['word'] ?? '';
    if (word.isEmpty) return;

    _isPlayingNotifier.value = true;
    try {
    // Chờ một chút để icon kịp phóng to lên trước khi âm thanh kết thúc
    await Future.wait([
      _ttsService.speak(word),
      Future.delayed(const Duration(milliseconds: 600)), // Đảm bảo nút phóng to ít nhất 0.6s
    ]);
  } finally {
    _isPlayingNotifier.value = false;
  }
  }

  Future<void> _onMicPressed() async {
  if (_recordService.isRecording && _currentFilePath == null) return;

  try {
    await _ttsService.stop();
    _isPlayingNotifier.value = false;

    final isLocked = _spokenCorrectly.contains(_currentPage);
    if (isLocked) return;

    if (!_recordService.isRecording) {
      // ▶ START
      _currentFilePath = await _recordService.startRecording();
      _startMicPulse();
    } else {
      // ⏹ STOP
      _stopMicPulse();

      final vocabData =
          _vocabularyList[_currentPage].data() as Map<String, dynamic>? ?? {};
      final correctWord = vocabData['word'] ?? '';

      final result = await _recordService.stopRecordingAndSend(
        filePath: _currentFilePath!,
        serverUrl: 'https://vosk-server-xbue.onrender.com/transcribe',
        expectedWord: correctWord,
      );

      _currentFilePath = null;

      await _saveSpeakingHistory(
        lessonId: widget.lessonId,
        expectedWord: correctWord,
        recognizedText: result['text'] ?? '',
        accuracy: (result['accuracy'] ?? 0.0).toDouble(),
        isCorrect: result['isCorrect'] ?? false,
      );

      await _showResultOverlay(
        correctWord,
        result['text'] ?? '',
        (result['accuracy'] ?? 0.0).toDouble(),
      );
    }
  } catch (e) {
    debugPrint('🔥 Mic error: $e');
    _stopMicPulse();
  }
}




  Future<void> _saveSpeakingHistory({
    required String lessonId,
    required String expectedWord,
    required String recognizedText,
    required double accuracy,
    required bool isCorrect,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('speaking_history')
          .doc(expectedWord.toLowerCase()); // 🔹 mỗi từ = 1 doc cố định

      final docSnap = await historyRef.get();

      final attemptData = {
        'recognizedText': recognizedText,
        'accuracy': accuracy,
        'timestamp': Timestamp.now(),
      };

      if (docSnap.exists) {
  final existing = docSnap.data()!;
  final prevBest = (existing['bestAccuracy'] ?? 0.0).toDouble();
  final totalAttempts = (existing['totalAttempts'] ?? 0) + 1;

  // ✅ GIỚI HẠN attempts (tối đa 10)
  final List attempts = List.from(existing['attempts'] ?? []);
  attempts.add(attemptData);
  if (attempts.length > 10) attempts.removeAt(0);

  await historyRef.update({
    'lessonId': lessonId,
    'lastAccuracy': accuracy,
    'bestAccuracy': accuracy > prevBest ? accuracy : prevBest,
    'totalAttempts': totalAttempts,
    'lastSpoken': recognizedText,
    'attempts': attempts, // ✅ ghi đè mảng đã giới hạn
    'timestamp': FieldValue.serverTimestamp(),
  });
      } else {
        await historyRef.set({
          'lessonId': lessonId,
          'expectedWord': expectedWord,
          'bestAccuracy': accuracy,
          'lastAccuracy': accuracy,
          'totalAttempts': 1,
          'lastSpoken': recognizedText,
          'attempts': [attemptData],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('🔥 Lỗi lưu speaking_history: $e');
    }
  }


//   // Hiệu ứng rung mic
//   void _startMicPulse() {
//   Future.delayed(const Duration(milliseconds: 200), () {
//     if (!mounted || !_recordService.isRecording) return;

//     _micScaleNotifier.value = 1.2;

//     Future.delayed(const Duration(milliseconds: 200), () {
//       if (!mounted || !_recordService.isRecording) return;

//       _micScaleNotifier.value = 1.0;
//       _startMicPulse();
//     });
//   });
// }
void _startMicPulse() {
  // đảm bảo chỉ có 1 pulse chạy
  _micTimer?.cancel();

  _micTimer = Timer.periodic(
    const Duration(milliseconds: 350),
    (timer) {
      if (!mounted || !_recordService.isRecording) {
        timer.cancel();
        _micScaleNotifier.value = 1.0;
        return;
      }

      _micScaleNotifier.value =
          _micScaleNotifier.value == 1.0 ? 1.2 : 1.0;
    },
  );
}


  void _stopMicPulse() {
  _micTimer?.cancel();
  _micTimer = null;
  _micScaleNotifier.value = 1.0;
}



  // Hiển thị kết quả (accuracy + highlight)
  Future<void> _showResultOverlay(
  String correctWord,
  String spokenWord,
  double accuracy,
) async {
  // 1️⃣ Quy đổi accuracy → enum
  final OverlayResultType resultType;

  if (accuracy >= 100) {
    resultType = OverlayResultType.correct;
  } else if (accuracy >= 70) {
    resultType = OverlayResultType.almostCorrect;
  } else {
    resultType = OverlayResultType.wrong;
  }

  // 2️⃣ Update UI
  setState(() {
    _lastResultType = resultType;
    _lastCorrectWord = correctWord;
    _highlightWidget = _highlightSpelling(correctWord, spokenWord, accuracy);
    _showOverlayDialog = true;
  });

  // 3️⃣ Logic bài học
  if (resultType == OverlayResultType.correct) {
  _spokenCorrectly.add(_currentPage);
}

  if (_spokenCorrectly.length == _vocabularyList.length && !_isLessonCompleted) {
    _isLessonCompleted = true;
    await updateStreak();
    _showFinalScore();
  }
}



  Widget _highlightSpelling(String correctWord, String spokenWord, double accuracy) {
    List<TextSpan> spans = [];
    int len = correctWord.length > spokenWord.length ? correctWord.length : spokenWord.length;
    for (int i = 0; i < len; i++) {
      String c = i < correctWord.length ? correctWord[i] : '';
      String s = i < spokenWord.length ? spokenWord[i] : '';
      spans.add(TextSpan(
        text: s.isEmpty ? '_' : s,
        style: TextStyle(
          color: c.toLowerCase() == s.toLowerCase() ? Colors.green : Colors.red,
          fontSize: 24,
        ),
      ));
    }
    return Column(
      children: [
        //richtext: hiển thị cùng dòng
        RichText(text: TextSpan(children: spans, style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Text("🎯 Accuracy: ${accuracy.toStringAsFixed(1)}%",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSpeakButton() {
  final bool isLocked = _spokenCorrectly.contains(_currentPage);

  return GestureDetector(
    onTap: _onMicPressed,
    child: ValueListenableBuilder<double>(
      valueListenable: _micScaleNotifier,
      builder: (context, scale, _) {
        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isLocked
                ? Colors.grey
                : (_recordService.isRecording ? Colors.red : const Color(0xFF89B3D4)),


              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: const Icon(
              FontAwesomeIcons.microphone,
              size: 28,
              color: Colors.white,
            ),
          ),
        );
      },
    ),
  );
}


  // Kết thúc bài học
  void _showFinalScore() {
    final total = _vocabularyList.length;
    final correct = _spokenCorrectly.length;
    final wrong = List<int>.generate(total, (i) => i).where((i) => !_spokenCorrectly.contains(i)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinalScoreDialog(
        correct: correct,
        total: total,
        wrongIndexes: wrong,
        onRetryWrong: () {
          Navigator.pop(context);
          _restartWrongQuestions(wrong);
        },
        onComplete: () async{
          Navigator.pop(context); // đóng dialog
          //await updateStreak();
          _safePop({
            'completedActivity': 'speaking',
            'correctCount': correct,
            'totalCount': total,
            'progress': (correct / total) * 100,
          });
        },
      ),
    );
  }

  void _restartWrongQuestions(List<int> wrong) {
    setState(() {
      _vocabularyList = wrong.map((i) => _vocabularyList[i]).toList();
      _spokenCorrectly.clear();
      _highlightWidget = null;
      _isLessonCompleted = false;
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
    _autoPlayWord(0);
  }

  // 🧩 Giao diện
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _showExitDialog(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _buildLessonContent(),
      ),
    );
  }

  Widget _buildLessonContent() {
  return Stack(
    children: [
      Positioned.fill(
        child: SafeArea(
          child: Column(
            children: [
              // 🌟 BackButton + HeaderLesson cùng 1 Column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(),
                    const SizedBox(height: 5), // khoảng cách giữa back và header
                    HeaderLesson(
                      title: 'Speaking (${_spokenCorrectly.length}/${_vocabularyList.length})',
                      color: const Color(0xFF89B3D4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // khoảng cách trước PageView
              
              // 🌟 PageView chiếm phần còn lại
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vocabularyList.length,
                  onPageChanged: (i) {
                    setState(() {
                      _currentPage = i;
                      _highlightWidget = null;
                    });
                    _autoPlayWord(i);
                  },
                  itemBuilder: (context, i) {
                    final data = _vocabularyList[i].data() as Map<String, dynamic>? ?? {};
                    final word = data['word'] ?? '';
                    final phonetic = data['phonetic'] ?? '';
                    final isCorrect = _spokenCorrectly.contains(i);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  word,
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? Colors.green[700] : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  phonetic,
                                  style: const TextStyle(fontSize: 22, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (_highlightWidget != null) _highlightWidget!,
                          const SizedBox(height: 230),
                          // Nút Play + Mic
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ValueListenableBuilder<double>(
                                  valueListenable: _micScaleNotifier, 
                                  builder: (context, scale, _) {
                                    final bool isRecording = _recordService.isRecording;


                                    return AbsorbPointer(
                                      absorbing: isRecording, 
                                      child: Opacity(
                                        opacity: isRecording ? 0.5 : 1.0, 
                                        child: PlayButton(
                                          onPressed: () async => await _autoPlayWord(i),
                                          isPlayingNotifier: _isPlayingNotifier,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 30),
                                _buildSpeakButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Overlay dialog
      if (_showOverlayDialog)
        AnimatedOverlayDialog(
  correctAnswer: _lastCorrectWord,
  resultType: _lastResultType,

  onRetry: () {
    setState(() {
      _showOverlayDialog = false;
      _highlightWidget = null;
    });
    _autoPlayWord(_currentPage);
  },

  onContinue: () {
  setState(() => _showOverlayDialog = false);

  if (_lastResultType != OverlayResultType.wrong &&
      _currentPage < _vocabularyList.length - 1) {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
},

),

    ],
  );
}


  Widget _buildBackButton() {
    return IconButton(
      padding: EdgeInsets.zero, // ✅ loại bỏ padding mặc định
    constraints: const BoxConstraints(),
    icon: const Icon(Icons.chevron_left, size: 28),
    onPressed: () async {
      if (await _showExitDialog(context)) Navigator.pop(context);
    },
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

  @override
  void dispose() {
    _micTimer?.cancel();
    _micScaleNotifier.dispose();
    _isPlayingNotifier.dispose();
    _ttsService.stop();
    _pageController.dispose();
    super.dispose();
  }
  
  void _safePop([Object? result]) {
    Navigator.pop(context, result);
  }

}

