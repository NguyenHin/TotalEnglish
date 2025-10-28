import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:total_english/widgets/exit_dialog.dart';
import 'package:total_english/widgets/final_score_dialog.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';
import 'package:total_english/widgets/animated_overlay_dialog.dart';

/// --- RecordService ---
class RecordService {
  final Record _record = Record();
  bool isRecording = false;
  bool isUploading = false;

  Future<String> _getNewFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/record_$timestamp.wav';
  }

  Future<String?> startRecording() async {
    if (isRecording || isUploading) return null;
    if (await _record.hasPermission()) {
      final path = await _getNewFilePath();
      await _record.start(
        path: path,
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        samplingRate: 16000,
      );
      isRecording = true;
      return path;
    }
    return null;
  }

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
      }

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

/// --- SpeakingScreen ---
class SpeakingScreen extends StatefulWidget {
  final String lessonId;
  const SpeakingScreen({super.key, required this.lessonId});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  final PageController _pageController = PageController();
  final RecordService _recordService = RecordService();

  List<QueryDocumentSnapshot> _vocabularyList = [];
  final Set<int> _spokenCorrectly = {};
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  String _micButtonLabel = 'Nói';
  double _micScale = 1.0;
  bool _isLessonCompleted = false;
  Widget? _highlightWidget;
  bool _showOverlayDialog = false;
  bool _lastAnswerCorrect = false;
  String _lastCorrectWord = '';
  String? _currentFilePath;

  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .collection('vocabulary')
          .get();
      _vocabularyList = snapshot.docs;
      setState(() => _isLoading = false);
      if (_vocabularyList.isNotEmpty) _autoPlayWord(0);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải từ vựng: $e";
      });
    }
  }

  Future<void> _autoPlayWord(int index) async {
    if (index < 0 || index >= _vocabularyList.length) return;
    final wordData = _vocabularyList[index].data() as Map<String, dynamic>? ?? {};
    final word = wordData['word'] ?? '';
    if (word.isEmpty) return;
    _isPlayingNotifier.value = true;
    await _ttsService.speak(word);
    _isPlayingNotifier.value = false;
  }

  /// --- Mic Button logic ---
  void _startMicPulse() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_recordService.isRecording) {
        setState(() => _micScale = 1.2);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_recordService.isRecording) {
            setState(() => _micScale = 1.0);
            _startMicPulse();
          }
        });
      }
    });
  }

  void _stopMicPulse() => setState(() => _micScale = 1.0);

  void _onMicPressed() async {
    bool isLocked = _spokenCorrectly.contains(_currentPage);
    if (isLocked) return;

    if (!_recordService.isRecording) {
      _currentFilePath = await _recordService.startRecording();
      if (_currentFilePath != null) _startMicPulse();
    } else {
      _stopMicPulse();
      final recognizedText = await _recordService.stopRecordingAndSend(
        filePath: _currentFilePath!,
        serverUrl: 'http://192.168.123.171:3000/transcribe',
        lessonId: widget.lessonId,
        wordIndex: _currentPage,
        saveToFirebase: true,
      );
      if (recognizedText != null) _checkSpokenWord(recognizedText);
    }
  }

  void _checkSpokenWord(String result) {
    if (_vocabularyList.isEmpty || _currentPage >= _vocabularyList.length) return;
    final wordData = _vocabularyList[_currentPage].data() as Map<String, dynamic>? ?? {};
    final correctWord = wordData['word'] ?? '';
    final spokenWord = result.trim();
    bool isCorrect = spokenWord.toLowerCase() == correctWord.toLowerCase();

    setState(() {
      _lastAnswerCorrect = isCorrect;
      _lastCorrectWord = correctWord;
      _showOverlayDialog = true;
      _highlightWidget = _highlightSpelling(correctWord, spokenWord);
      if (isCorrect) _spokenCorrectly.add(_currentPage);
      if (_spokenCorrectly.length == _vocabularyList.length && !_isLessonCompleted) {
        _isLessonCompleted = true;
        _showFinalScore();
      }
    });
  }

  Widget _highlightSpelling(String correctWord, String spokenWord) {
    List<TextSpan> spans = [];
    int length = correctWord.length > spokenWord.length ? correctWord.length : spokenWord.length;
    int correctCount = 0;
    for (int i = 0; i < length; i++) {
      String c = i < correctWord.length ? correctWord[i] : '';
      String s = i < spokenWord.length ? spokenWord[i] : '';
      if (c.toLowerCase() == s.toLowerCase()) {
        spans.add(TextSpan(text: s, style: const TextStyle(color: Colors.green, fontSize: 24)));
        correctCount++;
      } else {
        spans.add(TextSpan(text: s.isEmpty ? '_' : s, style: const TextStyle(color: Colors.red, fontSize: 24)));
      }
    }
    double accuracy = correctCount / correctWord.length * 100;
    return Column(
      children: [
        RichText(text: TextSpan(children: spans, style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Text("Accuracy: ${accuracy.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildSpeakButton() {
    bool isLocked = _spokenCorrectly.contains(_currentPage);
    return GestureDetector(
      onTap: _onMicPressed,
      child: Column(
        children: [
          AnimatedScale(
            scale: _micScale,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey
                    : (_recordService.isRecording ? Colors.red : const Color(0xFF89B3D4)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Icon(FontAwesomeIcons.microphone, size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(isLocked ? "Đã đúng" : (_recordService.isRecording ? "🎙️ Đang nghe..." : "Nói"),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
        ],
      ),
    );
  }

  /// --- Build UI ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _showExitDialog(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _buildLessonContent(context),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context) {
    return Stack(
      children: [
        _buildBackButton(context),
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                HeaderLesson(
                  title: 'Speaking (${_spokenCorrectly.length}/${_vocabularyList.length})',
                  color: const Color(0xFF89B3D4),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vocabularyList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _highlightWidget = null;
                      });
                      _autoPlayWord(index);
                    },
                    itemBuilder: (context, index) {
                      final wordData = _vocabularyList[index].data() as Map<String, dynamic>? ?? {};
                      final word = wordData['word'] ?? '';
                      final phonetic = wordData['phonetic'] ?? '';
                      final isCorrect = _spokenCorrectly.contains(index);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(word,
                                      style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: isCorrect ? Colors.green[700] : Colors.black87),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 10),
                                  Text(phonetic,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.black54),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PlayButton(onPressed: () async => await _autoPlayWord(index), isPlayingNotifier: _isPlayingNotifier),
                                const SizedBox(width: 50),
                                _buildSpeakButton(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (_highlightWidget != null) _highlightWidget!,
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_vocabularyList.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _spokenCorrectly.contains(index)
                            ? Colors.green
                            : (_currentPage == index ? Colors.blue : Colors.grey.shade400),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (_showOverlayDialog)
          AnimatedOverlayDialog(
            correctAnswer: _lastCorrectWord,
            isCorrect: _lastAnswerCorrect,
            onContinue: () {
              setState(() => _showOverlayDialog = false);
              if (_lastAnswerCorrect && _currentPage < _vocabularyList.length - 1) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                _autoPlayWord(_currentPage + 1);
              }
            },
          ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: MediaQuery.of(context).padding.top + 10,
      child: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () async {
          if (await _showExitDialog(context)) Navigator.pop(context);
        },
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExitDialog(
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    return result ?? false;
  }

  void _showFinalScore() {
    final total = _vocabularyList.length;
    final correct = _spokenCorrectly.length;
    final wrongIndexes = List<int>.generate(total, (i) => i).where((i) => !_spokenCorrectly.contains(i)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinalScoreDialog(
        correct: correct,
        total: total,
        wrongIndexes: wrongIndexes,
        onRetryWrong: () {
          Navigator.pop(context);
          _restartWrongQuestions(wrongIndexes);
        },
        onComplete: () {
          Navigator.pop(context);
          Navigator.pop(context, {
            'completedActivity': 'speaking',
            'correctCount': correct,
            'totalCount': total,
            'progress': (correct / total) * 100,
          });
        },
      ),
    );
  }

  void _restartWrongQuestions(List<int> wrongIndexes) {
    setState(() {
      _currentPage = 0;
      _vocabularyList = wrongIndexes.map((i) => _vocabularyList[i]).toList();
      _spokenCorrectly.clear();
      _highlightWidget = null;
      _isLessonCompleted = false;
    });
    _pageController.jumpToPage(0);
    _autoPlayWord(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    super.dispose();
  }
}
