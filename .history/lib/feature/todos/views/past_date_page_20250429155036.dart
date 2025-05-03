import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/daily_todos/models/daily_todo.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/services/todo_date_filter_service.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';
import 'package:todoApp/shared/styles/styles.dart';
import 'package:todoApp/core/providers/date_provider.dart';

/// A page to view past date summaries and todos
@RoutePage()
class PastDatePage extends ConsumerStatefulWidget {
  /// The date to display
  final DateTime date;

  /// Constructor
  const PastDatePage({Key? key, required this.date}) : super(key: key);

  @override
  ConsumerState<PastDatePage> createState() => _PastDatePageState();
}

class _PastDatePageState extends ConsumerState<PastDatePage> {
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to delay the provider update until after the build
    Future.microtask(() {
      // First set the selected date provider with the supplied date
      ref.read(selectedDateProvider.notifier).setDate(widget.date);
      debugPrint(
          '🔄 [PastDatePage] Setting selected date in initState: ${widget.date}');

      // Then explicitly update the DailyTodo with this date
      ref.read(dailyTodoProvider.notifier).dateChanged(widget.date);
      debugPrint(
          '🔄 [PastDatePage] Syncing DailyTodo with selected date: ${widget.date}');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current date from the provider for comparisons
    final currentDate = ref.watch(currentDateProvider);
    // Get the DailyTodo for this specific date - central data source
    final dailyTodoAsync = ref.watch(dailyTodoProvider);
    // Get all todos from the repository
    final allTodos = ref.watch(todoListProvider);

    // Flag to determine if this is a past date (read-only)
    final isPastDate = widget.date.isBefore(normalizeDate(currentDate));

    // Normalize the page date for consistent comparison
    final normalizedPageDate = normalizeDate(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            Text(DateFormat('EEEE, MMMM d, y').format(widget.date)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clear the selected date state before popping to prevent redirect loops
            debugPrint(
                '🔄 [PastDatePage] Back button pressed, popping and resetting date');

            // Pop back using auto_route
            context.router.popForced();

            // After a short delay, reset the date to today to avoid another redirect
            Future.delayed(const Duration(milliseconds: 100), () {
              final currentDate = normalizeDate(DateTime.now());
              debugPrint('🔄 [PastDatePage] Date reset to today: $currentDate');

              // Update both the selected date provider and DailyTodo provider
              ref.read(selectedDateProvider.notifier).setDate(currentDate);
              ref.read(dailyTodoProvider.notifier).dateChanged(currentDate);

              // Force reload data for the new date
              ref.read(dailyTodoProvider.notifier).forceReload();
            });
          },
        ),
      ),
      body: dailyTodoAsync.when(
        data: (dailyTodo) {
          if (dailyTodo == null) {
            return const Center(
              child: Text('No data available for this date'),
            );
          }

          // Filter todos for this specific date
          final todosForDate = allTodos.where((todo) {
            final todoDate = normalizeDate(todo.createdAt);
            return todoDate.isAtSameMomentAs(normalizedPageDate);
          }).toList();

          debugPrint(
              '🔄 [PastDatePage] Found ${todosForDate.length} todos for date: $normalizedPageDate');

          return Column(
            children: [
              // Date summary card
              _buildSummaryCard(context, dailyTodo),

              // Divider
              const Divider(height: 1),

              // Todo list (read-only)
              Expanded(
                child: _buildTodoList(context, todosForDate, isPastDate),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading data: $error'),
        ),
      ),
    );
  }

  /// Build the summary card for the date
  Widget _buildSummaryCard(BuildContext context, DailyTodo dailyTodo) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(dailyTodo.date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            _buildStat(
              context,
              'Completed',
              '${dailyTodo.completedTodosCount}',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 8),

            _buildStat(
              context,
              'Deleted',
              '${dailyTodo.deletedTodosCount}',
              Icons.delete,
              Colors.red,
            ),
            const SizedBox(height: 8),

            if (dailyTodo.taskGoal > 0) ...[
              _buildStat(
                context,
                'Goal Progress',
                '${dailyTodo.completedTodosCount}/${dailyTodo.taskGoal}',
                Icons.flag,
                AppColors.primary,
              ),
              const SizedBox(height: 8),

              // Progress bar
              LinearProgressIndicator(
                value: dailyTodo.taskGoal > 0
                    ? dailyTodo.completedTodosCount / dailyTodo.taskGoal
                    : 0,
                backgroundColor: Colors.grey[300],
                color: theme.colorScheme.primary,
              ),
            ],

            const SizedBox(height: 16),

            // Summary
            if (dailyTodo.summary != null) ...[
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(dailyTodo.summary!),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a stat row
  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }

  /// Build the todo list (read-only for past dates)
  Widget _buildTodoList(
      BuildContext context, List<Todo> todos, bool isPastDate) {
    return todos.isEmpty
        ? const Center(child: Text('No todos for this date'))
        : ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];

              // For past dates, show a read-only version
              return TodoListItem(
                todo: todo,
                isReadOnly: isPastDate,
                onToggle: isPastDate
                    ? null
                    : (id) {
                        print(
                            ' [PastDatePage] Toggled todo: $id (should be disabled)');
                      },
                onDelete: isPastDate
                    ? null
                    : (id) {
                        print(
                            ' [PastDatePage] Deleted todo: $id (should be disabled)');
                      },
              );
            },
          );
  }
}
