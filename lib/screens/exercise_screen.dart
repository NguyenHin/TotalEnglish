import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:total_english/services/text_to_speech_service.dart';
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
  List<int> _selectedLetterIndices = []; // ✅ LƯU Ý: Kiểu dữ liệu là List<int>
  List<bool?> _answerStatus = [];

  late List<bool> _hasAutoPlayed;
  
  Map<String, List<String>> _shuffledLetters = {}; // shuffle letters 1 lần
  List<Offset> _letterPositions = []; // lưu vị trí hiện tại của letter button
  List<bool> _letterUsed = []; // xem letter đã được dùng chưa



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
    final vocabSnap = await FirebaseFirestore.instance
        .collection('lessons')
        .doc(widget.lessonId)
        .collection('vocabulary')
        .get();

    List<ExerciseItem> exercises = [];

    // Tạo danh sách tất cả từ vựng để random options cho multiple choice
    List<ExerciseItem> allVocabItems = [];

    for (var vocabDoc in vocabSnap.docs) {
      final vocabItem = ExerciseItem.fromDoc(vocabDoc);
      allVocabItems.add(vocabItem);
    }

    for (var vocabItem in allVocabItems) {
      final activitiesSnap =
          await vocabItem.doc.reference.collection('activities').get();

      for (var activityDoc in activitiesSnap.docs) {
        final exercise = ExerciseItem.fromDoc(activityDoc);

        // Nếu multipleChoice thì random 3 từ khác để tạo 4 card
        if (exercise.type == ExerciseType.multipleChoice) {
          List<ExerciseItem> otherOptions = allVocabItems
              .where((e) => e.word != exercise.word)
              .toList()
            ..shuffle();

          // Chọn 3 từ khác + từ đúng
          exercise.optionsItems = [exercise, ...otherOptions.take(3)]..shuffle();
        }

        exercises.add(exercise);
      }
    }

    // Shuffle tất cả activity
    exercises.shuffle();

    setState(() {
      _exercises = exercises;
      _isLoading = false;
      _answerStatus = List.filled(_exercises.length, null);
      _hasAutoPlayed = List.filled(_exercises.length, false);
    });
    // ✅ Autoplay câu đầu tiên
    if (_exercises.isNotEmpty) {
      _autoPlayWord(0);
    }
  } catch (e) {
    print("Lỗi load exercises: $e");
    setState(() => _isLoading = false);
  }
}


Future<void> _autoPlayWord(int index) async {
  if (!_hasAutoPlayed[index]) {
    final currentExercise = _exercises[index];
    String? textToSpeak;

    // Xác định nội dung cần phát dựa trên loại bài tập
    if (currentExercise.type == ExerciseType.letterTiles) {
      // ✅ Đối với letterTiles: Phát câu ví dụ (example)
      textToSpeak = currentExercise.example;
    } else {
      // Đối với các loại khác (MultipleChoice, FillInBlank): Phát từ vựng (word)
      final wordData = currentExercise.doc.data() as Map<String, dynamic>?;
      textToSpeak = wordData?['word'];
    }

    if (textToSpeak != null && textToSpeak.isNotEmpty) {
      // Sử dụng thời gian trễ đã điều chỉnh (700ms) để đồng bộ với animation
      await Future.delayed(const Duration(milliseconds: 700)); 
      
      _isPlayingNotifier.value = true;
      await _ttsService.speak(textToSpeak);
      await Future.delayed(const Duration(milliseconds: 500));
      _isPlayingNotifier.value = false;
      _hasAutoPlayed[index] = true;
    }
  }
}


  Future<void> _handleListen(String text) async {
    _isPlayingNotifier.value = true;
    await _ttsService.speak(text);
    _isPlayingNotifier.value = false;
  }

  void _showCheckDialog(String correctAnswer, bool isCorrect) {
    final overlay = Overlay.of(context);
    _checkDialogEntry?.remove();
    _checkDialogEntry = OverlayEntry(
      builder: (context) => AnimatedOverlayDialog(
        correctAnswer: correctAnswer,
        isCorrect: isCorrect,
        onContinue: () {
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
    
    // ✅ 1. TÌM CÁC CHỈ MỤC (INDEX) CỦA CÂU SAI
    final wrongIndexes = <int>[];
    for (int i = 0; i < _answerStatus.length; i++) {
        // Kiểm tra _answerStatus[i] == false (null là chưa trả lời, true là đúng)
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
        wrongIndexes: wrongIndexes, // ✅ TRUYỀN VÀO DANH SÁCH INDEX CÂU SAI
        onRetryWrong: () {
          Navigator.pop(context);
          // ✅ GỌI HÀM LÀM LẠI CÂU SAI
          _restartWrongQuestions(wrongIndexes); 
        },
        onComplete: () {
          Navigator.pop(context);
          widget.onCompleted?.call('exercise', true);
        },
      ),
    );
}
void _restartWrongQuestions(List<int> wrongIndexes) {
    if (wrongIndexes.isEmpty) return;

    // ✅ 1. LẤY DANH SÁCH BÀI TẬP SAI
    final wrongExercises = wrongIndexes.map((i) => _exercises[i]).toList();
    
    // ✅ 2. TẠO TRẠNG THÁI MỚI CHO VÒNG LẶP LÀM LẠI
    // Chúng ta phải tạo một state mới để lưu lại các câu trả lời đúng/sai của vòng lặp này.

    setState(() {
      // Đổi _exercises thành danh sách các câu sai
      _exercises = wrongExercises;
      
      // Reset trạng thái:
      _currentIndex = 0;
      _selectedAnswer = null;
      _checked = false;
      _selectedLetterIndices.clear();
      
      // Tạo trạng thái trả lời mới (tất cả đều null/chưa trả lời)
      _answerStatus = List.filled(_exercises.length, null); 
      _hasAutoPlayed = List.filled(_exercises.length, false);
    });

    // ✅ 3. ĐI TỚI TRANG ĐẦU TIÊN
    // Đặt lại PageController về trang 0. Dùng addPostFrameCallback để đảm bảo widget đã được build xong.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(0);
      _autoPlayWord(0); // Phát âm câu đầu tiên của tập hợp mới
    });
}

  // ================= BUILD UI =================

  Widget _buildFillInBlank(ExerciseItem item) {
  final controller = TextEditingController();
  return SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.only(bottom: 80),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      
      // 1. Khu vực Hình ảnh & Âm thanh (Card nổi bật)
      Container(
        padding: const EdgeInsets.all(24.0),
        // ✅ Đồng bộ style Card nổi bật
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF89B3D4)),
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
            // Hình ảnh
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
            )
            .animate()
            .fadeIn(duration: 400.ms) 
            .slideY(begin: 0.2, curve: Curves.easeOut), 

            const SizedBox(height: 20),

            // Nút Play (Phát âm từ vựng)
            PlayButton(
              onPressed: () => _handleListen(item.word), // ✅ PHÁT ÂM TỪ VỰNG
              isPlayingNotifier: _isPlayingNotifier,
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .scale(delay: 200.ms), 
          ],
        ),
      ),
      
      const SizedBox(height: 40), // Khoảng cách lớn

      // 2. Khu vực Nhập liệu
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
            
            // ✅ Dùng khung để phân biệt rõ ràng khu vực gõ từ
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
      
      // 3. Nút Kiểm tra
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
  )
  );
}

  Widget _buildMultipleChoice(ExerciseItem item) {

  final List<ExerciseItem> options = item.optionsItems ?? [item]; 

  return Column(
    children: [
      PlayButton(
        onPressed: () => _handleListen(item.word), //đọc từ
        isPlayingNotifier: _isPlayingNotifier,
      ).animate() // ✅ Thêm animation cho nút Play
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .scale(delay: 200.ms),

      const SizedBox(height: 20),

      Expanded(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1, // Giữ tỷ lệ này nếu hình ảnh và text cân đối
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
              child: AnimatedContainer( // ✅ Sử dụng AnimatedContainer cho hiệu ứng chuyển đổi
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: Colors.white, // Màu nền trắng
                  borderRadius: BorderRadius.circular(16), // Bo tròn hơn
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF89B3D4) // ✅ Màu xanh chủ đạo khi chọn
                        : Colors.grey.shade300, // Màu xám nhạt khi không chọn
                    width: isSelected ? 3 : 1.5, // Viền dày hơn khi chọn
                  ),
                  boxShadow: [ // ✅ Thêm đổ bóng để tạo chiều sâu
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF89B3D4).withOpacity(0.4) // Bóng đậm hơn khi chọn
                          : Colors.grey.withOpacity(0.2), // Bóng nhẹ khi không chọn
                      spreadRadius: isSelected ? 2 : 1,
                      blurRadius: isSelected ? 8 : 4,
                      offset: isSelected ? const Offset(0, 4) : const Offset(0, 2), // Nổi lên nhiều hơn khi chọn
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hình ảnh với animation nhẹ
                    Image.network(
                      option.imageURL, 
                      width: 80, 
                      height: 80, 
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) { // ✅ Thêm loading builder
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
                    ).animate() // ✅ Animation cho hình ảnh
                      .fadeIn(duration: 300.ms)
                      .scale(duration: 300.ms, curve: Curves.easeOut),

                    const SizedBox(height: 8),
                    // Text với animation màu sắc
                    AnimatedDefaultTextStyle( // ✅ Animation màu chữ
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF89B3D4) : Colors.black87, // Màu chữ theo trạng thái
                      ),
                      child: Text(
                        option.word,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate() // ✅ Animation tổng thể cho mỗi ô khi xuất hiện
              .fadeIn(delay: (index * 100).ms, duration: 400.ms) // Xuất hiện tuần tự
              .slideY(begin: 0.1, delay: (index * 100).ms, duration: 400.ms, curve: Curves.easeOut);
          },
        ),
      ),
      const SizedBox(height: 16),
      SizedBox( // ✅ THÊM SIZEDBOX ĐỂ ĐỒNG BỘ KÍCH THƯỚC
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
          // Đảm bảo màu chữ là màu trắng
          child: const Text('Kiểm tra', style: TextStyle(fontSize: 18, color: Colors.white)), 
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

  // Thêm hàm này vào trong class _ExerciseScreenState
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
    child: Row( // ✅ ROW CHÍNH CHỈ CHỨA HÌNH ẢNH/NÚT VÀ TEXT
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. KHU VỰC HÌNH ẢNH & NÚT PLAY (LEFT SIDE)
        Column(
          mainAxisSize: MainAxisSize.min, // Giúp Column chỉ chiếm không gian cần thiết
          children: [
            // Hình ảnh
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
            )
            .animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, curve: Curves.easeOut), 

            const SizedBox(height: 8), // Khoảng cách nhỏ

            // ✅ NÚT PLAY ĐƯỢC ĐẶT NGAY DƯỚI HÌNH ẢNH
            PlayButton(
              onPressed: () => _handleListen(item.example),
              isPlayingNotifier: _isPlayingNotifier,
              size: 45
              // Tùy chỉnh kích thước nếu cần (PlayButton của bạn mặc định có thể là 50x50)
            )
            .animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(delay: 200.ms), 
          ],
        ),

        const SizedBox(width: 12),

        // 2. KHU VỰC CÂU VÍ DỤ/TEXT (RIGHT SIDE)
        Expanded( 
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0), // Padding trên nhẹ để cân bằng với ảnh
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
          )
          .animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ),
      ],
    ),
  );
}
Widget _buildLetterTiles(ExerciseItem item) {
  // Lấy danh sách ký tự gốc từ item.word, LỌC BỎ KHOẢNG TRẮNG, rồi shuffle
  final List<String> originalLetters = item.word.split('').where((char) => char != ' ').toList();
  
  // Shuffle các ký tự một lần và lưu lại để không bị xáo trộn khi build lại UI
  final shuffledLetters = _shuffledLetters.putIfAbsent(
    item.word, 
    () => List<String>.from(originalLetters)..shuffle()
  );

  // Tạo câu ví dụ với chỗ trống
  final maskedExample = item.example.replaceAll(
    RegExp('\\b${RegExp.escape(item.word)}\\b', caseSensitive: false),
    '__________', // Dùng gạch chân dài hơn cho đẹp
  );

  // ✅ TÍNH TOÁN SỐ KÝ TỰ CHỮ CÁI CẦN THIẾT
  final int wordLengthWithoutSpaces = originalLetters.length; // Dùng list đã được lọc

  // === XÂY DỰNG UI ===
  // LƯU Ý: VÌ CÁC WIDGET BÊN TRONG COLUMN NÀY CÓ THỂ TRÀN, NÊN HÀM GỌI NÓ (PageView.builder)
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      // mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // 1. QUESTION AREA (Cố định chiều cao)
        _buildQuestionArea(item, maskedExample),
        const SizedBox(height: 16),
        
        // 2. ANSWER AREA (Cố định/Tự điều chỉnh chiều cao theo Wrap)
        _buildAnswerArea(item, shuffledLetters),
        const SizedBox(height: 16),
        
        // 3. LETTER BANK (Flexible và có thể cuộn)
        Expanded( 
          // ✅ Bọc Letter Bank bằng Expanded và SingleChildScrollView
          child: SingleChildScrollView( 
            child: _buildLetterBank(item, shuffledLetters),
          ),
        ),
        
        const SizedBox(height: 16),

        // 4. NÚT KIỂM TRA (Cố định chiều cao)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            // Logic onPressed đã được sửa từ câu trả lời trước
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
        const SizedBox(height: 10), // Padding dưới cùng
      ],
    ),
  );
}

// === WIDGET PHỤ CHO _buildLetterTiles ===

// Widget xây dựng khu vực điền câu trả lời (Final fix: Khoảng trắng tự động và không tương tác)
Widget _buildAnswerArea(ExerciseItem item, List<String> shuffledLetters) {
  // Lấy danh sách các ký tự của từ/cụm từ (bao gồm cả khoảng trắng)
  final List<String> answerChars = item.word.split('');
  
  // Biến đếm vị trí ký tự được user chọn (chỉ dùng cho ký tự, bỏ qua khoảng trắng)
  int selectedCharCount = 0; 

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), 
    child: Wrap( 
      alignment: WrapAlignment.center,
      spacing: 6, 
      runSpacing: 8, 
      children: List.generate(answerChars.length, (index) {
        final String char = answerChars[index]; 
        
        // --- TRƯỜNG HỢP 1: KHOẢNG TRẮNG ---
        if (char == ' ') {
          // Trả về một khoảng cách cố định, KHÔNG TƯƠNG TÁC
          return const SizedBox(width: 25, height: 50); 
        }
        
        // --- TRƯỜNG HỢP 2: KÝ TỰ ---
        
        // Chỉ số trong mảng _selectedLetterIndices (chỉ chứa index của các ký tự được chọn)
        final int charIndexInSelection = selectedCharCount; 
        
        // Tăng biến đếm cho lần lặp tiếp theo
        selectedCharCount++; 

        // Kiểm tra xem vị trí ký tự này đã có ký tự được chọn chưa
        final bool hasLetter = charIndexInSelection < _selectedLetterIndices.length;
        
        // Lấy index của ký tự trong mảng shuffledLetters
        final int letterIndex = hasLetter ? _selectedLetterIndices[charIndexInSelection] : -1;
        
        // Lấy ký tự tương ứng
        final String letter = hasLetter ? shuffledLetters[letterIndex] : '';

        return GestureDetector(
          onTap: hasLetter
              ? () {
                  // Khi nhấn vào ô ký tự đã có, loại bỏ nó khỏi câu trả lời
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
              width: 45,
              height: 50,
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
                  fontSize: 24,
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
// Widget ô chứa các ký tự
Widget _buildLetterBank(ExerciseItem item, List<String> shuffledLetters) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    constraints: const BoxConstraints(minHeight: 120), // Đảm bảo có không gian tối thiểu
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 12, // Khoảng cách ngang
      runSpacing: 12, // Khoảng cách dọc
      children: List.generate(shuffledLetters.length, (index) {
        final letter = shuffledLetters[index];
        final isSelected = _selectedLetterIndices.contains(index);

        return GestureDetector(
          onTap: (!isSelected && _selectedLetterIndices.length < item.word.length)
              ? () {
                  // Thêm ký tự vào câu trả lời
                  setState(() {
                    _selectedLetterIndices.add(index);
                  });
                }
              : null,
          child: AnimatedOpacity(
            // Làm mờ ký tự đã chọn thay vì xóa hẳn
            opacity: isSelected ? 0.3 : 1.0, 
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 45,
              height: 45,
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
                  fontSize: 20,
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
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildProgressBar() {
  // Tính toán tiến trình (0.0 đến 1.0)
  final double targetProgress = (_currentIndex + 1) / _exercises.length;
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Column(
      children: [
        // Hiển thị số lượng bài tập
        Text(
          'Câu ${_currentIndex + 1} / ${_exercises.length}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 5),
        
        // Thanh tiến trình chính
        // ✅ SỬ DỤNG TWEENANIMATIONBUILDER CHO HIỆU ỨNG CHUYỂN ĐỘNG
        TweenAnimationBuilder<double>(
          // Bắt đầu từ giá trị hiện tại và chuyển động đến giá trị mới (targetProgress)
          tween: Tween<double>(begin: targetProgress, end: targetProgress),
          duration: const Duration(milliseconds: 300), // Thời gian chuyển động
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value, // Sử dụng giá trị đang chuyển động
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF89B3D4)), 
              ),
            );
          },
        )
        // ✅ Thêm animation trượt nhẹ khi toàn bộ Progress Bar xuất hiện lần đầu (không bắt buộc)
        .animate().slideX(begin: -1, duration: 800.ms), 
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                  // Dọn dẹp state của letter tiles
                                  _selectedLetterIndices.clear(); 
                                });
                                _autoPlayWord(index); //autoplay từ
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
      )
      );
  }
}
