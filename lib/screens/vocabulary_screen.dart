import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:total_english/widgets/animated_overlay_dialog.dart';
import 'package:total_english/widgets/exit_dialog.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';
import 'package:total_english/widgets/final_score_dialog.dart';
import '../models/vocabulary_item.dart';

class VocabularyScreen extends StatefulWidget {
  final String lessonId;
  const VocabularyScreen({super.key, required this.lessonId});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<VocabularyItem> _vocabularyItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextToSpeechService _ttsService = TextToSpeechService();
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);
  OverlayEntry? _checkDialogEntry;

  String? _selectedAnswer;
  bool _checked = false;
  bool _isAnswerCorrect = false;

  List<bool> _hasAutoPlayed = [];
  List<bool?> _answerStatus = [];

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    _checkDialogEntry?.remove();
    _checkDialogEntry = null;
    super.dispose();
  }

  /// 🔹 Chỉ sửa phần này cho đúng với VocabularyItem mới
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

      final docs = snapshot.docs;

      if (docs.isEmpty) {
        setState(() {
          _vocabularyItems = [];
          _isLoading = false;
        });
        return;
      }

      _vocabularyItems = [];
      for (var doc in docs) {
        final data = doc.data();
        final correctAnswer = data['meaning'] ?? '';

        final allMeanings = docs
            .map((d) => (d.data())['meaning']?.toString() ?? '')
            .where((m) => m.isNotEmpty && m != correctAnswer)
            .toList()
          ..shuffle();

        final wrongAnswers = allMeanings.take(2).toList();
        final options = <String>[correctAnswer, ...wrongAnswers]..shuffle();

        // ✅ Sử dụng VocabularyItem mới
        _vocabularyItems.add(VocabularyItem(
          doc: doc,
          options: options,
        ));
      }

      _vocabularyItems.shuffle();
      _hasAutoPlayed = List.filled(_vocabularyItems.length, false);
      _answerStatus = List.filled(_vocabularyItems.length, null);

      setState(() => _isLoading = false);

      if (_vocabularyItems.isNotEmpty) _autoPlayWord(0);
      print("✅ Đã tải ${_vocabularyItems.length} từ vựng (chỉ MultipleChoice)");
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải từ vựng. Lỗi: $e";
      });
      print("❌ Lỗi tải từ vựng: $e");
    }
  }

  Future<void> _handleListen(String text) async {
    _isPlayingNotifier.value = true;
    await _ttsService.speak(text);
    _isPlayingNotifier.value = false;
  }

  Future<void> _autoPlayWord(int index) async {
    if (!_hasAutoPlayed[index]) {
      final wordData = _vocabularyItems[index].doc.data() as Map<String, dynamic>?;
      if (wordData != null && wordData.containsKey('word')) {
        _isPlayingNotifier.value = true;
        await Future.delayed(const Duration(milliseconds: 100));
        await _ttsService.speak(wordData['word']);
        await Future.delayed(const Duration(milliseconds: 350));
        _isPlayingNotifier.value = false;
        _hasAutoPlayed[index] = true;
      }
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

  void _showCheckDialog(String correctAnswer, bool isCorrect) {
    final overlay = Overlay.of(context);
    _checkDialogEntry?.remove();
    _checkDialogEntry = OverlayEntry(
      builder: (context) => AnimatedOverlayDialog(
        correctAnswer: correctAnswer,
        isCorrect: isCorrect,
        onContinue: () async {
          _checkDialogEntry?.remove();
          _checkDialogEntry = null;
          _answerStatus[_currentIndex] = isCorrect;

          if (_currentIndex < _vocabularyItems.length - 1) {
            setState(() {
              _currentIndex++;
              _selectedAnswer = null;
              _checked = false;
            });

            await _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );

            await Future.delayed(const Duration(milliseconds: 900));
            await _autoPlayWord(_currentIndex);
          } else {
            await updateStreak();
            _showFinalScore();
          }
        },
      ),
    );
    overlay.insert(_checkDialogEntry!);
  }

  void _showFinalScore() {
    final total = _vocabularyItems.length;
    final correct = _answerStatus.where((e) => e == true).length;
    final wrongIndexes = <int>[];
    for (int i = 0; i < _answerStatus.length; i++) {
      if (_answerStatus[i] == false) wrongIndexes.add(i);
    }

    

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
          final percent = (correct / total) * 100;
          _safePop({
            'completedActivity': 'vocabulary',
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
      _currentIndex = 0;
      _vocabularyItems = wrongIndexes.map((i) => _vocabularyItems[i]).toList();
      _answerStatus = List.filled(_vocabularyItems.length, null);
      _hasAutoPlayed = List.filled(_vocabularyItems.length, false);
      _selectedAnswer = null;
      _checked = false;
      _pageController.jumpToPage(0);
      _autoPlayWord(0);
    });
  }

  Widget _buildMultipleChoice(VocabularyItem item, double maxWidth, double maxHeight) {
    final data = item.doc.data() as Map<String, dynamic>;
    final correctAnswer = data['meaning'] ?? '';
    final options = item.options;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...options.map((option) {
          Color? bgColor;
          Color? textColor;
          BorderSide? border;

          if (_checked) {
            if (option == correctAnswer) {
              bgColor = Colors.green;
              textColor = Colors.white;
            } else if (option == _selectedAnswer) {
              bgColor = Colors.red;
              textColor = Colors.white;
            }
          } else {
            if (_selectedAnswer == option) {
              border = const BorderSide(color: Colors.blue, width: 2);
            }
          }

          return Container(
            margin: EdgeInsets.symmetric(vertical: maxHeight * 0.008),
            width: double.infinity,
            height: maxHeight * 0.07,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor ?? Colors.white,
                foregroundColor: textColor ?? Colors.black,
                side: border ?? const BorderSide(color: Colors.black12, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: !_checked
                  ? () => setState(() => _selectedAnswer = option)
                  : null,
              child: Text(option, style: TextStyle(fontSize: maxWidth * 0.04)),
            ),
          );
        }),
        SizedBox(height: maxHeight * 0.02),
        SizedBox(
          width: double.infinity,
          height: maxHeight * 0.07,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF89B3D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            onPressed: (_selectedAnswer != null && !_checked)
                ? () {
                    setState(() {
                      _checked = true;
                      _isAnswerCorrect = _selectedAnswer?.trim().toLowerCase() ==
                          correctAnswer.trim().toLowerCase();
                    });
                    _showCheckDialog(correctAnswer, _isAnswerCorrect);
                  }
                : null,
            child: Text("Kiểm tra", style: TextStyle(fontSize: maxWidth * 0.045)),
          ),
        ),
      ],
    );
  }

  void _safePop([Object? result]) {
    _checkDialogEntry?.remove();
    _checkDialogEntry = null;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          _checkDialogEntry?.remove();
          _checkDialogEntry = null;
          Navigator.pop(context);
        }
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 45),
                    const HeaderLesson(
                      title: 'Vocabulary',
                      color: Color(0xFF89B3D4),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                              ? Center(child: Text(_errorMessage!))
                              : _vocabularyItems.isEmpty
                                  ? const Center(child: Text('Không có từ vựng'))
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final maxWidth = constraints.maxWidth;
                                        final maxHeight = constraints.maxHeight;

                                        return Column(
                                          children: [
                                            Expanded(
                                              child: PageView.builder(
                                                controller: _pageController,
                                                physics: const NeverScrollableScrollPhysics(),
                                                onPageChanged: (index) {
                                                  setState(() {
                                                    _currentIndex = index;
                                                    _selectedAnswer = null;
                                                    _checked = false;
                                                  });
                                                  _autoPlayWord(index);
                                                },
                                                itemCount: _vocabularyItems.length,
                                                itemBuilder: (context, index) {
                                                  final item = _vocabularyItems[index];
                                                  final data = item.doc.data() as Map<String, dynamic>?;

                                                  // ⚡ GIỮ NGUYÊN UI GỐC CỦA BẠN ⚡
                                                  return Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        width: double.infinity,
                                                        padding: EdgeInsets.all(maxWidth * 0.04),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(16),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              color: Colors.black26,
                                                              blurRadius: 8,
                                                              offset: Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(12),
                                                              child: Image.network(
                                                                data?['imageURL'] ?? '',
                                                                width: maxWidth * 0.45,
                                                                height: maxWidth * 0.45,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                            SizedBox(height: maxHeight * 0.02),
                                                            Text(
                                                              data?['word'] ?? '',
                                                              style: TextStyle(
                                                                fontSize: maxWidth * 0.06,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              data?['phonetic'] ?? '',
                                                              style: TextStyle(
                                                                fontSize: maxWidth * 0.045,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                            SizedBox(height: maxHeight * 0.015),
                                                            PlayButton(
                                                              onPressed: () async {
                                                                if (data != null && data.containsKey('word')) {
                                                                  await _handleListen(data['word']);
                                                                }
                                                              },
                                                              isPlayingNotifier: _isPlayingNotifier,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: maxHeight * 0.03),
                                                      _buildMultipleChoice(item, maxWidth, maxHeight),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: List.generate(_vocabularyItems.length, (index) {
                                                  return AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                                    height: 10,
                                                    width: 10,
                                                    decoration: BoxDecoration(
                                                      color: _currentIndex == index ? Colors.blue : Colors.grey,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            SizedBox(height: maxHeight * 0.01),
                                          ],
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                top: 20,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: () async {
                    final shouldExit = await _showExitDialog(context);
                    if (shouldExit) {
                      _checkDialogEntry?.remove();
                      _checkDialogEntry = null;
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
