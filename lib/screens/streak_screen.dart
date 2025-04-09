import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header không có nút back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  // Không cần icon quay lại
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Dòng chữ động viên + icon sao
            Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Great job! Keep it up! ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),

                    const SizedBox(width: 1),
                    const Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Biểu tượng lửa và streak với viền nhiều màu

            Stack(
              alignment: Alignment.center,
              children: [
                MultiColorBorderCircle(
                  colors: const [
                    Color(0xFFD36EE5),
                    Color(0xFFD88AB6),
                    Color(0xFFD994A3),
                    Color(0xFFDA999C),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FontAwesomeIcons.fire,
                      size: 90,
                      color: Color(0xFFD36EE5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '4 day streak',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF770B63),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Các ngày trong tuần - Không bị scroll
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DayCircle(label: 'T', filled: true, borderColor: const Color(0xFFE062D5), size: 40),
                  DayCircle(label: 'W', filled: true, borderColor: const Color(0xFF777777), size: 40),
                  DayCircle(label: 'T', filled: true, borderColor: const Color(0xFFE062D5), size: 40),
                  DayCircle(label: 'F', filled: true, borderColor: const Color(0xFFE062D5), size: 40),
                  DayCircle(label: 'S', filled: true, borderColor: const Color(0xFFE062D5), size: 40),
                  DayCircle(label: 'S', filled: true, borderColor: const Color(0xFFE062D5), size: 40),
                  DayCircle(label: 'M', filled: true, borderColor: const Color(0xFFE062D5), size: 40),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Gấu + thông báo streak

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(

                  padding: const EdgeInsets.only(left: 30.0),

                  child: Image.asset(
                    'assets/icon/panda_icon.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(width: 0),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "You're on a 4 day streak",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),

            const Spacer(flex: 1),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Widget nút ngày (vòng tròn)

class DayCircle extends StatelessWidget {
  final String label;
  final bool filled;
  final Color borderColor;
  final double size;

  const DayCircle({
    super.key,
    required this.label,
    this.filled = false,
    required this.borderColor,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 2),

      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(
          color: borderColor,
          width: 5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.black : borderColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


// Widget vòng tròn có viền nhiều màu

class MultiColorBorderCircle extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const MultiColorBorderCircle({
    super.key,
    this.size = 220,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: colors,
        ).createShader(bounds);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 12,
            color: Colors.white,

          ),
        ),
      ),
    );
  }
}
