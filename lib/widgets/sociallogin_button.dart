import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLoginButtons extends StatelessWidget {
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
        // Google - dùng hình ảnh thay vì icon
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _buildSocialButton(
            child: Image.asset(
              'assets/icon/gg_light.png',
              // width: 24,
              // height: 24,
            ),
            onTap: onGoogleTap,
          ),
        ),

        // Facebook - vẫn dùng icon
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: _buildSocialButton(
            child: Icon(
              FontAwesomeIcons.facebook,
              color: Color(0xFF1877F2),
              size: 30,
            ),
            onTap: onFacebookTap,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback onTap,
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
        child: Center(child: child),
      ),
    );
  }
}
