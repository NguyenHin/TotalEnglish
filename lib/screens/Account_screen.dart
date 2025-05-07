import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/screens/setting_screen.dart';
import 'package:total_english/screens/about_screen.dart';
import 'package:total_english/screens/switch_account_screen.dart';
import 'package:total_english/screens/personal_info_screen.dart';

import 'package:total_english/screens/main_screen.dart';
import 'package:total_english/screens/new_password.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _selectedLanguage = "vi";

//   User? _currentUser;
//   final AuthService _authService = AuthService();

//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentUser();
//   }

//   Future<void> _loadCurrentUser() async {
//     final user = await _authService.getCurrentUser();
//     if (mounted) {
//       setState(() {
//         _currentUser = user;
//       });
//     }
//   }


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

                await _authService.signOut();

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
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Tài khoản",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD3E6F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
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
                        Text("Tên người dùng",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Chuyển tài khoản",
                            style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ],

                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.compare_arrows),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SwitchAccountScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuCard([
              _buildListTile(
                icon: Icons.person_outline,
                title: "Thông tin cá nhân",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PersonalInfoScreen()),
                  );
                },
              ),

              _divider(),
              _buildListTile(
                icon: Icons.lock_outline,
                title: "Đổi mật khẩu",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewPassword()),
                  );
                },

              ),
            ]),
            const SizedBox(height: 16),
            _buildMenuCard([
              _buildListTile(
                icon: Icons.settings,
                title: "Cài đặt",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),

              _divider(),
              _buildListTile(
                icon: Icons.language,
                title: "Ngôn ngữ",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(languageLabel, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    const Icon(Icons.expand_more),
                  ],
                ),
                onTap: _showLanguagePicker,

              ),
              _divider(),
              _buildListTile(
                icon: Icons.info_outline,
                title: "Giới thiệu",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                //onPressed: _showLogoutDialog,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _showLogoutDialog,
                child: const Text(
                  "Đăng xuất",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Image.asset(
                  "assets/icon/panda_icon.png",
                  height: 220,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: Colors.black12);
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD3E6F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Bạn có chắc chắn muốn đăng xuất khỏi TotalEnglish không?",
            style: TextStyle(fontSize: 16),
          ),
          actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: const Text("Đăng xuất"),
            ),
          ],
        );
      },
    );
  }
}

