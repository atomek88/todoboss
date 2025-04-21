import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';

class TodoFormModal extends ConsumerStatefulWidget {
  final Todo? todo;
  final int? index;
  final ScrollController? scrollController;

  const TodoFormModal({
    Key? key,
    this.todo,
    this.index,
    this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<TodoFormModal> createState() => _TodoFormModalState();
}

class _TodoFormModalState extends ConsumerState<TodoFormModal> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  int priority = 0;
  bool rollover = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.todo?.title ?? '');
    descriptionController = TextEditingController(text: widget.todo?.description ?? '');
    priority = widget.todo?.priority ?? 0;
    rollover = widget.todo?.rollover ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
  
  // Get the color based on priority level
  Color _getPriorityColor(int priorityLevel) {
    switch (priorityLevel) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.amberAccent;
      default:
        return const Color.fromARGB(255, 105, 240, 174);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar at the top
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Title
          Text(
            isEditing ? 'Edit Task' : 'Add Task',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Form fields in a scrollable container
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.zero,
              children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Priority slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Priority', style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 10,
                    activeTrackColor: _getPriorityColor(priority),
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayColor: _getPriorityColor(priority).withOpacity(0.2),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Column(
                    children: [
                      Slider(
                        value: priority.toDouble(),
                        min: 0,
                        max: 2,
                        divisions: 2,
                        onChanged: (value) {
                          setState(() {
                            priority = value.toInt();
                          });
                        },
                      ),
                      // Labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Low', 
                              style: TextStyle(
                                fontWeight: priority == 0 ? FontWeight.bold : FontWeight.normal,
                                color: priority == 0 ? const Color.fromARGB(255, 105, 240, 174) : Colors.grey.shade600,
                              ),
                            ),
                            Text('Medium', 
                              style: TextStyle(
                                fontWeight: priority == 1 ? FontWeight.bold : FontWeight.normal,
                                color: priority == 1 ? Colors.amberAccent.shade700 : Colors.grey.shade600,
                              ),
                            ),
                            Text('High', 
                              style: TextStyle(
                                fontWeight: priority == 2 ? FontWeight.bold : FontWeight.normal,
                                color: priority == 2 ? Colors.redAccent : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: rollover,
              onChanged: (val) {
                setState(() {
                  rollover = val ?? false;
                });
              },
              title: const Text('Rollover'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.blue,
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.blue.withOpacity(0.1);
                      }
                      return null;
                    },
                  ),
                ),
                onPressed: () {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title cannot be empty')),
                    );
                    return;
                  }
                  
                  final Todo todo;
                  
                  if (isEditing) {
                    // For editing, use Todo.withId to preserve the original ID
                    todo = Todo.withId(
                      id: widget.todo!.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      priority: priority,
                      rollover: rollover,
                      status: widget.todo!.status,
                      createdAt: widget.todo!.createdAt,
                      endedOn: widget.todo!.endedOn,
                    );
                  } else {
                    // For new todos, use the default constructor
                    todo = Todo(
                      title: titleController.text,
                      description: descriptionController.text,
                      priority: priority,
                      rollover: rollover,
                    );
                  }

                  if (isEditing && widget.index != null) {
                    ref.read(todoListProvider.notifier).updateTodo(widget.index!, todo);
                  } else {
                    ref.read(todoListProvider.notifier).addTodo(todo);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(isEditing ? 'Save Changes' : 'Add Task'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet to add or edit a todo
void showTodoFormModal(BuildContext context, {Todo? todo, int? index}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    // Ensure clicking outside dismisses the modal
    barrierColor: Colors.black54,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TodoFormModal(
          todo: todo,
          index: index,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}
