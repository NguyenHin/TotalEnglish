# TotalEnglish — Speech to Text pipeline (Student Guide)

This guide helps you run a simple Speech-to-Text (STT) pipeline:

Flutter (record) → Express (Node.js) → Vosk (ASR) → Result text → Firebase (optional)

## 1) What you will build

- A Flutter app that records your voice and uploads a `.wav` file.
- A Node/Express server that uses the Vosk model to transcribe the audio.
- Optional: The server uploads audio to Firebase Storage and saves transcript in Firestore.

## 2) Requirements

- Flutter SDK installed
- Node.js 18+
- Download a Vosk model (example: small English):
  - Search for "vosk model small en-us 0.15", unzip to `server/models/vosk-model-small-en-us-0.15`
- Optional Firebase project + service account JSON

## 3) Run the server (local)

1. Open a terminal:
   ```bash
   cd server
   npm install
   ```
   If `npm install` complains, ensure you have build tools and enough disk space.

2. Create `.env` in `server/` (copy from `.env.example`):
   ```env
   PORT=8080
   VOSK_MODEL_PATH=./models/vosk-model-small-en-us-0.15
   FIREBASE_ENABLED=false
   ```

3. Start the server:
   ```bash
   npm start
   ```
   You should see: `STT server listening on http://localhost:8080`

Test health:
```bash
curl http://localhost:8080/health
```

## 4) Run the Flutter app

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Android emulator (works with local server):
   ```bash
   flutter run
   ```
   Note: The app uses `http://10.0.2.2:8080` on Android emulator.
3. Web/iOS/real device: Make sure the URL points to your machine IP or `localhost` depending on your target.

In the app:
- Press the mic button to start/stop recording.
- After stop, the app uploads the `.wav` file to the server and shows the transcript.

## 5) Audio format the server expects

- PCM WAV, mono, 16 kHz sample rate.
- The app uses these settings by default with the `record` package.

## 6) Enabling Firebase saving (optional)

1. Create a Firebase project. Generate a Service Account JSON with Storage and Firestore access.
2. Place JSON at `server/serviceAccountKey.json` and set:
   ```env
   FIREBASE_ENABLED=true
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
   FIREBASE_STORAGE_BUCKET=your-project.appspot.com
   ```
3. Restart the server. On each upload:
   - The audio file goes to `recordings/{userId}/{sessionId}-<filename>` in Storage.
   - A Firestore doc `sessions/{sessionId}` stores `finalText` and metadata.
   - You can pass a user id via header `x-user-id: <uid>` (basic demo).

## 7) Troubleshooting

- Server says model not found: check `VOSK_MODEL_PATH` and directory exists.
- Android cannot reach server: use `10.0.2.2` for emulator; for a real device, use your computer LAN IP and open firewall.
- iOS microphone permission dialog not shown: ensure `NSMicrophoneUsageDescription` exists in `ios/Runner/Info.plist`.
- Empty transcript: speak clearly; try a less noisy environment.

## 8) Next steps

- Switch to WebSocket streaming to see live partial results.
- Add Firebase Auth: send ID token and verify on the server.
- Store per-word timestamps (`result.words`) into a Firestore subcollection.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
