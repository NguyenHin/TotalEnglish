const admin = require('firebase-admin');
const serviceAccount = require("./serviceAccountKey.json");

// Khởi tạo Firebase Admin với service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Chỉ migrate lesson test
const LESSON_ID_TO_TEST = 'gNkMh6p9GCCv5giYy6m7';

async function migrateUserProgress() {
  try {
    const snapshot = await db.collection('user_lesson_progress')
      .where('lessonId', '==', LESSON_ID_TO_TEST)
      .get();

    console.log(`Tìm thấy ${snapshot.size} document cho lesson ${LESSON_ID_TO_TEST}.`);

    for (const doc of snapshot.docs) {
      const data = doc.data();

      // Lấy field cũ (có thể undefined nếu chưa tồn tại)
      const vocab = data['vocabularyCompleted'];
      const exercise = data['exerciseCompleted'];
      const speaking = data['speakingCompleted'];
      const quiz = data['quizCompleted'];

      // Tạo field mới đảm bảo luôn tồn tại
      const updatedData = {
        vocabulary: typeof vocab === 'boolean' ? (vocab ? 100 : 0) : 0,
        exercise: typeof exercise === 'boolean' ? (exercise ? 100 : 0) : 0,
        speaking: typeof speaking === 'boolean' ? (speaking ? 100 : 0) : 0,
        quiz: typeof quiz === 'boolean' ? (quiz ? 100 : 0) : 0,
      };

      // Cập nhật field mới và xóa field cũ + thừa
      await doc.ref.update({
        ...updatedData,
        vocabularyCompleted: admin.firestore.FieldValue.delete(),
        exerciseCompleted: admin.firestore.FieldValue.delete(),
        speakingCompleted: admin.firestore.FieldValue.delete(),
        quizCompleted: admin.firestore.FieldValue.delete(),
        listeningCompleted: admin.firestore.FieldValue.delete(), // xoá field thừa
      });

      console.log(`Cập nhật doc ${doc.id}:`, updatedData);
    }

    console.log('Migration lesson test hoàn tất ✅');
  } catch (error) {
    console.error('Lỗi migration:', error);
  }
}

migrateUserProgress();
