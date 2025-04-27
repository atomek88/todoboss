import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/voice_todo.dart';
import '../../todos/models/todo.dart';

/// Service for handling voice recording and speech-to-text functionality
class VoiceService {
  // Singleton instance
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Recording instance
  final _audioRecorder = AudioRecorder();

  // Speech to text instance
  final _speechToText = stt.SpeechToText();

  // Status flags
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isListening = false;

  // Current recording path
  String? _currentRecordingPath;

  // List of voice todos (in-memory storage for now)
  final List<VoiceTodo> _voiceTodos = [];

  /// Initialize the voice service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize speech recognition
      bool speechInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );

      _isInitialized = speechInitialized;
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
      return false;
    }
  }

  /// Check and request necessary permissions
  Future<bool> checkPermissions() async {
    // Check microphone permission
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        return false;
      }
    }

    // Check speech recognition permission on iOS
    if (Platform.isIOS) {
      final speechStatus = await Permission.speech.status;
      if (!speechStatus.isGranted) {
        final result = await Permission.speech.request();
        if (!result.isGranted) {
          return false;
        }
      }
    }

    return true;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    if (!await initialize()) return false;
    if (!await checkPermissions()) return false;
    if (_isRecording) return true;

    try {
      // Get the app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${appDir.path}/voice_todo_$timestamp.m4a';

      // Configure recording
      await _audioRecorder.start(
        RecordConfig(
          path: _currentRecordingPath!,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
      );

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and transcribe the audio
  Future<String?> stopRecordingAndTranscribe() async {
    if (!_isRecording || _currentRecordingPath == null) return null;

    try {
      // Stop recording
      await _audioRecorder.stop();
      _isRecording = false;

      // In a real app, you would use a proper audio-to-text service here
      // For this demo, we'll simulate speech recognition with a mock transcription
      // since direct transcription from a recorded file isn't straightforward

      // Simulate speech recognition
      _isListening = true;
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate processing time

      // Generate a mock transcription (in a real app, this would come from the speech recognition service)
      final mockTranscriptions = [
        "Buy groceries with milk, eggs, and bread",
        "Call dentist for appointment tomorrow high priority",
        "Finish Flutter project with voice recognition feature",
        "Pick up dry cleaning at 5pm",
        "Schedule team meeting for Friday medium priority",
      ];

      final transcription =
          mockTranscriptions[DateTime.now().second % mockTranscriptions.length];
      _isListening = false;

      // Save the voice todo to our in-memory list
      final voiceTodo = VoiceTodo.create(
        filePath: _currentRecordingPath!,
        transcription: transcription,
      );

      _voiceTodos.add(voiceTodo);

      return transcription;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Parse the transcription to extract todo information
  Todo? parseTodoFromTranscription(String transcription) {
    // Simple parsing logic - in a real app, you might want to use NLP
    // or a more sophisticated approach

    try {
      // Default values
      String title = transcription;
      String? description;
      int priority = 0;

      // Check for priority keywords
      if (transcription.toLowerCase().contains('urgent') ||
          transcription.toLowerCase().contains('high priority')) {
        priority = 2; // High priority
      } else if (transcription.toLowerCase().contains('medium priority')) {
        priority = 1; // Medium priority
      }

      // Check for title/description separation
      if (transcription.contains(':')) {
        final parts = transcription.split(':');
        title = parts[0].trim();
        description = parts.sublist(1).join(':').trim();
      } else if (transcription.contains(' with ')) {
        final parts = transcription.split(' with ');
        title = parts[0].trim();
        description = parts.sublist(1).join(' with ').trim();
      }

      // Create the todo
      return Todo.create(
        title: title,
        description: description,
        priority: priority,
      );
    } catch (e) {
      debugPrint('Error parsing todo from transcription: $e');
      return null;
    }
  }

  /// Create a todo from a voice recording
  Future<Todo?> createTodoFromVoice() async {
    try {
      if (!await startRecording()) {
        return null;
      }

      // Record for a few seconds
      await Future.delayed(const Duration(seconds: 3));

      final transcription = await stopRecordingAndTranscribe();
      if (transcription == null) {
        return null;
      }

      return parseTodoFromTranscription(transcription);
    } catch (e) {
      debugPrint('Error creating todo from voice: $e');
      return null;
    }
  }

  /// Get all voice todos
  List<VoiceTodo> getAllVoiceTodos() {
    return List.unmodifiable(_voiceTodos);
  }

  /// Mark a voice todo as processed
  void markVoiceTodoAsProcessed(String id, String todoId) {
    final index = _voiceTodos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final updated = _voiceTodos[index].copyWith(
        processed: true,
        todoId: todoId,
      );
      _voiceTodos[index] = updated;
    }
  }

  /// Delete a voice todo
  Future<void> deleteVoiceTodo(String id) async {
    final index = _voiceTodos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final voiceTodo = _voiceTodos[index];

      // Delete the audio file
      try {
        final file = File(voiceTodo.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting audio file: $e');
      }

      // Remove from the list
      _voiceTodos.removeAt(index);
    }
  }

  /// Clean up resources
  void dispose() {
    _audioRecorder.dispose();
    _speechToText.cancel();
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if currently listening
  bool get isListening => _isListening;
}
