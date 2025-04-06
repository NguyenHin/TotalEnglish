import 'package:flutter/material.dart';
import 'package:total_english/widgets/acc_textfield.dart';
import 'package:total_english/widgets/custom_button.dart';

class NewPassword extends StatefulWidget{
    const NewPassword({super.key});

    @override
    _NewPasswordState createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordControlller = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordControlller.dispose();
    super.dispose();
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
            _newPasswordForm(),
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

    Widget _newPasswordForm() {
        return Positioned(
        top: 100, // Điều chỉnh top nếu cần để đảm bảo chữ không bị che khuất
        left: 20,
        right: 20,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                const Text(
                'New Password',
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
                "Please write your new password",
                textAlign: TextAlign.center, // Căn giữa chữ
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Colors.black
                ),
                ),
                const SizedBox(height: 40),

                AccTextfield(
                    hintText: "Password", 
                    controller: _passwordController
                ),
                const SizedBox(height: 40),

                AccTextfield(
                    hintText: "Confirm password", 
                    controller: _confirmPasswordControlller
                ),
                const SizedBox(height: 40),

                CustomButton(
                    text: "Confirm password", 
                    onPressed: (){
                      //  ...
                    }
                ),
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