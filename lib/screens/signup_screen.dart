import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/services/auth_services.dart';
import 'package:total_english/widgets/acc_textfield.dart';
import 'package:total_english/widgets/custom_button.dart';
import 'package:total_english/widgets/sociallogin_button.dart';
import 'package:total_english/screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    // Kiểm tra nếu email hoặc mật khẩu trống
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    // Kiểm tra nếu mật khẩu và xác nhận mật khẩu không khớp
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu và xác nhận mật khẩu không khớp')),
      );
      return;
    }

    try {
      // Tạo tài khoản mới với email và mật khẩu
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kiểm tra nếu người dùng đã được đăng nhập thành công
      if (userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo tài khoản thành công')),
        );

        // Chuyển hướng đến HomeScreen sau khi đăng ký thành công
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý lỗi khi Firebase trả về lỗi
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email đã được sử dụng')),
        );
      } else if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu quá yếu, phải có ít nhất 6 ký tự')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi không xác định: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 130),
                  _buildTitle(),
                  const SizedBox(height: 50),
                  _buildSubtitle(),
                  const SizedBox(height: 25),
                  
                  // Account text field
                  AccTextfield(
                    hintText: 'Email', 
                    controller: _emailController,
                  ),
                  const SizedBox(height: 30),
                  AccTextfield(
                    hintText: 'Password', 
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 30),
                  AccTextfield(
                    hintText: 'Confirm Password', 
                    controller: _confirmController,
                  ),
                  const SizedBox(height: 40),

                  // Button
                  CustomButton(
                    text: "Sign up", 
                    onPressed: _signup,
                  ),
                  const SizedBox(height: 20),

                  // OR section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 125,
                        height: 1,
                        color: Colors.black54,
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
                      Container(
                        width: 125,
                        height: 1,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google, Facebook login buttons
                  SocialLoginButtons(
                    onGoogleTap: () async {
                      User? user = await AuthService().signInWithGoogle();
                      if (user != null && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      } else {
                        // Hiện thông báo lỗi nếu cần
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
                ],
              ),
            ),
            // Back button
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 20,
      top: 74,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        }, 
        icon: const Icon(Icons.chevron_left, size: 28,),
      ),
    );
  }

  Widget _buildTitle() {
    return const Center(  
      child: Text(
        'TotalEnglish',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          fontFamily: 'Kadwa',
          color: Color(0xFF116BAF),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      "Create your Account",
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w300,
        fontFamily: 'inter',
        color: Colors.black,
      ),
    );
  }
}
