// seed.js
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Tạo activity cho 1 lesson (chỉ khi chưa có activities cho từng word)
 */
async function createActivitiesForLesson(lessonId) {
  console.log(`\n▶ Processing lesson: ${lessonId}`);
  const vocabSnap = await db
    .collection("lessons")
    .doc(lessonId)
    .collection("vocabulary")
    .get();

  if (vocabSnap.empty) {
    console.log(`⚠️ Lesson ${lessonId} không có vocabulary.`);
    return;
  }

  for (const vocabDoc of vocabSnap.docs) {
    const data = vocabDoc.data();
    const wordId = vocabDoc.id;

    const activitiesRef = vocabDoc.ref.collection("activities");
    const activitiesSnap = await activitiesRef.get();

    // Nếu đã có activity subcollection -> skip (an toàn)
    if (!activitiesSnap.empty) {
      console.log(`⏩ Skip ${wordId} (activities already exist)`);
      continue;
    }

    // =============== Fill in Blank ===============
    await activitiesRef.doc("fill_in_blank").set({
      questionType: "fill_in_blank",
      word: data.word,
      meaning: data.meaning,
      example: data.example,
      exampleMeaning: data.exampleMeaning,
      imageURL: data.imageURL,
      phonetic: data.phonetic,
    });

    // =============== Multiple Choice ===============
    // Lưu như trước: options là list các nghĩa (text)
    // (Nếu bạn muốn options chứa word+image, mình sẽ sửa script sau)
    const otherMeanings = vocabSnap.docs
      .filter((d) => d.id !== wordId)
      .map((d) => (d.data().meaning ? d.data().meaning : ""))
      .filter((m) => m)
      .sort(() => 0.5 - Math.random())
      .slice(0, 2); // lấy 2 distractors như script cũ

    const options = [data.meaning, ...otherMeanings].sort(() => 0.5 - Math.random());

    await activitiesRef.doc("multiple_choice").set({
      questionType: "multiple_choice",
      word: data.word,
      meaning: data.meaning,
      example: data.example,
      exampleMeaning: data.exampleMeaning,
      imageURL: data.imageURL,
      phonetic: data.phonetic,
      options: options,
    });

    // =============== Letter Tiles ===============
    await activitiesRef.doc("letterTiles").set({
      questionType: "letterTiles",
      word: data.word,
      meaning: data.meaning,
      example: data.example,
      exampleMeaning: data.exampleMeaning,
      imageURL: data.imageURL,
      phonetic: data.phonetic,
      letters: data.word ? data.word.split("") : [],
    });

    console.log(`✅ Created activities for word: ${wordId}`);
  }

  console.log(`🎉 Done for lesson: ${lessonId}`);
}

/**
 * MAIN: chạy cho 1 mảng lessonIds (an toàn)
 * Thay array bên dưới bằng list 10 lessonId của bạn
 */
async function runSelectedLessons() {
  const lessonIds = [
    // Thay list này bằng lessonId thực tế của bạn (10 id)
    "gNkMh6p9GCCv5giYy6m7",
    "i7RRqFtUKCsQf4RAVUmf",
    "seJ93iGXIopphluwb8FH",
    "zgncrfDgGHlNx3rdE0Uf",
    "GPTLh1RRjLEexZrpeWog",
    "pxMl2Ww1nDRwwycYnk2K",
    "ETdUwkKqztCzq17Ojgem",
    "tesnlztzbdaubiB3nu8s",
    "VqjZhMv7iW2syIjL6gj7",
    "OoK0nxH7G5aMfgo7aZI0"
  ];

  for (const id of lessonIds) {
    try {
      await createActivitiesForLesson(id);
    } catch (err) {
      console.error(`❌ Error processing lesson ${id}:`, err);
    }
  }

  console.log("✅ All selected lessons processed.");
}

// chạy
runSelectedLessons().catch(console.error);
