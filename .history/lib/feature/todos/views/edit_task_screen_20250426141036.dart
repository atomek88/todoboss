import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';
import '../../../shared/widgets/recurring_app_icon.dart';

/// Provider to track the rollover state for edit task screen
final editTaskRolloverProvider =
    StateProvider.autoDispose<bool>((ref) => false);

@RoutePage()
class EditTaskPage extends ConsumerStatefulWidget {
  final Todo? todo;
  const EditTaskPage({Key? key, this.todo}) : super(key: key);

  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  late TextEditingController titleController;
  late TextEditingController descController;
  int priority = 0;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.todo?.title ?? '');
    descController =
        TextEditingController(text: widget.todo?.description ?? '');
    priority = widget.todo?.priority ?? 0;

    // Initialize the rollover state provider with the todo's value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editTaskRolloverProvider.notifier).state =
          widget.todo?.rollover ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Todo' : 'Edit Todo'),
        actions: [
          // Add the SquareAppIcon to the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SquareAppIcon(
              iconAsset: 'assets/icons/rock-hill.png',
              activationProvider: editTaskRolloverProvider,
              size: 40.0,
            ),
          ),
        ],
      ),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: priority,
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
            // Rollover explanation text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Rollover status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ref.watch(editTaskRolloverProvider)
                        ? 'Enabled'
                        : 'Disabled',
                    style: TextStyle(
                      color: ref.watch(editTaskRolloverProvider)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Toggle icon in app bar to change',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
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
                    if (widget.todo == null) {
                      // Create a new todo
                      final todo = Todo.create(
                        title: titleController.text,
                        description: descController.text,
                        priority: priority,
                        rollover: ref.read(editTaskRolloverProvider),
                        status: 0,
                      );
                      ref.read(todoListProvider.notifier).addTodo(todo);
                    } else {
                      // Update existing todo
                      final updatedTodo = widget.todo!.copyWith(
                        title: titleController.text,
                        description: descController.text,
                        priority: priority,
                        rollover: ref.read(editTaskRolloverProvider),
                      );
                      ref
                          .read(todoListProvider.notifier)
                          .updateTodo(widget.todo!.id, updatedTodo);
                    }
                    Navigator.of(context).pop();
                  },
                  child:
                      Text(widget.todo == null ? 'Add Task' : 'Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
