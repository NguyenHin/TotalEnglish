import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
//import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  List<String> _activeMotivations = [];
  List<String> _lostMotivations = [];
  

  @override
  void initState() {
    super.initState();
    _loadMotivations();
  }

  //lấy motivation
  Future<void> _loadMotivations() async {
    try {
      final activeSnapshot = await FirebaseFirestore.instance.collection('motivations_active').get();
      if (activeSnapshot.docs.isNotEmpty) {
        setState(() {
          _activeMotivations = activeSnapshot.docs.map((doc) => doc['text'] as String).toList();
        });
      }

      final lostSnapshot = await FirebaseFirestore.instance.collection('motivations_lost').get();
      if (lostSnapshot.docs.isNotEmpty) {
        setState(() {
          _lostMotivations = lostSnapshot.docs.map((doc) => doc['text'] as String).toList();
        });
      }
    } catch (error) {
      print("Lỗi tải câu động viên: $error");
      // Xử lý lỗi nếu cần
    }
  }

  String _getRandomMotivation(int currentStreak) {
    if (currentStreak > 0 && _activeMotivations.isNotEmpty) {
      return _activeMotivations[Random().nextInt(_activeMotivations.length)];
    } else if (_lostMotivations.isNotEmpty) {
      return _lostMotivations[Random().nextInt(_lostMotivations.length)];
    } else {
      return 'Hãy bắt đầu streak của bạn!'; // Câu mặc định nếu không có dữ liệu
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    //final todayFormatted = DateFormat('EEEE').format(DateTime.now().toLocal()).substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: user != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('streak')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final streakData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final currentStreak = streakData?['currentStreak'] as int? ?? 0;
                    final lastStudiedAtTimestamp = streakData?['lastStudiedAt'] as Timestamp?;
                    final hasStudiedToday = _hasStudiedToday(lastStudiedAtTimestamp);
                    final motivationText = _getRandomMotivation(currentStreak);

                    return _buildStreakContent(context, currentStreak, hasStudiedToday, snapshot.data, motivationText);
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Đã xảy ra lỗi khi tải streak.'));
                  } else {
                    // Hiển thị giao diện streak ban đầu khi chưa có dữ liệu
                    return _buildNoStreakContent(context);
                  }
                },
              )
            : _buildNoUserContent(context),
      ),
    );
  }

  Widget _buildNoUserContent(BuildContext context) {
    return const Center(child: Text('Bạn chưa đăng nhập.'));
  }

  Widget _buildNoStreakContent(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [],
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Bắt đầu học ngay để tạo streak!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        const Spacer(),
        Lottie.asset(
          'assets/icon/fire.json', // Đường dẫn đến file Lottie animation
          repeat: true,
        ),
        const SizedBox(height: 20),
        const Text(
          'Chưa có streak',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        const Spacer(flex: 2),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStreakContent(BuildContext context, int currentStreak, bool hasStudiedToday, DocumentSnapshot? snapshot, String motivationText) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 0.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  motivationText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  
                ),
                const SizedBox(width: 1),
                const Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Stack(
          alignment: Alignment.center,
          children: [
            MultiColorBorderCircle(
              colors: hasStudiedToday
                  ? const [Color(0xFFD36EE5), Color(0xFFD88AB6), Color(0xFFD994A3), Color(0xFFDA999C)]
                  : const [Colors.grey, Colors.grey, Colors.grey, Colors.grey],
            ),
            Positioned(
              top: 5, // Điều chỉnh giá trị này để định vị ngọn lửa theo chiều dọc
              child: SizedBox(
                width: 150, // Điều chỉnh kích thước ngọn lửa
                height: 150,
                child: Lottie.asset(
                  'assets/icon/fire.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              bottom: 50, // Điều chỉnh giá trị này để định vị text theo chiều dọc
              child: Text(
                '$currentStreak day streak',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF770B63),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DayCircle(label: 'M', filled: _checkDayInStreak(snapshot, 0), borderColor: _getDayBorderColor(snapshot, 0), size: 40),
              DayCircle(label: 'T', filled: _checkDayInStreak(snapshot, 1), borderColor: _getDayBorderColor(snapshot, 1), size: 40),
              DayCircle(label: 'W', filled: _checkDayInStreak(snapshot, 2), borderColor: _getDayBorderColor(snapshot, 2), size: 40),
              DayCircle(label: 'T', filled: _checkDayInStreak(snapshot, 3), borderColor: _getDayBorderColor(snapshot, 3), size: 40),
              DayCircle(label: 'F', filled: _checkDayInStreak(snapshot, 4), borderColor: _getDayBorderColor(snapshot, 4), size: 40),
              DayCircle(label: 'S', filled: _checkDayInStreak(snapshot, 5), borderColor: _getDayBorderColor(snapshot, 5), size: 40),
              DayCircle(label: 'S', filled: _checkDayInStreak(snapshot, 6), borderColor: _getDayBorderColor(snapshot, 6), size: 40),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Image.asset(
                'assets/icon/no_background.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(width: 0),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Text(
                    "Bạn đang duy trì chuỗi $currentStreak ngày liên tiếp.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
        const Spacer(flex: 1),
        const SizedBox(height: 20),
      ],
    );
  }

  bool _hasStudiedToday(Timestamp? lastStudiedAtTimestamp) {
    if (lastStudiedAtTimestamp != null) {
      final lastStudiedAt = lastStudiedAtTimestamp.toDate().toLocal();
      final now = DateTime.now().toLocal();
      return lastStudiedAt.year == now.year && lastStudiedAt.month == now.month && lastStudiedAt.day == now.day;
    }
    return false;
  }


  bool _checkDayInStreak(DocumentSnapshot? snapshot, int index) {
    if (snapshot != null && snapshot.exists) {
      final streakData = snapshot.data() as Map<String, dynamic>?;
      final studiedDays = streakData?['studiedDays'] as List<dynamic>? ?? [];

      // cộng +1 vì index (0–6) muốn khớp với DateTime.weekday (1–7)
      return studiedDays.contains(index + 1);
    }
    return false;
  }


  Color _getDayBorderColor(DocumentSnapshot? snapshot, int dayOffset) {
    if (_checkDayInStreak(snapshot, dayOffset)) {
      return const Color(0xFFE062D5);
    } else {
      return const Color(0xFF777777);
    }
  }


}



// Widget nút ngày (vòng tròn)
class DayCircle extends StatelessWidget {
  final String label;
  final bool filled;
  final Color borderColor;
  final double size;

  const DayCircle({
    super.key,
    required this.label,
    this.filled = false,
    required this.borderColor,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(color: borderColor, width: 5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: filled ? Colors.black : borderColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Widget vòng tròn có viền nhiều màu
class MultiColorBorderCircle extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const MultiColorBorderCircle({super.key, this.size = 220, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(colors: colors).createShader(bounds);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 12, color: Colors.white),
        ),
      ),
    );
  }
}