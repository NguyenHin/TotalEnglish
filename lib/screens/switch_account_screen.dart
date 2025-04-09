import 'package:flutter/material.dart';

class SwitchAccountScreen extends StatefulWidget {
  const SwitchAccountScreen({super.key});

  @override
  State<SwitchAccountScreen> createState() => _SwitchAccountScreenState();
}

class _SwitchAccountScreenState extends State<SwitchAccountScreen> {
  List<Map<String, String>> accounts = [
    {
      'name': 'Tài khoản A',
      'email': 'email_a@gmail.com',
      'avatar': 'assets/avatar.jpg',
      'selected': 'true',
    },
    {
      'name': 'Tài khoản B',
      'email': 'email_b@gmail.com',
      'avatar': 'assets/avatar.jpg',
      'selected': 'false',
    },
  ];

  // Giả lập danh sách tài khoản hợp lệ
  final validAccounts = {
    'user1@gmail.com': {'password': '123456', 'name': 'Tài khoản C'},
    'user2@gmail.com': {'password': 'abcdef', 'name': 'Tài khoản D'},
  };

  void _addNewAccount(String name, String email) {
    setState(() {
      accounts.add({
        'name': name,
        'email': email,
        'avatar': 'assets/avatar.jpg', // avatar mặc định
        'selected': 'false',
      });
    });
  }

  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Đăng nhập tài khoản'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  if (validAccounts.containsKey(email) &&
                      validAccounts[email]!['password'] == password) {
                    final name = validAccounts[email]!['name']!;
                    _addNewAccount(name, email);
                    Navigator.pop(context);
                  } else {
                    setStateDialog(() {
                      errorMessage = 'Email hoặc mật khẩu không đúng';
                    });
                  }
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD3E6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chuyển tài khoản",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...accounts.map((account) {
            return Column(
              children: [
                ListTile(
                  tileColor: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(account['avatar']!),
                  ),
                  title: Text(account['name']!),
                  subtitle: Text(account['email']!),
                  trailing: account['selected'] == 'true'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      for (var acc in accounts) {
                        acc['selected'] = 'false';
                      }
                      account['selected'] = 'true';
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showLoginDialog,
            icon: const Icon(Icons.add),
            label: const Text("Thêm tài khoản mới"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
