import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLoginButtons extends StatelessWidget{
  final VoidCallback onGoogleTap;
  final VoidCallback onFacebookTap;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onFacebookTap,
  });

  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Google
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildSocialButton(
              icon: FontAwesomeIcons.google,
              color: Color(0xFF89B3D4),
              onTap: onGoogleTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _buildSocialButton(
              icon: FontAwesomeIcons.facebook,
              color: Color(0xFF89B3D4),
              onTap: onFacebookTap,
            ),
          ),
        ],
    );
    
  }

  Widget _buildSocialButton({
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Center(
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }

}