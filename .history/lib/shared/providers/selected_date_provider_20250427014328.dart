import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:todoApp/feature/voice/providers/date_provider.dart';

/// Provider that stores the currently selected date for filtering todos
class SelectedDateNotifier extends StateNotifier<DateTime> {
  final Ref? _ref;
  
  SelectedDateNotifier(this._ref) : super(_normalizeDate(_getCurrentDate()));
  
  static DateTime _getCurrentDate() {
    // This is a fallback. Inside the class, we'll prefer the provider when ref is available
    return DateTime.now();
  }
  
  // Helper to normalize date to midnight for consistent comparison
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Set the selected date
  void setDate(DateTime date) {
    // Normalize the date to midnight to ensure consistent date comparison
    final normalizedDate = _normalizeDate(date);
    
    // Enhanced logging to help debug date synchronization issues
    debugPrint('🗓 [SelectedDateNotifier] setDate called with: ${date.toString()}');
    debugPrint('🗓 [SelectedDateNotifier] Normalized to: ${normalizedDate.toString()}');
    debugPrint('🗓 [SelectedDateNotifier] Current state: ${state.toString()}');
    
    // Only update if the date has actually changed
    if (normalizedDate != state) {
      debugPrint('🗓 [SelectedDateNotifier] Date changing: ${state.toString()} → ${normalizedDate.toString()}');
      debugPrint('🗓 [SelectedDateNotifier] Day of week changing: ${state.weekday} → ${normalizedDate.weekday}');
      state = normalizedDate;
    } else {
      debugPrint('🗓 [SelectedDateNotifier] Ignoring duplicate date update: ${date.toString()}');
    }
  }

  /// Move to the previous day
  void previousDay() {
    final newDate = state.subtract(const Duration(days: 1));
    debugPrint('🗓 [SelectedDateNotifier] Moving to previous day: ${state.toString()} → ${newDate.toString()}');
    state = newDate;
  }

  /// Move to the next day
  void nextDay() {
    final newDate = state.add(const Duration(days: 1));
    debugPrint('🗓 [SelectedDateNotifier] Moving to next day: ${state.toString()} → ${newDate.toString()}');
    state = newDate;
  }

  /// Check if the selected date is today
  bool get isToday {
    final today = _ref?.read(currentDateProvider) ?? DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return state == normalizedToday;
  }

  /// Format the selected date for display
  String get formattedDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[state.month - 1]} ${state.day}';
  }
}

/// Provider for the selected date
final selectedDateProvider =
    StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  // Pass the ref to access currentDateProvider inside the notifier
  final notifier = SelectedDateNotifier(ref);
  
  // Add a listener to debug selected date changes
  ref.listenSelf((previous, next) {
    if (previous != next) {
      debugPrint('🗓 [selectedDateProvider] Date changed: $previous → $next');
      // Safely access weekday with null checks
      final previousWeekday = previous?.weekday ?? 0;
      final nextWeekday = next.weekday;
      debugPrint('🗓 [selectedDateProvider] Day of week changed: $previousWeekday → $nextWeekday');
    }
  });
  
  return notifier;
});
