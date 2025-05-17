import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:total_english/services/notification_services.dart';
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
 print('📨 Chuẩn bị gọi sendStreakNotification cho user: $userId, streak: $newStreak');
              // Kiểm tra đã gửi chưa
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
              // Hết ngày -> reset streak
              await streakDoc.update({
                'currentStreak': 0,
                'lastStudiedAt': now,
                'studiedDays': studiedDays,
              });
              
              print('⚡ Reset currentStreak vì bỏ qua 1 ngày.');
              // 👉 Kiểm tra đã gửi thông báo mất streak hôm nay chưa
              final existingLost = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .where('type', isEqualTo: 'streak_lost')
                  .where('streakDays', isEqualTo: currentStreak)
                  .where('date', isEqualTo: today)
                  .get();

              if (existingLost.docs.isEmpty) {
                // Gửi thông báo "Mất streak"
                await sendStreakLostNotification(
                  userId: userId,
                  streakDays: currentStreak, // Sử dụng currentStreak trước khi reset
                );
              }
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


