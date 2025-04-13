import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/screens/verification_code.dart';
import 'package:total_english/services/otp_service.dart';
import 'package:total_english/widgets/acc_textfield.dart';
import 'package:total_english/widgets/custom_button.dart';

class ForgotPassword extends StatefulWidget{
  const ForgotPassword({super.key});
  @override
    // ignore: library_private_types_in_public_api
    _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  
  @override
    void dispose() {
      _emailController.dispose();
      _emailFocusNode.dispose();
      super.dispose();
    }

  //kiểm tra email đã đăng ký chưa?
  Future<bool> checkEmailExists(String email) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

  return snapshot.docs.isNotEmpty;
}


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),

      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        resizeToAvoidBottomInset: false, //Tránh giao diện bị đẩy lên khi bàn phím xuất hiện
        body: Stack(
          children: [
            _buildBackground(),
            _buildBackButton(context),
            _forgotPasswordForm(),
          ],
          
        ),
      ),
    );
  }



  Widget _buildBackground() {
    return Stack(
      children: [
        // Nền cong phía trên (WavePainter)
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
        icon: Icon(Icons.chevron_left, size: 28,)
      ),
    );
  } 

  Widget _forgotPasswordForm() {
    return Positioned(
      top: 100, // Điều chỉnh top nếu cần để đảm bảo chữ không bị che khuất
      left: 20,
      right: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Forgot Password?',
              textAlign: TextAlign.center, // Căn giữa chữ
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 80),
            
            const Text(
              "Please write your email to receive a \nconfirmation code to set a new password",
              textAlign: TextAlign.center, // Căn giữa chữ
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                color: Colors.black
              ),
            ),
            const SizedBox(height: 40),

            AccTextfield(
              hintText: 'Email', 
              controller: _emailController,
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: "Confirm mail",
              onPressed: () async {
                final email = _emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập email')),
                  );
                  return;
                }

                try {
                  // Nếu không có lỗi ở đây thì email chắc chắn đã tồn tại
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                  
                } catch (e) {
                  print('Lỗi khi gửi reset email: $e');

                  // Lúc này mới là email không tồn tại
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email chưa được đăng ký.')),
                  );
                }
              }

            )

          ],
        ),
    );
  }
}
class WavePainter extends CustomPainter{
  @override
  void paint(Canvas canvas, Size size){
    final paint = Paint()
      ..color = const Color(0xFF89B3D4)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      //đường cong
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