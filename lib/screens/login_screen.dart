import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/screens/forgot_password.dart';
import 'package:total_english/screens/home_screen.dart';
import 'package:total_english/screens/signup_screen.dart';
import 'package:total_english/services/auth_services.dart';
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

  int failedLoginAttempts = 0; //đếm số lần đăng nhập

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  return emailRegex.hasMatch(email);
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
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Stack(
    children: [
      // Language switcher
      Positioned(
        left: screenWidth * 0.6,
        top: screenHeight * 0.07,
        child: LanguageSwitcher(
          onLanguageChanged: (String newLanguage) {
            debugPrint('Ngôn ngữ đã đổi sang: $newLanguage');
          },
        ),
      ),

      // Email field
      Positioned(
        left: screenWidth * 0.07,
        top: screenHeight * 0.49,
        child: SizedBox(
          width: screenWidth * 0.87,
          child: CustomTextField(
            hintText: 'Email',
            icon: Icons.email,
            controller: emailController,
          ),
        ),
      ),

      // Password field
      Positioned(
        left: screenWidth * 0.07,
        top: screenHeight * 0.555,
        child: SizedBox(
          width: screenWidth * 0.87,
          child: CustomTextField(
            hintText: 'Password',
            icon: Icons.lock,
            controller: passwordController,
            isPassword: true,
          ),
        ),
      ),

      // Forgot password
      Positioned(
        left: screenWidth * 0.65,
        top: screenHeight * 0.605,
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const ForgotPassword()),
            );
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

      // Login button
      Positioned(
        left: screenWidth * 0.07,
        top: screenHeight * 0.66,
        child: SizedBox(
          width: screenWidth * 0.87,
          child: CustomButton(
            text: 'Login',
            onPressed: () async {
  try {
    final credential = await AuthService().signInWithEmail(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (credential != null) {
      // Kiểm tra trạng thái xác minh email
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        // Nếu email đã được xác minh, chuyển đến màn hình chính
        failedLoginAttempts = 0; // reset
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Nếu email chưa được xác minh, thông báo cho người dùng
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng xác minh email của bạn.')),
        );
        // Bạn có thể gửi lại email xác minh nếu cần
        await user?.sendEmailVerification();
      }
    } else {
      throw Exception('Đăng nhập thất bại');
    }
  } catch (e) {
    failedLoginAttempts++;

    String message = 'Email hoặc mật khẩu không đúng';
    if (failedLoginAttempts >= 3) {
      message += '\nBạn quên mật khẩu? Hoặc chưa có tài khoản?';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}





          ),
        ),
      ),


      // ---- OR ---- line
      Positioned(
        top: MediaQuery.of(context).size.height * 0.72,
        left: MediaQuery.of(context).size.width * 0.13,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black54,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Or',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),

      // Social login buttons
      Positioned(
        top: MediaQuery.of(context).size.height * 0.75,
        left: MediaQuery.of(context).size.width * 0.33,
        child: SocialLoginButtons(
          onGoogleTap: () async {
            await AuthService().signOut(); // <- Thêm dòng này

            User? user = await AuthService().signInWithGoogle();
            if (user != null && context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đăng nhập thất bại')),
              );
            }
          },

          onFacebookTap: () async {
            User? user = await AuthService().signInWithFacebook();
            if (user != null && context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              // Hiện thông báo lỗi nếu cần
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đăng nhập bằng Facebook thất bại')),
              );
            }
          },
        ),
      ),

      // Sign up text
      Positioned(
        top: screenHeight * 0.82,
        left: screenWidth * 0.2,
        child: Row(
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 5),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
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

