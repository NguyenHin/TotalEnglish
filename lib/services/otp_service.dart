import 'package:email_otp/email_otp.dart';

class OTPService {
  /// Gọi 1 lần khi khởi tạo app hoặc khi bắt đầu quy trình gửi OTP
  static void configOTP() {
    EmailOTP.config(
      appName: 'Total English',
      otpLength: 4,
      otpType: OTPType.numeric,
      expiry: 300, // thời gian hết hạn (giây)
      emailTheme: EmailTheme.v6,
      appEmail: 'totalenglish.app@gmail.com',
    );
  }

  /// Gửi mã OTP đến email
  static Future<bool> sendOTP(String email) async {
    try {
      await EmailOTP.sendOTP(email: email);
      print('✅ Gửi OTP thành công đến $email');
      return true;
    } catch (e) {
      print('❌ Gửi OTP thất bại: $e');
      return false;
    }
  }

  /// Xác minh mã OTP người dùng nhập
  static Future<bool> verifyOTP(String otp) async {
    try {
      final result = await EmailOTP.verifyOTP(otp: otp);
      if (result) {
        print('✅ Mã OTP đúng');
      } else {
        print('⚠️ Mã OTP sai');
      }
      return result;
    } catch (e) {
      print('❌ Xác minh OTP thất bại: $e');
      return false;
    }
  }
}
