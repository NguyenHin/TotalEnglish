const admin = require('firebase-admin');
const fs = require('fs');

// Đọc file key (đổi lại tên nếu cần)
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Hàm kiểm tra xem một bài học đã tồn tại hay chưa
async function checkIfLessonExists(title) {
  const lessonRef = await db.collection('lessons')
    .where('title', '==', title)
    .limit(1)
    .get();
  return !lessonRef.empty; // Nếu có dữ liệu trả về thì bài học đã tồn tại
}

async function seedData() {
  const userID = 'user1';
  const categoryID = 'category1';

  // Người dùng
  await db.collection('users').doc(userID).set({
    username: "exampleuser",
    email: "user@example.com",
    password: "hashedPassword",
    fullName: "Full Name",
    role: "User",
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Danh mục
  await db.collection('categories').doc(categoryID).set({
    name: "Grammar"
  });

  // Danh sách bài học
  const lessons = [
    { order: 1, title: 'L1-1: Giới thiệu bản thân', description: 'Introduce yourself' },
    { order: 2, title: 'L1-2: Giới thiệu gia đình', description: 'Introduce family' },
    { order: 3, title: 'L1-3: Giới thiệu trường học', description: 'Introduce school' },
    { order: 4, title: 'L1-4: Giới thiệu động vật', description: 'Introduce animals' },
    { order: 5, title: 'L1-5: Giới thiệu cây cối', description: 'Talk about trees' },
    { order: 6, title: 'L1-6: Giới thiệu sở thích', description: 'Talk about hobbies' },
    { order: 7, title: 'L1-7: Giới thiệu công việc', description: 'Talk about jobs' },
    { order: 8, title: 'L1-8: Giới thiệu thành phố', description: 'Talk about city' },
    { order: 9, title: 'L1-9: Giới thiệu đất nước', description: 'Talk about country' },
    { order: 10, title: 'L1-10: Giới thiệu món ăn', description: 'Talk about food' },
  ];

  for (const [index, lesson] of lessons.entries()) {
    const lessonExists = await checkIfLessonExists(lesson.title);
    
    if (!lessonExists) {
      const lessonRef = await db.collection('lessons').add({
        ...lesson,
        categoryID,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      const lessonID = lessonRef.id;

      // Mỗi bài học có dữ liệu mẫu
      await db.collection('vocabulary').add({
        lessonID,
        word: "Example",
        meaning: "This is an example.",
        audioURL: "http://link.to/audiofile"
      });

      await db.collection('listening_exercises').add({
        lessonID,
        audioURL: "http://link.to/audiofile",
        correctAnswer: "A"
      });

      await db.collection('speaking_exercises').add({
        lessonID,
        word: "Hello",
        audioURL: "http://link.to/audiofil"
      });

      await db.collection('quizzes').add({
        lessonID,
        question: "What is the meaning of 'Example'?",
        imageURL: "", // Có thể cập nhật sau
        optionA: "A. Example",
        optionB: "B. Sample",
        optionC: "C. Test",
        optionD: "D. None",
        correctAnswer: "A"
      });

      await db.collection('user_progress').add({
        userID,
        lessonID,
        progressPercent: 0,
        completedAt: null
      });

      console.log(`✅ Đã thêm bài học mới: ${lesson.title}`);
    } else {
      console.log(`❌ Bài học đã tồn tại: ${lesson.title}`);
    }
  }

  // Streak
  await db.collection('streak').doc(userID).set({
    userID,
    currentStreak: 5,
    lastStudiedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Cài đặt người dùng
  await db.collection('user_settings').doc(userID).set({
    language: "English",
    notificationsEnabled: true,
    theme: "Light"
  });

  console.log("✅ Đã thêm toàn bộ dữ liệu mẫu thành công!");
}

seedData().catch(console.error);
module.exports = { seedData };