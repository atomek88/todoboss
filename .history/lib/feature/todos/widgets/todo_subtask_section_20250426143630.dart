import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';
import '../../../shared/widgets/swipeable_item.dart';

class TodoSubtaskSection extends ConsumerStatefulWidget {
  final Todo parentTodo;

  const TodoSubtaskSection({
    Key? key,
    required this.parentTodo,
  }) : super(key: key);

  @override
  ConsumerState<TodoSubtaskSection> createState() => _TodoSubtaskSectionState();
}

class _TodoSubtaskSectionState extends ConsumerState<TodoSubtaskSection> {
  // Controller for adding new subtasks
  final TextEditingController _subtaskController = TextEditingController();

  // Map to track which subtasks are being edited
  final Map<String, bool> _editingSubtasks = {};

  // Controllers for editing existing subtasks
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void dispose() {
    _subtaskController.dispose();
    // Dispose all edit controllers
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    // Create a new subtask
    final newSubtask = Todo.create(
      title: _subtaskController.text.trim(),
      priority: widget.parentTodo.priority, // Inherit parent priority
      status: 0, // Active
    );

    // Get current subtasks or create empty list
    final currentSubtasks = widget.parentTodo.subtasks ?? [];

    // Create new list with the new subtask
    final updatedSubtasks = [...currentSubtasks, newSubtask];

    // Update parent todo with new subtasks list
    final updatedTodo = widget.parentTodo.copyWith(
      subtasks: updatedSubtasks,
    );

    // Update in repository
    ref
        .read(todoListProvider.notifier)
        .updateTodo(widget.parentTodo.id, updatedTodo);

    // Clear the text field
    _subtaskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Get the latest version of the parent todo
    final latestParentTodo = ref.watch(todoListProvider).firstWhere(
        (todo) => todo.id == widget.parentTodo.id,
        orElse: () => widget.parentTodo);

    // Get subtasks or empty list
    final subtasks = latestParentTodo.subtasks ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // List of existing subtasks
          if (subtasks.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtasks.length,
              itemBuilder: (context, index) {
                final subtask = subtasks[index];
                // Initialize controller for this subtask if needed
                if (!_editControllers.containsKey(subtask.id)) {
                  _editControllers[subtask.id] =
                      TextEditingController(text: subtask.title);
                }

                final bool isEditing = _editingSubtasks[subtask.id] ?? false;

                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 6.0), // Reduced from 8.0
                  child: SwipeableItem(
                    dismissibleKey: Key('subtask-${subtask.id}'),
                    onDelete: () {
                      // Remove this subtask
                      final updatedSubtasks = List<Todo>.from(subtasks);
                      updatedSubtasks.removeAt(index);

                      // Update parent todo
                      final updatedTodo = latestParentTodo.copyWith(
                        subtasks: updatedSubtasks,
                      );

                      // Save to repository
                      ref
                          .read(todoListProvider.notifier)
                          .updateTodo(latestParentTodo.id, updatedTodo);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Toggle editing mode for this subtask
                                setState(() {
                                  _editingSubtasks[subtask.id] = !isEditing;

                                  // Reset controller text if canceling edit
                                  if (!_editingSubtasks[subtask.id]!) {
                                    _editControllers[subtask.id]!.text =
                                        subtask.title;
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 3.0), // Reduced vertical padding
                                child: isEditing
                                    ? TextField(
                                        controller:
                                            _editControllers[subtask.id],
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical:
                                                  6.0), // Reduced from 8.0
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (value) {
                                          if (value.trim().isEmpty) return;

                                          // Update the subtask
                                          final updatedSubtask =
                                              subtask.copyWith(
                                            title: value.trim(),
                                          );

                                          // Update the subtask in the list
                                          final updatedSubtasks =
                                              List<Todo>.from(subtasks);
                                          updatedSubtasks[index] =
                                              updatedSubtask;

                                          // Update parent todo
                                          final updatedTodo =
                                              latestParentTodo.copyWith(
                                            subtasks: updatedSubtasks,
                                          );

                                          // Save to repository
                                          ref
                                              .read(todoListProvider.notifier)
                                              .updateTodo(latestParentTodo.id,
                                                  updatedTodo);

                                          // Exit editing mode
                                          setState(() {
                                            _editingSubtasks[subtask.id] =
                                                false;
                                          });
                                        },
                                      )
                                    : Text(
                                        subtask.title,
                                        style: TextStyle(
                                          decoration: subtask.completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: subtask.completed
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          // Save button when editing
                          if (isEditing)
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final value =
                                    _editControllers[subtask.id]!.text;
                                if (value.trim().isEmpty) return;

                                // Update the subtask
                                final updatedSubtask = subtask.copyWith(
                                  title: value.trim(),
                                );

                                // Update the subtask in the list
                                final updatedSubtasks =
                                    List<Todo>.from(subtasks);
                                updatedSubtasks[index] = updatedSubtask;

                                // Update parent todo
                                final updatedTodo = latestParentTodo.copyWith(
                                  subtasks: updatedSubtasks,
                                );

                                // Save to repository
                                ref.read(todoListProvider.notifier).updateTodo(
                                    latestParentTodo.id, updatedTodo);

                                // Exit editing mode
                                setState(() {
                                  _editingSubtasks[subtask.id] = false;
                                });
                              },
                            ),
                          // Checkbox to mark subtask as completed (only shown when not editing)
                          if (!isEditing)
                            Checkbox(
                              value: subtask.completed,
                              onChanged: (value) {
                                final updatedSubtask = subtask.copyWith(
                                  completed: value ?? false,
                                );

                                // Update the subtask in the list
                                final updatedSubtasks =
                                    List<Todo>.from(subtasks);
                                updatedSubtasks[index] = updatedSubtask;

                                // Update parent todo
                                final updatedTodo = latestParentTodo.copyWith(
                                  subtasks: updatedSubtasks,
                                );

                                // Save to repository
                                ref.read(todoListProvider.notifier).updateTodo(
                                    latestParentTodo.id, updatedTodo);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
          ],

          // Add new subtask row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subtaskController,
                  decoration: const InputDecoration(
                    labelText: 'Subtask',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6.0),
                  ),
                  onSubmitted: (_) => _addSubtask(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addSubtask,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
