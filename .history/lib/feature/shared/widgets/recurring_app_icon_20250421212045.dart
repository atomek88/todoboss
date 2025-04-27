import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type definition for state providers that can be either regular or auto-dispose
typedef BoolStateProviderBase = ProviderListenable<bool>;

/// A custom app icon widget that toggles between activated and deactivated states
class SquareAppIcon extends ConsumerWidget {
  /// Size of the icon
  final double size;

  /// Asset path for the icon
  final String iconAsset;

  /// Provider to track activation state
  final BoolStateProviderBase activationProvider;

  /// Optional callback when icon is pressed
  final VoidCallback? onStateChanged;

  const SquareAppIcon({
    Key? key,
    required this.iconAsset,
    required this.activationProvider,
    this.size = 60.0,
    this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current activation state from the provider
    final isActivated = ref.watch(activationProvider);

    return GestureDetector(
      onTap: () {
        // Toggle activation state
        if (activationProvider is StateProvider<bool>) {
          ref.read((activationProvider as StateProvider<bool>).notifier).state =
              !isActivated;
        } else if (activationProvider is AutoDisposeStateProvider<bool>) {
          ref
              .read((activationProvider as AutoDisposeStateProvider<bool>)
                  .notifier)
              .state = !isActivated;
        }

        // Call the callback if provided
        if (onStateChanged != null) {
          onStateChanged!();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Base icon image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                iconAsset,
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
            // Colored overlay based on activation state
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: size,
                height: size,
                color: isActivated
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.2),
              ),
            ),
            // Activation indicator
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActivated ? Colors.green : Colors.red,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
