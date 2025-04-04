import 'package:flutter/material.dart';
import 'test.dart'; // Import file test

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestScreen(), // Hiển thị màn hình test
    );
  }
}