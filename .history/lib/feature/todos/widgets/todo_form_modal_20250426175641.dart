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
                PrioritySlider(
                  priority: priority,
                  onChanged: _onPriorityChanged,
                ),
                const SizedBox(height: 12),
                // Show appropriate controls based on todo type
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // For default todos, show rollover toggle
                      if (todoType == TodoType.default_todo)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
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
                                        : Colors.grey),
                              ),
                              const Spacer(),
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
                        DaySelector(
                          selectedDays: ref.watch(todoScheduledDaysProvider),
                          onDaysChanged: (days) {
                            ref.read(todoScheduledDaysProvider.notifier).state =
                                days;
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Note about auto-saving
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                isEditing
                    ? 'Changes are saved automatically'
                    : 'Swipe down to save and dismiss',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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
    isDismissible: true, // Allow dismiss by tapping outside
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => DraggableScrollableSheet(
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
  ).then((_) {
    // When modal is dismissed, check if we need to create a new todo
    if (todo == null) {
      // Get the current values from the providers
      final todoNotifier =
          ProviderScope.containerOf(context).read(todoListProvider.notifier);
      final formValues =
          ProviderScope.containerOf(context).read(todoFormValuesProvider);
      final todoType =
          ProviderScope.containerOf(context).read(todoTypeProvider);

      final titleText = formValues['title'] as String;

      // Create and add the todo if title is not empty
      if (titleText.isNotEmpty) {
        // Set rollover and scheduled based on todo type
        bool rollover = false;
        Set<int> scheduled = {};

        switch (todoType) {
          case TodoType.scheduled:
            scheduled = ProviderScope.containerOf(context)
                .read(todoScheduledDaysProvider);
            // Validate scheduled days
            if (scheduled.isEmpty) {
              return; // Don't create a scheduled todo with no days selected
            }
            break;
          case TodoType.default_todo:
          default:
            break;
        }

        final newTodo = Todo.create(
          title: titleText,
          description: formValues['description'] as String,
          priority: formValues['priority'] as int,
          rollover: rollover,
          scheduled: scheduled,
        );

        talker.debug('[TodoFormModal] Creating new todo: ${newTodo.title}');
        talker.debug(
            '[TodoFormModal] Type: $todoType, Rollover: $rollover, Scheduled: $scheduled');

        todoNotifier.addTodo(newTodo);
      }
    }
  });
}

/// Shows a modal bottom sheet specifically for adding a scheduled/recurring task
void showScheduledTaskModal(BuildContext context) {
  showTodoFormModal(context, initialType: TodoType.scheduled);
}

/// Shows a modal bottom sheet specifically for adding a rollover task
void showRolloverTaskModal(BuildContext context) {
  showTodoFormModal(context, initialType: TodoType.rollover);
}
