const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  admin.app(); // Nếu đã có app thì sử dụng app hiện tại
}

const db = admin.firestore();

// Hàm xoá toàn bộ document trong collection
async function deleteCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const batch = db.batch();

  snapshot.forEach(doc => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`🗑️ Đã xoá ${snapshot.size} document trong "${collectionName}"`);
}

async function resetDatabase() {
  const collectionsToDelete = [
    'users',
    'categories',
    'lessons',
    'vocabulary',
    'quizzes',
    'listening_exercises',
    'speaking_exercises',
    'user_progress',
    'streak',
    'user_settings'
  ];

  for (const collection of collectionsToDelete) {
    await deleteCollection(collection);
  }

  console.log('✅ Dữ liệu đã được xoá hoàn toàn!');
}

resetDatabase().catch(console.error);
