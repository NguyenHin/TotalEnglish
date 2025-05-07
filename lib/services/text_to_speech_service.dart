import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  TextToSpeechService() {
    _initTTS();
  }

  void _initTTS() async {
  print("Đang khởi tạo FlutterTts...");
  try {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);   //Tốc độ đọc (0.0 - 1.0)
    await _flutterTts.setPitch(0.5);    //cao độ (0.0 - 1.0)
    
    print("FlutterTts khởi tạo thành công.");
  } catch (e) {
    print("Lỗi khởi tạo FlutterTts: $e");
  }
}

  Future<void> speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setVolume(1.0); // âm lượng
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
