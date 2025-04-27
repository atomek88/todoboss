import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voice_provider.dart';
import '../../todos/models/todo.dart';

/// A floating action button for voice recording to create todos
class VoiceRecordingButton extends ConsumerWidget {
  /// Callback for when a todo is created
  final Function(Todo, String)? onTodoCreated;
  
  /// Optional hero tag to avoid conflicts with multiple FABs
  final Object? heroTag;

  const VoiceRecordingButton({
    Key? key,
    this.onTodoCreated,
    this.heroTag = 'voiceRecordingButton',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the recording state
    final isRecording = ref.watch(voiceRecordingStateProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated ripple effect when recording
        if (isRecording)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        
        // Main button
        FloatingActionButton(
          onPressed: isRecording ? null : () => _startVoiceRecording(context, ref),
          backgroundColor: isRecording ? Colors.red : Colors.blue,
          heroTag: heroTag,
          elevation: isRecording ? 8 : 6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isRecording
                ? const Icon(
                    Icons.mic,
                    key: ValueKey('recording'),
                    color: Colors.white,
                    size: 28,
                  )
                : const Icon(
                    Icons.mic_none,
                    key: ValueKey('not_recording'),
                    color: Colors.white,
                    size: 26,
                  ),
          ),
        ),
      ],
    );
  }

  /// Start voice recording and create a todo
  Future<void> _startVoiceRecording(BuildContext context, WidgetRef ref) async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show a snackbar to indicate recording is starting
    if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listening...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Speak clearly to create a todo',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Visual indicator that mic is active
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.blue.shade700,
          ),
        );
      } catch (e) {
        // ScaffoldMessenger not found, show a dialog instead
        debugPrint('ScaffoldMessenger not available: $e');
        _showFallbackDialog(
          context: context,
          title: 'Listening...',
          message: 'Speak clearly to create a todo',
          isError: false,
        );
      }
    }
    
    // Log that we're starting voice recording
    debugPrint('Starting voice recording process...');

    // Create todo from voice
    debugPrint('Calling createTodoFromVoice...');
    final todo = await createTodoFromVoice(ref);

    // Get the transcription
    final transcription = ref.read(voiceTranscriptionProvider);
    debugPrint('Transcription result: $transcription');

    if (todo != null && transcription != null) {
      // Provide success haptic feedback
      HapticFeedback.lightImpact();
      debugPrint('Todo created successfully: ${todo.title}');
      
      // Show success message
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Todo created: ${todo.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (todo.description != null && todo.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        todo.description!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      'Voice: "$transcription"',
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.green.shade800,
            ),
          );
        } catch (e) {
          // ScaffoldMessenger not found, show a dialog instead
          debugPrint('ScaffoldMessenger not available: $e');
          _showFallbackDialog(
            context: context,
            title: 'Todo Created',
            message: '${todo.title}\n${todo.description ?? ''}\n\nVoice: "$transcription"',
            isError: false,
            onDismiss: () {
              if (onTodoCreated != null) {
                onTodoCreated!(todo, transcription);
              }
            },
          );
        }
      }
    } else {
      // Provide error haptic feedback
      HapticFeedback.heavyImpact();
      debugPrint('Failed to create todo from voice');
      
      // Show error message
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Recognition Failed',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Could not detect speech or create todo',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'TRY AGAIN',
                textColor: Colors.white,
                onPressed: () => _startVoiceRecording(context, ref),
              ),
            ),
          );
        } catch (e) {
          // ScaffoldMessenger not found, show a dialog instead
          debugPrint('ScaffoldMessenger not available: $e');
          _showFallbackDialog(
            context: context,
            title: 'Voice Recognition Failed',
            message: 'Could not detect speech or create todo. Please try again.',
            isError: true,
          );
        }
      }
    }
  }
  
  /// Show a fallback dialog when ScaffoldMessenger is not available
  void _showFallbackDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isError,
    VoidCallback? onDismiss,
  }) {
    debugPrint('Showing fallback dialog: $title - $message');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red.shade700 : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade50 : Colors.blue.shade50,
        titleTextStyle: TextStyle(
          color: isError ? Colors.red.shade700 : Colors.blue.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          color: isError ? Colors.red.shade900 : Colors.black87,
          fontSize: 16,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onDismiss != null) {
                onDismiss();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: isError ? Colors.red.shade700 : Colors.blue.shade700,
            ),
            child: const Text('OK'),
          ),
          if (isError)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Give a slight delay before retrying
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) {
                    // Just close the dialog - the user can tap the button again
                    debugPrint('Dialog closed, user should tap voice button again');
                  }
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
              child: const Text('TRY AGAIN'),
            ),
        ],
      ),
    );
  }
}
