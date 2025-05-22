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
                _buildListTile('Hướng dẫn sử dụng', context, const GuideScreen()),
                _buildListTile('Điều khoản sử dụng', context, const TermsScreen()),

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
                      onPressed: () {
                        // TODO: Thêm hành động đánh giá app
                      },
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
  // Hàm build ListTile chuyển trang
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

  // Icon hỗ trợ (facebook, google, phone)
  static Widget _buildSupportIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        // TODO: Thêm mở URL bằng url_launcher
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white,
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  // Nút quay lại trên góc trái
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

// Màn hình Hỗ trợ trực tuyến (mẫu)
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

// Màn hình Hướng dẫn sử dụng
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hướng dẫn sử dụng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            icon: Icons.download,
            title: '1. Tải và cài đặt ứng dụng',
            content:
            'Bạn có thể tải TotalEnglish từ Google Play Store hoặc App Store tùy thiết bị. '
            'Sau khi tải về, hãy mở ứng dụng và làm theo các bước đăng ký để bắt đầu học tập.',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.login,
            title: '2. Đăng nhập & Đăng ký',
            content:
            'Bạn có thể đăng nhập bằng email, tài khoản Google hoặc Facebook. '
                'Nếu chưa có tài khoản, chọn "Đăng ký" để tạo tài khoản mới, điền thông tin cần thiết và xác nhận qua email.',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.info_outline,
            title: '3. Cách hoạt động của ứng dụng',
            content:
            'TotalEnglish cung cấp các bài học từ vựng, ngữ pháp, kỹ năng nghe và nói. '
                'Bạn học qua các bài học có hình ảnh, âm thanh minh họa và bài tập tương tác để luyện tập hiệu quả.',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.book,
            title: '4. Học từ vựng',
            content:
            'Chọn mục "Từ vựng" trong menu chính. Mỗi từ đều có hình ảnh minh họa, phát âm chuẩn và ví dụ thực tế giúp bạn nhớ lâu hơn.',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.hearing,
            title: '5. Luyện nghe & nói',
            content:
            'Phần "Kỹ năng nghe" giúp bạn luyện nghe các đoạn hội thoại. '
                'Phần "Kỹ năng nói" cho phép ghi âm giọng nói và so sánh với giọng mẫu để cải thiện phát âm.',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.quiz,
            title: '6. Làm bài kiểm tra',
            content:
            'Sau khi học xong, bạn làm các bài trắc nghiệm để kiểm tra kiến thức. Kết quả sẽ được lưu và phân tích để cải thiện học tập.',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.settings,
            title: '7. Cài đặt & Hỗ trợ',
            content:
            'Bạn có thể thay đổi ngôn ngữ, cập nhật thông tin cá nhân hoặc liên hệ hỗ trợ qua Facebook, Google hoặc số điện thoại có trong mục "Giới thiệu".',
            style: sectionStyle,
          ),
          _buildSection(
            icon: Icons.lightbulb,
            title: '8. Mẹo sử dụng hiệu quả',
            content:
            'Hãy luyện tập đều đặn mỗi ngày, tận dụng phần ghi âm để cải thiện phát âm, và làm bài kiểm tra để đánh giá tiến bộ của bạn.',
            style: sectionStyle,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8),
              Text(title, style: style),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}


// Màn hình Điều khoản sử dụng
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản sử dụng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            title: '1. Chấp nhận điều khoản',
            content:
            'Bằng việc sử dụng ứng dụng TotalEnglish, bạn đồng ý tuân thủ các điều khoản và điều kiện được mô tả trong phần này.',
            style: sectionStyle,
          ),
          const Divider(height: 24, thickness: 1),
          _buildSection(
            title: '2. Quyền sử dụng',
            content:
            'Bạn được phép sử dụng ứng dụng cho mục đích học tập cá nhân, không được phép sao chép, phân phối hoặc sử dụng vào mục đích thương mại mà không có sự đồng ý.',
            style: sectionStyle,
          ),
          const Divider(height: 24, thickness: 1),
          _buildSection(
            title: '3. Bảo mật thông tin',
            content:
            'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn và không chia sẻ với bên thứ ba mà không có sự đồng ý.',
            style: sectionStyle,
          ),
          const Divider(height: 24, thickness: 1),
          _buildSection(
            title: '4. Trách nhiệm người dùng',
            content:
            'Bạn chịu trách nhiệm bảo mật tài khoản và không sử dụng ứng dụng vào các hoạt động vi phạm pháp luật.',
            style: sectionStyle,
          ),
          const Divider(height: 24, thickness: 1),
          _buildSection(
            title: '5. Thay đổi điều khoản',
            content:
            'TotalEnglish có quyền cập nhật và thay đổi điều khoản sử dụng bất cứ lúc nào mà không cần báo trước. Vui lòng kiểm tra thường xuyên.',
            style: sectionStyle,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: style),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}