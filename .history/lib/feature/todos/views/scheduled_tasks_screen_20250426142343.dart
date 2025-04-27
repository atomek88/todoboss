import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';
import 'package:todoApp/shared/utils/show_snack_bar.dart';

/// A screen that displays scheduled tasks
@RoutePage()
class ScheduledTasksScreen extends ConsumerWidget {
  const ScheduledTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all todos
    final todos = ref.watch(todoListProvider);

    // Filter to only show scheduled todos (scheduled = 1) that are active (status = 0)
    final scheduledTodos =
        todos.where((todo) => todo.scheduled == 1 && todo.status == 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Todos'),
        actions: [
          // Add a count badge in the app bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Chip(
              label: Text(
                '${scheduledTodos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
        ],
      ),
      body: scheduledTodos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No scheduled tasks',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tasks marked as scheduled will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: scheduledTodos.length,
              itemBuilder: (context, index) {
                final todo = scheduledTodos[index];
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
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
