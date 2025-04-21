import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';

@RoutePage()
class EditTaskPage extends ConsumerStatefulWidget {
  final Todo? todo;
  final int? index;
  const EditTaskPage({Key? key, this.todo, this.index}) : super(key: key);

  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  late TextEditingController titleController;
  late TextEditingController descController;
  int priority = 0;
  bool rollover = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.todo?.title ?? '');
    descController =
        TextEditingController(text: widget.todo?.description ?? '');
    priority = widget.todo?.priority ?? 0;
    rollover = widget.todo?.rollover ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.todo == null ? 'Add Task' : 'Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 2, child: Text('High')),
                DropdownMenuItem(value: 1, child: Text('Medium')),
                DropdownMenuItem(value: 0, child: Text('Low')),
              ],
              onChanged: (val) {
                setState(() {
                  priority = val ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: rollover,
              onChanged: (val) {
                setState(() {
                  rollover = val ?? false;
                });
              },
              title: const Text('Rollover'),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final todo = Todo(
                      title: titleController.text,
                      description: descController.text,
                      priority: priority,
                      rollover: rollover,
                      status: 0,
                      createdAt: widget.todo?.createdAt ?? DateTime.now(),
                      endedOn: null,
                    );
                    if (widget.todo == null) {
                      ref.read(todoListProvider.notifier).addTodo(todo);
                    } else if (widget.index != null) {
                      ref
                          .read(todoListProvider.notifier)
                          .updateTodo(widget.index!, todo);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(widget.todo == null ? 'Add Task' : 'Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
