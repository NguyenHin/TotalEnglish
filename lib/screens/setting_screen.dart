import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEffectsEnabled = true;
  bool _notificationsEnabled = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data()?['settings'] ?? {};

    setState(() {
      _soundEffectsEnabled = data['soundEffects'] ?? true;
      _notificationsEnabled = data['notifications'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'settings': {key: value}
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                const SizedBox(height: 100),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSettingCard(
                        icon: Icons.music_note,
                        title: 'Hiệu ứng âm thanh',
                        value: _soundEffectsEnabled,
                        onChanged: (value) {
                          setState(() => _soundEffectsEnabled = value);
                          _updateSetting('soundEffects', value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        icon: Icons.notifications_active,
                        title: 'Cho phép nhận thông báo',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                          _updateSetting('notifications', value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Custom AppBar
          Container(
            height: 100,
            padding: const EdgeInsets.only(top: 50),
            color: Colors.white,
            child: const Center(
              child: Text(
                'Cài đặt',
                style: TextStyle(
                  fontFamily: 'Koh Santepheap',
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Back button
          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: Transform.scale(
        scale: 0.75,
        child: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.chevron_left,
            size: 40,
            color: Colors.black,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade300,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
