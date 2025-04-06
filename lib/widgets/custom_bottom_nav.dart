import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.bookOpen),
          label: 'Bài học',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.fire),
          label: 'Streak',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Thông báo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
