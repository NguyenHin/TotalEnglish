import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LessonMenu extends StatelessWidget {
  final String lessonTitle;

  LessonMenu({
    super.key,
    required this.lessonTitle
  });
  
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8.0),
          child: Text(
            lessonTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Kadwa',
              color: Colors.black54
            ),
          ),
        ),
        _buildMenuButton("Từ vựng", Icons.library_books, Color(0xFFF2D16C)),
        _buildMenuButton("Luyện nghe", Icons.headphones, Color(0xFFBFA8E7)),
        _buildMenuButton("Luyện nói", Icons.mic, Color(0xFF95E499)),
        _buildMenuButton("Bài kiểm tra", Icons.assignment, Color(0xFF89B3D4)),

      ],
    );
  }

  Widget _buildMenuButton(String title, IconData icon, Color backgroundColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 4), // Điều chỉnh độ lệch của shadow
          ),
        ],
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white, // cần có để shadow thấy rõ
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () {
          // TODO: Add your navigation or action here
        },
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
  );
}

}