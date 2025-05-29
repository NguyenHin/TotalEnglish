import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/screens/home_screen.dart'; // Import HomeScreen
import 'package:total_english/widgets/custom_button.dart'; // Giữ lại nếu bạn muốn dùng lại style nút

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isEmailVerified = false;
  bool _canResendEmail = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResendEmail = false;
    _resendCooldown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email của bạn đã được xác minh!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Một email xác minh đã được gửi đến địa chỉ của bạn. Vui lòng kiểm tra hộp thư đến và làm theo hướng dẫn.')),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_canResendEmail) {
      try {
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lại email xác minh. Vui lòng kiểm tra hộp thư đến.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi lại email xác minh: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đợi $_resendCooldown giây trước khi gửi lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            _buildBackground(),
            _buildBackButton(context),
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Xác minh Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 100),
                  const Text(
                    'Một email xác minh đã được gửi đến địa chỉ của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Vui lòng kiểm tra hộp thư đến (bao gồm cả thư mục spam/quảng cáo) và nhấp vào liên kết trong email để xác minh tài khoản của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Đã xác minh',
                    onPressed: _checkEmailVerified,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Không nhận được email?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextButton(
                        onPressed: _canResendEmail ? _resendVerificationEmail : null,
                        child: Text(
                          _canResendEmail
                              ? 'Gửi lại Email'
                              : 'Gửi lại sau $_resendCooldown giây',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF89B3D4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/'); // Chuyển về màn hình đăng nhập/đăng ký
                    },
                    child: const Text(
                      'Quay lại màn hình Đăng nhập',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 290,
          child: CustomPaint(
            painter: WavePainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF89B3D4)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * -0.05,
        size.height * 0.3,
        size.width * 0.75,
        size.height * 0.9,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}