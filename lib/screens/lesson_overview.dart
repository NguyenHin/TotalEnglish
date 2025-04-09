import 'package:flutter/material.dart';
import 'package:total_english/widgets/lesson_menu.dart';

class LessonOverview extends StatefulWidget{
  const LessonOverview({super.key});

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
        resizeToAvoidBottomInset: false, //Tránh giao diện bị đẩy lên khi bàn phím xuất hiện
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
        icon: Icon(Icons.chevron_left, size: 28,)
      ),
    );
  } 

  Widget _buildLessonOverviewForm() {
    return Positioned(
    top: 141,
    left: 22,
    right: 22, // thêm right để tránh tràn màn
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon người và tiêu đề
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'L1-1: Giới thiệu\nbản thân',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Menu bài học
        LessonMenu(lessonTitle: ''), // không cần lặp lại tiêu đề
      ],
    ),
  );
  }
}
