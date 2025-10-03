import 'package:flutter/material.dart';

class FinalScoreDialog extends StatelessWidget {
  final int? correct;
  final int? total;
  final List<int> wrongIndexes;
  final VoidCallback onRetryWrong;
  final VoidCallback onComplete;
  final String? title;   // thêm title tuỳ biến
  final String? message; // thêm message tuỳ biến

  const FinalScoreDialog({
    super.key,
    this.correct,
    this.total,
    this.wrongIndexes = const [],
    required this.onRetryWrong,
    required this.onComplete,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF89B3D4), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 60, color: Colors.yellowAccent),
                const SizedBox(height: 16),
                Text(
                  title ?? "Bài học hoàn tất!",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (message != null)
                  Text(
                    message!,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  )
                else if (correct != null && total != null)
                  Text(
                    "Bạn làm đúng $correct/$total câu",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (wrongIndexes.isNotEmpty)
                      ElevatedButton(
                        onPressed: onRetryWrong,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text("Làm lại câu sai",
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ElevatedButton(
                      onPressed: onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text("Hoàn tất",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
