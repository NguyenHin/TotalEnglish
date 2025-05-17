import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/home_screen.dart';
//import 'package:total_english/services/otp_service.dart'; // Import OTPService

// Khai báo RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID channel phải trùng với ID bạn dùng để show notification
  'Thông báo quan trọng', // Tên channel sẽ hiện trong cài đặt Android
  description: 'Kênh để gửi các thông báo quan trọng của app',
  importance: Importance.high,
);


// ✅ Hàm xử lý thông báo nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📥 [Background] Message received: ${message.notification?.title}");
}

Future<void> main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await _initializeNotifications();     // ✅ thêm dòng này
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler); // ✅ chạy khi app tắt
  _setupFirebaseMessagingListener();    // ✅ và dòng này

  
  //OTPService.configOTP(); // Cấu hình OTPService khi ứng dụng khởi động
  
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


Future<void> _initializeNotifications() async {
  // Tạo channel trên Android (nếu có)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Cài đặt khởi tạo cho Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Tổng hợp các cài đặt
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // Khởi tạo flutter local notifications plugin với cài đặt trên
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void _setupFirebaseMessagingListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Phải trùng với channel ID khai báo trên
            'Thông báo quan trọng', 
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),

      );
    }
  });
}

