import 'package:flutter/material.dart';
import 'package:total_english/screens/signup_screen.dart';
import 'package:total_english/widgets/custom_button.dart';
import 'package:total_english/widgets/custom_textfield.dart';
import 'package:total_english/widgets/language_switcher.dart';
import 'package:total_english/widgets/sociallogin_button.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  

  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(), // Khi bấm ra ngoài, ẩn bàn phím
    
    child: Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      resizeToAvoidBottomInset: false,  // Tránh giao diện bị đẩy lên khi bàn phím xuất hiện
      body: Stack(
        children: [
          _buildBackground(),
          _buildLoginForm(),
          _buildLogo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        //Nen cong phia tren (WavePainter)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 393,
          child: CustomPaint(
            painter: WavePainter(),
          ),
        ),

        //Nen cong duoi (BottomWavePainter)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: CustomPaint(
            painter: BottomWavePainter(),
            size: Size(MediaQuery.of(context).size.width, 120),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
  return Stack(
    children: [
      //choose languge
      Positioned(
        left: 235,
        top: 59,
        child: LanguageSwitcher(
          onLanguageChanged: (String newLanguage) {
            debugPrint('Ngôn ngữ đã đổi sang: $newLanguage');
          },
        ),
      ),

      //email
      Positioned(
        left: 27,
        top: 400,
        child: SizedBox(
          width: 355,
          child: CustomTextField(
            hintText: 'Username or Email', 
            icon: Icons.email, 
            controller: emailController
          ),
        ),
      ),

      //password
      Positioned(
        left: 27,
        top: 455,
        child: SizedBox(
          width: 355,
          child: CustomTextField(
            hintText: 'Password', 
            icon: Icons.lock, 
            controller: passwordController,
            isPassword: true,
          ),
        ),
      ),

      //forgetpassword
      Positioned(
        left: 266,
        top: 495,
        child: TextButton(
          onPressed: () {
            //chuyển đến ForgetPassScreen
          }, 
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),

      //login button
      Positioned(
        left: 27,
        top: 545,
        child: SizedBox(
          width: 355,
          child: CustomButton(
            text: 'Login', 
            onPressed: () {
              //xu ly dang nhap
            },
          ),
        ),
      ),
      
      //SignUp
      Positioned(
        left: 95,
        top: 700,
        child: Row(
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 5),
            TextButton(
              onPressed: () {
                //chuyển đến SignUpScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupScreen()
                  ),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),

      //---- Or ----
      Positioned(
        left: 67,
        top: 600,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 125,
              height: 1,
              color: Colors.black54,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Or',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
            Container(
              width: 125,
              height: 1,
              color: Colors.black54,
            )
          ],
        )
      ),

      //fb, gg button
      Positioned(
        left: 138,
        top: 640,
        child: SocialLoginButtons(
          onGoogleTap: () {
            // Xử lý khi người dùng nhấn vào nút Google
            print("Google login tapped");
          },
          onFacebookTap: () {
            // Xử lý khi người dùng nhấn vào nút Facebook
            print("Facebook login tapped");
          },
        ),
      )

    ],
  );
}
 
  Widget _buildLogo() {
  return Positioned(
    top: 191,
    left: 0, // Không cần phải xác định left nữa
    right: 0, // Đặt right = 0 để căn giữa
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
      crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều ngang
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 161,
            height: 161,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6), // Khoảng cách giữa hình ảnh và chữ
        const Text(
          'Total English',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF116BAF),
            fontFamily: 'Kadwa',
          ),
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
      //
      ..cubicTo(
        size.width * 0.0, 
        size.height * -0.45, 
        size.width * 0.82, 
        size.height * 0.98, 
        size.width, 
        size.height * 0.3,
        )

      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
      
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
class BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF89B3D4)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, size.height * 0.8)

      ..cubicTo(
        size.width * -0.1, size.height * -0.7, 
        size.width * 0.7, size.height * 1.5, 
        size.width, size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldeDelegate) => false;
}

