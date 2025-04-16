import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:total_english/screens/lesson_overview.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});
  @override
  _LessonScreenState createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int selectedLesson = -1;
  late Stream<QuerySnapshot> lessonsStream;

  @override
  void initState() {
    super.initState();
    // Chỉ lấy stream một lần để tránh rebuild liên tục
    lessonsStream = FirebaseFirestore.instance
        .collection('lessons')
        .orderBy('order')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Lesson', style: TextStyle(fontFamily: 'Kavoon')),
        backgroundColor: const Color(0xFF89B3D4),
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: lessonsStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No lessons available'));
            }

            final lessons = snapshot.data!.docs;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lesson',
                    style: TextStyle(
                      fontFamily: 'Kavoon',
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true, // Để không làm cuộn toàn bộ màn hình
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final bool isSelected = selectedLesson == index;
                      final bool isEven = index % 2 == 0;

                      // Đặt icon và màu sắc tương ứng với bài học
                      IconData icon;
                      Color color;
                      switch (lesson['order']) {
                        case 1:
                          icon = FontAwesomeIcons.paintbrush;
                          color = Colors.blue;
                          break;
                        case 2:
                          icon = FontAwesomeIcons.peopleRoof;
                          color = Colors.green;
                          break;
                        case 3:
                          icon = FontAwesomeIcons.school;
                          color = Colors.orange;
                          break;
                        case 4:
                          icon = FontAwesomeIcons.dog;
                          color = Colors.purple;
                          break;
                        case 5:
                          icon = FontAwesomeIcons.tree;
                          color = Colors.brown;
                          break;
                        case 6:
                          icon = Icons.favorite;
                          color = Colors.teal;
                          break;
                        case 7:
                          icon = FontAwesomeIcons.briefcase;
                          color = Colors.deepOrange;
                          break;
                        case 8:
                          icon = FontAwesomeIcons.city;
                          color = Colors.indigo;
                          break;
                        case 9:
                          icon = FontAwesomeIcons.flag;
                          color = Colors.redAccent;
                          break;
                        case 10:
                          icon = FontAwesomeIcons.utensils;
                          color = Colors.pink;
                          break;
                        default:
                          icon = FontAwesomeIcons.question;
                          color = Colors.grey;
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedLesson = isSelected ? -1 : index;
                          });
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedContainer(
                            key: ValueKey<int>(index), // Đảm bảo mỗi phần có key riêng
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [color.withOpacity(0.25), Colors.white]
                                    : [Colors.white, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
                              children: [
                                if (!isEven) const Spacer(),
                                Flexible(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: isEven
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.end,
                                    children: [
                                      if (isEven)
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: color,
                                          child: Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lesson['title'],
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Tiến độ: 0%',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                lesson['description'],
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Align(
                                                alignment: isEven
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    // Điều hướng đến LessonOverview
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => LessonOverview(
                                                          lessonId: lesson.id,
                                                          lessonTitle: lesson['title'],  // Truyền tiêu đề bài học
                                                          lessonDescription: lesson['description'],  // Truyền mô tả bài học
                                                          lessonIcon: icon,  // Truyền icon của bài học
                                                          lessonColor: color,  // Truyền màu sắc của bài học
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    foregroundColor: Colors.white,
                                                    backgroundColor: color,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 10,
                                                    ),
                                                  ),
                                                  child: const Text('Bắt đầu'),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (!isEven)
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: color,
                                          child: Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isEven) const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
