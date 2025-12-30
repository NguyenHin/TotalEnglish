import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:total_english/services/fcm_service.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

String todayString() =>
    DateFormat('yyyy-MM-dd').format(DateTime.now());

/// =======================
/// 🔔 STREAK ACHIEVED
/// =======================
Future<void> sendStreakAchieved({
  required String userId,
  required int streakDays,
}) async {
  await _firestore.collection('notifications').add({
    'userId': userId,
    'type': 'streak_achieved',
    'message':
        'Chúc mừng! Bạn đã đạt được chuỗi $streakDays ngày học tập liên tục! 🎉🔥',
    'streakDays': streakDays,
    'createdAt': FieldValue.serverTimestamp(),
    'date': todayString(),
    'read': false,
  });

  await limitNotificationCount(userId);

  final token = await getUserFCMToken(userId);
  if (token != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: token,
      title: 'Chúc mừng!',
      body:
          'Bạn đã đạt được chuỗi $streakDays ngày học tập liên tục! 🎉🔥',
    );
  }
}

/// =======================
/// ⚠️ STREAK WARNING
/// =======================
Future<void> checkAndSendStreakWarning() async {
  final user = _auth.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final today = todayString();

  final streakDoc =
      await _firestore.collection('streak').doc(userId).get();
  if (!streakDoc.exists) return;

  final data = streakDoc.data()!;
  final currentStreak = data['currentStreak'] ?? 0;

  final lastStudiedAt =
      (data['lastStudiedAt'] as Timestamp?)?.toDate();
  final lastStudiedDate = lastStudiedAt != null
      ? DateFormat('yyyy-MM-dd').format(lastStudiedAt)
      : null;

  // ✅ Đã học hôm nay → không cảnh báo
  if (lastStudiedDate == today) return;

  // ✅ Không có streak → không cảnh báo
  if (currentStreak <= 0) return;

  // ✅ Mỗi ngày chỉ gửi 1 lần
  final existing = await _firestore
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'streak_warning')
      .where('date', isEqualTo: today)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) return;

  await _firestore.collection('notifications').add({
    'userId': userId,
    'type': 'streak_warning',
    'message':
        '⚠️ Bạn sắp mất chuỗi $currentStreak ngày. Hãy học ngay để duy trì nhé!',
    'streakDays': currentStreak,
    'createdAt': FieldValue.serverTimestamp(),
    'date': today,
    'read': false,
  });

  await limitNotificationCount(userId);

  final token = await getUserFCMToken(userId);
  if (token != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: token,
      title: 'Cảnh báo streak',
      body:
          '⚠️ Bạn sắp mất chuỗi $currentStreak ngày. Hãy học ngay!',
    );
  }
}

/// =======================
/// 📚 STUDY REMINDER
/// =======================
Future<void> checkAndSendStudyReminder() async {
  final user = _auth.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final today = todayString();

  final streakDoc =
      await _firestore.collection('streak').doc(userId).get();
  if (!streakDoc.exists) return;

  final lastStudiedAt =
      (streakDoc.data()?['lastStudiedAt'] as Timestamp?)?.toDate();

  final lastStudiedDate = lastStudiedAt != null
      ? DateFormat('yyyy-MM-dd').format(lastStudiedAt)
      : null;

  // ✅ Đã học hôm nay → không nhắc
  if (lastStudiedDate == today) return;

  // ✅ Chống spam (1 lần/ngày)
  final existing = await _firestore
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'reminder')
      .where('date', isEqualTo: today)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) return;

  await _firestore.collection('notifications').add({
    'userId': userId,
    'type': 'reminder',
    'message':
        '📚 Hôm nay bạn chưa học. Hãy dành vài phút để duy trì thói quen nhé!',
    'createdAt': FieldValue.serverTimestamp(),
    'date': today,
    'read': false,
  });

  await limitNotificationCount(userId);

  final token = await getUserFCMToken(userId);
  if (token != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: token,
      title: 'Nhắc nhở học tập',
      body:
          '📚 Hôm nay bạn chưa học. Hãy dành vài phút để duy trì thói quen nhé!',
    );
  }
}

/// =======================
/// ❌ STREAK LOST
/// =======================
Future<void> sendStreakLost({
  required String userId,
  required int streakDays,
}) async {
  await _firestore.collection('notifications').add({
    'userId': userId,
    'type': 'streak_lost',
    'message':
        'Chuỗi $streakDays ngày học tập của bạn đã kết thúc 😢. Bắt đầu lại nhé!',
    'streakDays': streakDays,
    'createdAt': FieldValue.serverTimestamp(),
    'date': todayString(),
    'read': false,
  });

  await limitNotificationCount(userId);

  final token = await getUserFCMToken(userId);
  if (token != null) {
    await sendPushNotificationWithHttpV1(
      targetToken: token,
      title: 'Chuỗi học tập kết thúc',
      body:
          'Chuỗi $streakDays ngày học tập của bạn đã kết thúc 😢',
    );
  }
}

/// =======================
/// 🧹 LIMIT NOTIFICATION
/// =======================
Future<void> limitNotificationCount(
  String userId, {
  int maxCount = 15,
}) async {
  final snapshot = await _firestore
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();

  if (snapshot.docs.length <= maxCount) return;

  final deleteList = snapshot.docs.sublist(maxCount);
  for (final doc in deleteList) {
    await doc.reference.delete();
  }
}
