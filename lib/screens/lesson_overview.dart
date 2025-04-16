import 'package:flutter/material.dart';
import 'package:total_english/widgets/lesson_menu.dart';

class LessonOverview extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String lessonDescription;
  final IconData lessonIcon; // Thêm tham số cho icon
  final Color lessonColor; // Thêm tham số cho màu sắc
  
  const LessonOverview({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonDescription,
    required this.lessonIcon,
    required this.lessonColor,
  });

  @override
  _LessonOverviewState createState() => _LessonOverviewState();
}

class _LessonOverviewState extends State<LessonOverview> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            _buildBackButton(context),
            _buildLessonOverviewForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
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
          // Tiêu đề bài học với icon và màu sắc
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.lessonColor, // Sử dụng màu sắc được truyền vào
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.lessonIcon, size: 40, color: Colors.white), // Sử dụng icon được truyền vào
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.lessonTitle,
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

          // Menu bài học (không thay đổi màu và icon của LessonMenu)
          LessonMenu(lessonId: widget.lessonId),  // Chỉ truyền lessonId
        ],
      ),
    );
  }
}
