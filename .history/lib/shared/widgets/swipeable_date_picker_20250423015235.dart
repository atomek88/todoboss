import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_date_provider.dart';

/// A swipeable date picker widget that can be used in app bars
/// Allows users to swipe left/right to change the selected date
class SwipeableDatePicker extends ConsumerWidget {
  /// Optional suffix text to display after the date
  final String? suffixText;

  /// Optional style for the date text
  final TextStyle? dateTextStyle;

  /// Optional style for the suffix text
  final TextStyle? suffixTextStyle;

  /// Animation duration for the date change
  final Duration animationDuration;

  const SwipeableDatePicker({
    super.key,
    this.suffixText,
    this.dateTextStyle,
    this.suffixTextStyle,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the notifier to get formatted date and isToday status
    final dateNotifier = ref.watch(selectedDateProvider.notifier);
    final formattedDate = dateNotifier.formattedDate;
    final isToday = dateNotifier.isToday;

    // Watch the actual date value for UI updates
    final _ = ref.watch(selectedDateProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detect swipe direction
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            // Swiped right - go to previous day
            print('SwipeableDatePicker: Swiped RIGHT - going to PREVIOUS day');
            ref.read(selectedDateProvider.notifier).previousDay();
          } else if (details.primaryVelocity! < 0) {
            // Swiped left - go to next day
            print('SwipeableDatePicker: Swiped LEFT - going to NEXT day');
            ref.read(selectedDateProvider.notifier).nextDay();
          }
        }
      },
      // Add horizontal drag start to improve swipe detection
      onHorizontalDragStart: (_) {
        print('SwipeableDatePicker: Horizontal drag started');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left arrow indicator
            Icon(
              Icons.chevron_left,
              size: 16,
              color: Colors.grey.shade600,
            ),

            // Date display with animation
            Flexible(
              child: AnimatedSwitcher(
                duration: animationDuration,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.5, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  formattedDate,
                  key: ValueKey<String>(formattedDate),
                  style: dateTextStyle ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue : null,
                      ),
                ),
              ),
            ),

            // Optional suffix text
            if (suffixText != null) ...[
              const SizedBox(width: 8),
              Text(
                suffixText!,
                style: suffixTextStyle ?? const TextStyle(),
              ),
            ],

            // Right arrow indicator
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
