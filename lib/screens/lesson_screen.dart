import 'package:firebase_auth/firebase_auth.dart';
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
  late Stream<Map<String, Map<String, bool>>> _userProgressStream;

  @override
  void initState() {
    super.initState();
    _userProgressStream = _loadUserProgressStream();
    lessonsStream = FirebaseFirestore.instance
        .collection('lessons')
        .orderBy('order')
        .snapshots();
  }

  Stream<Map<String, Map<String, bool>>> _loadUserProgressStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }
    return FirebaseFirestore.instance
        .collection('user_lesson_progress')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final progressMap = <String, Map<String, bool>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        progressMap[data['lessonId'] as String] = {
          'vocabulary': data['vocabularyCompleted'] as bool? ?? false,
          'listening': data['listeningCompleted'] as bool? ?? false,
          'speaking': data['speakingCompleted'] as bool? ?? false,
          'quiz': data['quizCompleted'] as bool? ?? false,
        };
      }
      return progressMap;
    });
  }


Future<void> _updateLessonProgress(String lessonId, String activity, bool completed) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  // Tạo docId duy nhất cho mỗi user-lesson
  final docId = '${userId}_$lessonId';
  final docRef = FirebaseFirestore.instance.collection('user_lesson_progress').doc(docId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);

    if (!snapshot.exists) {
      // Nếu chưa tồn tại, tạo mới
      transaction.set(docRef, {
        'userId': userId,
        'lessonId': lessonId,
        'vocabularyCompleted': activity == 'vocabulary' ? completed : false,
        'listeningCompleted': activity == 'listening' ? completed : false,
        'speakingCompleted': activity == 'speaking' ? completed : false,
        'quizCompleted': activity == 'quiz' ? completed : false,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Nếu đã tồn tại, chỉ cập nhật nếu activity chưa completed
      final data = snapshot.data() as Map<String, dynamic>;
      final isCurrentlyCompleted = data['${activity}Completed'] as bool? ?? false;

      if (!isCurrentlyCompleted && completed) {
        transaction.update(docRef, {
          '${activity}Completed': true,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  });
}


  double _calculateLessonProgress(String lessonId, Map<String, Map<String, bool>> progressMap) {
    if (progressMap.containsKey(lessonId)) {
      final status = progressMap[lessonId]!;
      int completedCount = 0;
      if (status['vocabulary'] == true) completedCount++;
      if (status['listening'] == true) completedCount++;
      if (status['speaking'] == true) completedCount++;
      if (status['quiz'] == true) completedCount++;
      return completedCount * 0.25;
    }
    return 0.0;
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
        child: StreamBuilder<QuerySnapshot>(
          stream: lessonsStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> lessonSnapshot) {
            if (lessonSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!lessonSnapshot.hasData) {
              return const Center(child: Text('No lessons available'));
            }

            final lessons = lessonSnapshot.data!.docs;

            return StreamBuilder<Map<String, Map<String, bool>>>(
              stream: _userProgressStream,
              builder: (context, AsyncSnapshot<Map<String, Map<String, bool>>> progressSnapshot) {
                final userProgress = progressSnapshot.data ?? {};
                
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
                        style: TextStyle(fontFamily: 'Kavoon', fontSize: 22),
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
                                key: ValueKey<int>(index),
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
                                  mainAxisAlignment: isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
                                  children: [
                                    if (!isEven) const Spacer(),
                                    Flexible(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
                                        children: [
                                          if (isEven)
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: color,
                                              child: Center(
                                                child: FaIcon(
                                                  icon,
                                                  color: Colors.white,
                                                  size: 28, // Nhỏ hơn một chút để vừa đẹp
                                                ),
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
                                                Text(
                                                  'Tiến độ: ${(_calculateLessonProgress(lesson.id, userProgress) * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
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
                                                    alignment: isEven ? Alignment.centerRight : Alignment.centerLeft,
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final lesson = lessons[index];
                                                        final result = await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => LessonOverview(
                                                              lessonId: lesson.id,
                                                              lessonTitle: lesson['title'],
                                                              lessonDescription: lesson['description'],
                                                              lessonIcon: icon,
                                                              lessonColor: color,
                                                              onLessonOverviewPop: (completedActivities) {
                                                                print("Tiến độ trả về từ LessonOverview (callback): $completedActivities");
                                                                // Duyệt qua map completedActivities và cập nhật tiến độ cho từng hoạt động
                                                                completedActivities.forEach((activity, isCompleted) {
                                                                  _updateLessonProgress(lesson.id, activity, isCompleted);
                                                                });
                                                              },
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
                                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                                              child: Center(
                                                child: FaIcon(
                                                  icon,
                                                  color: Colors.white,
                                                  size: 28, // Nhỏ hơn một chút để vừa đẹp
                                                ),
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
            );
          },
        ),
      )
    );
  }
}