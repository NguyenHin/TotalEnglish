import 'package:cloud_firestore/cloud_firestore.dart';
import 'vocabulary_item.dart';

enum ExerciseType { fillInBlank, multipleChoice, letterTiles }

class ExerciseItem {
  final DocumentSnapshot doc; // document trong subcollection activities
  final ExerciseType type;
  final VocabularyItem vocab; // tham chiếu từ vựng cha
  final List<ExerciseItem>? optionsItems; // chỉ dùng cho multiple-choice

  ExerciseItem({
    required this.doc,
    required this.type,
    required this.vocab,
    this.optionsItems,
  });

  /// ✅ Xác định ExerciseType bằng doc.id
  factory ExerciseItem.fromDoc(
    DocumentSnapshot doc,
    VocabularyItem vocab,
  ) {
    late final ExerciseType type;

    switch (doc.id) {
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
        throw Exception('Unknown exercise type: ${doc.id}');
    }

    return ExerciseItem(
      doc: doc,
      type: type,
      vocab: vocab,
    );
  }

  
  ExerciseItem copyWith({
    List<ExerciseItem>? optionsItems,
  }) {
    return ExerciseItem(
      doc: doc,
      type: type,
      vocab: vocab,
      optionsItems: optionsItems ?? this.optionsItems,
    );
  }

  // ===== Getters tiện dụng =====
  String get word => vocab.word;
  String get meaning => vocab.meaning;
  String get example => vocab.example;
  String get exampleMeaning => vocab.exampleMeaning;
  String get imageURL => vocab.imageURL;
  String get phonetic => vocab.phonetic;
}
