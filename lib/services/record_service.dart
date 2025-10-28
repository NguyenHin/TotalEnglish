import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordService {
  final Record _record = Record();

  bool isRecording = false;
  bool isUploading = false;

  /// Lấy đường dẫn file ghi âm mới
  Future<String> _getNewFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/record_$timestamp.wav';
  }

  /// Bắt đầu ghi âm
  Future<String?> startRecording() async {
    if (isRecording || isUploading) return null;

    if (await _record.hasPermission()) {
      final path = await _getNewFilePath();
      await _record.start(
        path: path,
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        samplingRate: 16000, // Vosk yêu cầu 16kHz
      );
      isRecording = true;
      return path;
    }
    return null;
  }

  /// Dừng ghi âm và gửi file lên server
  Future<String?> stopRecordingAndSend({
    required String filePath,
    required String serverUrl,
    String? lessonId,
    int? wordIndex,
    bool saveToFirebase = false,
  }) async {
    if (!isRecording) return null;

    await _record.stop();
    isRecording = false;
    isUploading = true;

    String recognizedText = '';
    final audioFile = File(filePath);

    try {
      final uri = Uri.parse(serverUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        recognizedText = data['text'] ?? '';
      } else {
        recognizedText = '';
      }

      // Lưu lên Firebase nếu cần
      if (saveToFirebase && lessonId != null && wordIndex != null) {
        FirebaseFirestore.instance.collection('speech_history').add({
          'text': recognizedText,
          'lessonId': lessonId,
          'wordIndex': wordIndex,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("RecordService error: $e");
    } finally {
      if (await audioFile.exists()) await audioFile.delete();
      isUploading = false;
    }

    return recognizedText;
  }
}
