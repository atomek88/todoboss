import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';
import 'package:todoApp/shared/utils/show_snack_bar.dart';
import 'package:todoApp/shared/utils/theme/theme_extension.dart';

/// A screen that displays scheduled tasks
@RoutePage()
class RecurringTodosPage extends ConsumerWidget {
  const RecurringTodosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all todos
    final todos = ref.watch(todoListProvider);

    // Filter to only show scheduled todos that are active (status = 0)
    final recurringTodos =
        todos.where((todo) => todo.isScheduled && todo.status == 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Todos'),
        backgroundColor: context.backgroundPrimary,
        foregroundColor: context.textPrimary,
        actions: [
          // Add a count badge in the app bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Chip(
              label: Text(
                '${recurringTodos.length}',
                style: TextStyle(
                  color: context.onPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: context.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
        ],
      ),
      body: recurringTodos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: context.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scheduled tasks',
                    style: TextStyle(
                      fontSize: 18,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasks marked as scheduled will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: recurringTodos.length,
              itemBuilder: (context, index) {
                final todo = recurringTodos[index];
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(
                    color: context.errorColor,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Delete the todo
                    ref.read(todoListProvider.notifier).deleteTodo(todo.id);

                    // Show a snackbar
                    NotificationService.showNotification(
                      '"${todo.title}" moved to trash',
                    );
                  },
                  child: TodoListItem(
                    todo: todo,
                    onComplete: (todo) {
                      // Complete the todo
                      ref.read(todoListProvider.notifier).completeTodo(todo.id);

                      // Show a snackbar
                      NotificationService.showNotification(
                        '"${todo.title}" marked as completed',
                      );
                    },
                    onDelete: (todo) {
                      // Delete the todo
                      ref.read(todoListProvider.notifier).deleteTodo(todo.id);

                      // Show a snackbar
                      NotificationService.showNotification(
                        '"${todo.title}" moved to trash',
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
