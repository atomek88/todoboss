// Central date management system for the Todo app.
// This file serves as the single source of truth for all date-related operations.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
// Ensure we have access to both Ref and WidgetRef types
import 'package:flutter/widgets.dart' show BuildContext;

// ============================================================================
// CORE DATE UTILITY FUNCTIONS
// ============================================================================

/// Normalizes a DateTime to midnight (00:00:00.000) for consistent date comparison
/// Use this function for all date normalization across the app
DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Formats a date in a consistent way across the app
String formatDate(DateTime date, {String format = 'EEE, MMM d, y'}) {
  return DateFormat(format).format(date);
}

/// Checks if two dates represent the same day (ignoring time)
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && 
         date1.month == date2.month && 
         date1.day == date2.day;
}

/// Gets the day of week (1-7, with 1 = Monday, 7 = Sunday)
int getDayOfWeek(DateTime date) {
  return date.weekday;
}

/// Checks if a date is yesterday relative to a reference date
/// If no reference date is provided, uses the current date
bool isYesterday(DateTime date, [DateTime? referenceDate]) {
  final normalizedDate = normalizeDate(date);
  final normalizedReference = normalizeDate(referenceDate ?? DateTime.now());
  return normalizedDate.isAtSameMomentAs(
      normalizedReference.subtract(const Duration(days: 1)));
}

/// Checks if a date is before today (not including yesterday)
/// If includeYesterday is true, yesterday will also be considered a past date
bool isPastDate(DateTime date, {bool includeYesterday = false}) {
  final normalizedDate = normalizeDate(date);
  final normalizedToday = normalizeDate(DateTime.now());
  
  if (includeYesterday) {
    return normalizedDate.isBefore(normalizedToday);
  } else {
    // Check if it's before today and not yesterday
    return normalizedDate.isBefore(normalizedToday) && 
        !isYesterday(date);
  }
}

// ============================================================================
// CORE DATE PROVIDERS
// ============================================================================

/// Provider for the current normalized date (today)
/// This is a StateProvider so it can be refreshed when needed
final currentDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return normalizeDate(now);
});

/// Selected date for filtering todos and other date-specific operations
final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  // Use today as the initial selected date
  return SelectedDateNotifier(ref, ref.watch(currentDateProvider));
});

/// Derived provider that indicates if the selected date is today
final isSelectedDateTodayProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final currentDate = ref.watch(currentDateProvider);
  return isSameDay(selectedDate, currentDate);
});

/// Derived provider that indicates if the selected date is in the past
final isSelectedDatePastProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final currentDate = ref.watch(currentDateProvider);
  return selectedDate.isBefore(currentDate);
});

/// Derived provider that provides the formatted selected date
final formattedSelectedDateProvider = Provider<String>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return formatDate(selectedDate);
});

// ============================================================================
// DATE SERVICE AND NOTIFIERS
// ============================================================================

/// Notifier for managing the selected date
class SelectedDateNotifier extends StateNotifier<DateTime> {
  final Ref _ref;
  
  SelectedDateNotifier(this._ref, DateTime initialDate) : super(normalizeDate(initialDate));
  
  /// Set the selected date (with normalization)
  void setDate(DateTime date) {
    final normalizedDate = normalizeDate(date);
    if (!isSameDay(normalizedDate, state)) {
      state = normalizedDate;
    }
  }
  
  /// Move to the previous day
  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }
  
  /// Move to the next day
  void nextDay() {
    state = state.add(const Duration(days: 1));
  }
  
  /// Reset to today's date
  void resetToToday() {
    final today = _ref.read(currentDateProvider);
    setDate(today);
  }
  
  /// Check if the selected date is today
  bool get isToday {
    final today = _ref.read(currentDateProvider);
    return isSameDay(state, today);
  }
}

/// Refreshes the current date provider to ensure it has the latest date
/// This is useful for apps that stay open for a long time
void refreshCurrentDate(dynamic ref) {
  // Handle both Ref and WidgetRef types
  if (ref is Ref || ref is WidgetRef) {
    final now = DateTime.now();
    final normalized = normalizeDate(now);
    final current = ref.read(currentDateProvider);
    
    if (!isSameDay(normalized, current)) {
      ref.read(currentDateProvider.notifier).state = normalized;
    }
  } else {
    throw ArgumentError('refreshCurrentDate expects a Ref or WidgetRef');
  }
}

/// Comprehensive date service for complex date operations
class DateService {
  final dynamic _ref;
  
  /// Create a service to handle date operations
  /// Accepts either a Ref or a WidgetRef
  DateService(this._ref) {
    // Validate that we can use this reference
    if (!(_ref is Ref || _ref is WidgetRef)) {
      throw ArgumentError('DateService expects a Ref or WidgetRef');
    }
  }
  
  /// Get the current date (today)
  DateTime get currentDate => _ref.read(currentDateProvider);
  
  /// Get the currently selected date
  DateTime get selectedDate => _ref.read(selectedDateProvider);
  
  /// Check if the selected date is today
  bool get isSelectedDateToday => _ref.read(isSelectedDateTodayProvider);
  
  /// Check if the selected date is in the past
  bool get isSelectedDatePast => _ref.read(isSelectedDatePastProvider);
  
  /// Get the formatted selected date
  String get formattedSelectedDate => _ref.read(formattedSelectedDateProvider);
  
  /// Set the selected date
  void setSelectedDate(DateTime date) {
    _ref.read(selectedDateProvider.notifier).setDate(date);
  }
  
  /// Move to the previous day
  void goToPreviousDay() {
    _ref.read(selectedDateProvider.notifier).previousDay();
  }
  
  /// Move to the next day
  void goToNextDay() {
    _ref.read(selectedDateProvider.notifier).nextDay();
  }
  
  /// Reset to today
  void goToToday() {
    _ref.read(selectedDateProvider.notifier).resetToToday();
  }
}

/// Provider for the date service
final dateServiceProvider = Provider<DateService>((ref) {
  return DateService(ref);
});

/// Extension method to get a DateService from a WidgetRef for convenience
extension DateServiceExtension on WidgetRef {
  /// Get a DateService instance for this WidgetRef
  DateService get dateService => DateService(this);
}
