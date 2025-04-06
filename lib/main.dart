import 'package:flutter/material.dart';
import 'package:total_english/screens/lesson_overview.dart';
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/main_screen.dart';
import 'package:total_english/screens/signup_screen.dart';
import 'package:total_english/screens/lesson_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
      home: LessonOverview(),
=======
      //home: LoginScreen(),
>>>>>>> ef4940305d5ad6b46248d6f687e368b633ab03aa
      //home: MainScreen(),
      //home: SignupScreen(),
      home: const LessonScreen(),
    );
  }
}