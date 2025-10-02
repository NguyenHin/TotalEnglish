import 'package:flutter/material.dart';

class PlayButton extends StatefulWidget {
  final VoidCallback onPressed;
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
  bool isPressed = false;

  @override
Widget build(BuildContext context) {
  return ValueListenableBuilder<bool>(
    valueListenable: widget.isPlayingNotifier,
    builder: (context, isPlaying, child) {
      bool animate = isPlaying || isPressed;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              widget.onPressed();

              setState(() {
                isPressed = true;
              });

              Future.delayed(const Duration(milliseconds: 300), () {
                setState(() {
                  isPressed = false;
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
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: animate ? 12 : 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: animate ? 16 : 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: animate ? 1.4 : 1.0,
                child: Icon(
                  Icons.volume_up_outlined,
                  size: widget.size * 0.5,
                  color: widget.iconColor,
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
