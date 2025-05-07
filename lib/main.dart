import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/home_screen.dart';
import 'package:total_english/services/otp_service.dart'; // Import OTPService

// Khai báo RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OTPService.configOTP(); // Cấu hình OTPService khi ứng dụng khởi động
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Lỗi khi khởi tạo Firebase")),
            );
          } else {
            // Firebase đã khởi tạo xong
            User? user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          }
        },
      ),
      // Thêm routeObserver vào navigatorObservers
      navigatorObservers: [routeObserver],
    );
  }
}
