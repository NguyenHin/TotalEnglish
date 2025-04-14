import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:total_english/screens/setting_screen.dart';
import 'package:total_english/screens/about_screen.dart';
import 'package:total_english/screens/switch_account_screen.dart';
import 'package:total_english/screens/personal_info_screen.dart';
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/new_password.dart';
import 'package:total_english/services/auth_services.dart'; // Thêm dòng này

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _selectedLanguage = "vi"; // "vi" = Tiếng Việt, "en" = English

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text("🇻🇳", style: TextStyle(fontSize: 20)),
                title: const Text("Tiếng Việt"),
                onTap: () {
                  setState(() {
                    _selectedLanguage = "vi";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 20)),
                title: const Text("English"),
                onTap: () {
                  setState(() {
                    _selectedLanguage = "en";
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String get languageLabel {
    return _selectedLanguage == "vi" ? "🇻🇳 Tiếng Việt" : "🇺🇸 English";
  }

  void _showLogoutDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Xác nhận đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn thoát khỏi TotalEnglish không?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              await AuthService().signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD3E6F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/avatar.jpg'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Tên", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("Chuyển tài khoản", style: TextStyle(fontSize: 15, color: Colors.black)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SwitchAccountScreen()));
                        },
                        child: const Icon(Icons.compare_arrows),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1, color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListTile(
                      leading: Icon(Icons.settings, color: Colors.blue[700]),
                      title: const Text("Cài đặt"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD3E6F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.blue[700]),
                    title: const Text("Thông tin cá nhân"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.black),
                  ListTile(
                    leading: Icon(Icons.password, color: Colors.blue[700]),
                    title: const Text("Đổi mật khẩu"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewPassword()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD3E6F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.blue[700]),
                    title: const Text("Giới thiệu"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.black),
                  ListTile(
                    leading: Icon(Icons.language, color: Colors.blue[700]),
                    title: const Text("Ngôn ngữ"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(languageLabel),
                        const SizedBox(width: 10),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                    onTap: _showLanguagePicker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showLogoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Đăng xuất", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                "assets/icon/panda_icon.png",
                height: 230,
              ),
            ),
          ],
        ),
      ),
    );
  }
}