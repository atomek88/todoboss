import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';
import 'package:todoApp/shared/utils/show_snack_bar.dart';
import 'package:todoApp/shared/widgets/swipeable_date_picker.dart';
import 'package:todoApp/shared/providers/selected_date_provider.dart';
import 'package:todoApp/shared/widgets/confetti_celebration.dart';
import '../services/todo_date_filter_service.dart';
import 'package:flutter/foundation.dart';
import '../providers/todos_provider.dart';
import '../providers/todo_goal_provider.dart';
import '../models/todo.dart';
import '../widgets/todo_form_modal.dart';
import '../widgets/todo_list_item.dart';
import '../../../shared/widgets/undo_button.dart';
import '../../voice/widgets/voice_recording_button.dart';

@RoutePage()
class TodosHomePage extends ConsumerStatefulWidget {
  const TodosHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TodosHomePage> createState() => _TodosHomePageState();
}

// Provider to track if goal celebration is active
final _goalCelebrationProvider = StateProvider<bool>((ref) => false);

class _TodosHomePageState extends ConsumerState<TodosHomePage> {
  // Store the last deleted todo for undo functionality
  Todo? _lastDeletedTodo;
  String? _lastDeletedId;
  bool _showDeleteUndoButton = false;

  // Store the last completed todo for undo functionality
  Todo? _lastCompletedTodo;
  String? _lastCompletedId;
  bool _showCompleteUndoButton = false;

  @override
  Widget build(BuildContext context) {
    // Get all todos and the selected date
    final todos = ref.watch(todoListProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // Filter todos by status for counters
    final completedCount = todos.where((Todo todo) => todo.status == 1).length;
    final deletedCount = todos.where((Todo todo) => todo.status == 2).length;

    // Maximum number of todos for the counter
    final maxTodos = ref.watch(todoGoalProvider);

    // Check if completed count exceeds goal and trigger celebration
    if (completedCount >= maxTodos) {
      debugPrint(
          '🎉 GOAL ACHIEVED! Completed todos ($completedCount) >= Goal ($maxTodos)');
      // Only trigger celebration if not already celebrating
      if (!ref.read(_goalCelebrationProvider)) {
        // Set a small delay to ensure UI is built before showing celebration
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ref.read(_goalCelebrationProvider.notifier).state = true;
            // Auto-dismiss celebration after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                ref.read(_goalCelebrationProvider.notifier).state = false;
              }
            });
          }
        });
      }
    }

    // Get todos for the selected date using the TodoDateFilterService
    final activeTodos =
        TodoDateFilterService.getTodosForDate(todos, selectedDate);

    // Watch celebration state
    final showCelebration = ref.watch(_goalCelebrationProvider);

    return ConfettiCelebration(
      isPlaying: showCelebration,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: const Text('Todo List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                context.pushRoute(const ProfileWrapperRoute());
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // SwipeableDatePicker moved from AppBar to body
            const SwipeableDatePicker(
              height: 80,
              mainDateTextStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
              adjacentDateTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xB3000000), // Black with 70% opacity
                letterSpacing: 0.3,
              ),
              maxDaysForward: 7, // Limit to one week forward
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deleted',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        AnimatedCounter(
                            count: deletedCount,
                            total: maxTodos,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text('Completed',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      AnimatedCounter(
                          count: completedCount,
                          total: maxTodos,
                          color: completedCount >= maxTodos
                              ? Colors.amber
                              : Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: activeTodos.isEmpty
                  ? const Center(child: Text('No active tasks'))
                  : ListView.builder(
                      itemCount: activeTodos.length,
                      itemBuilder: (context, index) {
                        final todo = activeTodos[index];
                        // Find the original index in the full todos list
                        return TodoListItem(
                          todo: todo,
                          onComplete: (todo) {
                            // Store the completed todo for potential undo
                            setState(() {
                              _lastCompletedTodo = todo;
                              _lastCompletedId = todo.id;
                              _showCompleteUndoButton = true;
                            });

                            // Count subtasks for completion counter
                            final subtaskCount = todo.subtasks?.length ?? 0;
                            final completionMessage = subtaskCount > 0
                                ? '"${todo.title}" and $subtaskCount subtasks marked as completed'
                                : '"${todo.title}" marked as completed';

                            // Complete the todo
                            ref
                                .read(todoListProvider.notifier)
                                .completeTodo(todo.id);

                            // If there are subtasks, mark them all as completed too
                            // This is just for the counter - they're already visually completed
                            // when the parent is completed

                            // Use Future.delayed to show the snackbar after the animation completes
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              if (context.mounted) {
                                NotificationService.showNotification(
                                    completionMessage);
                              }
                            });
                          },
                          onDelete: (todo) {
                            // Store the deleted todo for potential undo
                            setState(() {
                              _lastDeletedTodo = todo;
                              _lastDeletedId = todo.id;
                              _showDeleteUndoButton = true;
                            });

                            // Delete the todo
                            ref
                                .read(todoListProvider.notifier)
                                .deleteTodo(todo.id);

                            NotificationService.showNotification(
                                '"${todo.title}" moved to trash');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Undo button for completed todos
            if (_showCompleteUndoButton)
              UndoButton(
                label: 'Undo Complete',
                onPressed: () {
                  if (_lastCompletedTodo != null && _lastCompletedId != null) {
                    // Create a copy of the todo with status set back to active
                    final restoredTodo = _lastCompletedTodo!.copyWith(
                      status: 0, // Set back to active
                      endedOn: null, // Clear completion date
                    );

                    // Update the todo
                    ref.read(todoListProvider.notifier).updateTodo(
                          _lastCompletedId!,
                          restoredTodo,
                        );

                    // Hide the undo button
                    setState(() {
                      _showCompleteUndoButton = false;
                      _lastCompletedTodo = null;
                      _lastCompletedId = null;
                    });

                    NotificationService.showNotification(
                        'Task marked as active');
                  }
                },
                onDurationEnd: () {
                  if (mounted) {
                    setState(() {
                      _showCompleteUndoButton = false;
                      _lastCompletedTodo = null;
                      _lastCompletedId = null;
                    });
                  }
                },
                // Use the same grey styling for consistency
                backgroundColor: Colors.grey[700],
              ),

            // Undo button for deleted todos
            if (_showDeleteUndoButton)
              UndoButton(
                label: 'Undo Delete',
                onPressed: () {
                  if (_lastDeletedTodo != null && _lastDeletedId != null) {
                    // Restore the deleted todo
                    ref
                        .read(todoListProvider.notifier)
                        .restoreTodo(_lastDeletedId!);

                    // Hide the undo button
                    setState(() {
                      _showDeleteUndoButton = false;
                      _lastDeletedTodo = null;
                      _lastDeletedId = null;
                    });

                    NotificationService.showNotification('Todo restored');
                  }
                },
                onDurationEnd: () {
                  if (mounted) {
                    setState(() {
                      _showDeleteUndoButton = false;
                      _lastDeletedTodo = null;
                      _lastDeletedId = null;
                    });
                  }
                },
              ),
            // Voice recording button - with unique hero tag
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: VoiceRecordingButton(
                heroTag: 'todosHomePageVoiceButton',
                onTodoCreated: (todo, transcription) {
                  // Show a more detailed snackbar
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Todo created from voice:'),
                            Text(todo.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (todo.description != null &&
                                todo.description!.isNotEmpty)
                              Text(todo.description!,
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } catch (e) {
                    // Handle case where ScaffoldMessenger is not available
                    debugPrint('Error showing SnackBar: $e');
                  }
                },
              ),
            ),
            // Regular add button with unique hero tag
            FloatingActionButton(
              heroTag: 'todosHomePageAddButton',
              onPressed: () {
                showTodoFormModal(context);
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int count;
  final int total;
  final Color color;
  const AnimatedCounter(
      {super.key,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    // For deleted tasks, don't show the total
    final displayText = color == Colors.grey ? '$count' : '$count/$total';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        displayText,
        key: ValueKey(count),
        style:
            TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
