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
      body: completed.isEmpty
          ? const Center(child: Text('No completed tasks yet'))
          : ListView.builder(
              itemCount: completed.length,
              itemBuilder: (context, index) {
                final todo = completed[index];
                return ListTile(
                  title: Text(todo.title),
                  subtitle: todo.description != null 
                      ? Text(todo.description!)
                      : null,
                  trailing: todo.endedOn != null
                      ? Text(
                          'Completed: ${todo.endedOn!.day}/${todo.endedOn!.month}/${todo.endedOn!.year}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
