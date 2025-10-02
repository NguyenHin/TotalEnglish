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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        width: 330, // Set the width
        height: 55, // Set the height
        alignment: Alignment.center, 
        decoration: BoxDecoration(
          color: Color(0xFF89B3D4), // Background color of the container
          borderRadius: BorderRadius.circular(20), // Optional: Rounded corners
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Color of the text
          ),
        ),
      ),
    );
  }
}
