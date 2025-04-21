import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';

@RoutePage()
class DeletedTasksScreen extends ConsumerWidget {
  const DeletedTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final deleted = todos.where((Todo todo) => todo.status == 2).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Deleted Tasks')),
      body: ListView.builder(
        itemCount: deleted.length,
        itemBuilder: (context, index) {
          final todo = deleted[index];
          return ListTile(
            title: Text(todo.title),
            subtitle: Text(todo.description),
            trailing: Text(
              todo.endedOn != null ? 'Deleted: ${todo.endedOn}' : '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
