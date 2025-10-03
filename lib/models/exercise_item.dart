import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseType { fillInBlank, multipleChoice, letterTiles }

class ExerciseItem {
  final DocumentSnapshot doc; // document activity từ Firestore
  final ExerciseType type;
  final List<String>? letters; // chỉ dùng cho LetterTiles

  // Chỉ dùng cho MultipleChoice: mỗi option có word + imageURL
  List<ExerciseItem>? optionsItems;

  ExerciseItem({
    required this.doc,
    required this.type,
    this.letters,
    this.optionsItems,
  });

  // Factory từ DocumentSnapshot
  factory ExerciseItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    ExerciseType type;

    switch (data['questionType']) {
      case 'fill_in_blank':
        type = ExerciseType.fillInBlank;
        break;
      case 'multiple_choice':
        type = ExerciseType.multipleChoice;
        break;
      case 'letterTiles':
        type = ExerciseType.letterTiles;
        break;
      default:
        throw Exception("Unknown questionType: ${data['questionType']}");
    }

    return ExerciseItem(
      doc: doc,
      type: type,
      letters: data['letters'] != null ? List<String>.from(data['letters']) : null,
    );
  }

  // Copy để set optionsItems
  ExerciseItem copyWith({List<ExerciseItem>? optionsItems}) {
    return ExerciseItem(
      doc: doc,
      type: type,
      letters: letters,
      optionsItems: optionsItems ?? this.optionsItems,
    );
  }

  // Getters tiện dụng
  String get word => (doc.data() as Map<String, dynamic>)['word'] ?? '';
  String get meaning => (doc.data() as Map<String, dynamic>)['meaning'] ?? '';
  String get example => (doc.data() as Map<String, dynamic>)['example'] ?? '';
  String get exampleMeaning => (doc.data() as Map<String, dynamic>)['exampleMeaning'] ?? '';
  String get imageURL => (doc.data() as Map<String, dynamic>)['imageURL'] ?? '';
  String get phonetic => (doc.data() as Map<String, dynamic>)['phonetic'] ?? '';
}
