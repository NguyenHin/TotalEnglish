import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyItem {
  final QueryDocumentSnapshot doc;

  // Danh sách options cho multiple-choice (mặc định rỗng)
  final List<String> options;

  VocabularyItem({
    required this.doc,
    this.options = const [],
  });

  Map<String, dynamic> get data => doc.data() as Map<String, dynamic>;

  String get word => data['word'] ?? '';
  String get meaning => data['meaning'] ?? '';
  String get example => data['example'] ?? '';
  String get exampleMeaning => data['exampleMeaning'] ?? '';
  String get imageURL => data['imageURL'] ?? '';
  String get phonetic => data['phonetic'] ?? '';
}
