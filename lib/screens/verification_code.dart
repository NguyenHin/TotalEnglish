import 'package:flutter/material.dart';
import 'package:total_english/services/otp_service.dart'; // <-- thêm dòng này
import 'package:total_english/widgets/custom_button.dart';

class VerificationCode extends StatefulWidget {
  final String email;
  final bool autoFocus;

  const VerificationCode({
    super.key,
    required this.email,
    this.autoFocus = false,
  });

  @override
  _VerificationCodeState createState() => _VerificationCodeState();
}

class _VerificationCodeState extends State<VerificationCode> {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _verifyOTP() async {
    String otp = _controllers.map((e) => e.text).join();

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ mã OTP')),
      );
      return;
    }

    bool isValid = await OTPService.verifyOTP(otp);

    if (isValid) {
      Navigator.pushNamed(context, '/new_password');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mã OTP không đúng')),
      );
    }
  }

  void _resendCode() async {
    bool success = await OTPService.sendOTP(widget.email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Đã gửi lại mã xác minh đến ${widget.email}'
            : 'Gửi lại mã OTP thất bại'),
      ),
    );
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
            _buildVerificationForm(),
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
        icon: Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: OtpBox(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            index: index,
          ),
        );
      }),
    );
  }

  Widget _buildVerificationForm() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'Verification Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 100),
          Text(
            'Verification code sent to ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.email,
                  style: TextStyle(
                    color: Color(0xFF89B3D4),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOtpFields(),
          const SizedBox(height: 30),
          CustomButton(
            text: 'Confirm code',
            onPressed: _verifyOTP, // <-- gọi xác minh
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              TextButton(
                onPressed: _resendCode, // <-- gọi gửi lại
                child: Text(
                  "Resend code",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF89B3D4),
                  ),
                ),
              ),
            ],
          ),
        ],
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

class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.5),
            blurRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        textAlignVertical: TextAlignVertical.center,
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}
