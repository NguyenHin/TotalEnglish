import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:total_english/services/fcm_service.dart';

Future<void> sendStreakNotification({
  required String userId,
  required int streakDays,
}) async {
  final now = DateTime.now();

  // Thêm log để xác nhận hàm này chạy
  print('📨 Gọi sendStreakNotification cho user: $userId, streak: $streakDays');

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId' : userId,
    'type': 'streak_achieved',
    'message': 'Chúc mừng! Bạn đã đạt được chuỗi $streakDays ngày học tập liên tục!🎉🔥',
    'streakDays': streakDays,
    'createdAt': now,
    'date': DateFormat('yyyy-MM-dd').format(now),
    'read': false,
  });

  await limitNotificationCount(userId);  // <-- Gọi giới hạn ở đây

  final fcmToken = await getUserFCMToken(userId);
  print('📱 FCM Token lấy được: $fcmToken'); //in log
  if (fcmToken != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: fcmToken,
      title: 'Chúc mừng!',
      body: 'Bạn đã đạt được chuỗi $streakDays ngày học tập liên tục!🎉🔥',
    );
  }else{
    print('⚠️ Không tìm thấy FCM token cho user: $userId');
  }
}


Future<void> sendStreakWarningNotification({
  required String userId,
  required int currentStreak,
}) async {
  final now = DateTime.now();

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'type': 'streak_warning',
    'message': '⚠️ Bạn sắp mất chuỗi $currentStreak ngày. Hãy học ngay để duy trì chuỗi!🔥!',
    'streakDays': currentStreak,
    'createdAt': now,
    'date': DateFormat('yyyy-MM-dd').format(now),
    'read': false,
  });

  await limitNotificationCount(userId);  // <-- Gọi giới hạn ở đây

  // Lấy token FCM user để gửi push notification
  final fcmToken = await getUserFCMToken(userId);
  if (fcmToken != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: fcmToken,
      title: 'Cảnh báo mất streak',
      body: '⚠️ Bạn sắp mất chuỗi $currentStreak ngày. Hãy học ngay để duy trì chuỗi!🔥!',
    );
  }
}


Future<void> checkAndSendStreakWarning() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);

  // 👉 Chỉ thực hiện đúng lúc 23:00
  if (now.hour != 23 || now.minute != 0) return;

  final userId = user.uid;
  final streakDoc = await FirebaseFirestore.instance.collection('streak').doc(userId).get();
  if (!streakDoc.exists) return;

  final data = streakDoc.data();
  final lastStudiedAt = (data?['lastStudiedAt'] as Timestamp?)?.toDate();
  final lastStudiedDate = lastStudiedAt != null
      ? DateFormat('yyyy-MM-dd').format(lastStudiedAt)
      : null;

  if (lastStudiedDate == today) return;

  // Kiểm tra đã gửi warning hôm nay chưa
  final existingWarnings = await FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'streak_warning')
      .where('date', isEqualTo: today)
      .get();

  if (existingWarnings.docs.isEmpty) {
    final currentStreak = data?['currentStreak'] as int? ?? 0;

    await sendStreakWarningNotification(
      userId: userId,
      currentStreak: currentStreak,
    );

    print('🔔 Gửi cảnh báo streak_warning cho user $userId');
  }
}


Future<void> sendStudyReminderNotification({
  required String userId,
}) async {
  final now = DateTime.now();

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'type': 'reminder',
    'message': 'Đừng quên bài học hôm nay nhé📚! Hãy dành chút thời gian để học tập.',
    'createdAt': now,
    'date': DateFormat('yyyy-MM-dd').format(now),
    'read': false,
  });

  await limitNotificationCount(userId);  // <-- Gọi giới hạn ở đây

  // Lấy token FCM của user
  final fcmToken = await getUserFCMToken(userId);
  if (fcmToken != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: fcmToken,
      title: 'Nhắc nhở học tập',
      body: 'Đừng quên bài học hôm nay nhé📚! Hãy dành chút thời gian để học tập.',
    );
  }
}

Future<void> checkAndSendStudyReminder() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);

  // Kiểm tra nếu là 12:00
  if (now.hour != 12 || now.minute != 0) return;

  final userId = user.uid;
  final streakDoc = await FirebaseFirestore.instance.collection('streak').doc(userId).get();
  if (!streakDoc.exists) return;

  final data = streakDoc.data();
  final lastStudiedAt = (data?['lastStudiedAt'] as Timestamp?)?.toDate();
  final lastStudiedDate = lastStudiedAt != null
      ? DateFormat('yyyy-MM-dd').format(lastStudiedAt)
      : null;

  // Nếu chưa học hôm nay, gửi thông báo nhắc nhở
  if (lastStudiedDate != today) {
    // Kiểm tra đã gửi reminder hôm nay chưa
    final existingReminders = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'reminder')
        .where('date', isEqualTo: today)
        .get();

    if (existingReminders.docs.isEmpty) {
      await sendStudyReminderNotification(userId: userId);
      print('📚 Đã gửi thông báo nhắc học tập cho user $userId');
    }
  }
}

Future<void> sendStreakLostNotification({
  required String userId,
  required int streakDays,
}) async {
  final now = DateTime.now();

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'type': 'streak_lost',
    'message': 'Chuỗi $streakDays ngày học tập của bạn đã kết thúc😢. Hãy bắt đầu lại một chuỗi mới nhé!',
    'streakDays': streakDays,
    'createdAt': now,
    'date': DateFormat('yyyy-MM-dd').format(now),
    'read': false,
  });

  await limitNotificationCount(userId);  // <-- Gọi giới hạn ở đây

  final fcmToken = await getUserFCMToken(userId);
  if (fcmToken != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: fcmToken,
      title: 'Chuỗi học tập kết thúc',
      body: 'Chuỗi $streakDays ngày học tập của bạn đã kết thúc😢. Hãy bắt đầu lại một chuỗi mới nhé!',
    );
  }
}

//hàm giới hạn 15 thông báo
Future<void> limitNotificationCount(String userId, {int maxCount = 15}) async {
  final notificationsRef = FirebaseFirestore.instance.collection('notifications');

  final querySnapshot = await notificationsRef
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();

  final docs = querySnapshot.docs;

  if (docs.length > maxCount) {
    final docsToDelete = docs.sublist(maxCount);
    for (final doc in docsToDelete) {
      await notificationsRef.doc(doc.id).delete();
      print('🗑️ Đã xóa thông báo cũ: ${doc.id}');
    }
  }
}
