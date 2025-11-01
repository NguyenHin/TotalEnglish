import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:total_english/models/vocabulary_item.dart';
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:total_english/widgets/exit_dialog.dart';
import '../models/exercise_item.dart';
import '../widgets/play_button.dart';
import '../widgets/header_lesson.dart';
import '../widgets/animated_overlay_dialog.dart';
import '../widgets/final_score_dialog.dart';

class ExerciseScreen extends StatefulWidget {
  final String lessonId;
  final void Function(String activity, bool isCompleted)? onCompleted;

  const ExerciseScreen({
    super.key,
    required this.lessonId,
    this.onCompleted,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final PageController _pageController = PageController();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  List<ExerciseItem> _exercises = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  OverlayEntry? _checkDialogEntry;

  String? _selectedAnswer; // multiple choice
  bool _checked = false;
  List<int> _selectedLetterIndices = [];
  List<bool?> _answerStatus = [];

  late List<bool> _hasAutoPlayed;

  Map<String, List<String>> _shuffledLetters = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    _checkDialogEntry?.remove();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      // Lấy danh sách vocabulary trong bài học
      final vocabSnap = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .collection('vocabulary')
          .get();

      // Chuyển thành list VocabularyItem
      final allVocabItems =
      vocabSnap.docs.map((doc) => VocabularyItem(doc: doc)).toList();

      List<ExerciseItem> exercises = [];

      // 🔹 Dùng Future.wait để load tất cả activities song song
      final allActivities = await Future.wait(
        allVocabItems.map((vocabItem) async {
          final activitiesSnap =
          await vocabItem.doc.reference.collection('activities').get();

          // Tạo list ExerciseItem từ mỗi activityDoc
          return activitiesSnap.docs.map((activityDoc) {
            return ExerciseItem.fromDoc(activityDoc, vocabItem);
          }).toList();
        }),
      );

      // Gộp tất cả lại thành một list duy nhất
      for (var exerciseList in allActivities) {
        exercises.addAll(exerciseList);
      }

      // 🔹 Xử lý multiple choice: thêm 3 đáp án sai ngẫu nhiên
      for (var i = 0; i < exercises.length; i++) {
        final ex = exercises[i];
        if (ex.type == ExerciseType.multipleChoice) {
          final correctVocab = ex.vocab;

          // Lấy 3 vocab khác làm đáp án sai
          final wrongVocabItems = allVocabItems
              .where((v) => v.word != correctVocab.word)
              .toList()
            ..shuffle();

          // Tạo danh sách 4 lựa chọn (1 đúng + 3 sai)
          final options = [
            ex,
            ...wrongVocabItems.take(3).map(
                  (v) => ExerciseItem(
                doc: ex.doc,
                type: ex.type,
                vocab: v,
              ),
            )
          ]..shuffle();

          // Gán options vào ExerciseItem gốc
          exercises[i] = ex.copyWith(optionsItems: options);
        }
      }

      // Thứ tự ngẫu nhiên
      exercises.shuffle();

      // ✅ Khởi tạo trạng thái để tránh RangeError
      setState(() {
        _exercises = exercises;
        _isLoading = false;
        _answerStatus = List<bool?>.filled(_exercises.length, null);
        _hasAutoPlayed = List<bool>.filled(_exercises.length, false);
      });

      // ✅ Tự động phát âm từ đầu tiên nếu có
      if (_exercises.isNotEmpty) {
        _autoPlayWord(0);
      }
    } catch (e, st) {
      debugPrint("❌ Error loading exercises: $e\n$st");
      setState(() => _isLoading = false);
    }
  }


  Future<void> _autoPlayWord(int index) async {
    if (!_hasAutoPlayed[index]) {
      final currentExercise = _exercises[index];
      String? textToSpeak;

      if (currentExercise.type == ExerciseType.letterTiles) {
        textToSpeak = currentExercise.example;
      } else {
        textToSpeak = currentExercise.word;
      }

      if (textToSpeak != null && textToSpeak.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 700));
        _isPlayingNotifier.value = true;
        await _ttsService.stop(); // dừng TTS cũ trước khi đọc
        await _ttsService.speak(textToSpeak);
        await Future.delayed(const Duration(milliseconds: 500));
        _isPlayingNotifier.value = false;
        _hasAutoPlayed[index] = true;
      }
    }
  }

  Future<void> _handleListen(String text) async {
    _isPlayingNotifier.value = true;
    await _ttsService.stop(); // dừng âm cũ
    await _ttsService.speak(text);
    _isPlayingNotifier.value = false;
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

          if (_currentIndex < _exercises.length - 1) {
            setState(() {
              _currentIndex++;
              _selectedAnswer = null;
              _checked = false;
              _selectedLetterIndices = [];
            });
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
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
    final total = _exercises.length;
    final correct = _answerStatus.where((e) => e == true).length;

    final wrongIndexes = <int>[];
    for (int i = 0; i < _answerStatus.length; i++) {
      if (_answerStatus[i] == false) {
        wrongIndexes.add(i);
      }
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
          // 1) Đóng dialog
          Navigator.pop(context);

          // 2) Tính progress percent
          final percent = total > 0 ? ((correct / total) * 100) : 0.0;

          // await updateStreak();

          // 3) Pop màn hình Exercise và trả kết quả về LessonMenu
          _safePop({
            'completedActivity': 'exercise',
            'correctCount': correct,
            'totalCount': total,
            'progress': percent,
          });
        },
      ),
    );
  }

  void _restartWrongQuestions(List<int> wrongIndexes) {
    if (wrongIndexes.isEmpty) return;

    final wrongExercises = wrongIndexes.map((i) => _exercises[i]).toList();

    setState(() {
      _exercises = wrongExercises;
      _currentIndex = 0;
      _selectedAnswer = null;
      _checked = false;
      _selectedLetterIndices.clear();
      _answerStatus = List.filled(_exercises.length, null);
      _hasAutoPlayed = List.filled(_exercises.length, false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(0);
      _autoPlayWord(0);
    });
  }

  // ========== UI  ==========

  Widget _buildFillInBlank(ExerciseItem item) {
    final controller = TextEditingController();
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF89B3D4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.8),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageURL,
                    height: 150,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      return progress == null ? child : const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                    },
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 20),
                PlayButton(
                  onPressed: () => _handleListen(item.word),
                  isPlayingNotifier: _isPlayingNotifier,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(delay: 200.ms),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Nhập từ vào đây',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF89B3D4), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final input = controller.text.trim().toLowerCase();
                  final isCorrect = input == item.word.trim().toLowerCase();
                  _showCheckDialog(item.word, isCorrect);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF89B3D4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kiểm tra', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoice(ExerciseItem item) {
    final List<ExerciseItem> options = item.optionsItems ?? [item];

    return Column(
      children: [
        PlayButton(
          onPressed: () => _handleListen(item.word),
          isPlayingNotifier: _isPlayingNotifier,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(delay: 200.ms),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = _selectedAnswer == option.word;

              return GestureDetector(
                onTap: !_checked
                    ? () {
                  setState(() {
                    _selectedAnswer = option.word;
                  });
                }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF89B3D4) : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? const Color(0xFF89B3D4).withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                        spreadRadius: isSelected ? 2 : 1,
                        blurRadius: isSelected ? 8 : 4,
                        offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        option.imageURL,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(duration: 300.ms).scale(duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF89B3D4) : Colors.black87,
                        ),
                        child: Text(option.word, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.1, delay: (index * 100).ms, duration: 400.ms, curve: Curves.easeOut);
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_selectedAnswer != null && !_checked)
                ? () {
              setState(() {
                _checked = true;
              });
              _showCheckDialog(item.word, _selectedAnswer?.toLowerCase() == item.word.toLowerCase());
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF89B3D4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text('Kiểm tra', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuestionArea(ExerciseItem item, String maskedExample) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF89B3D4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageURL,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const SizedBox(height: 100, width: 100, child: Center(child: CircularProgressIndicator()));
                  },
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, curve: Curves.easeOut),
              const SizedBox(height: 8),
              PlayButton(
                onPressed: () => _handleListen(item.example),
                isPlayingNotifier: _isPlayingNotifier,
                size: 45,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(delay: 200.ms),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                maskedExample,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterTiles(ExerciseItem item) {
    final List<String> originalLetters = item.word.split('').where((char) => char != ' ').toList();
    final shuffledLetters = _shuffledLetters.putIfAbsent(item.word, () => List<String>.from(originalLetters)..shuffle());
    final maskedExample = item.example.replaceAll(RegExp('\\b${RegExp.escape(item.word)}\\b', caseSensitive: false), '__________');
    final int wordLengthWithoutSpaces = originalLetters.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          _buildQuestionArea(item, maskedExample),
          const SizedBox(height: 16),
          _buildAnswerArea(item, shuffledLetters),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildLetterBank(item, shuffledLetters),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedLetterIndices.length == wordLengthWithoutSpaces
                  ? () {
                final userAnswer = _selectedLetterIndices.map((i) => shuffledLetters[i]).join();
                final isCorrect = userAnswer.toLowerCase() == originalLetters.join('').toLowerCase();
                _showCheckDialog(item.word, isCorrect);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF89B3D4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Kiểm tra', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(ExerciseItem item, List<String> shuffledLetters) {
    final List<String> answerChars = item.word.split('');
    int selectedCharCount = 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: List.generate(answerChars.length, (index) {
          final String char = answerChars[index];
          if (char == ' ') {
            return const SizedBox(width: 25, height: 50);
          }
          final int charIndexInSelection = selectedCharCount;
          selectedCharCount++;
          final bool hasLetter = charIndexInSelection < _selectedLetterIndices.length;
          final int letterIndex = hasLetter ? _selectedLetterIndices[charIndexInSelection] : -1;
          final String letter = hasLetter ? shuffledLetters[letterIndex] : '';

          return GestureDetector(
            onTap: hasLetter
                ? () {
              setState(() {
                _selectedLetterIndices.removeAt(charIndexInSelection);
              });
            }
                : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Container(
                key: ValueKey<String>('$letter-$index'),
                width: 30,
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasLetter ? Colors.white : Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasLetter ? Colors.blueAccent : Colors.grey.shade400,
                    width: 2,
                  ),
                  boxShadow: hasLetter
                      ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                      : [],
                ),
                child: Text(
                  letter.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLetterBank(ExerciseItem item, List<String> shuffledLetters) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      constraints: const BoxConstraints(minHeight: 120),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: List.generate(shuffledLetters.length, (index) {
          final letter = shuffledLetters[index];
          final isSelected = _selectedLetterIndices.contains(index);

          return GestureDetector(
            onTap: (!isSelected && _selectedLetterIndices.length < item.word.length)
                ? () {
              setState(() {
                _selectedLetterIndices.add(index);
              });
            }
                : null,
            child: AnimatedOpacity(
              opacity: isSelected ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 35,
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.8),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  letter.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      left: 8,
      top: 12,
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
    );
  }

  Widget _buildProgressBar() {
    final double targetProgress = (_exercises.isEmpty) ? 0.0 : (_currentIndex + 1) / _exercises.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          Text(
            'Câu ${_currentIndex + 1} / ${_exercises.length}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: targetProgress, end: targetProgress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF89B3D4)),
                ),
              );
            },
          ).animate().slideX(begin: -1, duration: 800.ms),
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
          _checkDialogEntry?.remove();
          _checkDialogEntry = null;
          Navigator.pop(context);
        }
        return false; // luôn chặn pop mặc định
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      const HeaderLesson(
                        title: 'Exercise',
                        color: Color(0xFF89B3D4),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                              _selectedAnswer = null;
                              _checked = false;
                              _selectedLetterIndices.clear();
                            });
                            _autoPlayWord(index);
                          },
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            final item = _exercises[index];
                            switch (item.type) {
                              case ExerciseType.fillInBlank:
                                return _buildFillInBlank(item);
                              case ExerciseType.multipleChoice:
                                return _buildMultipleChoice(item);
                              case ExerciseType.letterTiles:
                                return _buildLetterTiles(item);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressBar(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildBackButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Safe pop: remove overlay nếu có rồi pop với [result] (nếu có)
  void _safePop([Object? result]) {
    _checkDialogEntry?.remove();
    _checkDialogEntry = null;
    Navigator.pop(context, result);
  }
}
