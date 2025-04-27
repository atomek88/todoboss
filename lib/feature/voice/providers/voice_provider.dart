import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/voice_todo.dart';
import '../../todos/models/todo.dart';
import 'voice_service.dart';

part 'voice_provider.g.dart';

/// Provider for the VoiceService
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the recording state
@riverpod
class VoiceRecordingState extends _$VoiceRecordingState {
  @override
  bool build() => false;

  void setRecording(bool isRecording) {
    state = isRecording;
  }
}

/// Provider for the transcription
@riverpod
class VoiceTranscription extends _$VoiceTranscription {
  @override
  String? build() => null;

  void setTranscription(String? transcription) {
    state = transcription;
  }
}

/// Provider for all voice todos
@riverpod
class VoiceTodos extends _$VoiceTodos {
  @override
  List<VoiceTodo> build() {
    final voiceService = ref.watch(voiceServiceProvider);
    return voiceService.getAllVoiceTodos();
  }

  void refresh() {
    state = ref.read(voiceServiceProvider).getAllVoiceTodos();
  }

  void markAsProcessed(String id, String todoId) {
    final voiceService = ref.read(voiceServiceProvider);
    voiceService.markVoiceTodoAsProcessed(id, todoId);
    refresh();
  }

  Future<void> delete(String id) async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.deleteVoiceTodo(id);
    refresh();
  }
}

/// Function to create a todo from voice
Future<Todo?> createTodoFromVoice(WidgetRef ref) async {
  final voiceService = ref.read(voiceServiceProvider);
  String? errorMessage;
  
  // Set recording state
  ref.read(voiceRecordingStateProvider.notifier).setRecording(true);
  
  try {
    debugPrint('Starting voice recording process...');
    
    // Create todo directly from voice service
    final todo = await voiceService.createTodoFromVoice();
    
    // Update recording state
    ref.read(voiceRecordingStateProvider.notifier).setRecording(false);
    
    if (todo == null) {
      debugPrint('No todo was created from voice');
      return null;
    }
    
    // Get the latest transcription
    final voiceTodos = ref.read(voiceTodosProvider);
    if (voiceTodos.isNotEmpty) {
      final latestVoiceTodo = voiceTodos.last;
      ref.read(voiceTranscriptionProvider.notifier).setTranscription(latestVoiceTodo.transcription);
      
      // Mark the voice todo as processed with the todo ID
      ref.read(voiceTodosProvider.notifier).markAsProcessed(latestVoiceTodo.id, todo.id);
    }
    
    // Refresh the voice todos list
    ref.read(voiceTodosProvider.notifier).refresh();
    
    return todo;
  } catch (e) {
    debugPrint('Error creating todo from voice: $e');
    
    // Extract error message
    if (e is Exception) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } else {
      errorMessage = 'Failed to create todo from voice. Please try again.';
    }
    
    // Set the error message as transcription for UI feedback
    ref.read(voiceTranscriptionProvider.notifier).setTranscription('ERROR: $errorMessage');
    
    // Update recording state
    ref.read(voiceRecordingStateProvider.notifier).setRecording(false);
    return null;
  }
}
