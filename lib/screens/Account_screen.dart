import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/screens/setting_screen.dart';
import 'package:total_english/screens/about_screen.dart';
import 'package:total_english/screens/personal_info_screen.dart';
import 'package:total_english/screens/switch_account_screen.dart';
import 'package:total_english/screens/login_screen.dart';
import 'package:total_english/screens/change_password_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? currentUser;

  String displayName = "";
  String email = "";
  String? photoUrl;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
          _loadUserInfo(user);
        });
      }
    });

    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadUserInfo(currentUser);
    }
  }

  void _loadUserInfo(User? user) {
    if (user != null) {
      displayName = user.displayName ?? user.email ?? tr("no_name");
      email = user.email ?? "";
      photoUrl = user.photoURL;
    } else {
      displayName = tr("not_logged_in");
      email = "";
      photoUrl = null;
    }
  }

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
                  context.setLocale(const Locale('vi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 20)),
                title: const Text("English"),
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr("logout_confirm_title")),
          content: Text(tr("logout_confirm_content")),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr("cancel")),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              child: Text(tr("logout")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF1F9FF);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBBDEFB),
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr("account"),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD6ECFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: photoUrl != null
                        ? NetworkImage("$photoUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}")
                        : const AssetImage('assets/icon/no_background.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuCard([
              _buildListTile(
                icon: Icons.person_outline,
                title: tr("personal_info"),
                onTap: () async {
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr("not_logged_in"))),
                    );
                    return;
                  }

                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInfoScreen(user: currentUser!),
                    ),
                  );

                  if (updated == true) {
                    await FirebaseAuth.instance.currentUser?.reload();
                    final refreshedUser = FirebaseAuth.instance.currentUser;

                    setState(() {
                      currentUser = refreshedUser;
                      _loadUserInfo(refreshedUser);
                    });
                  }
                },
              ),
              _divider(),
              _buildListTile(
                icon: Icons.lock_outline,
                title: tr("change_password"),
                onTap: () {
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr("not_logged_in"))),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _divider(),
              _buildListTile(
                icon: Icons.switch_account_outlined,
                title: tr("switch_account"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SwitchAccountScreen()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 16),
            _buildMenuCard([
              _buildListTile(
                icon: Icons.settings,
                title: tr("settings"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              _divider(),
              _buildListTile(
                icon: Icons.language,
                title: tr("language"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.locale.languageCode == "vi"
                          ? "🇻🇳 Tiếng Việt"
                          : "🇺🇸 English",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.expand_more),
                  ],
                ),
                onTap: _showLanguagePicker,
              ),
              _divider(),
              _buildListTile(
                icon: Icons.info_outline,
                title: tr("about"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _showLogoutDialog,
                child: Text(
                  tr("logout"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              "Phiên bản 1.0.0",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}