import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/daily_todos/models/daily_todo.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todo_summary_providers.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';

/// A card that displays daily statistics for todos
class DailyStatsCard extends ConsumerWidget {
  const DailyStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the selected date for filtering todos and normalize it
    final normalizedSelectedDate =
        normalizeDate(ref.watch(selectedDateProvider));

    // Watch the dailyTodoByDate provider for this date
    final dailyStatsAsync =
        ref.watch(dailyTodoByDateProvider(normalizedSelectedDate));

    // Watch the DailyTodo provider as backup (bridge provider)
    final dailyTodoAsync = ref.watch(dailyTodoProvider);

    // First try using the new provider
    return dailyStatsAsync.when(
      data: (stats) {
        // Use the data from daily stats provider
        // Get the dailyTodo from our AsyncValue provider
        return dailyTodoAsync.when(
          data: (dailyTodo) {
            if (dailyTodo == null) {
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
                    _StatsCountersRow(dailyTodo: dailyTodo),
                    if (dailyTodo.taskGoal > 0) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: dailyTodo.taskGoal > 0
                            ? (dailyTodo.completedTodosCount /
                                    dailyTodo.taskGoal)
                                .clamp(0.0, 1.0)
                            : 0.0,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: ${dailyTodo.completedTodosCount}/${dailyTodo.taskGoal} (${(dailyTodo.completionPercentage).toStringAsFixed(0)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (dailyTodo.summary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dailyTodo.summary!,
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading dailyTodo: $err'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading daily stats: $err'),
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
      onPressed: () async {
        // Show a date picker to select past dates
        final selectedDate = await showDatePicker(
          context: context,
          initialDate:
              ref.read(currentDateProvider).subtract(const Duration(days: 1)),
          firstDate:
              ref.read(currentDateProvider).subtract(const Duration(days: 365)),
          lastDate:
              ref.read(currentDateProvider).subtract(const Duration(days: 1)),
        );

        // Check if widget is still mounted before using context
        if (selectedDate != null && context.mounted) {
          // Navigate to the past date page with the selected date
          context.router.push(const UnifiedTodosRoute());
        }
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
  final DailyTodo dailyTodo;

  const _StatsCountersRow({required this.dailyTodo, Key? key})
      : super(key: key);

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
            Text('${dailyTodo.completedTodosCount}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        // Goal counter
        Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.blue),
            const SizedBox(height: 4),
            Text('${dailyTodo.taskGoal}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        // Deleted counter
        Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(height: 4),
            Text('${dailyTodo.deletedTodosCount}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
