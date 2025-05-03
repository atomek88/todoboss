import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/todos_provider.dart';
import '../../../../shared/utils/theme/theme_extension.dart';
import '../../../../shared/widgets/swipeable_item.dart';
import '../../../../core/providers/date_provider.dart';
import '../../../daily_todos/providers/daily_todos_provider.dart';
import '../../../../core/globals.dart';

/// A more minimalist version of the subtask section
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
  final FocusNode _addSubtaskFocusNode = FocusNode();

  // Map to track which subtasks are being edited
  final Map<String, bool> _editingSubtasks = {};

  // Controllers for editing existing subtasks
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    // Request focus on the subtask field when there are no subtasks
    if (!widget.parentTodo.hasSubtasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addSubtaskFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    _addSubtaskFocusNode.dispose();
    // Dispose all edit controllers
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    // Create a new subtask with current timestamp
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

    // Update the dailyTodo to ensure changes are reflected in all relevant providers
    // Get normalized dates for proper synchronization
    final currentDate = normalizeDate(DateTime.now());
    final selectedDate = normalizeDate(ref.read(selectedDateProvider));

    talker.debug('📌 [TodoSubtaskSection] Current date: $currentDate');
    talker.debug('📌 [TodoSubtaskSection] Selected date: $selectedDate');

    // Always refresh for the selected date to ensure UI consistency
    ref
        .read(dailyTodoProvider.notifier)
        .refreshTodoForDate(selectedDate, updatedTodo);

    // If selected date is different from current date, also refresh for current date
    // This ensures proper synchronization across different date views
    if (!currentDate.isAtSameMomentAs(selectedDate)) {
      talker.debug(
          '📌 [TodoSubtaskSection] Dates don\'t match, refreshing both dates');
      ref
          .read(dailyTodoProvider.notifier)
          .refreshTodoForDate(currentDate, updatedTodo);
    }

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Clear the text field
    _subtaskController.clear();

    // Keep focus on the input field for easy sequential adding
    _addSubtaskFocusNode.requestFocus();

    talker.debug(
        '📌 [TodoSubtaskSection] Added subtask to ${widget.parentTodo.title}. Total: ${updatedSubtasks.length}');
  }

  // Helper method to get priority color
  Color _getPriorityColor(int priority) {
    switch (priority) {
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
    // Get the latest version of the parent todo
    final latestParentTodo = ref.watch(todoListProvider).firstWhere(
        (todo) => todo.id == widget.parentTodo.id,
        orElse: () => widget.parentTodo);

    // Get subtasks or empty list
    final subtasks = latestParentTodo.subtasks ?? [];

    // Get the priority color for styling
    final priorityColor = _getPriorityColor(latestParentTodo.priority);

    // Calculate completion stats
    final completedCount = subtasks.where((s) => s.completed).length;
    final totalCount = subtasks.length;
    final completionPercentage =
        totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimal header with completion indicator
        if (subtasks.isNotEmpty) ...[
          // Progress bar and count
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                // Progress bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: LinearProgressIndicator(
                      value: completionPercentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                      minHeight: 4.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Count
                Text(
                  '$completedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],

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
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
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

                    // Update the dailyTodo to ensure changes are reflected
                    // Get normalized dates for proper synchronization
                    final currentDate = normalizeDate(DateTime.now());
                    final selectedDate =
                        normalizeDate(ref.read(selectedDateProvider));

                    talker.debug(
                        '📌 [TodoSubtaskSection] Deleting subtask - Current date: $currentDate');
                    talker.debug(
                        '📌 [TodoSubtaskSection] Deleting subtask - Selected date: $selectedDate');

                    // Always refresh for the selected date to ensure UI consistency
                    ref
                        .read(dailyTodoProvider.notifier)
                        .refreshTodoForDate(selectedDate, updatedTodo);

                    // If selected date is different from current date, also refresh for current date
                    if (!currentDate.isAtSameMomentAs(selectedDate)) {
                      talker.debug(
                          '📌 [TodoSubtaskSection] Dates don\'t match, refreshing both dates');
                      ref
                          .read(dailyTodoProvider.notifier)
                          .refreshTodoForDate(currentDate, updatedTodo);
                    }

                    // Haptic feedback for deletion
                    HapticFeedback.mediumImpact();

                    talker.debug(
                        '📌 [TodoSubtaskSection] Removed subtask from ${latestParentTodo.title}');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        // Minimalist checkbox to mark subtask as completed (only shown when not editing)
                        if (!isEditing)
                          Transform.scale(
                            scale: 0.85, // Slightly smaller checkbox
                            child: Checkbox(
                              value: subtask.completed,
                              activeColor: priorityColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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

                                // Update the dailyTodo to ensure changes are reflected
                                // Get normalized dates for proper synchronization
                                final currentDate =
                                    normalizeDate(DateTime.now());
                                final selectedDate = normalizeDate(
                                    ref.read(selectedDateProvider));

                                talker.debug(
                                    '📌 [TodoSubtaskSection] Toggling completion - Current date: $currentDate');
                                talker.debug(
                                    '📌 [TodoSubtaskSection] Toggling completion - Selected date: $selectedDate');

                                // Always refresh for the selected date to ensure UI consistency
                                ref
                                    .read(dailyTodoProvider.notifier)
                                    .refreshTodoForDate(
                                        selectedDate, updatedTodo);

                                // If selected date is different from current date, also refresh for current date
                                if (!currentDate
                                    .isAtSameMomentAs(selectedDate)) {
                                  talker.debug(
                                      '📌 [TodoSubtaskSection] Dates don\'t match, refreshing both dates');
                                  ref
                                      .read(dailyTodoProvider.notifier)
                                      .refreshTodoForDate(
                                          currentDate, updatedTodo);
                                }

                                // Haptic feedback
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),

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
                                      controller: _editControllers[subtask.id],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 6.0), // Reduced from 8.0
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (value) {
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
                                          _editingSubtasks[subtask.id] = false;
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
                            icon: const Icon(Icons.check, color: Colors.green),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              final value = _editControllers[subtask.id]!.text;
                              if (value.trim().isEmpty) return;

                              // Update the subtask
                              final updatedSubtask = subtask.copyWith(
                                title: value.trim(),
                              );

                              // Update the subtask in the list
                              final updatedSubtasks = List<Todo>.from(subtasks);
                              updatedSubtasks[index] = updatedSubtask;

                              // Update parent todo
                              final updatedTodo = latestParentTodo.copyWith(
                                subtasks: updatedSubtasks,
                              );

                              // Save to repository
                              ref
                                  .read(todoListProvider.notifier)
                                  .updateTodo(latestParentTodo.id, updatedTodo);

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
                              final updatedSubtasks = List<Todo>.from(subtasks);
                              updatedSubtasks[index] = updatedSubtask;

                              // Update parent todo
                              final updatedTodo = latestParentTodo.copyWith(
                                subtasks: updatedSubtasks,
                              );

                              // Save to repository
                              ref
                                  .read(todoListProvider.notifier)
                                  .updateTodo(latestParentTodo.id, updatedTodo);
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

        // Add new subtask row with indentation to match list items
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _subtaskController,
                      focusNode: _addSubtaskFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Add a subtask...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: priorityColor,
                    size: 28,
                  ),
                  splashRadius: 24,
                  onPressed: _addSubtask,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
