import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { multipleChoice, fillInBlank, letterTiles }

class VocabularyItem {
  final QueryDocumentSnapshot doc;
  final ActivityType activityType;
  final List<String> options; // chỉ dùng cho multiple-choice

  VocabularyItem({
    required this.doc,
    required this.activityType,
    this.options = const [],
  });
}
