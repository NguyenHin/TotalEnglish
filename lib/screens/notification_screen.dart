import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Column(
            children: [
              Text(
                'Thông báo',
                style: TextStyle(
                  fontFamily: 'KohSantepheap',
                  fontSize: 20.0,
                ),
              ),
              SizedBox(height: 4.0),
              Divider(
                color: Colors.grey,
                thickness: 0.5,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Handle edit action (ví dụ: đánh dấu đã đọc tất cả)
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Bạn chưa đăng nhập.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUser.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi khi tải thông báo.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có thông báo nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16.0),
                  itemBuilder: (context, index) {
                    final notificationData =
                        snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final notificationType = notificationData['type'] as String?;
                    final message = notificationData['message'] as String?;
                    final createdAt = notificationData['createdAt'] as Timestamp?;
                    final streakDays = notificationData['streakDays'] as int?;

                    IconData? icon;
                    Color? iconColor;

                    switch (notificationType) {
                      case 'reminder':
                        icon = Icons.notifications_active_outlined;
                        iconColor = Colors.blue;
                        break;
                      case 'streak_achieved':
                        icon = FontAwesomeIcons.fire;
                        iconColor = const Color(0xFFD36EE5);
                        break;
                      case 'streak_warning':
                        icon = Icons.local_fire_department_outlined;
                        iconColor = Colors.orange;
                        break;
                      case 'streak_lost':
                        icon = Icons.broken_image_outlined;
                        iconColor = Colors.grey;
                        break;
                      case 'new_content':
                        icon = Icons.new_releases_outlined;
                        iconColor = Colors.green;
                        break;
                      default:
                        icon = Icons.info_outline;
                        iconColor = Colors.grey;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: iconColor),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message ?? 'Không có nội dung',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                                if (streakDays != null && notificationType == 'streak_achieved')
                                  Text(
                                    'Bạn đã đạt được chuỗi $streakDays ngày học tập!',
                                    style: const TextStyle(fontSize: 14.0, color: Colors.black87),
                                  ),
                                if (createdAt != null)
                                  Text(
                                    DateFormat('HH:mm dd/MM/yyyy')
                                        .format(createdAt.toDate().toLocal()),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}