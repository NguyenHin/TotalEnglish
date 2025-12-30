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
  double _vocabProgress = 0;
  double _exerciseProgress = 0;
  double _speakingProgress = 0;
  double _quizProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgressFromFirebase();
  }

  // ================================
  /// 🔼 UPDATE PROGRESS + SAVE FIREBASE
  // ================================
  Future<void> _updateProgressOnFirebase(
      String activity, double percent) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        switch (activity) {
          case 'vocabulary':
            _vocabProgress =
                percent > _vocabProgress ? percent : _vocabProgress;
            break;
          case 'exercise':
            _exerciseProgress =
                percent > _exerciseProgress ? percent : _exerciseProgress;
            break;
          case 'speaking':
            _speakingProgress =
                percent > _speakingProgress ? percent : _speakingProgress;
            break;
          case 'quiz':
            _quizProgress =
                percent > _quizProgress ? percent : _quizProgress;
            break;
        }
      });

      final docRef = FirebaseFirestore.instance
          .collection('user_lesson_progress')
          .doc('${user.uid}_${widget.lessonId}');

      await docRef.set(
        {
          'userId': user.uid,
          'lessonId': widget.lessonId,
          'vocabularyProgress': _vocabProgress,
          'exerciseProgress': _exerciseProgress,
          'speakingProgress': _speakingProgress,
          'quizProgress': _quizProgress,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint("✅ Saved progress: $activity = $percent%");
    } catch (e) {
      debugPrint("❌ Firebase save error: $e");
    }
  }

  // ================================
  /// 🔽 LOAD PROGRESS FROM FIREBASE
  // ================================
  Future<void> _loadProgressFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_lesson_progress')
          .doc('${user.uid}_${widget.lessonId}')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      setState(() {
        _vocabProgress = (data['vocabularyProgress'] ?? 0).toDouble();
        _exerciseProgress = (data['exerciseProgress'] ?? 0).toDouble();
        _speakingProgress = (data['speakingProgress'] ?? 0).toDouble();
        _quizProgress = (data['quizProgress'] ?? 0).toDouble();
      });

      debugPrint("✅ Progress loaded for lesson ${widget.lessonId}");
    } catch (e) {
      debugPrint("❌ Firebase load error: $e");
    }
  }

  // ================================
  // 🟦 UI
  // ================================
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuButton(
          context,
          title: "Từ vựng",
          icon: Icons.library_books,
          color: const Color(0xFFF2D16C),
          progress: _vocabProgress,
          screen: VocabularyScreen(lessonId: widget.lessonId),
          activityKey: 'vocabulary',
        ),
        _buildMenuButton(
          context,
          title: "Luyện nói",
          icon: Icons.mic,
          color: const Color(0xFF95E499),
          progress: _speakingProgress,
          screen: SpeakingScreen(lessonId: widget.lessonId),
          activityKey: 'speaking',
        ),
        _buildMenuButton(
          context,
          title: "Bài tập",
          icon: Icons.fitness_center,
          color: const Color(0xFFFFA500),
          progress: _exerciseProgress,
          screen: ExerciseScreen(lessonId: widget.lessonId),
          activityKey: 'exercise',
        ),
        _buildMenuButton(
          context,
          title: "Mini Game",
          icon: Icons.videogame_asset,
          color: const Color(0xFF89B3D4),
          progress: _quizProgress,
          screen: QuizScreen(lessonId: widget.lessonId),
          activityKey: 'quiz',
        ),
      ],
    );
  }

  // ================================
  // 🟩 MENU BUTTON
  // ================================
  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required double progress,
    required Widget screen,
    required String activityKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );

          if (result is Map<String, dynamic>) {
            final correct = result['correctCount'] ?? 0;
            final total = result['totalCount'] ?? 1;
            final percent = ((correct / total) * 100).roundToDouble();

            await _updateProgressOnFirebase(activityKey, percent);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      _buildProgressBar(color, progress),
                      const SizedBox(height: 6),
                      Text("${progress.toStringAsFixed(0)}%",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: color)),
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================================
  // 🟦 PROGRESS BAR
  // ================================
  Widget _buildProgressBar(Color color, double progress) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress / 100),
      duration: const Duration(milliseconds: 600),
      builder: (_, value, __) => Container(
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
      ),
    );
  }
}
