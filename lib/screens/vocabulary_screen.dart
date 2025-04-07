import 'package:flutter/material.dart';
import 'package:total_english/widgets/header_lesson.dart';
import 'package:total_english/widgets/play_button.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  _VocabularyScreenState createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // The current page controller for the PageView
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // A list of words to simulate the vocabulary
  final List<Map<String, String>> _vocabularyList = [
    {
      'word': 'Good bye',
      'type': '(verb)',
      'meaning': 'Tạm biệt',
      'example': 'Good bye!',
      'image': 'assets/icon/bye.png', // Replace with your image path
    },
    {
      'word': 'Hello',
      'type': '(greeting)',
      'meaning': 'Xin chào',
      'example': 'Hello, how are you?',
      'image': 'assets/icon/hello.png', // Replace with your image path
    },
    // Add more words here
  ];

  // The back button widget
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      left: 10,
      top: 30,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chevron_left, size: 28),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // The main content of the screen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  // Header for the lesson
                  const HeaderLesson(
                    title: 'Vocabulary',
                    color: Color(0xFF89B3D4),
                  ),
                  const SizedBox(height: 16),

                  // PageView for swiping between words
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: _vocabularyList.length,
                      itemBuilder: (context, index) {
                        final currentWord = _vocabularyList[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Word image
                            Image.asset(
                              currentWord['image']!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,  // Use BoxFit.cover for good scaling
                            ),
                            const SizedBox(height: 16),

                            // Word and type
                            Text(
                              currentWord['word']!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentWord['type']!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Play Button for the word sound
                            PlayButton(
                              onPressed: () {
                                // Play sound logic
                              },
                            ),
                            const SizedBox(height: 16),

                            // Vietnamese meaning
                            Text(
                              currentWord['meaning']!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Example sentence
                            Text(
                              currentWord['example']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Play Button for the example sentence
                            PlayButton(
                              onPressed: () {
                                // Play example sentence sound logic
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Small circular indicators for navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_vocabularyList.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Colors.blue
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // The back button, overlayed on top of the content
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }
}
