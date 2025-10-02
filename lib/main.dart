import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/home_screen.dart';
import 'package:total_english/services/streak_services.dart';


// RouteObserver để theo dõi chuyển màn hình
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Thông báo quan trọng',
  description: 'Kênh để gửi các thông báo quan trọng của app',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📥 [Background] Message received: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();

  // Khởi tạo Notification và Messaging
  await _initializeNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  _setupFirebaseMessagingListener();


  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Localization
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
      ),

      home: FutureBuilder(
        future: Firebase.initializeApp(),
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
            /*dùng StreamBuilder vì cần lắng nghe trạng thái đăng nhập thay đổi theo thời gian thực.
Nếu chỉ dùng Future thì nó chỉ check một lần, không thể cập nhật khi user login/logout.
→ Điều đó sẽ dẫn đến việc: đăng nhập rồi nhưng không vào HomeScreen, hoặc đăng xuất rồi mà vẫn ở lại trong app. */
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(), //lắng nghe trạng thái user theo thời gian thưc
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.active) { //if stream đã hđ
                  final user = userSnapshot.data;
                  if (user != null) {
                    // Kiểm tra và reset streak nếu cần
                    checkAndResetStreakIfMissedDay().then((_) {
                      print('✅ Đã kiểm tra và reset streak nếu cần');
                    });
                    return const HomeScreen();
                  } else {
                    return const LoginScreen();
                  }
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
      navigatorObservers: [routeObserver],
    );
  }
}

// ==================== NOTIFICATION SETUP ===================

Future<void> _initializeNotifications() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

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
            'high_importance_channel',
            'Thông báo quan trọng',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}
