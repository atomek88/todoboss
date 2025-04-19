import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';
import 'package:todoApp/feature/todos/providers/todos_notifier.dart';
import 'package:todoApp/feature/todos/views/todo_form_page.dart';
import 'package:todoApp/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todoApp/feature/todos/models/todo.dart';

@RoutePage()
class TodosWrapperPage extends StatelessWidget {
  const TodosWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(const TodosPage(), const IOSTodosPage());
  }
}

class TodosPage extends HookConsumerWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);

    return Scaffold(
      appBar: AppBar(title: Text(Loc.of(context).todos)),
      body: todos.isEmpty
          ? Center(child: Text(Loc.of(context).noTodos))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return ListTile(
                  leading: Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: todo.completed,
                    onChanged: (value) => ref
                        .read(todosProvider.notifier)
                        .update(todo.copyWith(completed: value!)),
                  ),
                  title: Text(todo.title),
                  subtitle:
                      todo.description != null ? Text(todo.description!) : null,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      onPressed: () => _showTodoForm(context, todo),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(todosProvider.notifier).remove(todo),
                      icon: const Icon(Icons.delete),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'todos',
        onPressed: () => _showTodoForm(context, null),
        tooltip: Loc.of(context).increment,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTodoForm(BuildContext context, Todo? todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TodoFormPage(todo: todo),
        fullscreenDialog: true,
      ),
    );
  }
}

/// iOS version of the TodosPage using Cupertino widgets
class IOSTodosPage extends HookConsumerWidget {
  const IOSTodosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(Loc.of(context).todos),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showTodoForm(context, null),
        ),
      ),
      child: SafeArea(
        child: todos.isEmpty
            ? Center(child: Text(Loc.of(context).noTodos))
            : ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: CupertinoListTile(
                      leading: CupertinoSwitch(
                        value: todo.completed,
                        onChanged: (value) => ref
                            .read(todosProvider.notifier)
                            .update(todo.copyWith(completed: value)),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.completed
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.label,
                        ),
                      ),
                      subtitle: todo.description != null
                          ? Text(
                              todo.description!,
                              style: TextStyle(
                                color: todo.completed
                                    ? CupertinoColors.systemGrey3
                                    : CupertinoColors.systemGrey,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.pencil,
                              size: 20,
                            ),
                            onPressed: () => _showTodoForm(context, todo),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.delete,
                              size: 20,
                              color: CupertinoColors.destructiveRed,
                            ),
                            onPressed: () =>
                                _showDeleteConfirmation(context, ref, todo),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showTodoForm(BuildContext context, Todo? todo) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => IOSTodoFormPage(todo: todo),
        fullscreenDialog: true,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Todo todo) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              ref.read(todosProvider.notifier).remove(todo);
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
