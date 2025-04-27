import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'voice_todo.freezed.dart';
part 'voice_todo.g.dart';

/// Voice Todo model for storing voice recordings and their transcriptions
@freezed
class VoiceTodo with _$VoiceTodo {
  // Factory constructor for freezed
  @JsonSerializable(explicitToJson: true)
  const factory VoiceTodo({
    required String id,
    required String filePath,
    required String transcription,
    required DateTime createdAt,
    @Default(false) bool processed,
    String? todoId, // ID of the Todo created from this voice recording
  }) = _VoiceTodo;

  // Factory for creating a new VoiceTodo with auto-generated ID
  factory VoiceTodo.create({
    required String filePath,
    required String transcription,
    bool processed = false,
    String? todoId,
    DateTime? createdAt,
  }) {
    return VoiceTodo(
      id: const Uuid().v4(),
      filePath: filePath,
      transcription: transcription,
      processed: processed,
      todoId: todoId,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // From JSON factory
  factory VoiceTodo.fromJson(Map<String, dynamic> json) => _$VoiceTodoFromJson(json);
}
