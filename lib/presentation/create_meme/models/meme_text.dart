import 'package:uuid/uuid.dart';

class MemeText {
  final String id;
  final String text;

  MemeText({required this.id, required this.text});

  factory MemeText.create() {
    return MemeText(id: Uuid().v4(), text: '');
  }

  @override

  /// добавляем hashCode -> cd+N
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MemeText &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              text == other.text;

  @override
  int get hashCode => id.hashCode ^ text.hashCode;

  @override

  /// добавляем toString() -> cd+N
  String toString() {
    return 'MemeText{id: $id, text: $text}';
  }
}
