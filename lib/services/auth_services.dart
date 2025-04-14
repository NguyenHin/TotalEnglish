import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  // 3. Đăng nhập bằng Facebook
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
// Kiểm tra trạng thái login
    print("Login result status: ${result.status}");
    print("Login result message: ${result.message}");
      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken;
        final credential = FacebookAuthProvider.credential(accessToken!.tokenString);
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        print("✅ Đăng nhập bằng Facebook thành công");
        return userCredential.user;
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


}
