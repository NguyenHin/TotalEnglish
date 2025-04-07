import 'package:flutter/material.dart';

class SpeakingScreen extends StatelessWidget {
  const SpeakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện nói')),
      body: const Center(child: Text('Màn hình Luyện nói')),
    );
  }
}
