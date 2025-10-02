import 'package:flutter/material.dart';
import '../models/vocabulary_item.dart';

Widget buildMultipleChoicePage({
  required VocabularyItem item,
  required int index,
  required String? selectedAnswer,
  required bool checked,
  required void Function(String) onSelect,
  required void Function() onCheck,
}) {
  final data = item.doc.data() as Map<String, dynamic>;
  final correctAnswer = data['meaning'] ?? '';
  final options = item.options;

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Image, Word, Phonetic, PlayButton...
      ...options.map((option) {
        Color? bgColor;
        Color? textColor;

        if (checked) {
          if (option == correctAnswer) {
            bgColor = Colors.green;
            textColor = Colors.white;
          } else if (option == selectedAnswer) {
            bgColor = Colors.red;
            textColor = Colors.white;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor ?? Colors.white,
              foregroundColor: textColor ?? Colors.black,
            ),
            onPressed: !checked ? () => onSelect(option) : null,
            child: Text(option),
          ),
        );
      }),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: !checked ? onCheck : null,
        child: const Text("Kiểm tra"),
      ),
    ],
  );
}
