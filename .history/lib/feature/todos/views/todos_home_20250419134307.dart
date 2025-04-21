import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../providers/todos_provider.dart';
import '../models/todo.dart';

@RoutePage()
class TodosHomePage extends ConsumerWidget {
  const TodosHomePage({Key? key}) : super(key: key);

  Color _priorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((Todo todo) => todo.status == 1).length;
    final deletedCount = todos.where((Todo todo) => todo.status == 2).length;
    final activeTodos = todos.where((Todo todo) => todo.status == 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.pushRoute(ProfileWrapperRoute.routeName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Completed',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      AnimatedCounter(
                          count: completedCount, color: Colors.teal),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text('Deleted',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    AnimatedCounter(count: deletedCount, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: activeTodos.length,
              itemBuilder: (context, index) {
                final todo = activeTodos[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Card(
                    color: _priorityColor(todo.priority),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(todo.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(todo.description!),
                      onTap: () {
                        // Find the original index in the full todos list
                        final originalIndex = todos.indexWhere((t) =>
                            t.title == todo.title &&
                            t.description == todo.description &&
                            t.createdAt == todo.createdAt);

                        if (originalIndex != -1) {
                          context.router.push(
                              EditTaskRoute(todo: todo, index: originalIndex));
                        }
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () {
                              // Find the original index in the full todos list
                              final originalIndex = todos.indexWhere((t) =>
                                  t.title == todo.title &&
                                  t.description == todo.description &&
                                  t.createdAt == todo.createdAt);

                              if (originalIndex != -1) {
                                ref
                                    .read(todoListProvider.notifier)
                                    .completeTodo(originalIndex);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '"${todo.title}" marked as completed')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              // Find the original index in the full todos list
                              final originalIndex = todos.indexWhere((t) =>
                                  t.title == todo.title &&
                                  t.description == todo.description &&
                                  t.createdAt == todo.createdAt);

                              if (originalIndex != -1) {
                                ref
                                    .read(todoListProvider.notifier)
                                    .deleteTodo(originalIndex);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '"${todo.title}" moved to trash')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show add new task modal
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int count;
  final Color color;
  const AnimatedCounter({super.key, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        '$count',
        key: ValueKey(count),
        style:
            TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
