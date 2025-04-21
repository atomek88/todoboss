import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../providers/todos_provider.dart';
import '../models/todo.dart';

@RoutePage()
class CompletedTasksPage extends ConsumerWidget {
  const CompletedTasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final completed = todos.where((Todo todo) => todo.status == 1).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Tasks')),
      body: ListView.builder(
        itemCount: completed.length,
        itemBuilder: (context, index) {
          final todo = completed[index];
          return ListTile(
            title: Text(todo.title),
            subtitle: Text(todo.description!),
            trailing: Text(
              todo.endedOn != null ? 'Completed: ${todo.endedOn}' : '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
