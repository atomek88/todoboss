import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';
import '../../shared/widgets/recurring_app_icon.dart';

/// Provider to track the rollover state for todos
final todoRolloverProvider = StateProvider.autoDispose<bool>((ref) => false);

class TodoFormModal extends ConsumerStatefulWidget {
  final Todo? todo;
  final ScrollController? scrollController;

  const TodoFormModal({
    Key? key,
    this.todo,
    this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<TodoFormModal> createState() => _TodoFormModalState();
}

class _TodoFormModalState extends ConsumerState<TodoFormModal> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  int priority = 0;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.todo?.title ?? '');
    descriptionController =
        TextEditingController(text: widget.todo?.description ?? '');
    priority = widget.todo?.priority ?? 0;

    // Initialize the rollover state provider with the todo's value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todoRolloverProvider.notifier).state =
          widget.todo?.rollover ?? false;
    });
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
          // Title and Rollover Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'Add Task',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Rock Hill Icon for rollover
              SquareAppIcon(
                iconAsset: 'assets/icons/rock-hill.png',
                activationProvider: todoRolloverProvider,
                size: 40.0,
                onStateChanged: () {
                  final isActivated = ref.read(todoRolloverProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Rollover ${isActivated ? 'enabled' : 'disabled'}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
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
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                    const Text('Priority',
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 10,
                        activeTrackColor: _getPriorityColor(priority),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 12),
                        overlayColor:
                            _getPriorityColor(priority).withOpacity(0.2),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 20),
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
                                Text(
                                  'Low',
                                  style: TextStyle(
                                    fontWeight: priority == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: priority == 0
                                        ? const Color.fromARGB(
                                            255, 105, 240, 174)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Medium',
                                  style: TextStyle(
                                    fontWeight: priority == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: priority == 1
                                        ? Colors.amberAccent.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'High',
                                  style: TextStyle(
                                    fontWeight: priority == 2
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: priority == 2
                                        ? Colors.redAccent
                                        : Colors.grey.shade600,
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
                        ref.watch(todoRolloverProvider)
                            ? 'Enabled'
                            : 'Disabled',
                        style: TextStyle(
                          color: ref.watch(todoRolloverProvider)
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Toggle icon to change',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
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

                  // Get the current rollover state from the provider
                  final rolloverState = ref.read(todoRolloverProvider);

                  if (isEditing) {
                    // For editing, update the existing todo with copyWith
                    todo = widget.todo!.copyWith(
                      title: titleController.text,
                      description: descriptionController.text,
                      priority: priority,
                      rollover: rolloverState,
                    );
                  } else {
                    // For new todos, use the create factory
                    todo = Todo.create(
                      title: titleController.text,
                      description: descriptionController.text,
                      priority: priority,
                      rollover: rolloverState,
                    );
                  }

                  if (isEditing) {
                    ref
                        .read(todoListProvider.notifier)
                        .updateTodo(todo.id, todo);
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
void showTodoFormModal(BuildContext context, {Todo? todo}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true, // Allow dismiss by tapping outside
    enableDrag: true,
    backgroundColor: Colors.transparent,
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
          scrollController: scrollController,
        ),
      ),
    ),
  );
}
