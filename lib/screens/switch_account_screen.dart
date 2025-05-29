import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SwitchAccountScreen extends StatefulWidget {
  const SwitchAccountScreen({super.key});

  @override
  State<SwitchAccountScreen> createState() => _SwitchAccountScreenState();
}

class _SwitchAccountScreenState extends State<SwitchAccountScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  void _refreshUser() {
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  void _addNewAccount() async {
    final newAccount = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (newAccount != null) {
      _refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm tài khoản ${newAccount["email"]}')),
      );
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    _refreshUser();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất tài khoản')));
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF1F9FF);
    const cardColor = Color(0xFFEAF6FF);
    const buttonColor = Color(0xFF64B5F6);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Tài khoản', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.black54),
          ),
        ),
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _addNewAccount,
            child: const Text(
              'Đăng nhập tài khoản',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final photoUrl =
        currentUser!.photoURL ?? 'assets/images/default_avatar.png';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tài khoản hiện tại',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.black54),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              color: cardColor,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                leading: CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      photoUrl.startsWith('http')
                          ? NetworkImage(photoUrl)
                          : AssetImage(photoUrl) as ImageProvider,
                ),
                title: Text(
                  currentUser!.displayName ?? 'Không có tên',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  currentUser!.email ?? 'Không có email',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  tooltip: 'Đăng xuất',
                  onPressed: _signOut,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(child: Container()),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.only(left: 16, bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _addNewAccount,
          label: const Text(
            'Thêm tài khoản mới',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.black54),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
