import 'package:flutter/material.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';

class SpeakingScreen extends StatelessWidget {
  const SpeakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              _buildBackButton(context),
              _buildHeaderLesson(context),
              _buildSpeakingForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakingForm(BuildContext context) {
    return Positioned(
      top: 190, // Đặt vị trí khung phía dưới HeaderLesson
      left: 22,
      right: 22,
      child: Container(
        width: 370, // Kích thước chiều rộng của khung
        height: 650, // Kích thước chiều cao của khung
        decoration: BoxDecoration(
          color: const Color(0xFFD3E6F6), // Màu nền khung
          borderRadius: BorderRadius.circular(20), // Bo góc 20
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Padding cho nội dung bên trong
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Căn giữa nội dung
            crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều ngang
            children: [
              // Hiển thị từ vựng
              Text(
                'Apple', // Từ vựng
                style: TextStyle(
                  fontSize: 35, // Kích thước chữ lớn cho từ vựng
                  fontWeight: FontWeight.w400, // Đậm cho từ vựng
                  color: Colors.black, // Màu chữ
                ),
                textAlign: TextAlign.center, // Căn giữa
              ),
              const SizedBox(height: 5), // Khoảng cách giữa từ vựng và phiên âm
              Text(
                '/ˈæp.əl/', // Phiên âm
                style: TextStyle(
                  fontSize: 20, // Kích thước chữ nhỏ hơn cho phiên âm
                  fontWeight: FontWeight.w300, // Nhẹ hơn một chút
                  color: Colors.black54, // Màu chữ nhạt hơn
                ),
                textAlign: TextAlign.center, // Căn giữa
              ),
              const SizedBox(height: 20), // Khoảng cách giữa phiên âm và nút Play
              // Các nút Play và Microphone
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều ngang
                children: [
                  // Nút Play
                  PlayButton(
                    onPressed: () {
                      // Thêm hành động phát âm thanh ở đây nếu cần
                    },
                    label: "Nghe", // Label cho nút Play
                  ),
                  const SizedBox(width: 40), // Khoảng cách giữa nút Play và Microphone
                  // Nút Microphone (không còn chức năng ghi âm)
                  InkWell(
                    onTap: () {
                      // Bạn có thể thêm hành động cho nút này nếu cần, ví dụ, hiển thị một thông báo
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF89B3D4), // Màu nền cho nút Microphone
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mic, // Biểu tượng microphone
                            size: 30,
                            color: Colors.white, // Màu biểu tượng
                          ),
                        ),
                        const SizedBox(height: 8), // Khoảng cách giữa icon và label
                        Text(
                          "Nói", // Label cho nút Microphone
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Hiển thị phần trăm khi nói xong
              // Bạn có thể loại bỏ phần này nếu không cần hiển thị độ chính xác
              // const SizedBox(height: 20),
              // Hình ảnh Panda sẽ bị ẩn sau khi nói xong
              Image.asset(
                'assets/icon/no_background.png',
                width: 210,
                height: 210,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng nút back
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context); // Quay lại màn hình trước
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  // Hàm gọi HeaderLesson với tiêu đề "Speaking"
  Widget _buildHeaderLesson(BuildContext context) {
    return Positioned(
      top: 100,
      left: 22,
      right: 22,
      child: const HeaderLesson(
        title: 'Speaking', // Tiêu đề của màn hình
        color: Color(0xFF89B3D4), // Màu sắc cho header
      ),
    );
  }
}
