import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/feature/todos/models/todo_date.dart';
import 'package:todoApp/feature/todos/providers/todo_date_provider.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/services/todo_date_filter_service.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';
import 'package:todoApp/shared/providers/selected_date_provider.dart';
import 'package:todoApp/shared/styles/styles.dart';

/// A page to view past date summaries and todos
class PastDatePage extends ConsumerWidget {
  /// The date to display
  final DateTime date;

  /// Constructor
  const PastDatePage({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the TodoDate for this specific date
    ref.read(selectedDateProvider.notifier).setDate(date);
    final todoDateAsync = ref.watch(todoDateProvider);
    final filteredTodos = ref.watch(filteredTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            Text(DateFormat('EEEE, MMMM d, y').format(date)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: todoDateAsync.when(
        data: (todoDate) {
          if (todoDate == null) {
            return const Center(
              child: Text('No data available for this date'),
            );
          }

          return Column(
            children: [
              // Date summary card
              _buildSummaryCard(context, todoDate),

              // Divider
              const Divider(height: 1),

              // Todo list (read-only)
              Expanded(
                child: _buildTodoList(context, filteredTodos),
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
  Widget _buildSummaryCard(BuildContext context, TodoDate todoDate) {
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
                  DateFormat('EEEE, MMMM d, y').format(todoDate.date),
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
              '${todoDate.completedTodosCount}',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 8),

            _buildStat(
              context,
              'Deleted',
              '${todoDate.deletedTodosCount}',
              Icons.delete,
              Colors.red,
            ),
            const SizedBox(height: 8),

            if (todoDate.taskGoal > 0) ...[
              _buildStat(
                context,
                'Goal Progress',
                '${todoDate.completedTodosCount}/${todoDate.taskGoal}',
                Icons.flag,
                AppColors.primary,
              ),
              const SizedBox(height: 8),

              // Progress bar
              LinearProgressIndicator(
                value: todoDate.taskGoal > 0
                    ? todoDate.completedTodosCount / todoDate.taskGoal
                    : 0,
                backgroundColor: Colors.grey[300],
                color: theme.colorScheme.primary,
              ),
            ],

            const SizedBox(height: 16),

            // Summary
            if (todoDate.summary != null) ...[
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(todoDate.summary!),
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

  /// Build the todo list (read-only)
  Widget _buildTodoList(BuildContext context, List<Todo> todos) {
    if (todos.isEmpty) {
      return const Center(
        child: Text('No todos for this date'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoListItem(
          key: ValueKey(todo.id),
          todo: todo,
          isReadOnly: true, // Set to read-only for past dates
        );
      },
    );
  }
}
