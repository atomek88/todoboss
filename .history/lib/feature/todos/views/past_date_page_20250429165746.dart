import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:auto_route/auto_route.dart';
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

    // Use Future.microtask to ensure providers are updated after build
    Future.microtask(() {
      // First set the selected date provider with the supplied date
      ref.read(selectedDateProvider.notifier).setDate(widget.date);
      debugPrint(
          '🔄 [PastDatePage] Setting selected date in initState: ${widget.date}');

      // Then explicitly update the DailyTodo with this date to maintain sync
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

            // Pop back using auto_route with force to avoid redirect issues
            context.router.popForced();

            // After a short delay, reset the date to today to avoid another redirect
            Future.delayed(const Duration(milliseconds: 100), () {
              final todayDate = normalizeDate(DateTime.now());
              debugPrint(
                  '🔄 [PastDatePage] Resetting date to today: $todayDate');

              // Update both providers to maintain sync
              ref.read(selectedDateProvider.notifier).setDate(todayDate);
              ref.read(dailyTodoProvider.notifier).dateChanged(todayDate);

              // Force reload to ensure data consistency
              ref.read(dailyTodoProvider.notifier).forceReload();
            });
          },
        ),
      ),
      body: dailyTodoAsync.when(
        data: (dailyTodo) {
          // Check if DailyTodo is null or date doesn't match
          if (dailyTodo == null) {
            debugPrint('⚠️ [PastDatePage] DailyTodo is null, forcing reload');

            // Force reload after a short delay
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                ref.read(dailyTodoProvider.notifier).dateChanged(widget.date);
              }
            });

            return const Center(child: CircularProgressIndicator());
          }

          // Ensure dates match
          final dailyTodoDate = normalizeDate(dailyTodo.date);
          if (!dailyTodoDate.isAtSameMomentAs(normalizedPageDate)) {
            debugPrint(
                '⚠️ [PastDatePage] Date mismatch: DailyTodo=${dailyTodo.date}, Page=$normalizedPageDate, forcing sync');

            // Force sync after a short delay
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                ref.read(dailyTodoProvider.notifier).dateChanged(widget.date);
              }
            });

            return const Center(child: CircularProgressIndicator());
          }

          // Filter todos for this specific date
          final todosForDate = allTodos.where((todo) {
            final todoDate = normalizeDate(todo.createdAt);
            return todoDate.isAtSameMomentAs(normalizedPageDate);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10.0,
                          offset: const Offset(0, 5),
                        )
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12.0),
                      _buildSummaryRow(
                          context,
                          'Created',
                          // where created_at is same date as Todo date
                          '${dailyTodo.todos}',
                          Icons.add_circle_outline),
                      const SizedBox(height: 8.0),
                      _buildSummaryRow(
                          context,
                          'Completed',
                          '${dailyTodo.completedTodosCount}',
                          Icons.check_circle_outline),
                      const SizedBox(height: 8.0),
                      _buildSummaryRow(context, 'Goal', '${dailyTodo.taskGoal}',
                          Icons.flag_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 24.0),

                // Task list header
                Row(
                  children: [
                    const Icon(Icons.list_alt, size: 18),
                    const SizedBox(width: 8.0),
                    Text(
                      'Tasks (${todosForDate.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),

                // Todo list (read-only for past dates)
                Expanded(
                  child: _buildTodoList(context, todosForDate, isPastDate),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Build a summary row for the stats card
  Widget _buildSummaryRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8.0),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
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
                        debugPrint(
                            '✅ [PastDatePage] Toggled todo: $id (should be disabled)');
                      },
                onDelete2: isPastDate
                    ? null
                    : (id) {
                        debugPrint(
                            '🗑️ [PastDatePage] Deleted todo: $id (should be disabled)');
                      },
              );
            },
          );
  }
}
