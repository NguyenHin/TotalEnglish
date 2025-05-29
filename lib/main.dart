import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart'; // ✅ Localization
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/home_screen.dart';
import 'package:total_english/services/otp_service.dart'; // ✅ OTPService

// ✅ RouteObserver để theo dõi chuyển màn hình
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo EasyLocalization
  await EasyLocalization.ensureInitialized();

  // ✅ Cấu hình OTP Service (nếu bạn có)
  OTPService.configOTP();

  // ✅ Bọc app với EasyLocalization
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/lang', // ✅ Đường dẫn chứa file vi.json, en.json
      fallbackLocale: const Locale('en'),
      saveLocale: true, // ✅ Ghi nhớ lựa chọn của người dùng
      child: const MyApp(),
    ),
  );
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

      // ✅ Cấu hình localization
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,

      // ✅ Theme hoặc thêm cấu hình chung nếu cần
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
      ),

      // ✅ Đợi Firebase khởi tạo trước khi hiển thị màn hình
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text("firebase_init_error".tr())),
            );

          } else {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  final User? user = snapshot.data;
                  return user != null ? const HomeScreen() : const LoginScreen();
                } else {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            );
          }
        },
      ),

      // ✅ Theo dõi navigation nếu cần (Analytics,...)
      navigatorObservers: [routeObserver],
    );
  }
}
