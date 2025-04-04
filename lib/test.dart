import 'package:flutter/material.dart';
import 'package:total_english/widgets/custom_button.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Button")),
      body: Center(
        child: CustomButton(
          text: "Login", // Nội dung nút
          onPressed: () {
            print("Button pressed!"); // Kiểm tra xem nút có hoạt động không
          },
        ),
      ),
    );
  }
}