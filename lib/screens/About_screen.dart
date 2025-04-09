import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Giới thiệu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 24, thickness: 0.8),
                const SizedBox(height: 4),

                Column(
                  children: const [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: AssetImage('assets/icon/app_icon.png'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'English',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Phiên bản: 1.1.1',
                      style: TextStyle(fontSize: 17),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1, height: 1, color: Colors.black),

                // Mỗi mục sẽ dẫn đến một màn hình khác
                _buildListTile('Hỗ trợ trực tuyến', context, SupportScreen()),
                _buildListTile('Hướng dẫn sử dụng', context, GuideScreen()),
                _buildListTile('Điều khoản sử dụng', context, TermsScreen()),

                const Divider(thickness: 1, height: 24),

                const Text(
                  'Hỗ trợ trực tuyến',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),

                // Icon hỗ trợ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSupportIcon(FontAwesomeIcons.facebookF, Colors.blue, 'https://www.facebook.com'),
                    const SizedBox(width: 30),
                    _buildSupportIcon(FontAwesomeIcons.google, Colors.redAccent, 'https://www.google.com'),
                    const SizedBox(width: 30),
                    _buildSupportIcon(Icons.phone, Colors.black87, 'tel:+1234567890'),
                  ],
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'ĐÁNH GIÁ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '2025 Copyright TotalEnglish',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 8),
              ],
            ),
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  // Cập nhật ListTile để điều hướng đến màn hình khác
  static Widget _buildListTile(String title, BuildContext context, Widget nextScreen) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          },
        ),
        const Divider(
          thickness: 1.2,
          height: 1,
          color: Colors.black87,
        ),
      ],
    );
  }

  static Widget _buildSupportIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        // TODO: Mở URL nếu cần (sử dụng url_launcher)
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white,
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  static Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 4,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }
}

// Các màn hình mẫu cho "Hỗ trợ trực tuyến", "Hướng dẫn sử dụng", và "Điều khoản sử dụng"
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ trực tuyến')),
      body: const Center(child: Text('Thông tin hỗ trợ trực tuyến')),
    );
  }
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn sử dụng')),
      body: const Center(child: Text('Thông tin hướng dẫn sử dụng')),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điều khoản sử dụng')),
      body: const Center(child: Text('Thông tin điều khoản sử dụng')),
    );
  }
}
