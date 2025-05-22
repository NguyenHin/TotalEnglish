import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:total_english/services/notification_services.dart';
import 'package:week_of_year/date_week_extensions.dart';


Future<void> checkAndResetStreakIfMissedDay() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final streakDoc = FirebaseFirestore.instance.collection('streak').doc(userId);
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);

  final docSnapshot = await streakDoc.get();
  if (!docSnapshot.exists) return;

  final data = docSnapshot.data();
  final lastStudiedAtTimestamp = data?['lastStudiedAt'] as Timestamp?;
  final currentStreak = data?['currentStreak'] as int? ?? 0;

  if (lastStudiedAtTimestamp == null) return;

  final lastStudiedAt = lastStudiedAtTimestamp.toDate();
  final lastStudiedDate = DateFormat('yyyy-MM-dd').format(lastStudiedAt);
  final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days:1)));

  if (lastStudiedDate != today && lastStudiedDate != yesterday) {
    // Bỏ qua ít nhất 1 ngày, reset streak về 0
    if (currentStreak > 0) {
      await streakDoc.update({'currentStreak': 0});
      print('⚡ Reset currentStreak vì bỏ qua 1 ngày.');

      // Kiểm tra đã gửi thông báo mất streak hôm nay chưa
      final existingLost = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'streak_lost')
          .where('streakDays', isEqualTo: currentStreak)
          .where('date', isEqualTo: today)
          .get();

      if (existingLost.docs.isEmpty) {
        await sendStreakLostNotification(
          userId: userId,
          streakDays: currentStreak,
        );
      }
    } else {
      print('⚡ Streak đã là 0, không gửi thông báo mất streak');
    }
  }
}

Future<void> updateStreak() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final streakDoc = FirebaseFirestore.instance.collection('streak').doc(userId);
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);

  final docSnapshot = await streakDoc.get();
  if (!docSnapshot.exists) {
    // Tạo document lần đầu
    await streakDoc.set({
      'userID': userId,
      'currentStreak': 1,
      'lastStudiedAt': now,
      'studiedDays': updateStudiedDaysList([], now),
    });
    print('🆕 Created new streak document with studiedDays');
    return;
  }

  final data = docSnapshot.data();
  final lastStudiedAtTimestamp = data?['lastStudiedAt'] as Timestamp?;
  final currentStreak = data?['currentStreak'] as int? ?? 0;
  List<dynamic> studiedDays = data?['studiedDays'] ?? [];

  if (lastStudiedAtTimestamp == null) {
    // Lần đầu học, khởi tạo tương tự
    await streakDoc.set({
      'userID': userId,
      'currentStreak': 1,
      'lastStudiedAt': now,
      'studiedDays': updateStudiedDaysList([], now),
    });
    return;
  }

  final lastStudiedAt = lastStudiedAtTimestamp.toDate();
  final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 1)));
  final lastStudiedDate = DateFormat('yyyy-MM-dd').format(lastStudiedAt);

  // Xử lý tuần, studiedDays ...
  final currentWeek = weekNumber(now);
  final lastWeek = weekNumber(lastStudiedAt);
  if (currentWeek != lastWeek) {
    studiedDays = [];
    await streakDoc.update({'studiedDays': []});
  }
  studiedDays = updateStudiedDaysList(studiedDays, now);

  if (lastStudiedDate == today) {
    // Đã học hôm nay, chỉ update lastStudiedAt + studiedDays
    await streakDoc.update({
      'lastStudiedAt': now,
      'studiedDays': studiedDays,
    });
  } else if (lastStudiedDate == yesterday) {
    // Học liên tục → tăng streak
    final newStreak = currentStreak + 1;
    await streakDoc.update({
      'currentStreak': newStreak,
      'lastStudiedAt': now,
      'studiedDays': studiedDays,
    });

    if (newStreak % 5 == 0) {
      print('📨 Chuẩn bị gọi sendStreakNotification cho user: $userId, streak: $newStreak');

      final existingAchieved = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'streak_achieved')
          .where('streakDays', isEqualTo: newStreak)
          .where('date', isEqualTo: today)
          .get();

      if (existingAchieved.docs.isEmpty) {
        await sendStreakNotification(userId: userId, streakDays: newStreak);
      }
    }
  } else {
    // Nếu currentStreak == 0, học lại → set currentStreak = 1
    final newStreak = currentStreak == 0 ? 1 : currentStreak;
    // Không reset streak ở đây nữa, đã xử lý ở hàm riêng rồi
    await streakDoc.update({
      'currentStreak': newStreak,
      'lastStudiedAt': now,
      'studiedDays': studiedDays,
    });
  }

  print('✅ Updated studiedDays: $studiedDays');
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

