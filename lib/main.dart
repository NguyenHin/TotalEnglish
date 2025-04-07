import 'package:flutter/material.dart';



import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/main_screen.dart';
import 'package:total_english/screens/lesson_screen.dart';
import 'package:total_english/screens/streak_screen.dart';
import 'package:total_english/screens/home_screen.dart';


import 'package:total_english/screens/signup_screen.dart';
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





      //home: LoginScreen(),
      //home: MainScreen(),
      //home: SignupScreen(),


      //home: LoginScreen(),
      //home: MainScreen(),
      //home: SignupScreen(),
      //home: const HomeScreen(),
      //home: const AccountScreen(),



      //home: LoginScreen(),
      //home: MainScreen(),
      //home: SignupScreen(),
      home: const HomeScreen()
      // home: const SettingsScreen(),

    );
  }
}