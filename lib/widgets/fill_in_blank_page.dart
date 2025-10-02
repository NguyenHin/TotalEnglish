import 'package:flutter/material.dart';
import 'package:total_english/widgets/play_button.dart';
import '../models/vocabulary_item.dart';

Widget buildFillInBlankPage({
  required VocabularyItem item,
  required TextEditingController controller,
  required void Function(bool) onCheck,
  required ValueNotifier<bool> isPlayingNotifier,
  required Future<void> Function(String) onListen,
}) {
  final data = item.doc.data() as Map<String, dynamic>;
  final word = data['word'] ?? '';

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Nút nghe dùng PlayButton để đồng bộ với MC
      PlayButton(
        onPressed: () => onListen(word),
        isPlayingNotifier: isPlayingNotifier,
      ),
      const SizedBox(height: 24),

      // TextField nhập từ
      TextField(
        controller: controller,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          hintText: 'Nhập từ vào đây',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),

      // Nút kiểm tra đồng bộ màu và kích thước với MC
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF89B3D4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          onPressed: () {
            final input = controller.text.trim().toLowerCase();
            final isCorrect = input == word.trim().toLowerCase();
            onCheck(isCorrect);
          },
          child: const Text(
            "Kiểm tra",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ],
  );
}

