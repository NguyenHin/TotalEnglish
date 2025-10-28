import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class RecordTestScreen extends StatefulWidget {
  const RecordTestScreen({super.key});

  @override
  State<RecordTestScreen> createState() => _RecordTestScreenState();
}

class _RecordTestScreenState extends State<RecordTestScreen> {
  final record = Record();
  bool _isRecording = false;
  bool _isUploading = false;
  List<Map<String, String>> _recordings = []; // {fileName, text}
  String? _currentFilePath;

  // Lấy đường dẫn file ghi âm mới
  Future<String> _getNewFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/record_$timestamp.wav';
  }

  // Bắt đầu ghi âm
  Future<void> _startRecording() async {
    if (await record.hasPermission()) {
      final path = await _getNewFilePath();
      await record.start(
        path: path,
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        samplingRate: 16000, // Vosk yêu cầu 16kHz
      );
      setState(() {
        _isRecording = true;
        _currentFilePath = path;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có quyền sử dụng micro!")),
      );
    }
  }

  // Dừng ghi âm và gửi file lên server
  Future<void> _stopRecording() async {
    await record.stop();
    setState(() => _isRecording = false);

    if (_currentFilePath != null) {
      await _sendFile(File(_currentFilePath!));
    }
  }

  // Gửi file lên server Node.js để chuyển đổi âm thanh thành văn bản
  Future<void> _sendFile(File audioFile) async {
    setState(() => _isUploading = true);

    final uri = Uri.parse('http://192.168.123.171:3000/transcribe'); // IP của máy server
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      String resultText;

      if (response.statusCode == 200) {
        resultText = response.body; // Nhận kết quả chuyển đổi
      } else {
        resultText = 'Error: ${response.statusCode}';
      }

      // Cập nhật danh sách ghi âm và kết quả chuyển đổi văn bản
      setState(() {
        _recordings.add({
          'fileName': audioFile.path.split('/').last,
          'text': resultText,
        });
      });
    } catch (e) {
      setState(() {
        _recordings.add({
          'fileName': audioFile.path.split('/').last,
          'text': 'Exception: $e',
        });
      });
    } finally {
      // Xóa file ghi âm sau khi đã gửi và nhận kết quả
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record & Transcribe')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(_isRecording ? '🎙️ Đang ghi âm...' : '⏹️ Đã dừng'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Dừng' : 'Bắt đầu ghi'),
            ),
            const SizedBox(height: 10),
            if (_isUploading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _recordings.length,
                itemBuilder: (context, index) {
                  final rec = _recordings[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('File: ${rec['fileName']}'),
                      subtitle: Text('Text: ${rec['text']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
