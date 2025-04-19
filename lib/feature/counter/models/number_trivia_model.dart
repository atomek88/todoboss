import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_trivia_model.freezed.dart';
part 'number_trivia_model.g.dart';

@freezed
class NumberTriviaModel with _$NumberTriviaModel {
  factory NumberTriviaModel({
    required int number,
    required String text,
    required String type,
    required bool found,
  }) = _NumberTriviaModel;

  factory NumberTriviaModel.fromJson(Map<String, dynamic> json) =>
      _$NumberTriviaModelFromJson(json);
}
