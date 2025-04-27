import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Provider that stores the currently selected date for filtering todos
class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier() : super(_normalizeDate(DateTime.now()));
  
  // Helper to normalize date to midnight for consistent comparison
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Set the selected date
  void setDate(DateTime date) {
    // Normalize the date to midnight to ensure consistent date comparison
    final normalizedDate = _normalizeDate(date);
    
    // Only update if the date has actually changed
    if (normalizedDate != state) {
      debugPrint('🗓 [SelectedDateNotifier] Date changing: ${state.toString()} → ${normalizedDate.toString()}');
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
    final today = _normalizeDate(DateTime.now());
    return state.year == today.year && 
           state.month == today.month && 
           state.day == today.day;
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
final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  return SelectedDateNotifier();
});
