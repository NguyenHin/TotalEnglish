import 'package:flutter/material.dart';

class AnimatedOverlayDialog extends StatefulWidget {
  final String correctAnswer;
  final bool isCorrect;
  final VoidCallback onContinue;

  const AnimatedOverlayDialog({
    Key? key,
    required this.correctAnswer,
    required this.isCorrect,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<AnimatedOverlayDialog> createState() => _AnimatedOverlayDialogState();
}

class _AnimatedOverlayDialogState extends State<AnimatedOverlayDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // ✅ DÙNG SCALE VÀ SLIDE NHẸ CHO HIỆU ỨNG NHẢY/NẨY
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation; 

  // Định nghĩa màu sắc cố định
  final Color correctColor = const Color(0xFF4CAF50); // Xanh lá đậm
  final Color wrongColor = const Color(0xFFE53935); // Đỏ đậm

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400), // Tăng thời gian animation
      vsync: this,
    );
    
    // Animation trượt từ dưới lên (Offset(0, 0.3))
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Animation phóng to/thu nhỏ (Hiệu ứng nảy/bounce)
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut)); // ✅ Dùng Curves.elasticOut!

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
    // Màu sắc nền và nút dựa trên kết quả
    final Color primaryColor = widget.isCorrect ? correctColor : wrongColor;

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
                  // ✅ Đặt MÀU NỀN CONTAINER theo kết quả
                  color: primaryColor, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3), // Đổi màu bóng sang đen
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ ICON VÀ TEXT MÀU TRẮNG
                    Icon(
                      widget.isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: Colors.white, // Màu trắng
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      widget.isCorrect ? "Chính xác!" : "Sai rồi!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white, // Màu trắng
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (!widget.isCorrect)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          "Đáp án đúng là:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8), // Trắng mờ
                          ),
                        ),
                      ),
                    
                    if (!widget.isCorrect)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          widget.correctAnswer,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Màu trắng
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Nút Tiếp tục
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // ✅ Nền Nút MÀU TRẮNG
                          backgroundColor: Colors.white,
                          // ✅ Chữ Nút MÀU CHỦ ĐẠO (primaryColor)
                          foregroundColor: primaryColor, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        onPressed: widget.onContinue,
                        child: const Text(
                          "Tiếp tục",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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