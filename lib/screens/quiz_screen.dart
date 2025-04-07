import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài kiểm tra')),
      body: const Center(child: Text('Màn hình Bài kiểm tra')),
    );
  }
}
