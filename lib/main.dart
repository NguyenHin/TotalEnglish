import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'test.dart'; // Import file test
=======
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/main_screen.dart';
import 'package:total_english/screens/signup_screen.dart';
>>>>>>> 9af244ad87b4f309e75a998a9b16cf8cf2659d9a

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
      home: TestScreen(), // Hiển thị màn hình test
=======
      home: LoginScreen(),
      //home: MainScreen(),
      //home: SignupScreen(),
>>>>>>> 9af244ad87b4f309e75a998a9b16cf8cf2659d9a
    );
  }
}