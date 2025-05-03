import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:async';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/daily_todos/models/daily_todo.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/daily_todos/widgets/daily_stats_card.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/views/past_date_page.dart';
import 'package:todoApp/feature/todos/widgets/todo_form_modal.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';
import 'package:todoApp/shared/styles/styles.dart';
import 'package:todoApp/shared/widgets/swipeable_date_picker.dart';
import 'package:todoApp/shared/widgets/undo_button.dart';
import 'package:todoApp/feature/voice/widgets/voice_recording_button.dart';
import 'package:todoApp/feature/goals/providers/daily_goal_provider.dart';
import 'package:todoApp/shared/widgets/confetti_celebration.dart';
// Import our newly extracted components
import 'components/index.dart';

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

  // Navigation state tracking to prevent circular redirects
  bool _isRedirecting = false;
  DateTime? _lastRedirectedDate;
  
  // Debounce timer for date changes
  Timer? _dateChangeDebounceTimer;
  
  // Timer for date stabilization
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

      // Ensure DailyTodo is loaded for this date
      ref.read(dailyTodoProvider.notifier).dateChanged(normalizedDate);

      // Ensure the DailyTodo has the correct goal from global settings
      ref.read(dailyTodoProvider.notifier).setTaskGoal(todoGoal);

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
        // 2. Get the DailyTodo with the latest goal
        // 3. Update the counters with the latest todos
        // 4. Update the UI with the fresh data
        ref.read(dailyTodoProvider.notifier).forceReload();

        // Log the force refresh
        debugPrint(
            '🔄 [TodosHomePage] Forced reload of DailyTodo for: $currDateStr');
      }
      // }
    });
  }

  @override
  void dispose() {
    // Cancel any timers before disposal
    _dateStabilizationTimer?.cancel();
    _dateChangeDebounceTimer?.cancel();
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

    // First ensure the DailyTodo has the correct goal from global settings
    ref.read(dailyTodoProvider.notifier).setTaskGoal(todoGoal);

    // Then update all the counters
    _updateDailyTodoCounters();

    debugPrint(
        '🔄 [TodosHome] Updated goals and counters for ${selectedDate.toString().split(' ')[0]} with goal: $todoGoal');
  }

  // Update DailyTodo counters based on tods
  void _updateDailyTodoCounters() {
    final allTodos = ref.read(todoListProvider);
    final currentDate = ref.read(selectedDateProvider);
    final todoGoal = ref.read(todoGoalProvider);

    // First ensure the DailyTodo has the correct goal from the global setting
    ref.read(dailyTodoProvider.notifier).setTaskGoal(todoGoal);

    // Then update the counters for completed and deleted todos
    ref.read(dailyTodoProvider.notifier).updateCounters(allTodos);

    debugPrint(
        '🔄 [TodosHome] Updated counters for ${currentDate.toString().split(' ')[0]} with goal: $todoGoal');
  }

  @override
  Widget build(BuildContext context) {
    // Watch the required providers for UI updates
    final selectedDate = ref.watch(selectedDateProvider);
    final currentDate = ref.watch(currentDateProvider);
    final todos = ref.watch(todoListProvider);
    final dailyTodo = ref.watch(dailyTodoProvider);
    
    // Normalize dates for comparison
    final normalizedSelectedDate = normalizeDate(selectedDate);
    final normalizedCurrentDate = normalizeDate(currentDate);
    
    // Check if selected date is in the past
    final isPastDate = normalizedSelectedDate.isBefore(normalizedCurrentDate);
    
    // Handle navigation to PastDatePage for past dates
    // This uses a post-frame callback to avoid build-time navigation
    if (isPastDate && !_isRedirecting && (_lastRedirectedDate == null || 
        !_lastRedirectedDate!.isAtSameMomentAs(normalizedSelectedDate))) {
      // Set navigation state flag to avoid multiple redirects
      setState(() {
        _isRedirecting = true;
        _lastRedirectedDate = normalizedSelectedDate;
      });
      
      debugPrint('🔄 [TodosHomePage] Selected date ($normalizedSelectedDate) is in the past, redirecting to PastDatePage');
      
      // Cancel any previous timer
      _dateChangeDebounceTimer?.cancel();
      
      // Use a debounce to prevent rapid navigation changes
      _dateChangeDebounceTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          // Safe post-frame navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isRedirecting) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PastDatePage(date: normalizedSelectedDate),
                ),
              ).then((_) {
                // When returning from PastDatePage
                debugPrint('🔄 [TodosHomePage] Returned from PastDatePage');
                
                // Reset navigation state
                setState(() {
                  _isRedirecting = false;
                  _lastRedirectedDate = null;
                });
                
                // Reset to today's date to prevent navigation loops
                final todayDate = normalizeDate(DateTime.now());
                debugPrint('🔄 [TodosHomePage] Resetting date to today: $todayDate');
                ref.read(selectedDateProvider.notifier).setDate(todayDate);
                
                // Force reload data for the new date
                ref.read(dailyTodoProvider.notifier).forceReload();
              });
            }
          });
        }
      });
    }
    
    // Get todos filtered for today or current selected date
    final activeTodos = todos.where((todo) {
      // Simple filtering for UI purposes - actual filtering is done in repositories
      if (isPastDate) {
        // For past dates, show todos for that specific date only
        final todoDate = normalizeDate(todo.createdAt);
        return todoDate.isAtSameMomentAs(normalizedSelectedDate);
      } else {
        // For today, show all active todos
        return !todo.completed;
      }
    }).toList();
    
    // Add undo buttons and floating action button based on state
  final List<Widget> floatingActionButtons = [];
  
  // Only show undo buttons if needed
  if (_showCompleteUndoButton) {
    floatingActionButtons.add(
      UndoButton(
        label: 'Undo Mark Complete',
        onPressed: _undoCompleteTodo,
        onDurationEnd: () {
          setState(() {
            _showCompleteUndoButton = false;
          });
        },
      ),
    );
  }
  
  if (_showDeleteUndoButton) {
    floatingActionButtons.add(
      UndoButton(
        label: 'Undo Delete',
        onPressed: _undoDeleteTodo,
        onDurationEnd: () {
          setState(() {
            _showDeleteUndoButton = false;
          });
        },
      ),
    );
  }
  
  // Regular add button if no undo buttons are visible
  if (!_showCompleteUndoButton && !_showDeleteUndoButton) {
    floatingActionButtons.add(
      FloatingActionButton(
        onPressed: () => showTodoFormModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      child: Column(
        children: [
          // Header with date picker
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            child: Row(
              children: [
                // SwipeableDatePicker takes most of the space
                Expanded(
                  child: SwipeableDatePicker(
                    height: 70, // Slightly reduced height
                    mainDateTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                    maxDaysForward: 7, // Limit to one week forward
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Daily stats card
          const DailyStatsCard(),
          // TodoList section takes remaining space
          Expanded(
            child: activeTodos.isEmpty
                ? const Center(child: Text('No tasks for this date'))
                : ListView.builder(
                    itemCount: activeTodos.length,
                    itemBuilder: (context, index) {
                      final todo = activeTodos[index];
                      return TodoListItem(
                        todo: todo,
                        onToggle: _toggleTodo,
                        onDelete: _deleteTodo,
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    floatingActionButton: floatingActionButtons.isEmpty
        ? null
        : (floatingActionButtons.length == 1
            ? floatingActionButtons.first
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: floatingActionButtons,
              )),
  );
  }

    
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
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Row(
                    children: [
                      // SwipeableDatePicker takes most of the space
                      Expanded(
                        child: SwipeableDatePicker(
                          height: 70, // Slightly reduced height
                          mainDateTextStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                          maxDaysForward: 7, // Limit to one week forward
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Daily stats card - extracted to a separate component
                const DailyStatsCard(),
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
                                _updateDailyTodoCounters();

                                // Log counter update for debugging
                                debugPrint(
                                    '🔄 [TodosHome] Updated counters after completing: ${todo.title}');

                                // If there are subtasks, mark them all as completed too
                                // This is just for the counter - they're already visually completed
                                // when the parent is completed

                                // Use Future.delayed to show the snackbar after the animation completes
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  void _showNotification() {
                                    if (NotificationService.instance.permissionGranted) {
                                      NotificationService.instance.showScheduledTodosNotification();
                                    }
                                  }
                                  _showNotification();
                                  NotificationService.showNotification(
                                      completionMessage);
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
                                _updateDailyTodoCounters();

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
                  label: 'Undo Mark Complete',
                  onUndo: () => _undoCompleteTodo(),
                ),
              // Undo button for deleted todos
              if (_showDeleteUndoButton)
                UndoButton(
                  label: 'Undo Delete',
                  onUndo: () => _undoDeleteTodo(),
                ),
              // Only show action buttons if no undo buttons are visible
              if (!_showCompleteUndoButton && !_showDeleteUndoButton) ...[
                // Voice recording button - with unique hero tag
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: VoiceRecordingButton(
                    heroTag: 'todosHomePageVoiceButton',
                    onRecordingComplete: (String text) {
                      // Create a new todo with the transcribed text
                      _createTodoFromVoice(text);
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
