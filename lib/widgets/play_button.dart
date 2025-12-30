import 'package:flutter/material.dart';

class PlayButton extends StatefulWidget {
  final VoidCallback? onPressed; // ✅ nullable
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final String? label;
  final ValueNotifier<bool> isPlayingNotifier;

  const PlayButton({
    Key? key,
    required this.onPressed,
    required this.isPlayingNotifier,
    this.size = 60,
    this.backgroundColor = const Color(0xFF89B3D4),
    this.iconColor = Colors.white,
    this.label,
  }) : super(key: key);

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  bool _isPressed = false;

  @override
Widget build(BuildContext context) {
  return ValueListenableBuilder<bool>(
    valueListenable: widget.isPlayingNotifier,
    builder: (context, isPlaying, _) {
      if (!isPlaying && _isPressed) {
    _isPressed = false; // 🔑 ép reset
  }
      
      // Nút sẽ phóng to nếu đang phát (auto hoặc click)
      final bool shouldScale = isPlaying || _isPressed;
      final bool canInteract = widget.onPressed != null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: canInteract ? 1.0 : 0.4,
            child: InkWell(
              onTap: canInteract
                  ? () {
                      widget.onPressed!();
                      setState(() => _isPressed = true);
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) setState(() => _isPressed = false);
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(widget.size),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      // Khi phóng to thì bóng đổ nhạt đi một chút tạo cảm giác nút bay lên
                      blurRadius: shouldScale ? 10 : 15, 
                      offset: shouldScale ? const Offset(0, 4) : const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 600), // Tăng thời gian animation một chút cho mượt
                  scale: shouldScale ? 1.5 : 1.0, // Phóng to 35% so với ban đầu
                  curve: Curves.easeOutBack, // Hiệu ứng nảy (bounce) nhẹ khi phóng to
                  child: Icon(
                    Icons.volume_up_outlined, // Giữ nguyên 1 loại icon
                    size: widget.size * 0.5,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
          ),
            if (widget.label != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
