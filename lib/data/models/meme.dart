import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';

part 'meme.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Meme extends Equatable {
  final String id;
  final List<TextWithPosition> texts;
  /// ImagePicker -memePath- для сохранения - модель уровня дата слоя
  final String? memePath;
  Meme({
    required this.id,
    required this.texts,
    this.memePath, /// ImagePicker
  });

  factory Meme.fromJson(final Map<String, dynamic> json) =>
      _$MemeFromJson(json);

  Map<String, dynamic> toJson() => _$MemeToJson(this);

  @override
  List<Object?> get props => [id, texts, memePath]; /// ImagePicker
}
