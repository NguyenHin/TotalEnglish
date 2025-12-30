import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:total_english/services/notification_services.dart';
import 'package:week_of_year/date_week_extensions.dart';

/// ===============================
/// ❌ RESET STREAK NẾU BỎ QUA NGÀY
/// ===============================
Future<void> checkAndResetStreakIfMissedDay() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final streakDoc =
      FirebaseFirestore.instance.collection('streak').doc(userId);

  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final yesterday =
      DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

  final docSnapshot = await streakDoc.get();
  if (!docSnapshot.exists) return;

  final data = docSnapshot.data();
  final lastStudiedAtTimestamp = data?['lastStudiedAt'] as Timestamp?;
  final currentStreak = data?['currentStreak'] as int? ?? 0;

  if (lastStudiedAtTimestamp == null) return;

  final lastStudiedAt = lastStudiedAtTimestamp.toDate();
  final lastStudiedDate =
      DateFormat('yyyy-MM-dd').format(lastStudiedAt);

  // ❌ Bỏ qua ít nhất 1 ngày
  if (lastStudiedDate != today && lastStudiedDate != yesterday) {
    if (currentStreak <= 0) return;

    await streakDoc.update({'currentStreak': 0});
    print('⚡ Reset streak vì bỏ qua ngày học');

    // 🔒 Chống gửi trùng streak_lost
    final existing = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'streak_lost')
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await sendStreakLost(
        userId: userId,
        streakDays: currentStreak,
      );
    }
  }
}

/// ===============================
/// 🔥 UPDATE STREAK KHI HỌC BÀI
/// ===============================
Future<void> updateStreak() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final streakDoc =
      FirebaseFirestore.instance.collection('streak').doc(userId);

  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final yesterday =
      DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

  final docSnapshot = await streakDoc.get();

  // 🆕 Lần đầu học
  if (!docSnapshot.exists) {
    await streakDoc.set({
      'userID': userId,
      'currentStreak': 1,
      'lastStudiedAt': now,
      'studiedDays': updateStudiedDaysList([], now),
    });
    return;
  }

  final data = docSnapshot.data();
  final lastStudiedAtTimestamp = data?['lastStudiedAt'] as Timestamp?;
  final currentStreak = data?['currentStreak'] as int? ?? 0;
  List<dynamic> studiedDays = data?['studiedDays'] ?? [];

  if (lastStudiedAtTimestamp == null) {
    await streakDoc.update({
      'currentStreak': 1,
      'lastStudiedAt': now,
      'studiedDays': updateStudiedDaysList([], now),
    });
    return;
  }

  final lastStudiedAt = lastStudiedAtTimestamp.toDate();
  final lastStudiedDate =
      DateFormat('yyyy-MM-dd').format(lastStudiedAt);

  /// 🔁 Reset studiedDays khi sang tuần mới
  if (weekNumber(now) != weekNumber(lastStudiedAt)) {
    studiedDays = [];
    await streakDoc.update({'studiedDays': []});
  }

  studiedDays = updateStudiedDaysList(studiedDays, now);

  // ✅ Đã học hôm nay
  if (lastStudiedDate == today) {
    await streakDoc.update({
      'lastStudiedAt': now,
      'studiedDays': studiedDays,
    });
    return;
  }

  // 🔥 Học liên tục
  if (lastStudiedDate == yesterday) {
    final newStreak = currentStreak + 1;

    await streakDoc.update({
      'currentStreak': newStreak,
      'lastStudiedAt': now,
      'studiedDays': studiedDays,
    });

    // 🎉 Mốc thưởng (5, 10, 15...)
    if (newStreak % 5 == 0) {
      final existing = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'streak_achieved')
          .where('streakDays', isEqualTo: newStreak)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await sendStreakAchieved(
          userId: userId,
          streakDays: newStreak,
        );
      }
    }
    return;
  }

  // 😶 Học lại sau khi streak = 0
  if (currentStreak == 0) {
    await streakDoc.update({
      'currentStreak': 1,
      'lastStudiedAt': now,
      'studiedDays': studiedDays,
    });
  }
}

/// ===============================
/// 📅 STUDIED DAYS
/// ===============================
List<int> updateStudiedDaysList(List<dynamic> oldList, DateTime now) {
  final weekday = now.weekday; // 1–7
  final list = List<int>.from(oldList);
  if (!list.contains(weekday)) {
    list.add(weekday);
  }
  return list;
}

int weekNumber(DateTime date) => date.weekOfYear;
