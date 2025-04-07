import 'package:flutter/material.dart';
import 'package:total_english/screens/lesson_overview.dart';
import 'package:total_english/screens/lesson_screen.dart';
// import 'package:total_english/screens/login_screen.dart';
// import 'package:total_english/screens/main_screen.dart';
// import 'package:total_english/screens/signup_screen.dart';
// import 'package:total_english/screens/lesson_screen.dart';
// import 'package:total_english/screens/vocabulary_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LessonOverview(),
      //home: LoginScreen(),
      //home: MainScreen(),
      //home: LessonScreen(),
      
    );
  }
}