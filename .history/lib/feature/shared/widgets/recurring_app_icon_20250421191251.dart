import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track the current state of the RecurringAppIcon
final recurringIconStateProvider = StateProvider<int>((ref) => 0);

/// A custom app icon widget that cycles through three states when pressed
class RecurringAppIcon extends ConsumerWidget {
  /// Size of the icon
  final double size;

  /// Optional callback when icon is pressed
  final VoidCallback? onStateChanged;

  /// List of asset paths for the three icon states
  static const List<String> iconAssets = [
    'assets/icons/icons8-reset-80.png',
    'assets/icons/rock-hill.png',
    'assets/icons/slinky.png',
  ];

  const RecurringAppIcon({
    Key? key,
    this.size = 60.0,
    this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current state from the provider
    final currentState = ref.watch(recurringIconStateProvider);

    return GestureDetector(
      onTap: () {
        // Cycle to the next state (0 -> 1 -> 2 -> 0)
        final nextState = (currentState + 1) % 3;
        ref.read(recurringIconStateProvider.notifier).state = nextState;

        // Call the callback if provided
        if (onStateChanged != null) {
          onStateChanged!();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            iconAssets[currentState],
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to a placeholder if asset loading fails
              return Container(
                width: size,
                height: size,
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: size * 0.5,
                  color: Colors.grey.shade700,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
