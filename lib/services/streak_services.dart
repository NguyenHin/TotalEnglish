import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

Future<void> updateStreak() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userId = user.uid;
    final streakDoc = FirebaseFirestore.instance.collection('streak').doc(userId);
    final now = DateTime.now().toUtc(); // Lấy thời điểm hiện tại theo UTC
    final today = DateFormat('yyyy-MM-dd').format(now);

    try {
      final docSnapshot = await streakDoc.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final lastStudiedAtTimestamp = data?['lastStudiedAt'] as Timestamp?;
        final currentStreak = data?['currentStreak'] as int? ?? 0;

        if (lastStudiedAtTimestamp != null) {
          final lastStudiedAt = lastStudiedAtTimestamp.toDate().toUtc();
          final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
          final lastStudiedDate = DateFormat('yyyy-MM-dd').format(lastStudiedAt);

          if (lastStudiedDate == today) {
            // Đã học hôm nay, chỉ cần cập nhật thời gian
            await streakDoc.update({'lastStudiedAt': now});
          } else if (lastStudiedDate == yesterday) {
            // Học liên tục
            await streakDoc.update({
              'currentStreak': currentStreak + 1,
              'lastStudiedAt': now,
            });
          } else {
            // Streak bị gián đoạn
            await streakDoc.update({
              'currentStreak': 1,
              'lastStudiedAt': now,
            });
          }
        } else {
          // Lần học đầu tiên
          await streakDoc.set({
            'userID': userId,
            'currentStreak': 1,
            'lastStudiedAt': now,
          });
        }
      } else {
        // Người dùng chưa có document streak
        await streakDoc.set({
          'userID': userId,
          'currentStreak': 1,
          'lastStudiedAt': now,
        });
      }
    } catch (e) {
      print("Lỗi cập nhật streak: $e");
      // Xử lý lỗi nếu cần
    }
  }
}