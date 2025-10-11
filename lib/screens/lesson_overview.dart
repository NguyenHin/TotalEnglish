import 'package:flutter/material.dart';
import 'package:total_english/widgets/lesson_menu.dart';

class LessonOverview extends StatelessWidget {
  final String lessonId;
  final String lessonTitle;
  final String lessonDescription;
  final IconData lessonIcon;
  final Color lessonColor;

  const LessonOverview({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonDescription,
    required this.lessonIcon,
    required this.lessonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackButton(context),
          _buildLessonOverviewForm(),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  Widget _buildLessonOverviewForm() {
    return Positioned(
      top: 141,
      left: 22,
      right: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bài học
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: lessonColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(lessonIcon, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lessonTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // LessonMenu: hiển thị 4 phần (Vocabulary, Speaking, Exercise, Quiz)
          LessonMenu(lessonId: lessonId),
        ],
      ),
    );
  }
}
