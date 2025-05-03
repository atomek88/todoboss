import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/todos/views/past_date_page.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';

/// A card that displays daily statistics for todos
class DailyStatsCard extends ConsumerWidget {
  const DailyStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the selected date for filtering todos and normalize it
    final normalizedSelectedDate =
        normalizeDate(ref.watch(selectedDateProvider));

    // Watch the DailyTodo provider to display stats
    final todoDateAsync = ref.watch(dailyTodoProvider);

    return todoDateAsync.when(
      data: (todoDate) {
        if (todoDate == null) {
          return const SizedBox(height: 8);
        }

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Stats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 40),
                    // Today button
                    _TodayButton(
                        normalizedSelectedDate: normalizedSelectedDate),
                    // History button for past dates
                    _HistoryButton(),
                    // Profile icon button
                    _ProfileButton(),
                  ],
                ),
                const Divider(),
                _StatsCountersRow(todoDate: todoDate),
                if (todoDate.taskGoal > 0) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: todoDate.taskGoal > 0
                        ? (todoDate.completedTodosCount / todoDate.taskGoal)
                            .clamp(0.0, 1.0)
                        : 0.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Progress: ${todoDate.completedTodosCount}/${todoDate.taskGoal} (${(todoDate.completionPercentage).toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (todoDate.summary != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    todoDate.summary!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 115,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading daily stats: $error'),
        ),
      ),
    );
  }
}

/// Button to navigate to today's date
class _TodayButton extends ConsumerWidget {
  final DateTime normalizedSelectedDate;

  const _TodayButton({required this.normalizedSelectedDate, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: DateUtils.isSameDay(
              normalizedSelectedDate, ref.read(currentDateProvider))
          ? 0.3
          : 1.0,
      child: IconButton(
        icon: const Icon(Icons.calendar_today_rounded),
        tooltip: 'Go to Today',
        onPressed: () {
          // Force refresh the current date
          refreshCurrentDate(ref);

          // Get the current date from the provider after refresh
          final normalizedToday = ref.read(currentDateProvider);

          debugPrint(
              '📅 [DailyStatsCard] Today button pressed. Current date from provider: ${normalizedToday.toString()}');

          // Provide haptic feedback when changing date
          HapticFeedback.selectionClick();

          // Force date update to today
          ref.read(selectedDateProvider.notifier).setDate(normalizedToday);

          // Force reload the DailyTodo for today
          ref.read(dailyTodoProvider.notifier).forceReload();
        },
      ),
    );
  }
}

/// Button to view history of past dates
class _HistoryButton extends ConsumerWidget {
  const _HistoryButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.calendar_month_rounded),
      tooltip: 'View Past Dates',
      onPressed: () {
        // Show a date picker to select past dates
        showDatePicker(
          context: context,
          initialDate:
              ref.read(currentDateProvider).subtract(const Duration(days: 1)),
          firstDate:
              ref.read(currentDateProvider).subtract(const Duration(days: 365)),
          lastDate:
              ref.read(currentDateProvider).subtract(const Duration(days: 1)),
        ).then((selectedDate) {
          if (selectedDate != null) {
            // Navigate to the past date page with the selected date
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PastDatePage(date: selectedDate),
              ),
            );
          }
        });
      },
    );
  }
}

/// Button to navigate to the profile page
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.person_outline),
        onPressed: () {
          // Navigate to profile using auto_route
          context.pushRoute(const ProfileWrapperRoute());
        },
        tooltip: 'Profile',
        iconSize: 26,
      ),
    );
  }
}

/// Row of statistics counters (completed, goal, deleted)
class _StatsCountersRow extends StatelessWidget {
  final dynamic todoDate;

  const _StatsCountersRow({required this.todoDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Completed counter
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(height: 4),
            Text('${todoDate.completedTodosCount}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        // Goal counter
        Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.blue),
            const SizedBox(height: 4),
            Text('${todoDate.taskGoal}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        // Deleted counter
        Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(height: 4),
            Text('${todoDate.deletedTodosCount}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
