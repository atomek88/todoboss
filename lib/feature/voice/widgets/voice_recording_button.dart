import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/voice_provider.dart';
import '../../todos/models/todo.dart';

/// A floating action button for voice recording to create todos
class VoiceRecordingButton extends ConsumerWidget {
  /// Callback for when a todo is created
  final Function(Todo, String?)? onTodoCreated;

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
          heroTag: heroTag,
          onPressed: isRecording ? null : () => _startVoiceRecording(context, ref),
          backgroundColor: isRecording ? Colors.red : Theme.of(context).primaryColor,
          child: Icon(
            isRecording ? Icons.mic : Icons.mic_none,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Show a fallback dialog when ScaffoldMessenger is not available
  void _showFallbackDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isError,
    VoidCallback? onDismiss,
    bool showSettingsButton = false,
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
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade50 : Colors.blue.shade50,
        actions: [
          if (showSettingsButton)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('OPEN SETTINGS'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDismiss != null) {
                onDismiss();
              }
            },
            child: Text(isError ? 'CLOSE' : 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show an error message with appropriate actions
  void _showErrorMessage(BuildContext context, WidgetRef ref, String? errorMessage, {bool isPermissionError = false}) {
    final message = errorMessage?.replaceAll('ERROR: ', '') ?? 
        'Could not detect speech or create todo. Please try again.';
        
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voice Recognition Failed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          action: isPermissionError
              ? SnackBarAction(
                  label: 'OPEN SETTINGS',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                )
              : SnackBarAction(
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
        message: message,
        isError: true,
        showSettingsButton: isPermissionError,
      );
    }
  }
  
  /// Start voice recording and handle the result
  Future<void> _startVoiceRecording(BuildContext context, WidgetRef ref) async {
    // Prevent multiple recordings
    if (ref.read(voiceRecordingStateProvider)) {
      return;
    }

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    debugPrint('Calling createTodoFromVoice...');
    try {
      // Show listening snackbar
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mic, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Listening...'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
        } catch (e) {
          debugPrint('ScaffoldMessenger not available: $e');
        }
      }

      final todo = await createTodoFromVoice(ref);
      final transcription = ref.read(voiceTranscriptionProvider);

      debugPrint('Transcription result: $transcription');

      if (todo != null) {
        // Provide success haptic feedback
        HapticFeedback.lightImpact();

        // Show success message
        if (context.mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Todo Created',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${todo.title}\n${todo.description ?? ''}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (transcription != null && !transcription.startsWith('ERROR:'))
                            Text(
                              'Voice: "$transcription"',
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade800,
              ),
            );
          } catch (e) {
            // ScaffoldMessenger not found, show a dialog instead
            debugPrint('ScaffoldMessenger not available: $e');
            _showFallbackDialog(
              context: context,
              title: 'Todo Created',
              message:
                  '${todo.title}\n${todo.description ?? ''}\n\nVoice: "$transcription"',
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
          _showErrorMessage(context, ref, transcription);
        }
      }
    } catch (e) {
      // Provide error haptic feedback
      HapticFeedback.heavyImpact();
      debugPrint('Exception creating todo from voice: $e');
      
      // Get the error message
      final String errorMessage = e.toString().contains('Exception:') 
          ? e.toString().replaceAll('Exception: ', '') 
          : 'Failed to create todo from voice. Please try again.';
      
      // Check if this is a permissions error
      final bool isPermissionError = errorMessage.toLowerCase().contains('permission');
      
      // Show error message
      if (context.mounted) {
        _showErrorMessage(context, ref, errorMessage, isPermissionError: isPermissionError);
      }
    }
  }
}
