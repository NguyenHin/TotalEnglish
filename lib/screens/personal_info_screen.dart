import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_english/services/auth_services.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void _editInfo() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPersonalInfoScreen(user: _currentUser != null ? {
          'name': _currentUser!.displayName ?? '',
          'email': _currentUser!.email ?? '',
          'birthdate': '',
          'phone': '',
        } : {},),
      ),
    );

    if (result != null) {
      setState(() {
        // Xử lý kết quả chỉnh sửa (nếu cần)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = _currentUser?.displayName ?? "Người dùng";
    String email = _currentUser?.email ?? "Chưa có";
    ImageProvider avatarImage = (_currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty)
        ? NetworkImage(_currentUser!.photoURL!)
        : const AssetImage('assets/icon/panda_icon.png') as ImageProvider;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Thông tin cá nhân",
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
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: avatarImage,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoTile("Họ và tên", displayName),
          _buildInfoTile("Email", email),
          _buildInfoTile("Ngày sinh", "Chưa có"),
          _buildInfoTile("Số điện thoại", "Chưa có"),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _editInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Chỉnh sửa thông tin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class EditPersonalInfoScreen extends StatefulWidget {
  final Map<String, String> user;

  const EditPersonalInfoScreen({super.key, required this.user});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController birthdateController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['name']);
    emailController = TextEditingController(text: widget.user['email']);
    birthdateController = TextEditingController(text: widget.user['birthdate']);
    phoneController = TextEditingController(text: widget.user['phone']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    birthdateController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _saveInfo() {
    Navigator.pop(context, {
      'name': nameController.text,
      'email': emailController.text,
      'birthdate': birthdateController.text,
      'phone': phoneController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa thông tin"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildTextField("Họ và tên", nameController),
            _buildTextField("Email", emailController),
            _buildTextField("Ngày sinh", birthdateController),
            _buildTextField("Số điện thoại", phoneController),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Lưu",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}