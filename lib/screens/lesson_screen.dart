import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentIndex = 0;
  int selectedLesson = -1;

  final List<Map<String, dynamic>> lessons = [
    {
      'title': 'L1-1: Giới thiệu bản thân',
      'description': 'Introduce yourself',
      'icon': FontAwesomeIcons.user,
      'color': Colors.blue,
    },
    {
      'title': 'L1-2: Giới thiệu gia đình',
      'description': 'Introduce family',
      'icon': FontAwesomeIcons.peopleRoof,
      'color': Colors.green,
    },
    {
      'title': 'L1-3: Giới thiệu trường học',
      'description': 'Introduce school',
      'icon': FontAwesomeIcons.school,
      'color': Colors.orange,
    },
    {
      'title': 'L1-4: Giới thiệu động vật',
      'description': 'Introduce animals',
      'icon': FontAwesomeIcons.dog,
      'color': Colors.purple,
    },
    {
      'title': 'L1-5: Giới thiệu cây cối',
      'description': 'Talk about trees',
      'icon': FontAwesomeIcons.tree,
      'color': Colors.brown,
    },
    {
      'title': 'L1-6: Giới thiệu sở thích',
      'description': 'Talk about hobbies',
      'icon': FontAwesomeIcons.paintBrush,
      'color': Colors.teal,
    },
    {
      'title': 'L1-7: Giới thiệu công việc',
      'description': 'Talk about jobs',
      'icon': FontAwesomeIcons.briefcase,
      'color': Colors.deepOrange,
    },
    {
      'title': 'L1-8: Giới thiệu thành phố',
      'description': 'Talk about city',
      'icon': FontAwesomeIcons.city,
      'color': Colors.indigo,
    },
    {
      'title': 'L1-9: Giới thiệu đất nước',
      'description': 'Talk about country',
      'icon': FontAwesomeIcons.flag,
      'color': Colors.redAccent,
    },
    {
      'title': 'L1-10: Giới thiệu món ăn',
      'description': 'Talk about food',
      'icon': FontAwesomeIcons.utensils,
      'color': Colors.pink,
    },
  ];

  // Hàm để ẩn bảng khi bấm ra ngoài vùng trống
  void _hideLessonDetails() {
    setState(() {
      selectedLesson = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Lesson 1', style: TextStyle(fontFamily: 'Kavoon')),
        backgroundColor: const Color(0xFF89B3D4),
      ),
      body: GestureDetector(
        onTap: _hideLessonDetails,  // Khi bấm ra ngoài sẽ gọi _hideLessonDetails
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final bool isSelected = selectedLesson == index;
                    final bool isEven = index % 2 == 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLesson = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [lesson['color'].withOpacity(0.25), Colors.white]
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
                                      backgroundColor: lesson['color'],
                                      child: Icon(
                                        lesson['icon'],
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
                                                // TODO: Navigate or start lesson
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: lesson['color'],
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
                                      backgroundColor: lesson['color'],
                                      child: Icon(
                                        lesson['icon'],
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
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
