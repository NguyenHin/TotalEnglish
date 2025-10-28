/* eslint-disable no-console */
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const vosk = require('vosk');
const wav = require('wav');

require('dotenv').config();

const PORT = process.env.PORT || 8080;
const VOSK_MODEL_PATH = process.env.VOSK_MODEL_PATH || './models/vosk-model-small-en-us-0.15';

const FIREBASE_ENABLED = String(process.env.FIREBASE_ENABLED || 'false').toLowerCase() === 'true';
let firebaseAdmin = null;
let firestore = null;
let storageBucket = null;

if (FIREBASE_ENABLED) {
  // Lazy init to avoid requiring credentials when not used
  // GOOGLE_APPLICATION_CREDENTIALS should point to a service account JSON
  // FIREBASE_STORAGE_BUCKET should be like "your-project.appspot.com"
  // eslint-disable-next-line global-require
  firebaseAdmin = require('firebase-admin');
  if (!firebaseAdmin.apps.length) {
    firebaseAdmin.initializeApp({
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    });
  }
  firestore = firebaseAdmin.firestore();
  storageBucket = firebaseAdmin.storage().bucket();
}

if (!fs.existsSync(VOSK_MODEL_PATH)) {
  console.error(`Vosk model not found at ${VOSK_MODEL_PATH}. Please download and set VOSK_MODEL_PATH.`);
  process.exit(1);
}

vosk.setLogLevel(0);
const model = new vosk.Model(VOSK_MODEL_PATH);

const app = express();
app.use(cors());
app.use(express.json());

const uploadsDir = path.join(__dirname, 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });
const upload = multer({ dest: uploadsDir });

app.get('/health', (_req, res) => {
  res.json({ ok: true, modelPath: VOSK_MODEL_PATH });
});

// POST /stt/upload - multipart/form-data with field name 'audio'
app.post('/stt/upload', upload.single('audio'), async (req, res) => {
  const uploadedFile = req.file;
  if (!uploadedFile) {
    return res.status(400).json({ error: 'Missing audio file field "audio"' });
  }

  const sessionId = uuidv4();
  const filePath = uploadedFile.path;
  const originalName = uploadedFile.originalname || 'audio.wav';

  try {
    const result = await transcribeWavWithVosk(filePath);

    let firebaseDocRef = null;
    let storageFilePath = null;

    if (FIREBASE_ENABLED) {
      const userId = req.header('x-user-id') || 'anonymous';
      const createdAt = Date.now();
      storageFilePath = `recordings/${userId}/${sessionId}-${originalName}`;

      // Upload original audio to Cloud Storage
      await storageBucket.upload(filePath, {
        destination: storageFilePath,
        metadata: { contentType: uploadedFile.mimetype || 'audio/wav' },
      });

      // Create Firestore doc with transcript
      firebaseDocRef = firestore.collection('sessions').doc(sessionId);
      await firebaseDocRef.set({
        userId,
        createdAt,
        audioPath: storageFilePath,
        finalText: result.text || '',
        rawResult: result,
      });
    }

    return res.json({
      sessionId,
      text: result.text || '',
      result,
      firebase: FIREBASE_ENABLED
        ? { sessionDocPath: firebaseDocRef.path, storagePath: storageFilePath }
        : null,
    });
  } catch (err) {
    console.error('Transcription error:', err);
    return res.status(500).json({ error: 'Transcription failed', details: String(err) });
  } finally {
    // Clean up disk upload
    fs.unlink(filePath, () => {});
  }
});

async function transcribeWavWithVosk(filePath) {
  return new Promise((resolve, reject) => {
    const fileStream = fs.createReadStream(filePath);
    const reader = new wav.Reader();

    let recognizer = null;
    let finalResult = null;

    reader.on('format', (fmt) => {
      // Require PCM 16-bit mono. If not matching, ask client to send correct format
      if (fmt.audioFormat !== 1) {
        reject(new Error('Unsupported audio format: only PCM is supported'));
        return;
      }
      if (fmt.channels !== 1) {
        reject(new Error('Audio must be mono (1 channel)'));
        return;
      }

      const sampleRate = fmt.sampleRate || 16000;
      recognizer = new vosk.Recognizer({ model, sampleRate });
    });

    reader.on('data', (data) => {
      if (!recognizer) return;
      recognizer.acceptWaveform(data);
    });

    reader.on('end', () => {
      if (!recognizer) {
        reject(new Error('Recognizer not initialized'));
        return;
      }
      try {
        finalResult = recognizer.finalResult();
        recognizer.free();
      } catch (e) {
        reject(e);
        return;
      }
      resolve(finalResult);
    });

    reader.on('error', (e) => reject(e));
    fileStream.on('error', (e) => reject(e));

    fileStream.pipe(reader);
  });
}

app.listen(PORT, () => {
  console.log(`STT server listening on http://localhost:${PORT}`);
});


