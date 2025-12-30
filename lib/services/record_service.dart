// import 'dart:io';
// import 'dart:math' as math;
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class RecordService {
//   final Record _record = Record();
//   bool isRecording = false;
//   bool isUploading = false;
  

//   /// 🗂️ Tạo đường dẫn file .wav mới
//   Future<String> _getNewFilePath() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     return '${dir.path}/record_$timestamp.wav';
//   }

//   /// 🎙️ Bắt đầu ghi âm
//   Future<String?> startRecording() async {
//     if (isRecording || isUploading) return null;  //kt có đang ghi âm or tải file?

//     if (await _record.hasPermission()) {
//       final path = await _getNewFilePath();
//       await _record.start(
//         path: path,
//         encoder: AudioEncoder.wav,
//         bitRate: 32000,
//         samplingRate: 16000, // ✅ Vosk yêu cầu 16kHz
//         numChannels: 1,
//       );
//       isRecording = true;
//       return path;
//     }
//     return null;
//   }

//   /// ⏹️ Dừng ghi âm và gửi file lên server Vosk
//   Future<Map<String, dynamic>> stopRecordingAndSend({
//     required String filePath,
//     required String serverUrl,
//     String? expectedWord, // từ đúng để so sánh accuracy
//   }) async {
//     if (!isRecording) return {'text': '', 'accuracy': 0.0, 'isCorrect': false};

//     await _record.stop();
//     isRecording = false;
//     isUploading = true;

//     //dữ liệu gửi lên server
//     String recognizedText = '';
//     double accuracy = 0.0;
//     bool isCorrect = false;
//     final audioFile = File(filePath);

//     try {
//       final uri = Uri.parse(serverUrl);
//       //hhtp.post chỉ gửi dữ liệu dạng text
//       //cần gửi cả file âm thanh (.wav) lên server, nên phải dùng MultipartRequest,
//       final request = http.MultipartRequest('POST', uri);

//       // Thêm dòng này để gửi từ mục tiêu sang Node.js
//       if (expectedWord != null) {
//         request.fields['expectedWord'] = expectedWord;
//       }

//       request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         recognizedText = (data['text'] ?? '').trim();

//         if (expectedWord != null && expectedWord.isNotEmpty) {
//           accuracy = _calculateAccuracy(recognizedText, expectedWord);
//           isCorrect = accuracy >= 70.0;
//         }
//       }
//     } catch (e) {
//       print("❌ RecordService error: $e");
//     } finally {
//       //if (await audioFile.exists()) await audioFile.delete();
//       Future.delayed(const Duration(seconds: 1), () async {
//   if (await audioFile.exists()) {
//     await audioFile.delete();
//   }
// });

//       isUploading = false;
//     }

//     return {
//       'text': recognizedText,
//       'accuracy': accuracy,
//       'isCorrect': isCorrect,
//     };
//   }

//   /// 📊 Hàm tính độ chính xác giữa 2 chuỗi (Levenshtein)
//   double _calculateAccuracy(String spoken, String expected) {
//     if (spoken.isEmpty || expected.isEmpty) return 0.0;

//     spoken = spoken.toLowerCase().trim();
//     expected = expected.toLowerCase().trim();

//     final distance = _levenshtein(spoken, expected);
//     final maxLen = math.max(spoken.length, expected.length);

//     final accuracy = ((maxLen - distance) / maxLen) * 100;
//     return accuracy.clamp(0.0, 100.0);
//   }


//   int _levenshtein(String a, String b) {
//     final m = a.length; 
//     final n = b.length;
//     List<List<int>> dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

//     for (int i = 0; i <= m; i++) {
//       dp[i][0] = i;
//     }

//     for (int j = 0; j <= n; j++) {
//       dp[0][j] = j;
//     }

//     for (int i = 1; i <= m; i++) {
//       for (int j = 1; j <= n; j++) {
//         final cost = a[i - 1] == b[j - 1] ? 0 : 1;
//         dp[i][j] = [
//           dp[i - 1][j] + 1, // xóa
//           dp[i][j - 1] + 1, // thêm
//           dp[i - 1][j - 1] + cost, // thay
//         ].reduce((a, b) => a < b ? a : b);
//       }
//     }

//     return dp[m][n];
//   }

// }


// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:math' as math;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecordService {
  final Record _record = Record();

  bool _isRecording = false;
  bool _isUploading = false;

bool get isRecording => _isRecording;
bool get isUploading => _isUploading;
bool get isBusy => _isRecording || _isUploading;

  Future<String> _getNewFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/record_$timestamp.wav';
  }

  /// 🎙️ Start recording
  Future<String> startRecording() async {
    if (_isRecording) {
      throw StateError('Recording already started');
    }
    if (_isUploading) {
      throw StateError('Uploading in progress');
    }

    final hasPermission = await _record.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission denied');
    }

    final path = await _getNewFilePath();

    await _record.start(
      path: path,
      encoder: AudioEncoder.wav,
      bitRate: 32000,
      samplingRate: 16000,
      numChannels: 1,
    );

    _isRecording = true;
    return path;
  }

  /// ⏹️ Stop & send
  Future<Map<String, dynamic>> stopRecordingAndSend({
    required String filePath,
    required String serverUrl,
    String? expectedWord,
  }) async {
    if (!_isRecording) {
      throw StateError('Not recording');
    }

    await _record.stop();
    _isRecording = false;
    _isUploading = true;

    String recognizedText = '';
    double accuracy = 0.0;
    bool isCorrect = false;

    final audioFile = File(filePath);

    try {
      final uri = Uri.parse(serverUrl);
      final request = http.MultipartRequest('POST', uri);

      if (expectedWord != null) {
        request.fields['expectedWord'] = expectedWord;
      }

      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        recognizedText = (data['text'] ?? '').trim();

        if (expectedWord != null && expectedWord.isNotEmpty) {
          accuracy = _calculateAccuracy(recognizedText, expectedWord);
          isCorrect = accuracy >= 70.0;
        }
      }
    } finally {
      _isUploading = false;

      Future.delayed(const Duration(seconds: 1), () async {
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      });
    }

    return {
      'text': recognizedText,
      'accuracy': accuracy,
      'isCorrect': isCorrect,
    };
  }

  double _calculateAccuracy(String spoken, String expected) {
    if (spoken.isEmpty || expected.isEmpty) return 0.0;

    spoken = spoken.toLowerCase().trim();
    expected = expected.toLowerCase().trim();

    final distance = _levenshtein(spoken, expected);
    final maxLen = math.max(spoken.length, expected.length);

    final accuracy = ((maxLen - distance) / maxLen) * 100;
    return accuracy.clamp(0.0, 100.0);
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;

    final dp = List.generate(
      m + 1,
      (_) => List.filled(n + 1, 0),
    );

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce(math.min);
      }
    }
    return dp[m][n];
  }
}
