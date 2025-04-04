import 'package:flutter/material.dart';
import 'package:total_english/screens/login_screen.dart';


class MainScreen extends StatefulWidget{
  const MainScreen({super.key});
  @override
    MainScreenState createState() => MainScreenState();
  }

class MainScreenState extends State<MainScreen> {
  
  @override 
  void initState() {
    super.initState();
    //
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      });
    });
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF89B3D4),  // Màu nền theo mã màu bạn chọn
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              ClipOval(
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 290,
                  height: 290,
                  fit: BoxFit.cover, // Đảm bảo ảnh lấp đầy khung hình tròn
                ),
              ),

            SizedBox(height: 20),
            Text(
              'TotalEnglish',
              style: TextStyle(
                fontSize: 48,

                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Kavoon',
                shadows: [
                  Shadow(
                    blurRadius: 4.0, //Độ mờ
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    offset: Offset(3, 3), //Độ lệch
                  )
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}