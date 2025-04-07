import 'package:flutter/material.dart';
import 'package:total_english/widgets/header_lesson.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Nền trắng chung
      body: Stack(
        children: [
          _buildBackButton(context),
          _buildHeaderLesson(),
          _buildQuizContainer(), // Khung nền xanh nhạt
        ],
      ),
    );
  }

  // Nút quay lại
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 10,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  // Header tiêu đề
  Widget _buildHeaderLesson() {
    return const Positioned(
      top: 100,
      left: 22,
      right: 22,
      child: HeaderLesson(
        title: 'Quiz',
        color: Color(0xFF89B3D4),
      ),
    );
  }

  // Khung nền xanh nhạt
  Widget _buildQuizContainer() {
    return Positioned(
      top: 190,
      left: 22,
      right: 22,
      child: Container(
        width: 370,
        height: 650,
        decoration: BoxDecoration(
          color: const Color(0xFFD3E6F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            // Tạm để rỗng cho bạn thêm nội dung sau
          ),
        ),
      ),
    );
  }
}
