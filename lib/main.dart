import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:total_english/screens/lesson_screen.dart';
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/streak_screen.dart';
import 'package:total_english/screens/home_screen.dart';
import 'package:total_english/screens/Account_screen.dart';
import 'package:total_english/screens/About_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Lỗi khi khởi tạo Firebase")),
            );
          } else {
            // Firebase đã khởi tạo xong
            User? user = FirebaseAuth.instance.currentUser;

            // Nếu đã đăng nhập, chuyển đến màn hình học
            if (user != null) {
              return const LessonScreen();
            } else {
              return const LoginScreen();
            }
          }
        },
      ),

    );
  }
}
