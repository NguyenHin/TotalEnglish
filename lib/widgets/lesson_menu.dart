import 'package:flutter/material.dart';
import 'package:total_english/screens/listening_screen.dart';
import 'package:total_english/screens/quiz_screen.dart';
import 'package:total_english/screens/speaking_screen.dart';
import 'package:total_english/screens/vocabulary_screen.dart'; // Import màn hình Từ vựng

class LessonMenu extends StatelessWidget {
  final String lessonId;
  final Function(String activity, bool isCompleted)? onActivityCompleted;
  
  const LessonMenu({
    super.key,
    required this.lessonId,  // Chỉ cần truyền lessonId
    this.onActivityCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuButton(
          context,
          "Từ vựng",
          Icons.library_books,
          Color(0xFFF2D16C),
          VocabularyScreen(
            lessonId: lessonId,
            onCompleted: (activity, isCompleted) {
              print("onActivityCompleted gọi cho $activity: $isCompleted");  // Log khi callback được gọi
              if (onActivityCompleted != null) {
                onActivityCompleted!(activity, isCompleted);
              }
            },
          ),
        ),
        _buildMenuButton(
          context,
          "Luyện nghe",
          Icons.headphones,
          Color(0xFFBFA8E7),
          ListeningScreen(
            lessonId: lessonId,
            onCompleted: (activity, isCompleted) {
              print("onActivityCompleted gọi cho $activity: $isCompleted"); // Log khi callback được gọi
              if (onActivityCompleted != null) {
                onActivityCompleted!(activity, isCompleted);
              }
            },
          ), // Chuyển đến màn hình ListeningScreen
        ),
        _buildMenuButton(
          context,
          "Luyện nói",
          Icons.mic,
          Color(0xFF95E499),
          SpeakingScreen(
    lessonId: lessonId,
    onCompleted: (activity, isCompleted) {
      print("onActivityCompleted gọi cho $activity: $isCompleted"); // Log khi callback được gọi
      if (onActivityCompleted != null) {
        onActivityCompleted!(activity, isCompleted);
      }
    },
  ), // Chuyển đến màn hình SpeakingScreen
        ),
        _buildMenuButton(
          context,
          "Bài kiểm tra",
          Icons.assignment,
          Color(0xFF89B3D4),
         QuizScreen(
            lessonId: lessonId,
            onCompleted: (activity, isCompleted) {
              print("onActivityCompleted gọi cho $activity: $isCompleted"); // Log khi callback được gọi
              if (onActivityCompleted != null) {
                onActivityCompleted!(activity, isCompleted);
              }
            },
          ), // Chuyển đến màn hình QuizScreen
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color backgroundColor, Widget targetScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 4), // Điều chỉnh độ lệch của shadow
            ),
          ],
        ),
        child: InkWell(  // Sử dụng InkWell để xử lý sự kiện nhấn
          borderRadius: BorderRadius.circular(12.0),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );

            if (result is Map && onActivityCompleted != null) {
              final activity = result['completedActivity'];
              final isCompleted = result['isCompleted'] ?? false;
              if (activity != null) {
                onActivityCompleted!(activity, isCompleted);
              }
            }
          },

          child: Container(  // Thêm container để chứa toàn bộ giao diện của nút
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,  // Đảm bảo màu nền của nút là trắng
              border: Border.all(color: Colors.grey[300]!),  // Viền màu sáng hơn
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
