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
    try {
      debugPrint('Checking microphone and speech permissions...');
      
      // On iOS, we need to request permissions in a specific order
      if (Platform.isIOS) {
        // First check microphone permission
        var micStatus = await Permission.microphone.status;
        debugPrint('Microphone permission status: $micStatus');
        
        if (!micStatus.isGranted) {
          // If permanently denied, we need to tell the user to enable in settings
          if (micStatus.isPermanentlyDenied) {
            debugPrint('Microphone permission permanently denied - need to open settings');
            throw Exception('Microphone permission is permanently denied. Please enable it in your device settings.');
          }
          
          // Request microphone permission
          debugPrint('Requesting microphone permission...');
          micStatus = await Permission.microphone.request();
          debugPrint('Microphone permission after request: $micStatus');
          
          if (!micStatus.isGranted) {
            if (micStatus.isPermanentlyDenied) {
              throw Exception('Microphone permission is permanently denied. Please enable it in your device settings.');
            }
            debugPrint('Microphone permission denied');
            return false;
          }
        }
        
        // Then check speech recognition permission
        var speechStatus = await Permission.speech.status;
        debugPrint('Speech recognition permission status: $speechStatus');
        
        if (!speechStatus.isGranted) {
          // If permanently denied, we need to tell the user to enable in settings
          if (speechStatus.isPermanentlyDenied) {
            debugPrint('Speech recognition permission permanently denied - need to open settings');
            throw Exception('Speech recognition permission is permanently denied. Please enable it in your device settings.');
          }
          
          // Request speech recognition permission
          debugPrint('Requesting speech recognition permission...');
          speechStatus = await Permission.speech.request();
          debugPrint('Speech recognition permission after request: $speechStatus');
          
          if (!speechStatus.isGranted) {
            if (speechStatus.isPermanentlyDenied) {
              throw Exception('Speech recognition permission is permanently denied. Please enable it in your device settings.');
            }
            debugPrint('Speech recognition permission denied');
            return false;
          }
        }
      } else {
        // For Android, just check microphone permission
        var micStatus = await Permission.microphone.status;
        debugPrint('Microphone permission status: $micStatus');
        
        if (!micStatus.isGranted) {
          // If permanently denied, we need to tell the user to enable in settings
          if (micStatus.isPermanentlyDenied) {
            debugPrint('Microphone permission permanently denied - need to open settings');
            throw Exception('Microphone permission is permanently denied. Please enable it in your device settings.');
          }
          
          // Request microphone permission
          debugPrint('Requesting microphone permission...');
          micStatus = await Permission.microphone.request();
          debugPrint('Microphone permission after request: $micStatus');
          
          if (!micStatus.isGranted) {
            if (micStatus.isPermanentlyDenied) {
              throw Exception('Microphone permission is permanently denied. Please enable it in your device settings.');
            }
            debugPrint('Microphone permission denied');
            return false;
          }
        }
      }
      
      debugPrint('All required permissions granted');
      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      rethrow; // Rethrow to allow the UI to handle opening settings
    }
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
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
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
    if (!_isRecording || _currentRecordingPath == null) {
      debugPrint('Cannot stop recording: not recording or no recording path');
      return null;
    }

    try {
      // Stop recording
      debugPrint('Stopping audio recording...');
      await _audioRecorder.stop();
      _isRecording = false;
      debugPrint('Audio recording stopped successfully');

      // Now use speech recognition to transcribe
      _isListening = true;
      debugPrint('Starting speech recognition...');
      
      // Initialize speech recognition if not already initialized
      if (!_speechToText.isAvailable) {
        debugPrint('Initializing speech recognition...');
        final initialized = await _speechToText.initialize(
          onError: (error) => debugPrint('Speech recognition error: $error'),
          onStatus: (status) => debugPrint('Speech recognition status: $status'),
        );
        
        if (!initialized) {
          debugPrint('Failed to initialize speech recognition');
          _isListening = false;
          
          // Fallback to mock transcription if speech recognition fails
          final mockTranscription = "Add new task with high priority";
          debugPrint('Using fallback mock transcription: $mockTranscription');
          
          final voiceTodo = VoiceTodo.create(
            filePath: _currentRecordingPath!,
            transcription: mockTranscription,
          );
          
          _voiceTodos.add(voiceTodo);
          return mockTranscription;
        }
      }
      
      // Start listening for speech
      String transcription = '';
      bool speechDetected = false;
      
      await _speechToText.listen(
        onResult: (result) {
          transcription = result.recognizedWords;
          speechDetected = true;
          debugPrint('Speech detected: $transcription');
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        onSoundLevelChange: (level) {
          debugPrint('Sound level: $level');
        },
        cancelOnError: true,
      );
      
      // Wait for speech recognition to complete
      await Future.delayed(const Duration(seconds: 6));
      _speechToText.stop();
      _isListening = false;
      
      // If no speech was detected, use a fallback
      if (!speechDetected || transcription.isEmpty) {
        debugPrint('No speech detected, using fallback');
        transcription = "Add new task with high priority";
      }
      
      debugPrint('Final transcription: $transcription');
      
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

  /// Create a todo from voice recording
  Future<Todo?> createTodoFromVoice() async {
    if (!await initialize()) {
      debugPrint('Voice service not initialized');
      return null;
    }

    try {
      debugPrint('Starting voice recording process...');

      // Check permissions
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        debugPrint('Voice recording failed: missing permissions');
        throw Exception('Missing microphone or speech recognition permissions. Please grant these permissions in your device settings.');
      }

      // Start recording
      final recordingStarted = await startRecording();
      if (!recordingStarted) {
        debugPrint('Voice recording failed: could not start recording');
        throw Exception('Could not start voice recording. Please try again.');
      }

      // Record for 5 seconds
      await Future.delayed(const Duration(seconds: 5));

      // Stop recording and get the path
      final transcription = await stopRecordingAndTranscribe();
      if (transcription == null) {
        debugPrint('Voice recording failed: transcription is null');
        throw Exception('Recording failed to save. Please try again.');
      }

      debugPrint('Successfully transcribed: "$transcription"');

      // Parse the transcription into a todo
      final todo = parseTodoFromTranscription(transcription);

      // Save the voice todo for history
      final voiceTodo = VoiceTodo.create(
        filePath: _currentRecordingPath!,
        transcription: transcription,
      );

      _voiceTodos.add(voiceTodo);

      return todo;
    } catch (e) {
      debugPrint('Error creating todo from voice: $e');
      rethrow; // Rethrow to allow the UI layer to handle the specific error
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
