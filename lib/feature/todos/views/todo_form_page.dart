import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:todoApp/feature/todos/providers/todos_notifier.dart';
import 'package:todoApp/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todoApp/feature/todos/models/todo.dart';

class TodoFormPage extends HookConsumerWidget {
  final Todo? todo;
  final bool isNew;

  const TodoFormPage({this.todo, super.key}) : isNew = todo == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = useState(todo?.title);
    final description = useState(todo?.description);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isNew ? Loc.of(context).createTodo : Loc.of(context).updateTodo),
      ),
      body: Form(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    TextFormField(
                      autofocus: true,
                      initialValue: title.value,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) => title.value = value,
                      decoration: InputDecoration(
                        labelText: Loc.of(context).title,
                      ),
                    ),
                    TextFormField(
                      initialValue: description.value,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) => description.value = value,
                      decoration: InputDecoration(
                        labelText: Loc.of(context).description,
                      ),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    child: Text(Loc.of(context).save),
                    onPressed: () =>
                        _save(context, ref, title.value, description.value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(
      BuildContext context, WidgetRef ref, String? title, String? description) {
    if (title == null || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Loc.of(context).titleRequired)),
      );
      return;
    }

    if (isNew) {
      ref.read(todosProvider.notifier).add(
            Todo(
              title: title,
              description: description,
            ),
          );
    } else {
      ref.read(todosProvider.notifier).update(
            todo!.copyWith(
              title: title,
              description: description,
            ),
          );
    }

    Navigator.of(context).pop();
  }
}

/// iOS version of the TodoFormPage using Cupertino widgets
class IOSTodoFormPage extends HookConsumerWidget {
  final Todo? todo;
  final bool isNew;

  const IOSTodoFormPage({this.todo, super.key}) : isNew = todo == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = useState(todo?.title);
    final description = useState(todo?.description);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
            isNew ? Loc.of(context).createTodo : Loc.of(context).updateTodo),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(Loc.of(context).save),
          onPressed: () => _save(context, ref, title.value, description.value),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CupertinoTextField(
                        placeholder: Loc.of(context).title,
                        controller: TextEditingController(text: title.value),
                        onChanged: (value) => title.value = value,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        clearButtonMode: OverlayVisibilityMode.editing,
                        autocorrect: true,
                        autofocus: true,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    CupertinoTextField(
                      placeholder: Loc.of(context).description,
                      controller: TextEditingController(text: description.value),
                      onChanged: (value) => description.value = value,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      maxLines: 5,
                      minLines: 3,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(
      BuildContext context, WidgetRef ref, String? title, String? description) {
    if (title == null || title.isEmpty) {
      // Show iOS-style alert
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Error'),  // Using hardcoded string since Loc.error is not defined
          content: Text(Loc.of(context).titleRequired),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),  // Using hardcoded string since Loc.ok is not defined
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (isNew) {
      ref.read(todosProvider.notifier).add(
            Todo(
              title: title,
              description: description,
            ),
          );
    } else {
      ref.read(todosProvider.notifier).update(
            todo!.copyWith(
              title: title,
              description: description,
            ),
          );
    }

    Navigator.of(context).pop();
  }
}
