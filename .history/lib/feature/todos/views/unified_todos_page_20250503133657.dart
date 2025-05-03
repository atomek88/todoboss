import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/shared/widgets/swipeable_date_picker.dart';
import 'package:auto_route/auto_route.dart';

// Import the view components (not full pages)
import 'widgets/past_date_view.dart';
import 'widgets/todos_home_view.dart';

/// A unified page that conditionally displays either past date view or current todos
/// based on the selected date, eliminating the need for navigation between date pages
@RoutePage()
class UnifiedTodosPage extends ConsumerWidget {
  const UnifiedTodosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the date providers for changes
    final selectedDate = ref.watch(selectedDateProvider);
    final currentDate = ref.watch(currentDateProvider);

    // Determine if we should show past date view
    // We show past date view if date is before today and not yesterday
    final shouldShowPastView =
        isPastDate(selectedDate, includeYesterday: false);

    // Format dates for debug information
    final formattedSelected = formatDate(selectedDate);
    final formattedCurrent = formatDate(currentDate);

    // Normalize dates for consistent display
    final normalizedSelectedDate = normalizeDate(selectedDate);

    debugPrint(
        '📅 [UnifiedTodosPage] Selected date: $formattedSelected (normalized: $normalizedSelectedDate)');
    debugPrint('📅 [UnifiedTodosPage] Current date: $formattedCurrent');
    debugPrint(
        '📅 [UnifiedTodosPage] Showing ${shouldShowPastView ? "PAST" : "CURRENT"} view');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SwipeableDatePicker(
          height: 70,
          mainDateTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          maxDaysForward: 7, // Limit to one week forward
          // Single callback to update date - no navigation
          onDateSelected: (date) {
            // Update DailyTodo provider when date changes
            ref.read(dailyTodoProvider.notifier).dateChanged(date);
            debugPrint('🔄 [UnifiedTodosPage] Date selected via picker: $date');
          },
        ),
      ),

      // Conditional body based on the selected date
      body: SafeArea(
        child: shouldShowPastView
            ? const PastDateView() // Component for past dates
            : const TodosHomeView(), // Component for current/future dates
      ),
    );
  }
}
