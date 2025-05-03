import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';
import '../providers/todo_form_providers.dart';
import '../../../shared/widgets/recurring_app_icon.dart';
import '../../../shared/widgets/day_selector.dart';
import '../../../shared/widgets/priority_slider.dart';

/// Main form modal for creating and editing todos of all types
class TodoFormModal extends ConsumerStatefulWidget {
  final Todo? todo;
  final ScrollController? scrollController;
  final TodoType initialType;

  const TodoFormModal({
    Key? key,
    this.todo,
    this.scrollController,
    this.initialType = TodoType.default_todo,
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

    // Determine the todo type based on the existing todo or initial type
    TodoType todoType = widget.initialType;
    if (widget.todo != null) {
      if (widget.todo!.isScheduled) {
        todoType = TodoType.scheduled;
      } else {
        todoType = TodoType.default_todo;
      }
    }

    // Initialize providers based on the todo or initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set the todo type
      ref.read(todoTypeProvider.notifier).state = todoType;

      // Set rollover state (only for default todos)
      ref.read(todoRolloverProvider.notifier).state =
          widget.todo?.rollover ?? false;

      // Set scheduled days (only for scheduled todos)
      ref.read(todoScheduledDaysProvider.notifier).state =
          widget.todo?.scheduled ?? {};
    });

    // Add listeners to automatically save changes
    titleController.addListener(_saveChanges);
    descriptionController.addListener(_saveChanges);
  }

  @override
  void dispose() {
    // Remove listeners when disposing
    titleController.removeListener(_saveChanges);
    descriptionController.removeListener(_saveChanges);
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Save changes whenever any value changes
  void _saveChanges() {
    // Only save if title is not empty
    if (titleController.text.isEmpty) return;

    final isEditing = widget.todo != null;
    final todoType = ref.read(todoTypeProvider);

    // Get values based on todo type
    final bool rolloverState;
    final Set<int> scheduledDays;

    if (todoType == TodoType.scheduled) {
      rolloverState =
          false; // Scheduled todos should always have rollover=false
      scheduledDays = ref.read(todoScheduledDaysProvider);
    } else {
      rolloverState = ref.read(todoRolloverProvider);
      scheduledDays = {};
    }

    if (isEditing) {
      // For editing, update the existing todo with copyWith
      final updatedTodo = widget.todo!.copyWith(
        title: titleController.text,
        description: descriptionController.text,
        priority: priority,
        rollover: rolloverState,
        scheduled: scheduledDays,
      );

      talker.debug('[TodoFormModal] Updating todo: ${updatedTodo.title}');
      talker.debug(
          '[TodoFormModal] Type: $todoType, Rollover: $rolloverState, Scheduled: $scheduledDays');

      ref
          .read(todoListProvider.notifier)
          .updateTodo(updatedTodo.id, updatedTodo);
    } else {
      // For new todos, store form values in provider for potential save on dismiss
      ref.read(todoFormValuesProvider.notifier).state = {
        'title': titleController.text,
        'description': descriptionController.text,
        'priority': priority,
        'type': ref.read(todoTypeProvider),
      };
    }
  }

  // Save changes when priority changes
  void _onPriorityChanged(double value) {
    setState(() {
      priority = value.toInt();
    });
    _saveChanges();
  }

  // Create and save a new todo
  void _saveTodo() {
    // Make sure form values are saved
    _saveChanges();

    // For new todos, create a new todo if form values exist
    if (widget.todo == null) {
      final formValues = ref.read(todoFormValuesProvider);
      if (formValues['title']?.isNotEmpty ?? false) {
        final TodoType type =
            formValues['type'] as TodoType? ?? TodoType.default_todo;

        // Build the todo based on type
        final newTodo = Todo.create(
          title: formValues['title'] as String,
          description: formValues['description'] as String?,
          priority: (formValues['priority'] as int?) ?? 0,
          rollover: type == TodoType.default_todo
              ? ref.read(todoRolloverProvider)
              : false,
          scheduled: type == TodoType.scheduled
              ? ref.read(todoScheduledDaysProvider)
              : <int>{},
        );

        // Add the new todo
        ref.read(todoListProvider.notifier).addTodo(newTodo);
        talker.debug('[TodoFormModal] Created new todo: ${newTodo.title}');
      }
    }

    // Close the modal
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;
    final todoType = ref.watch(todoTypeProvider);

    // Listen to rollover changes to trigger save
    ref.listen(todoRolloverProvider, (previous, current) {
      if (previous != current) {
        _saveChanges();
      }
    });

    // Listen to scheduled days changes to trigger save
    ref.listen(todoScheduledDaysProvider, (previous, current) {
      if (previous != current) {
        _saveChanges();
      }
    });

    // Listen to todo type changes to trigger save
    ref.listen(todoTypeProvider, (previous, current) {
      if (previous != current) {
        _saveChanges();
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, 0), // Remove bottom padding for buttons
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

          // Title and Todo Type Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Todo' : 'Add Todo',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Only show the rollover icon for default todos
              if (todoType == TodoType.default_todo)
                SquareAppIcon(
                  iconAsset: 'assets/icons/rock-hill.png',
                  activationProvider: todoRolloverProvider,
                  size: 40.0,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  maxLines: 4,
                ),

                const SizedBox(height: 24),

                // Priority selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      priority == 0
                          ? 'Low'
                          : priority == 1
                              ? 'Medium'
                              : 'High',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: priority == 0
                            ? Colors.green
                            : priority == 1
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Priority slider
                PrioritySlider(
                  priority: priority,
                  onChanged: _onPriorityChanged,
                ),

                const SizedBox(height: 24),

                // Rollover status (only for default todos)
                if (todoType == TodoType.default_todo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rollover status: ${ref.watch(todoRolloverProvider) ? 'Enabled' : 'Disabled'}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: ref.watch(todoRolloverProvider)
                                  ? Colors.green
                                  : Colors.grey),
                        ),
                        SquareAppIcon(
                          iconAsset: 'assets/icons/rock-hill.png',
                          activationProvider: todoRolloverProvider,
                          size: 30.0,
                        ),
                      ],
                    ),
                  ),

                // Day selector for scheduled todos
                if (todoType == TodoType.scheduled)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select days:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DaySelector(
                        selectedDays: ref.watch(todoScheduledDaysProvider),
                        onDaysChanged: (days) {
                          ref.read(todoScheduledDaysProvider.notifier).state =
                              days;
                        },
                      ),
                    ],
                  ),

                // Add some bottom spacing after form
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom buttons section - moved to bottom of screen with better styling
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  // Cancel button - simple text style
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cancel and close modal
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600, // Bolder text
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Save button - more prominent
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTodo, // Use the dedicated save method
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFB8860B), // Gold/bronze
                        foregroundColor: Colors.white,
                        elevation:
                            5, // Increased elevation for better visibility
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600, // Bolder text
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet to add or edit a todo
void showTodoFormModal(BuildContext context,
    {Todo? todo, TodoType initialType = TodoType.default_todo}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true, // Allow dismiss by tapping outside but no auto-save
    enableDrag: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => GestureDetector(
      // This gesture detector ensures taps don't propagate through the modal
      onTap: () {}, // Empty callback to intercept taps inside the modal
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6, // Increased size to accommodate type selector
        minChildSize: 0.4,
        maxChildSize: 0.8,
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
            initialType: initialType,
          ),
        ),
      ),
    ),
  );
  // Auto-save on dismiss functionality is removed to prevent double saves
}

/// Shows a modal bottom sheet specifically for adding a scheduled/recurring task
void showScheduledTaskModal(BuildContext context) {
  showTodoFormModal(context, initialType: TodoType.scheduled);
}

/// Shows a modal bottom sheet specifically for adding a rollover task
void showRolloverTaskModal(BuildContext context) {
  showTodoFormModal(context, initialType: TodoType.default_todo);
}
