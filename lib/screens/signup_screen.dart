import 'package:flutter/material.dart';
import 'package:total_english/widgets/acc_textfield.dart';
import 'package:total_english/widgets/custom_button.dart';
import 'package:total_english/widgets/sociallogin_button.dart';

class SignupScreen extends StatefulWidget{
  const SignupScreen({super.key});
  
  @override
    // ignore: library_private_types_in_public_api
    _SignupScreenState createState() => _SignupScreenState();
  
   
}

class _SignupScreenState extends  State<SignupScreen> {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Khi bấm ra ngoài, ẩn bàn phím
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
                  const SizedBox(height: 130), // Khoảng cách từ trên
                  _buildTitle(),
                  const SizedBox(height: 50),
                  _buildSubtitle(),
                  const SizedBox(height: 25),
                  
                  //account text field
                  AccTextfield(
                    hintText: 'Email', 
                    controller: _emailController
                  ),
                  const SizedBox(height: 30),
                  AccTextfield(
                    hintText: 'Password', 
                    controller: _passwordController
                  ),
                  const SizedBox(height: 30),
                  AccTextfield(
                    hintText: 'Confirm Password', 
                    controller: _confirmController
                  ),
                  const SizedBox(height: 40),

                  //button
                  CustomButton(
                    text: "Sign up", 
                    onPressed: (){
                      //...
                    }),
                  const SizedBox(height: 20),

                  //----OR----
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

                  //gg, fb button
                  SocialLoginButtons(
                    onGoogleTap: () {}, 
                    onFacebookTap: (){}
                  )


                ],
              ),
            ),
            // Nút back được đặt trong Stack
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
        icon: Icon(Icons.chevron_left, size: 28,)
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
          color: Color(0xFF116BAF)
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