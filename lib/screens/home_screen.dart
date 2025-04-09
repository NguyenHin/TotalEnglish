import 'package:flutter/material.dart';
import 'lesson_screen.dart';
import 'streak_screen.dart';
import 'notification_screen.dart';
import 'Account_screen.dart';  // Import màn hình tài khoản
import 'package:total_english/widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LessonScreen(),
    StreakScreen(),
    NotificationScreen(),
    AccountScreen(),  // Thêm màn hình tài khoản vào danh sách
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
