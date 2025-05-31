import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy thông tin người dùng hiện tại
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // 1. Đăng nhập bằng email & password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print("✅ Đăng nhập bằng email thành công");
      return credential;
    } catch (e) {
      print("❌ Lỗi đăng nhập email: $e");
      return null;
    }
  }

  // 2. Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Lưu thông tin người dùng vào Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'provider': 'google',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print("✅ Đăng nhập bằng Google thành công");
      return user;
    } catch (e) {
      print("❌ Lỗi đăng nhập Google: $e");
      return null;
    }
  }

  // 3. Đăng nhập bằng Facebook
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      print("Login result status: ${result.status}");
      print("Login result message: ${result.message}");
      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken;
        final credential = FacebookAuthProvider.credential(accessToken!.tokenString);
        UserCredential userCredential = await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          // Lưu thông tin người dùng vào Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'displayName': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'provider': 'facebook',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        print("✅ Đăng nhập bằng Facebook thành công");
        return user;
      } else {
        print("❌ Facebook login failed: ${result.message}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi đăng nhập Facebook: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      print("📤 Bắt đầu đăng xuất Firebase");

      // Đăng xuất Firebase
      await _auth.signOut();

      // Đăng xuất Google nếu đang đăng nhập bằng Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        print("🔁 Đã signOut Google");
      }

      // Đăng xuất Facebook nếu cần
      await FacebookAuth.instance.logOut();
      print("🔁 Đã signOut Facebook");

      print("✅ Đăng xuất thành công");
    } catch (e) {
      print("❌ Lỗi khi signOut: $e");
    }
  }

  Future<void> saveFCMTokenToFirestore(User user) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Lấy token FCM của thiết bị
    String? fcmToken = await messaging.getToken();

    if (fcmToken != null) {
      // Lưu token vào Firestore dưới document của user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': fcmToken,
      }, SetOptions(merge: true)); //merge để không ghi đè dữ liệu khác
      
      print("FCM Token saved: $fcmToken");
    }
  }
}
