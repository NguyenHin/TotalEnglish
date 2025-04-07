import 'package:flutter/material.dart';
import 'package:total_english/screens/lesson_overview.dart';
import 'package:total_english/screens/lesson_screen.dart';
import 'package:total_english/screens/streak_screen.dart';
import 'package:total_english/screens/home_screen.dart';
import 'package:total_english/screens/setting_screen.dart';

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
      //home: SignupScreen(),
      //home: const HomeScreen()
      //home: SettingsScreen()
    );
  }
}