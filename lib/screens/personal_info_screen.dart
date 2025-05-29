import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PersonalInfoScreen extends StatefulWidget {
  final User user;

  const PersonalInfoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Nam';
  String? _photoUrl;
  File? _pickedImage;
  bool _isLoading = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = "${data['lastName'] ?? ''} ${data['firstName'] ?? ''}".trim();
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _gender = data['gender'] ?? 'Nam';
      _photoUrl = data['photoUrl'];
      if (data['birthDate'] != null) {
        _birthDate = (data['birthDate'] as Timestamp).toDate();
      }
    } else {
      _nameController.text = widget.user.displayName ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _photoUrl = null;
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Bỏ qua'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadAvatar(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('user_avatars/${widget.user.uid}.jpg');
      final snapshot = await ref.putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload ảnh: $e')));
      return null;
    }
  }

  Future<void> _saveAndExit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String? imageUrl = _photoUrl;

    if (_pickedImage != null) {
      imageUrl = await _uploadAvatar(_pickedImage!);
    }

    final nameParts = _nameController.text.trim().split(' ');
    final lastName = nameParts.length > 1 ? nameParts.sublist(0, nameParts.length - 1).join(' ') : '';
    final firstName = nameParts.isNotEmpty ? nameParts.last : '';

    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'gender': _gender,
      'photoUrl': imageUrl ?? '',
      'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
      'email': widget.user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set(data, SetOptions(merge: true));

    await widget.user.updateDisplayName(_nameController.text.trim());
    await widget.user.reload();

    Navigator.pop(context, true);
  }
  void _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBBDEFB),
        elevation: 0,
        centerTitle: true,
        title: const Text("Thông tin cá nhân", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black), // Đổi màu icon tại đây
            onPressed: _isLoading ? null : _saveAndExit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty
                        ? NetworkImage(_photoUrl!)
                        : const AssetImage('assets/icon/no_background.png')) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: InkWell(
                      onTap: _showImageSourceActionSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                          border: Border.all(width: 2, color: Colors.white),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Họ và tên",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Vui lòng nhập họ và tên";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Số điện thoại",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                controller: TextEditingController(text: widget.user.email),
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Ngày sinh",
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _birthDate != null
                        ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                        : 'Chọn ngày sinh',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.transgender),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Nam',
                        groupValue: _gender,
                        onChanged: (value) => setState(() => _gender = value!),
                      ),
                      const Text('Nam'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'Nữ',
                        groupValue: _gender,
                        onChanged: (value) => setState(() => _gender = value!),
                      ),
                      const Text('Nữ'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Địa chỉ",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
