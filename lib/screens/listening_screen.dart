import 'package:flutter/material.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  _ListeningScreenState createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _words = [
    {'word': 'apple', 'meaning': 'trái táo'},
    {'word': 'banana', 'meaning': 'chuối'},
    {'word': 'cat', 'meaning': 'con mèo'},
  ];

  String? _vocabulary = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                _buildBackButton(context),
                _buildListeningForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 50,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  Widget _buildListeningForm(BuildContext context) {
    return Positioned(
      top: 120,
      left: 22,
      right: 22,
      child: Column(
        children: [
          const HeaderLesson(
            title: 'Listening',
            color: Color(0xFF89B3D4),
          ),
          const SizedBox(height: 30),

          // Hiển thị kết quả: đúng hay sai
          if (_vocabulary != null && _vocabulary!.isNotEmpty)
            Text(
              _vocabulary!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _vocabulary == 'Không đúng, thử lại.'
                    ? Colors.red
                    : Colors.green,
              ),
            ),

          const SizedBox(height: 30),

          // PageView để chuyển từ
          SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _words.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _controller.clear();
                  _vocabulary = '';
                });
              },
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    PlayButton(
                      onPressed: () {
                        // future: phát âm thanh _words[index]['word']
                      },
                      label: "Click to hear the word",
                    ),
                    const SizedBox(height: 30),

                    Container(
                      width: 265,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F9FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập từ vào đây',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 30,
                          ),
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF89B3D4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Check Answer",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_words.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.blue
                      : Colors.grey.shade400,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _checkAnswer() {
    String correctWord = _words[_currentPage]['word']!.toLowerCase();
    String correctMeaning = _words[_currentPage]['meaning']!;

    setState(() {
      if (_controller.text.trim().toLowerCase() == correctWord) {
        _vocabulary = '$correctWord : $correctMeaning';
      } else {
        _vocabulary = 'Không đúng, thử lại.';
      }
    });
  }
}
