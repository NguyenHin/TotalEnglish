import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Ẩn/hiện mật khẩu từng trường
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đổi mật khẩu thành công")),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Có lỗi xảy ra.";
      if (e.code == 'wrong-password') {
        message = "Mật khẩu hiện tại không đúng.";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu mới quá yếu.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggleVisibility,
          ),
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF1F9FF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBBDEFB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Đổi mật khẩu",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _currentPasswordController,
                label: "Mật khẩu hiện tại",
                icon: Icons.lock,
                obscure: _obscureCurrent,
                toggleVisibility: () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                },
                validator: (value) =>
                value == null || value.isEmpty ? "Vui lòng nhập mật khẩu hiện tại" : null,
              ),
              _buildTextField(
                controller: _newPasswordController,
                label: "Mật khẩu mới",
                icon: Icons.lock_outline,
                obscure: _obscureNew,
                toggleVisibility: () {
                  setState(() => _obscureNew = !_obscureNew);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Vui lòng nhập mật khẩu mới";
                  }
                  if (value.length < 6) {
                    return "Mật khẩu cần ít nhất 6 ký tự";
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _confirmPasswordController,
                label: "Xác nhận mật khẩu mới",
                icon: Icons.lock_reset,
                obscure: _obscureConfirm,
                toggleVisibility: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                validator: (value) =>
                value != _newPasswordController.text ? "Mật khẩu không khớp" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Xác nhận",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
