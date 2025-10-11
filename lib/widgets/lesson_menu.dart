import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/screens/exercise_screen.dart';
import 'package:total_english/screens/quiz_screen.dart';
import 'package:total_english/screens/speaking_screen.dart';
import 'package:total_english/screens/vocabulary_screen.dart';

class LessonMenu extends StatefulWidget {
  final String lessonId;
  final Function(String activity, bool isCompleted)? onActivityCompleted;

  const LessonMenu({
    super.key,
    required this.lessonId,
    this.onActivityCompleted,
  });

  @override
  State<LessonMenu> createState() => _LessonMenuState();
}

class _LessonMenuState extends State<LessonMenu> {
  double _vocabProgress = 0.0;
  double _exerciseProgress = 0.0;
  double _speakingProgress = 0.0;
  double _quizProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProgressFromFirebase();
  }

  // 🟩 Lưu tiến độ lên Firebase
  Future<void> _updateProgressOnFirebase(String activity, double percent) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Cập nhật giá trị trong state
      setState(() {
        switch (activity) {
          case 'vocabulary':
            _vocabProgress = percent;
            break;
          case 'exercise':
            _exerciseProgress = percent;
            break;
          case 'speaking':
            _speakingProgress = percent;
            break;
          case 'quiz':
            _quizProgress = percent;
            break;
        }
      });

      final docRef = FirebaseFirestore.instance
          .collection('user_lesson_progress')
          .doc('${user.uid}_${widget.lessonId}');

      await docRef.set({
        'userId': user.uid,
        'lessonId': widget.lessonId,
        'vocabularyProgress': _vocabProgress,
        'exerciseProgress': _exerciseProgress,
        'speakingProgress': _speakingProgress,
        'quizProgress': _quizProgress,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Progress đã cập nhật đầy đủ lên Firebase");
    } catch (e) {
      debugPrint("❌ Lỗi lưu progress lên Firebase: $e");
    }
  }


  // 🟨 Tải tiến độ từ Firebase
  Future<void> _loadProgressFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_lesson_progress')
          .doc('${user.uid}_${widget.lessonId}')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _vocabProgress = (data['vocabularyProgress'] ?? 0).toDouble();
          _exerciseProgress = (data['exerciseProgress'] ?? 0).toDouble();
          _speakingProgress = (data['speakingProgress'] ?? 0).toDouble();
          _quizProgress = (data['quizProgress'] ?? 0).toDouble();
        });

        debugPrint("✅ Load progress: vocab=$_vocabProgress, exercise=$_exerciseProgress, speaking=$_speakingProgress, quiz=$_quizProgress");
      }
    } catch (e) {
      debugPrint("❌ Lỗi load progress: $e");
    }
  }

  // 🟦 Xây dựng giao diện
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuButton(
          context,
          "Từ vựng",
          Icons.library_books,
          const Color(0xFFF2D16C),
          VocabularyScreen(lessonId: widget.lessonId),
        ),
        _buildMenuButton(
          context,
          "Luyện nói",
          Icons.mic,
          const Color(0xFF95E499),
          SpeakingScreen(lessonId: widget.lessonId),
        ),
        _buildMenuButton(
          context,
          "Bài tập",
          Icons.fitness_center,
          const Color(0xFFFFA500),
          ExerciseScreen(lessonId: widget.lessonId),
        ),
        _buildMenuButton(
          context,
          "Mini Game",
          Icons.videogame_asset,
          const Color(0xFF89B3D4),
          QuizScreen(lessonId: widget.lessonId),
        ),
      ],
    );
  }

  // 🟩 Hàm tạo từng button với progress bar
  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color backgroundColor,
    Widget targetScreen,
  ) {
    double progress = 0;
    String activityKey = '';

    switch (title) {
      case "Từ vựng":
        progress = _vocabProgress;
        activityKey = 'vocabulary';
        break;
      case "Bài tập":
        progress = _exerciseProgress;
        activityKey = 'exercise';
        break;
      case "Luyện nói":
        progress = _speakingProgress;
        activityKey = 'speaking';
        break;
      case "Mini Game":
        progress = _quizProgress;
        activityKey = 'quiz';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );

            if (result is Map<String, dynamic> &&
                result.containsKey('completedActivity')) {
              final activity = result['completedActivity'];
              final correct = (result['correctCount'] ?? 0) as int;
              final total = (result['totalCount'] ?? 1) as int;
              final percent = ((correct / total) * 100).roundToDouble();

              setState(() {
                switch (activity) {
                  case 'vocabulary':
                    _vocabProgress = percent > _vocabProgress ? percent : _vocabProgress;
                    break;
                  case 'exercise':
                    _exerciseProgress = percent > _exerciseProgress ? percent : _exerciseProgress;
                    break;
                  case 'speaking':
                    _speakingProgress = percent > _speakingProgress ? percent : _speakingProgress;
                    break;
                  case 'quiz':
                    _quizProgress = percent > _quizProgress ? percent : _quizProgress;
                    break;
                }
              });

              await _updateProgressOnFirebase(activity, percent);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (progress > 0) ...[
                        const SizedBox(height: 8),
                        _buildProgressBar(context, backgroundColor, progress),
                        const SizedBox(height: 6),
                        Text(
                          "${progress.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: backgroundColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟦 Thanh progress động
  Widget _buildProgressBar(BuildContext context, Color color, double progress) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress / 100),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}
