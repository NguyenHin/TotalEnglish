import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:week_of_year/date_week_extensions.dart';

Future<void> updateStreak() async {
  print('=== DEBUG STREAK ===');
  print('Giờ hiện tại (local): ${DateTime.now()}');

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userId = user.uid;
    final streakDoc = FirebaseFirestore.instance.collection('streak').doc(userId);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    try {
      final docSnapshot = await streakDoc.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final lastStudiedAtTimestamp = data?['lastStudiedAt'] as Timestamp?;
        final currentStreak = data?['currentStreak'] as int? ?? 0;
        List<dynamic> studiedDays = data?['studiedDays'] ?? [];

        if (lastStudiedAtTimestamp != null) {
          final lastStudiedAt = lastStudiedAtTimestamp.toDate();
          final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
          final lastStudiedDate = DateFormat('yyyy-MM-dd').format(lastStudiedAt);

          print('Lần học gần nhất: $lastStudiedAt');
          print('Ngày hôm nay: $today');
          print('Ngày học trước: $lastStudiedDate');

          // Kiểm tra sang tuần mới ➔ reset studiedDays
          final currentWeek = weekNumber(now);
          final lastWeek = weekNumber(lastStudiedAt);
          
          print('Current week: $currentWeek');
          print('Last studied week: $lastWeek');

          if (currentWeek != lastWeek) {
            print('➡️ Sang tuần mới, reset studiedDays');
            studiedDays = [];
            await streakDoc.update({'studiedDays': []}); // ⬅️ Thêm dòng này
          }

          // Cập nhật studiedDays (luôn thêm ngày hôm nay)
          studiedDays = updateStudiedDaysList(studiedDays, now);

          // Xử lý streak
          if (lastStudiedDate == today) {
            // Đã học hôm nay, chỉ cần update studiedDays + lastStudiedAt
            await streakDoc.update({
              'lastStudiedAt': now,
              'studiedDays': studiedDays,
            });
          } else if (lastStudiedDate == yesterday) {
            // Học liên tục
            final newStreak = currentStreak + 1;
            await streakDoc.update({
              'currentStreak': newStreak,
              'lastStudiedAt': now,
              'studiedDays': studiedDays,
            });
            // 🔥 Gửi thông báo nếu đạt mốc đặc biệt
            if(newStreak % 5 == 0) {
              await sendStreakNotification(userId: userId, streakDays: newStreak);
            }
          } else {
              // Hết ngày -> reset streak
              await streakDoc.update({
                'currentStreak': 1,
                'lastStudiedAt': now,
                'studiedDays': studiedDays,
              });
              print('⚡ Reset currentStreak vì bỏ qua 1 ngày.');
          }


          print('✅ Updated studiedDays: $studiedDays');
        } else {
          // Lần học đầu tiên
          await streakDoc.set({
            'userID': userId,
            'currentStreak': 1,
            'lastStudiedAt': now,
            'studiedDays': updateStudiedDaysList([], now),
          });
          print('🆕 Created new streak document with studiedDays');
        }
      } else {
        // Chưa có document
        await streakDoc.set({
          'userID': userId,
          'currentStreak': 1,
          'lastStudiedAt': now,
          'studiedDays': updateStudiedDaysList([], now),
        });
        print('🆕 Created new streak document with studiedDays');
      }
    } catch (e) {
      print("Lỗi cập nhật streak: $e");
    }
  }
}

// Hàm cập nhật danh sách studiedDays
List<int> updateStudiedDaysList(List<dynamic> oldList, DateTime now) {
  final weekday = now.weekday; // GIỮ nguyên: 1–7
  final updatedList = List<int>.from(oldList);
  if (!updatedList.contains(weekday)) {
    updatedList.add(weekday);
  }
  return updatedList;
}


int weekNumber(DateTime date) {
  return date.weekOfYear;
}


Future<void> sendStreakNotification({
  required String userId,
  required int streakDays,
}) async {
  final now = DateTime.now();

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId' : userId,
    'type': 'streak_achieved',
    'message': 'Chúc mừng! Bạn đã đạt được chuỗi $streakDays ngày học tập liên tục!🎉🔥',
    'streakDays': streakDays,
    'createdAt': now,
  });
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
  });
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

