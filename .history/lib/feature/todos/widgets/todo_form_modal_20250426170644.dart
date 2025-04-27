import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';
import '../../../shared/widgets/recurring_app_icon.dart';
import 'package:todoApp/core/globals.dart';

/// Enum to define the different types of todos
enum TodoType {
  standard,  // Regular todo with no special behavior
  rollover,   // Todo that rolls over to the next day if not completed
  scheduled   // Todo that is scheduled for specific days of the week
}

/// Provider to track the rollover state for todos
final todoRolloverProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Provider to track the selected days for scheduled todos
final todoScheduledDaysProvider = StateProvider<Set<int>>((ref) => {});

/// Provider to track the type of todo being created/edited
final todoTypeProvider = StateProvider<TodoType>((ref) => TodoType.standard);

// Provider to store the current form values for creating a new todo when dismissed
final todoFormValuesProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'title': '',
  'description': '',
  'priority': 0,
  'type': TodoType.standard,
});

class TodoFormModal extends ConsumerStatefulWidget {
  final Todo? todo;
  final ScrollController? scrollController;
  final TodoType initialType;

  const TodoFormModal({
    Key? key,
    this.todo,
    this.scrollController,
    this.initialType = TodoType.standard,
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
      } else if (widget.todo!.rollover) {
        todoType = TodoType.rollover;
      } else {
        todoType = TodoType.standard;
      }
    }
    
    // Initialize providers based on the todo or initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set the todo type
      ref.read(todoTypeProvider.notifier).state = todoType;
      
      // Set rollover state (only for rollover todos)
      ref.read(todoRolloverProvider.notifier).state = 
          todoType == TodoType.rollover ? true : false;
      
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
    
    switch (todoType) {
      case TodoType.rollover:
        rolloverState = true;
        scheduledDays = {};
        break;
      case TodoType.scheduled:
        rolloverState = false; // Scheduled todos should always have rollover=false
        scheduledDays = ref.read(todoScheduledDaysProvider);
        break;
      case TodoType.standard:
      default:
        rolloverState = false;
        scheduledDays = {};
        break;
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
      talker.debug('[TodoFormModal] Type: $todoType, Rollover: $rolloverState, Scheduled: $scheduledDays');
      
      ref.read(todoListProvider.notifier).updateTodo(updatedTodo.id, updatedTodo);
    } else {
      // For new todos, store the current values in the provider for later use
      ref.read(todoFormValuesProvider.notifier).state = {
        'title': titleController.text,
        'description': descriptionController.text,
        'priority': priority,
        'type': todoType,
        'rollover': rolloverState,
        'scheduled': scheduledDays,
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
              // Only show the rollover icon for rollover todos
              if (todoType == TodoType.rollover)
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            onChanged: _onPriorityChanged,
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
                // Todo Type Selector
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Todo Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Segmented button for todo type selection
                      SegmentedButton<TodoType>(
                        segments: const [
                          ButtonSegment<TodoType>(
                            value: TodoType.standard,
                            label: Text('Standard'),
                            icon: Icon(Icons.check_box_outline_blank),
                          ),
                          ButtonSegment<TodoType>(
                            value: TodoType.rollover,
                            label: Text('Rollover'),
                            icon: Icon(Icons.update),
                          ),
                          ButtonSegment<TodoType>(
                            value: TodoType.scheduled,
                            label: Text('Scheduled'),
                            icon: Icon(Icons.calendar_today),
                          ),
                        ],
                        selected: {ref.watch(todoTypeProvider)},
                        onSelectionChanged: (Set<TodoType> selected) {
                          if (selected.isNotEmpty) {
                            ref.read(todoTypeProvider.notifier).state = selected.first;
                          }
                        },
                      ),
                      
                      // Show appropriate controls based on todo type
                      if (todoType == TodoType.rollover)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              const Text(
                                'Rollover status: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Enabled',
                                style: TextStyle(color: Colors.green),
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
                        _buildDaySelector(),
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
  
  // Build the day selector for scheduled todos
  Widget _buildDaySelector() {
    final Set<int> selectedDays = ref.watch(todoScheduledDaysProvider);
    
    // Day names in order Monday to Sunday
    final List<String> dayNames = [
      'Mon', // Index 0 maps to weekday 1 (Monday)
      'Tue', // Index 1 maps to weekday 2 (Tuesday)
      'Wed', // Index 2 maps to weekday 3 (Wednesday)
      'Thu', // Index 3 maps to weekday 4 (Thursday)
      'Fri', // Index 4 maps to weekday 5 (Friday)
      'Sat', // Index 5 maps to weekday 6 (Saturday)
      'Sun'  // Index 6 maps to weekday 7 (Sunday)
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            'Select days:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: List.generate(7, (index) {
            final weekday = index + 1; // Convert to 1-based weekday
            final isSelected = selectedDays.contains(weekday);
            
            return FilterChip(
              label: Text(dayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                final currentDays = Set<int>.from(selectedDays);
                if (selected) {
                  currentDays.add(weekday);
                } else {
                  currentDays.remove(weekday);
                }
                ref.read(todoScheduledDaysProvider.notifier).state = currentDays;
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade800,
            );
          }),
        ),
      ],
    );
  }
 
  }
}

}

/// Shows a modal bottom sheet to add or edit a todo
void showTodoFormModal(BuildContext context, {Todo? todo, TodoType initialType = TodoType.standard}) {
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
      final todoNotifier = ProviderScope.containerOf(context).read(todoListProvider.notifier);
      final formValues = ProviderScope.containerOf(context).read(todoFormValuesProvider);
      final todoType = ProviderScope.containerOf(context).read(todoTypeProvider);
      
      final titleText = formValues['title'] as String;
      
      // Create and add the todo if title is not empty
      if (titleText.isNotEmpty) {
        // Set rollover and scheduled based on todo type
        bool rollover = false;
        Set<int> scheduled = {};
        
        switch (todoType) {
          case TodoType.rollover:
            rollover = true;
            break;
          case TodoType.scheduled:
            scheduled = ProviderScope.containerOf(context).read(todoScheduledDaysProvider);
            // Validate scheduled days
            if (scheduled.isEmpty) {
              return; // Don't create a scheduled todo with no days selected
            }
            break;
          case TodoType.standard:
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
        talker.debug('[TodoFormModal] Type: $todoType, Rollover: $rollover, Scheduled: $scheduled');
        
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
