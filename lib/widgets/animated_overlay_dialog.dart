import 'package:flutter/material.dart';

/// 🔹 Kết quả overlay (dùng cho Speaking)
enum OverlayResultType {
  correct,
  almostCorrect,
  wrong,
}

class AnimatedOverlayDialog extends StatefulWidget {
  final String correctAnswer;
  final OverlayResultType resultType;
  final VoidCallback onContinue;
  final VoidCallback? onRetry;

  const AnimatedOverlayDialog({
    super.key,
    required this.correctAnswer,
    required this.resultType,
    required this.onContinue,
    this.onRetry,
  });

  /// 🔹 Constructor PHỤ cho Voca,Exercise KHÔNG CÓ accuracy
  factory AnimatedOverlayDialog.simple({
    required String correctAnswer,
    required bool isCorrect,
    required VoidCallback onContinue,
  }) {
    return AnimatedOverlayDialog(
      correctAnswer: correctAnswer,
      resultType:
          isCorrect ? OverlayResultType.correct : OverlayResultType.wrong,
      onContinue: onContinue,
    );
  }

  @override
  State<AnimatedOverlayDialog> createState() => _AnimatedOverlayDialogState();
}

class _AnimatedOverlayDialogState extends State<AnimatedOverlayDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  final Color correctColor = const Color(0xFF4CAF50);
  final Color wrongColor = const Color(0xFFE53935);
  final Color almostColor = const Color(0xFFFFA000);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    switch (widget.resultType) {
      case OverlayResultType.correct:
        return correctColor;
      case OverlayResultType.almostCorrect:
        return almostColor;
      case OverlayResultType.wrong:
        return wrongColor;
    }
  }

  IconData get _icon {
    switch (widget.resultType) {
      case OverlayResultType.correct:
        return Icons.check_circle_outline;
      case OverlayResultType.almostCorrect:
        return Icons.error_outline;
      case OverlayResultType.wrong:
        return Icons.cancel_outlined;
    }
  }

  String get _title {
    switch (widget.resultType) {
      case OverlayResultType.correct:
        return "Chính xác!";
      case OverlayResultType.almostCorrect:
        return "Gần đúng!";
      case OverlayResultType.wrong:
        return "Sai rồi!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),

                    if (widget.resultType != OverlayResultType.correct) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Đáp án đúng là:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.correctAnswer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 🔹 Nút Thử lại (chỉ hiện với almostCorrect)
                    if (widget.resultType == OverlayResultType.almostCorrect &&
                        widget.onRetry != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: widget.onRetry,
                          child: const Text(
                            "Thử lại",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 🔹 Nút Tiếp tục
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: widget.onContinue,
                        child: const Text(
                          "Tiếp tục",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
