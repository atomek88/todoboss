import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:async';
import 'package:todoApp/shared/navigation/app_router.gr.dart';
import 'package:todoApp/feature/todos/providers/todo_date_provider.dart';
import 'package:todoApp/feature/todos/views/past_date_page.dart';
import 'package:todoApp/shared/utils/show_snack_bar.dart';
import 'package:todoApp/shared/widgets/swipeable_date_picker.dart';
import 'package:todoApp/core/providers/selected_date_provider.dart';
// Import date-related utilities with specific functions to avoid duplication
import 'package:todoApp/core/providers/date_provider.dart'
    show currentDateProvider, refreshCurrentDate, normalizeDate;
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
import '../../../core/providers/date_provider.dart';

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

  // Track if the TodoDate is stable for this date
  bool _todoDateIsStable = false;
  Timer? _dateStabilizationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize with a slight delay to ensure all providers are ready
    Future.delayed(const Duration(milliseconds: 300), () {
      // Get the current global task goal
      final todoGoal = ref.read(todoGoalProvider);

      // Ensure we have the correct date synchronized
      final todayDate = ref.read(currentDateProvider);
      final normalizedDate = normalizeDate(todayDate);

      // Set the selected date to normalized today
      ref.read(selectedDateProvider.notifier).setDate(normalizedDate);

      debugPrint(
          '🚀 [TodosHomePage] Initializing with goal: $todoGoal for date: ${normalizedDate.toString().split(' ')[0]}');

      // Ensure TodoDate is loaded for this date
      ref.read(todoDateProvider.notifier).dateChanged(normalizedDate);

      // Ensure the TodoDate has the correct goal from global settings
      ref.read(todoDateProvider.notifier).setTaskGoal(todoGoal);

      // Update counters after everything is initialized
      _updateGoals();

      // Listen for date changes and update counters when date changes
      _setupDateChangeListener();
    });
  }

  // Setup a listener for date changes to refresh counters
  void _setupDateChangeListener() {
    ref.listen<DateTime>(selectedDateProvider, (previous, current) {
      if (previous != current) {
        // Helper function to format date or handle null
        String _formatDate(DateTime? date) {
          if (date == null) return 'null';
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }

        // Format dates for logging with null safety
        final prevDateStr = _formatDate(previous);
        final currDateStr = _formatDate(current);

        debugPrint(
            '📅 [TodosHomePage] Date changed from $prevDateStr to $currDateStr - refreshing counters');

        // When date changes, we need to ensure immediate reliable updates
        // if (current != null && current is DateTime) {
        // The new forceReload method will:
        // 1. Force the UI into loading state immediately
        // 2. Get the TodoDate with the latest goal
        // 3. Update the counters with the latest todos
        // 4. Update the UI with the fresh data
        ref.read(todoDateProvider.notifier).forceReload();

        // Log the force refresh
        debugPrint(
            '🔄 [TodosHomePage] Forced reload of TodoDate for: $currDateStr');
      }
      // }
    });
  }

  @override
  void dispose() {
    _dateStabilizationTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TodosHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Schedule a microtask to update goals after rebuild
    Future.microtask(() => _updateGoals());
  }

  // Update goals and counters whenever needed - this is a key coordination point
  void _updateGoals() {
    // Get the current global goal and selected date
    final todoGoal = ref.read(todoGoalProvider);
    final selectedDate = ref.read(selectedDateProvider);

    // First ensure the TodoDate has the correct goal from global settings
    ref.read(todoDateProvider.notifier).setTaskGoal(todoGoal);

    // Then update all the counters
    _updateTodoDateCounters();

    debugPrint(
        '🔄 [TodosHome] Updated goals and counters for ${selectedDate.toString().split(' ')[0]} with goal: $todoGoal');
  }

  // Update TodoDate counters based on todos
  void _updateTodoDateCounters() {
    final allTodos = ref.read(todoListProvider);
    final currentDate = ref.read(selectedDateProvider);
    final todoGoal = ref.read(todoGoalProvider);

    // First ensure the TodoDate has the correct goal from the global setting
    ref.read(todoDateProvider.notifier).setTaskGoal(todoGoal);

    // Then update the counters for completed and deleted todos
    ref.read(todoDateProvider.notifier).updateCounters(allTodos);

    debugPrint(
        '🔄 [TodosHome] Updated counters for ${currentDate.toString().split(' ')[0]} with goal: $todoGoal');
  }

  @override
  Widget build(BuildContext context) {
    // Get the selected date for filtering todos and normalize it
    final normalizedSelectedDate =
        normalizeDate(ref.watch(selectedDateProvider));

    // Watch the TodoDate provider - this ensures we're using the right date state
    final todoDateAsync = ref.watch(todoDateProvider);

    // Check if the TodoDate is stable for this date
    todoDateAsync.whenData((todoDate) {
      if (todoDate != null) {
        final todoDateDate = normalizeDate(todoDate.date);

        // Check for date mismatch
        if (!todoDateDate.isAtSameMomentAs(normalizedSelectedDate)) {
          debugPrint(
              '⚠️ [TodosHomePage] Date mismatch: TodoDate=${todoDate.date}, Selected=$normalizedSelectedDate');
          _todoDateIsStable = false;

          // Debounce to avoid rapid changes
          _dateStabilizationTimer?.cancel();
          _dateStabilizationTimer =
              Timer(const Duration(milliseconds: 300), () {
            // Force synchronization if there's a mismatch
            debugPrint(
                '🛠 [TodosHomePage] Applying date correction to TodoDate: $normalizedSelectedDate');
            ref
                .read(todoDateProvider.notifier)
                .dateChanged(normalizedSelectedDate);
          });
        } else if (!_todoDateIsStable) {
          // Date matches and we need to mark as stable
          _todoDateIsStable = true;
          debugPrint(
              '✅ [TodosHomePage] TodoDate stabilized for date: ${todoDate.date}');
        }
      }
    });

    // Get filtered todos and the selected date after ensuring sync
    final filteredTodos = ref.watch(filteredTodosProvider);
    final allTodos = ref.read(todoListProvider);
    final completedCount =
        allTodos.where((Todo todo) => todo.status == 1).length;

    // Get the daily todo goal
    final dailyTodoGoal = ref.watch(todoGoalProvider);

    // Check if we should show celebration
    final shouldCelebrate = ref
        .watch(dailyGoalAchievementProvider.notifier)
        .shouldShowCelebration(normalizedSelectedDate);

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
              .markCelebrationShown(normalizedSelectedDate);
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
                                    const SizedBox(width: 40),
                                    // Today button
                                    AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      opacity: DateUtils.isSameDay(
                                              normalizedSelectedDate,
                                              ref.read(currentDateProvider))
                                          ? 0.3
                                          : 1.0,
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.calendar_today_rounded),
                                        tooltip: 'Go to Today',
                                        onPressed: () {
                                          // FORCE refresh the current date to ensure we're using TODAY
                                          refreshCurrentDate(ref);

                                          // Get the refreshed current date
                                          final today = DateTime.now();
                                          final normalizedToday =
                                              normalizeDate(today);

                                          debugPrint(
                                              '📅 [TodosHome] Today button pressed. System date: ${today.toString()}');
                                          debugPrint(
                                              '📅 [TodosHome] Normalized today: ${normalizedToday.toString()}');

                                          // Provide haptic feedback when changing date
                                          HapticFeedback.selectionClick();

                                          // Force date update to today
                                          ref
                                              .read(
                                                  selectedDateProvider.notifier)
                                              .setDate(normalizedToday);

                                          // Force reload the TodoDate for today
                                          ref
                                              .read(todoDateProvider.notifier)
                                              .forceReload();
                                        },
                                      ),
                                    ),
                                    // History button for past dates
                                    IconButton(
                                      icon: const Icon(
                                          Icons.calendar_month_rounded),
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

                                // Update the counters immediately
                                _updateTodoDateCounters();

                                // Log counter update for debugging
                                debugPrint(
                                    '🔄 [TodosHome] Updated counters after completing: ${todo.title}');

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

                                // Update the counters immediately
                                _updateTodoDateCounters();

                                // Log counter update for debugging
                                debugPrint(
                                    '🔄 [TodosHome] Updated counters after deleting: ${todo.title}');

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
