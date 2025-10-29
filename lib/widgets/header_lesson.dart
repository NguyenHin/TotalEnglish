// header_lesson.dart

import 'package:flutter/material.dart';

class HeaderLesson extends StatelessWidget {
  final String title;
  final Color? color;

  const HeaderLesson({
    super.key,
    required this.title,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding( // Padding ban đầu để tạo khoảng trống bên dưới
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        // Loại bỏ: width: 330, // ❌ Bỏ dòng này
        height: 55, // Giữ nguyên chiều cao cố định
        alignment: Alignment.center, 
        decoration: BoxDecoration(
          color: Color(0xFF89B3D4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}