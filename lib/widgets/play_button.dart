import 'package:flutter/material.dart';

class PlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final String? label;

  const PlayButton({
    Key? key,
    required this.onPressed,
    this.size = 60,
    this.backgroundColor = const Color(0xFF89B3D4),
    this.iconColor = Colors.white,
    this.label,
  }) : super(key: key);

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  bool isPressed = false; // Trạng thái để biết nút đang được nhấn

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            widget.onPressed();

            // Tạo hiệu ứng nhấn vào nút một lần
            setState(() {
              isPressed = true; 
            });

            // Sau khoảng thời gian ngắn, thu nhỏ nút lại
            Future.delayed(Duration(milliseconds: 300), () {
              setState(() {
                isPressed = false; // Sau 200ms, thu nhỏ lại
              });
            });
          },
          borderRadius: BorderRadius.circular(widget.size),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25), // Bóng mạnh hơn khi nhấn
                  blurRadius: isPressed ? 12 : 16, // Bóng rõ hơn khi nhấn
                  offset: Offset(0, 8), // Đẩy bóng xuống dưới để tạo hiệu ứng nổi
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.4), // Bóng sáng ở trên
                  blurRadius: isPressed ? 16 : 20, // Bóng sáng rõ hơn khi nhấn
                  offset: Offset(0, -8), // Đẩy bóng sáng lên trên
                ),
              ],
            ),
            child: AnimatedScale(
              duration: Duration(milliseconds: 200), // Thời gian hiệu ứng lâu hơn
              scale: isPressed ? 1.4 : 1.0, // Phóng to rõ rệt khi nhấn
              child: Icon(
                Icons.volume_up_outlined,
                size: widget.size * 0.5,
                color: widget.iconColor,
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          SizedBox(height: 8),
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
  }
}
