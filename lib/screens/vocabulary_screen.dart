import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_english/services/streak_services.dart';
import 'package:total_english/services/text_to_speech_service.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';

class VocabularyScreen extends StatefulWidget {
  final String lessonId;
  final void Function(String activity, bool isCompleted)? onCompleted;


  VocabularyScreen({
    super.key, 
    required this.lessonId,
    this.onCompleted});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<QueryDocumentSnapshot> _vocabularyList = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _vocabularyCompleted = false;
  int _listenCount = 0;
  bool _streakUpdated = false;

  //nghe 5 lần -> streak
  Future<void> _handleListen(String text) async {
    await _ttsService.speak(text);
    _listenCount++;
    print('So lan nghe hien tai: $_listenCount');
    
    if (_listenCount >=5 && !_streakUpdated) {
      _streakUpdated = true;
      print("Đã nghe đủ 5 lần. Cập nhật streak...");
      try {
        await updateStreak();
        print("Cập nhật streak thành công.");
      } catch (e) {
        print("Lỗi khi cập nhật streak: $e");
      }
    }
  }

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
      setState(() {
        _vocabularyList = snapshot.docs;
        _isLoading = false;
      });
      print("Đã tải ${_vocabularyList.length} từ vựng cho bài học: ${widget.lessonId}");
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải từ vựng. Lỗi: $error";
      });
      print("Lỗi tải từ vựng cho bài học ${widget.lessonId}: $error");
    }
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 30,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context, _vocabularyCompleted ? {'completedActivity': 'vocabulary', 'isCompleted': true} : null);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop(); // Dừng phát âm khi màn hình không còn được hiển thị
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Đang build giao diện từ vựng cho bài học: ${widget.lessonId}");
    return PopScope<int>(
      onPopInvokedWithResult: (bool didPop, int? result) {
        if (!_vocabularyCompleted && _currentIndex == _vocabularyList.length - 1) {
          _vocabularyCompleted = true;
          widget.onCompleted?.call('vocabulary', true);
          print("Đã gọi onCompleted khi user bấm nút back hệ thống.");
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 55),
                    const HeaderLesson(
                      title: 'Vocabulary',
                      color: Color(0xFF89B3D4),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                              ? Center(child: Text(_errorMessage!))
                              : _vocabularyList.isEmpty
                                  ? const Center(child: Text('Không có từ vựng'))
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: PageView.builder(
                                            controller: _pageController,
                                            onPageChanged: (index) {
                                              setState(() {
                                                _currentIndex = index;
                                                print("Đang ở trang: $_currentIndex");
      
                                                // Kiểm tra nếu người dùng đến từ vựng cuối cùng, gọi onCompleted 1 lần
                                                if (index == _vocabularyList.length - 1 && !_vocabularyCompleted) {
                                                  _vocabularyCompleted = true;
                                                  print("Đã hoàn thành từ vựng.");
                                                  widget.onCompleted?.call('vocabulary', true);
                                                }
      
                                              });
                                            },
      
                                            itemCount: _vocabularyList.length,
                                            itemBuilder: (context, index) {
                                              final currentWord = _vocabularyList[index];
                                              final wordData = currentWord.data() as Map<String, dynamic>?;
                                              return SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Hình ảnh của từ vựng
                                                    Image.network(
                                                      wordData?['imageURL'] ?? '',
                                                      width: 160,
                                                      height: 160,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const SizedBox(
                                                          width: 160,
                                                          height: 160,
                                                          child: Center(child: Icon(Icons.image_not_supported)),
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      wordData?['word'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      wordData?['phonetic'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
      
                                                    Text(
                                                      wordData?['meaning'] ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 17,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 16),
      
                                                    PlayButton(
                                                      onPressed: () async{
                                                        final wordData = _vocabularyList[_currentIndex].data() as Map<String, dynamic>?;
                                                        if (wordData != null && wordData.containsKey('word')) {
                                                          await _handleListen(wordData['word']);
      
      
                                                        } else {
                                                          print("Không tìm thấy từ để phát âm.");
                                                        }
                                                      },
                                                    ),
      
                                                    const SizedBox(height: 16),
                                                    // Ví dụ câu cho từ vựng
                                                    if (wordData?.containsKey('example') ?? false)
                                                      Column(
                                                        children: [
                                                          Text(
                                                            wordData?['example'] ?? '',
                                                            style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                          const SizedBox(height: 12),
                                                          
                                                         //Nghĩa của câu 
                                                          if (wordData?.containsKey('exampleMeaning') ?? false)
                                                            Text(
                                                              wordData?['exampleMeaning'] ?? '',
                                                              style: const TextStyle(
                                                                color: Colors.blueAccent,
                                                                fontSize: 16,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          const SizedBox(height: 16),
      
                                                          // Nút play cho ví dụ
                                                          PlayButton(
                                                            onPressed: () async {
                                                              final wordData = _vocabularyList[_currentIndex].data() as Map<String, dynamic>?;
                                                              if (wordData != null && wordData.containsKey('example')) {
                                                                await _handleListen(wordData['example']);
                                                              } else {
                                                                print("Không tìm thấy ví dụ để phát âm.");
                                                              }
                                                            },
                                                          ),
                                                          const SizedBox(height: 12),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(_vocabularyList.length, (index) {
                                            return AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              margin: const EdgeInsets.symmetric(horizontal: 5),
                                              height: 10,
                                              width: 10,
                                              decoration: BoxDecoration(
                                                color: _currentIndex == index ? Colors.blue : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                    ),
                  ],
                ),
              ),
              _buildBackButton(context),
            ],
          ),
        ),
      ),
    );
  }
}