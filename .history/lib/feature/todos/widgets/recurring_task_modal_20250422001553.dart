import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/utils/show_snack_bar.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';

/// Shows a modal bottom sheet to add a recurring task
void showRecurringTaskModal(BuildContext context) {
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
        height:
            MediaQuery.of(context).size.height * 0.65, // Increased height by 10
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: RecurringTaskModal(
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

class RecurringTaskModal extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const RecurringTaskModal({
    Key? key,
    this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<RecurringTaskModal> createState() => _RecurringTaskModalState();
}

class _RecurringTaskModalState extends ConsumerState<RecurringTaskModal> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  int priority = 0;

  // Days of the week selection (Sunday = 0, Saturday = 6)
  final List<bool> selectedDays = List.generate(7, (_) => false);

  // Day names
  final List<String> dayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
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
          const Text(
            'Recurring Task',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 16),
                // Day of week picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repeat on',
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDays[index] = !selectedDays[index];
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selectedDays[index]
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                dayNames[index],
                                style: TextStyle(
                                  color: selectedDays[index]
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
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

                  if (!selectedDays.contains(true)) {
                    NotificationService.showNotification(
                        'Please select at least one day');
                    return;
                  }

                  // Create a new recurring todo
                  final todo = Todo.create(
                    title: titleController.text,
                    description: descriptionController.text,
                    priority: priority,
                    rollover: true, // Recurring tasks are always rollover
                    // Store the selected days in the scheduled property
                    scheduled: selectedDays.where((day) => day).length,
                    // We could also add subtasks here if needed
                    subtasks: [],
                  );
                  print(todo.scheduled);

                  // Add the todo
                  ref.read(todoListProvider.notifier).addTodo(todo);

                  // Show success message
                  NotificationService.showNotification('Recurring task added');

                  Navigator.of(context).pop();
                },
                child: const Text('Add Recurring Task'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
