import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';
import 'package:todoApp/feature/todos/providers/todo_date_provider.dart';
import 'package:todoApp/feature/todos/views/past_date_page.dart';
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
import '../../goals/providers/daily_goal_provider.dart';
import '../../voice/providers/date_provider.dart';

@RoutePage()
class TodosHomePage extends ConsumerStatefulWidget {
  const TodosHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TodosHomePage> createState() => _TodosHomePageState();
}

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
  void initState() {
    super.initState();
    // Schedule a microtask to update goals after the first build
    Future.microtask(() => _updateGoals());
  }

  @override
  void didUpdateWidget(TodosHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Schedule a microtask to update goals after rebuild
    Future.microtask(() => _updateGoals());
  }

  // Update the daily goal achievement outside the build method
  void _updateGoals() {
    final selectedDate = ref.read(selectedDateProvider);
    final allTodos = ref.read(todoListProvider);
    final completedCount =
        allTodos.where((Todo todo) => todo.status == 1).length;

    // Update the daily goal achievement outside the build method
    ref
        .read(dailyGoalAchievementProvider.notifier)
        .updateCompletedCount(selectedDate, completedCount);

    // Also update TodoDate counters
    _updateTodoDateCounters();
  }

  // Update TodoDate counters based on todos
  void _updateTodoDateCounters() {
    final selectedDate = ref.read(selectedDateProvider);
    final allTodos = ref.read(todoListProvider);

    // Update TodoDate counters
    ref.read(todoDateProvider.notifier).updateCounters(allTodos);
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered todos and the selected date
    final filteredTodos = ref.watch(filteredTodosProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // Get all todos for counters
    final allTodos = ref.watch(todoListProvider);
    final completedCount =
        allTodos.where((Todo todo) => todo.status == 1).length;
    final deletedCount = allTodos.where((Todo todo) => todo.status == 2).length;

    // Get the daily todo goal
    final dailyTodoGoal = ref.watch(todoGoalProvider);

    // Check if we should show celebration
    final shouldCelebrate = ref
        .watch(dailyGoalAchievementProvider.notifier)
        .shouldShowCelebration(selectedDate);

    // If we should celebrate, mark it as shown after the celebration completes
    if (shouldCelebrate) {
      debugPrint(
          '🎉 GOAL ACHIEVED! Completed todos ($completedCount) >= Goal ($dailyTodoGoal)');
    }

    // Filtered todos are already available from the provider
    final activeTodos = filteredTodos;

    // Watch celebration state from provider
    final showCelebration = shouldCelebrate;

    return ConfettiCelebration(
      isPlaying: showCelebration,
      maxCycles: 2,
      onComplete: () {
        // Mark the celebration as shown when animation completes
        if (showCelebration) {
          ref
              .read(dailyGoalAchievementProvider.notifier)
              .markCelebrationShown(selectedDate);
        }
      },
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header with date picker and profile icon
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Row(
                    children: [
                      // SwipeableDatePicker takes most of the space
                      const Expanded(
                        child: SwipeableDatePicker(
                          height: 70, // Slightly reduced height
                          mainDateTextStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                          adjacentDateTextStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xB3000000), // Black with 70% opacity
                            letterSpacing: 0.3,
                          ),
                          maxDaysForward: 7, // Limit to one week forward
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Todo date stats card
                Consumer(
                  builder: (context, ref, child) {
                    final todoDateAsync = ref.watch(todoDateProvider);

                    return todoDateAsync.when(
                      data: (todoDate) {
                        if (todoDate == null) {
                          return const SizedBox(height: 8);
                        }

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Daily Stats',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(width: 20),
                                    // Today button
                                    AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      opacity: DateUtils.isSameDay(selectedDate,
                                              ref.watch(currentDateProvider))
                                          ? 0.3
                                          : 1.0,
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.calendar_today_rounded),
                                        tooltip: 'Go to Today',
                                        onPressed: () {
                                          if (!DateUtils.isSameDay(selectedDate,
                                              ref.read(currentDateProvider))) {
                                            // Provide haptic feedback when changing date
                                            HapticFeedback.selectionClick();
                                            ref
                                                .read(selectedDateProvider
                                                    .notifier)
                                                .setDate(ref
                                                    .read(currentDateProvider));
                                          }
                                        },
                                      ),
                                    ),
                                    // History button for past dates
                                    IconButton(
                                      icon:
                                          const Icon(Icons.calendar_view_month),
                                      tooltip: 'View Past Dates',
                                      onPressed: () {
                                        // Show a date picker to select past dates
                                        showDatePicker(
                                          context: context,
                                          initialDate: ref
                                              .read(currentDateProvider)
                                              .subtract(
                                                  const Duration(days: 1)),
                                          firstDate: ref
                                              .read(currentDateProvider)
                                              .subtract(
                                                  const Duration(days: 365)),
                                          lastDate: ref
                                              .read(currentDateProvider)
                                              .subtract(
                                                  const Duration(days: 1)),
                                        ).then((selectedDate) {
                                          if (selectedDate != null) {
                                            // Navigate to the past date page with the selected date
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PastDatePage(
                                                        date: selectedDate),
                                              ),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    // Profile icon button
                                    Container(
                                      margin: const EdgeInsets.only(left: 0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.person_outline),
                                        onPressed: () {
                                          context.pushRoute(
                                              const ProfileWrapperRoute());
                                        },
                                        tooltip: 'Profile',
                                        iconSize: 26,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Completed counter
                                    Column(
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            color: Colors.green),
                                        const SizedBox(height: 4),
                                        Text('${todoDate.completedTodosCount}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const Text('Completed'),
                                      ],
                                    ),
                                    // Goal counter
                                    Column(
                                      children: [
                                        const Icon(Icons.flag_outlined,
                                            color: Colors.blue),
                                        const SizedBox(height: 4),
                                        Text('${todoDate.taskGoal}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const Text('Goal'),
                                      ],
                                    ),
                                    // Deleted counter
                                    Column(
                                      children: [
                                        const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        const SizedBox(height: 4),
                                        Text('${todoDate.deletedTodosCount}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const Text('Deleted'),
                                      ],
                                    ),
                                  ],
                                ),
                                if (todoDate.taskGoal > 0) ...[
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: todoDate.taskGoal > 0
                                        ? (todoDate.completedTodosCount /
                                                todoDate.taskGoal)
                                            .clamp(0.0, 1.0)
                                        : 0.0,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Progress: ${todoDate.completedTodosCount}/${todoDate.taskGoal} (${(todoDate.completionPercentage).toStringAsFixed(0)}%)',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                if (todoDate.summary != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    todoDate.summary!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 115,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error loading daily stats: $error'),
                        ),
                      ),
                    );
                  },
                ),
                // TodoList section takes remaining space
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
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
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
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Undo button for completed todos
              if (_showCompleteUndoButton)
                UndoButton(
                  label: 'Undo Complete',
                  onPressed: () {
                    if (_lastCompletedTodo != null &&
                        _lastCompletedId != null) {
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
              // Only show action buttons if no undo buttons are visible
              if (!_showCompleteUndoButton && !_showDeleteUndoButton) ...[
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
            ],
          ),
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
