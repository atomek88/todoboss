import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/feature/todos/views/past_date_page.dart';

/// A simple date picker widget with left and right arrow buttons for navigation
class SwipeableDatePicker extends ConsumerStatefulWidget {
  /// Text style for the main date display
  final TextStyle? mainDateTextStyle;

  /// Whether to provide haptic feedback on date change
  final bool enableHapticFeedback;

  /// Height of the date picker container
  final double height;

  /// Maximum days forward from current date that can be selected
  final int maxDaysForward;

  /// For backward compatibility with existing code
  final TextStyle? dateTextStyle;

  const SwipeableDatePicker({
    super.key,
    this.mainDateTextStyle,
    this.enableHapticFeedback = true,
    this.height = 100,
    this.maxDaysForward = 7, // Limit to one week forward by default
    this.dateTextStyle, // For backward compatibility
  });

  @override
  ConsumerState<SwipeableDatePicker> createState() =>
      _SwipeableDatePickerState();
}

class _SwipeableDatePickerState extends ConsumerState<SwipeableDatePicker> {
  // The last selected date for tracking changes
  DateTime? _lastSelectedDate;

  @override
  void initState() {
    super.initState();

    // Initialize with the current date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Make sure current date provider is refreshed
      refreshCurrentDate(ref);

      // Get selected date and current date
      final selectedDate = ref.read(selectedDateProvider);
      final currentDate = ref.read(currentDateProvider);

      // Use the date provider's normalizeDate function for consistency
      final normalizedSelectedDate = normalizeDate(selectedDate);
      final normalizedCurrentDate = normalizeDate(currentDate);

      // Log both dates for debugging
      debugPrint(
          '📅 [SwipeableDatePicker] Selected date: ${normalizedSelectedDate.toString()}');
      debugPrint(
          '📅 [SwipeableDatePicker] Current date: ${normalizedCurrentDate.toString()}');

      // Save the selected date as our last selected date
      _lastSelectedDate = normalizedSelectedDate;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Handle date changes with haptic feedback and validation
  void _changeDate(int dayOffset) {
    // Get current date and calculate new date
    final currentDate = ref.read(selectedDateProvider);
    final normalizedCurrentDay = normalizeDate(DateTime.now());

    // Ensure we're adding days to a normalized date to avoid time inconsistencies
    final normalizedDate = normalizeDate(currentDate);
    final newDate = normalizedDate.add(Duration(days: dayOffset));

    // Check if the new date is within allowed range
    if (!_isDateWithinAllowedRange(newDate)) {
      // If not within range, provide feedback and return
      if (widget.enableHapticFeedback) {
        HapticFeedback
            .heavyImpact(); // Stronger feedback to indicate limit reached
      }
      debugPrint(
          '📅 [SwipeableDatePicker] Date change rejected - outside allowed range');
      return;
    }

    // Provide haptic feedback if enabled
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Check if we're changing to a past date (which would trigger PastDatePage navigation)
    final isPastDate = newDate.isBefore(normalizedCurrentDay);
    // Check if we're changing to yesterday (which would trigger TodosHomePage navigation)
    final isYesterday = newDate.isAtSameMomentAs(
        normalizedCurrentDay.subtract(const Duration(days: 1)));
    debugPrint(
        '📅 [SwipeableDatePicker] Date changed from $normalizedDate to $newDate (isPastDate: $isPastDate)');

    // Update the provider with the new date
    ref.read(selectedDateProvider.notifier).setDate(newDate);
    _lastSelectedDate = newDate;

    // Reset any related providers that need to be updated with the new date
    ref.read(dailyTodoProvider.notifier).dateChanged(newDate);
  }

  // Format a date for display in full format (e.g., "Monday, April 24, 2025")
  String _formatDateFull(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  // Check if date is within allowed range
  bool _isDateWithinAllowedRange(DateTime date) {
    final today = ref.read(currentDateProvider);

    // Use normalizeDate utility for consistent date handling
    final normalizedDate = normalizeDate(date);

    // Calculate difference in days
    final difference = normalizedDate.difference(today).inDays;

    // Allow any date from the past, but limit future dates
    return difference <= widget.maxDaysForward;
  }

  // Check if the given date is today
  bool _isToday(DateTime date) {
    final today = ref.read(currentDateProvider);
    final normalizedDate = normalizeDate(date);
    final normalizedToday = normalizeDate(today);

    // Compare year, month, and day
    return normalizedDate.year == normalizedToday.year &&
        normalizedDate.month == normalizedToday.month &&
        normalizedDate.day == normalizedToday.day;
  }

  @override
  Widget build(BuildContext context) {
    // Watch selected date to rebuild when it changes
    final selectedDate = ref.watch(selectedDateProvider);
    final currentDate = ref.watch(currentDateProvider);

    // Ensure we have a normalized date for consistent display
    final normalizedDate = normalizeDate(selectedDate);

    // Format date for display
    final formattedDate = _formatDateFull(normalizedDate);

    // Check if this is today's date
    final isToday = _isToday(normalizedDate);

    // Debug information for date synchronization
    debugPrint('📅 [SwipeableDatePicker] Building with date: $normalizedDate');
    if (_lastSelectedDate != null &&
        (_lastSelectedDate!.day != normalizedDate.day ||
            _lastSelectedDate!.month != normalizedDate.month ||
            _lastSelectedDate!.year != normalizedDate.year)) {
      debugPrint(
          '📅 [SwipeableDatePicker] Date changed from $_lastSelectedDate to $normalizedDate');
      _lastSelectedDate = normalizedDate;
    }

    // Calculate if we should show past date page based on comparison with current date
    final isPastDate = normalizedDate.isBefore(normalizeDate(currentDate));
    final isYesterday = isYesterday(normalizeDate(currentDate));
    final isFutureDate = normalizedDate.isAfter(normalizeDate(currentDate));

    return Container(
      height: widget.height,
      child: Row(
        children: [
          // Left arrow button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _changeDate(-1),
            tooltip: 'Previous day',
          ),

          // Central date display
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Only navigate to PastDate for past dates except yesterday
                if (isPastDate && isYesterday) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PastDatePage(date: normalizedDate),
                    ),
                  );
                }
              },
              child: Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Date text
                    Text(
                      formattedDate,
                      style: widget.mainDateTextStyle ??
                          widget.dateTextStyle ??
                          TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : isPastDate && !isYesterday
                                    ? Colors.grey.shade600
                                    : isFutureDate
                                        ? Colors.blue.shade800
                                        : null,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    // Optional indicator for past, present, future
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : isPastDate && !isYesterday
                                ? Colors.grey.shade400
                                : Colors.blue.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right arrow button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => _changeDate(1),
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}
