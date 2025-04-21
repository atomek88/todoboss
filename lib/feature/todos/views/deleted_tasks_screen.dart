import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../providers/todos_provider.dart';
import '../models/todo.dart';

@RoutePage()
class DeletedTasksPage extends ConsumerWidget {
  const DeletedTasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final deleted = todos.where((Todo todo) => todo.status == 2).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Deleted Tasks')),
      body: deleted.isEmpty
          ? const Center(child: Text('No deleted tasks'))
          : ListView.builder(
              itemCount: deleted.length,
              itemBuilder: (context, index) {
                final todo = deleted[index];
                return ListTile(
                  title: Text(todo.title),
                  subtitle:
                      todo.description != null ? Text(todo.description!) : null,
                  trailing: todo.endedOn != null
                      ? Text(
                          'Deleted: ${todo.endedOn!.day}/${todo.endedOn!.month}/${todo.endedOn!.year}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
