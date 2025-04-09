const admin = require('firebase-admin');
const fs = require('fs');

// Đọc file key (đổi lại tên nếu cần)
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

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
    { title: 'L1-1: Giới thiệu bản thân', description: 'Introduce yourself' },
    { title: 'L1-2: Giới thiệu gia đình', description: 'Introduce family' },
    { title: 'L1-3: Giới thiệu trường học', description: 'Introduce school' },
    { title: 'L1-4: Giới thiệu động vật', description: 'Introduce animals' },
    { title: 'L1-5: Giới thiệu cây cối', description: 'Talk about trees' },
    { title: 'L1-6: Giới thiệu sở thích', description: 'Talk about hobbies' },
    { title: 'L1-7: Giới thiệu công việc', description: 'Talk about jobs' },
    { title: 'L1-8: Giới thiệu thành phố', description: 'Talk about city' },
    { title: 'L1-9: Giới thiệu đất nước', description: 'Talk about country' },
    { title: 'L1-10: Giới thiệu món ăn', description: 'Talk about food' },
  ];

  for (const [index, lesson] of lessons.entries()) {
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
