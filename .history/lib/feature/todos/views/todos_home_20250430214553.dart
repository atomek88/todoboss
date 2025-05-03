import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:async';
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
import 'package:todoApp/feature/goals/providers/daily_goal_provider.dart';

@RoutePage()
class TodosHomePage extends ConsumerStatefulWidget {
  const TodosHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TodosHomePage> createState() => _TodosHomePageState();
}

class _TodosHomePageState extends ConsumerState<TodosHomePage> {
  // State variables for undo functionality
  Todo? _lastDeletedTodo;
  Todo? _lastCompletedTodo;
  bool _showDeleteUndoButton = false;
  bool _showCompleteUndoButton = false;

  // Navigation state tracking to prevent circular redirects
  bool _isRedirecting = false;
  DateTime? _lastRedirectedDate;

  // Debounce timer for date changes
  Timer? _dateChangeDebounceTimer;

  // Date stabilization timer
  Timer? _dateStabilizationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize with a slight delay to ensure all providers are ready
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Set today's date
      final todayDate = normalizeDate(DateTime.now());
      ref.read(selectedDateProvider.notifier).setDate(todayDate);

      // Ensure DailyTodo is loaded for today
      ref.read(dailyTodoProvider.notifier).dateChanged(todayDate);

      // Set the goal from settings
      final todoGoal = ref.read(todoGoalProvider);
      ref.read(dailyTodoProvider.notifier).setTaskGoal(todoGoal);

      // Update counters
      _updateDailyTodoCounters();

      debugPrint(
          '🚀 [TodosHomePage] Initialized with today\'s date: $todayDate');
    });
  }

  @override
  void dispose() {
    // Cancel any timers
    _dateChangeDebounceTimer?.cancel();
    _dateStabilizationTimer?.cancel();
    super.dispose();
  }

  // Helper to format dates for logging with null safety
  String _formatDate(DateTime? date) {
    return date != null ? date.toString() : 'null';
  }

  // Update counters based on todos
  void _updateDailyTodoCounters() {
    if (!mounted) return;

    final allTodos = ref.read(todoListProvider);
    ref.read(dailyTodoProvider.notifier).updateCounters(allTodos);
  }

  // Toggle a todo completion state
  void _toggleTodo(String id) {
    final todos = ref.read(todoListProvider);
    final todo = todos.firstWhere((t) => t.id == id,
        orElse: () => throw Exception('Todo not found'));

    // Store for undo functionality
    setState(() {
      _lastCompletedTodo = todo;
      _showCompleteUndoButton = true;
    });

    // Update in repository
    final updatedTodo = todo.copyWith(completed: !todo.completed);
    ref.read(todoListProvider.notifier).updateTodo(id, updatedTodo);

    // Update counters
    _updateDailyTodoCounters();

    // Provide feedback
    HapticFeedback.mediumImpact();
    debugPrint('✅ [TodosHome] Toggled todo: ${todo.title}');
  }

  // Delete a todo
  void _deleteTodo(String id) {
    final todos = ref.read(todoListProvider);
    final todo = todos.firstWhere((t) => t.id == id,
        orElse: () => throw Exception('Todo not found'));

    // Store for undo functionality
    setState(() {
      _lastDeletedTodo = todo;
      _showDeleteUndoButton = true;
    });

    // Delete from repository
    ref.read(todoListProvider.notifier).deleteTodo(id);

    // Update counters
    _updateDailyTodoCounters();

    // Provide feedback
    HapticFeedback.mediumImpact();
    debugPrint('🗑️ [TodosHome] Deleted todo: ${todo.title}');
  }

  // Undo a completed todo
  void _undoCompleteTodo() {
    if (_lastCompletedTodo == null) return;

    // Restore original state
    ref
        .read(todoListProvider.notifier)
        .updateTodo(_lastCompletedTodo!.id, _lastCompletedTodo!);

    // Update counters
    _updateDailyTodoCounters();

    // Clear undo state
    setState(() {
      _lastCompletedTodo = null;
      _showCompleteUndoButton = false;
    });

    debugPrint('↩️ [TodosHome] Undid todo completion');
  }

  // Undo a deleted todo
  void _undoDeleteTodo() {
    if (_lastDeletedTodo == null) return;

    // Add back to repository
    ref.read(todoListProvider.notifier).addTodo(_lastDeletedTodo!);

    // Update counters
    _updateDailyTodoCounters();

    // Clear undo state
    setState(() {
      _lastDeletedTodo = null;
      _showDeleteUndoButton = false;
    });

    debugPrint('↩️ [TodosHome] Undid todo deletion');
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers - DailyTodo as central source
    final dailyTodoAsync = ref.watch(dailyTodoProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final currentDate = ref.watch(currentDateProvider);

    // Normalize dates for consistent comparison
    final normalizedSelectedDate = normalizeDate(selectedDate);
    final normalizedCurrentDate = normalizeDate(currentDate);

    // Check if selected date is in the past
    final isPastDate = normalizedSelectedDate.isBefore(normalizedCurrentDate);

    // Ensure DailyTodo date matches the selected date
    dailyTodoAsync.whenData((dailyTodo) {
      if (dailyTodo != null) {
        final dailyTodoDate = normalizeDate(dailyTodo.date);

        // Check for date mismatch and sync if needed
        if (!dailyTodoDate.isAtSameMomentAs(normalizedSelectedDate)) {
          debugPrint(
              '⚠️ [TodosHomePage] Date mismatch: DailyTodo=${dailyTodo.date}, Selected=$normalizedSelectedDate');

          // Debounce date synchronization
          _dateStabilizationTimer?.cancel();
          _dateStabilizationTimer =
              Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              debugPrint(
                  '🔄 [TodosHomePage] Syncing DailyTodo to selected date: $normalizedSelectedDate');
              ref
                  .read(dailyTodoProvider.notifier)
                  .dateChanged(normalizedSelectedDate);
            }
          });
        }
      }
    });

    // Navigate to PastDatePage for past dates
    if (isPastDate &&
        !_isRedirecting &&
        (_lastRedirectedDate == null ||
            !_lastRedirectedDate!.isAtSameMomentAs(normalizedSelectedDate))) {
      // Set flag to prevent multiple redirects
      setState(() {
        _isRedirecting = true;
        _lastRedirectedDate = normalizedSelectedDate;
      });

      debugPrint(
          '🔄 [TodosHomePage] Date $normalizedSelectedDate is past, redirecting to PastDatePage');

      // Cancel any previous timer
      _dateChangeDebounceTimer?.cancel();

      // Use a debounce to prevent rapid navigation changes
      _dateChangeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isRedirecting) {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) =>
                      PastDatePage(date: normalizedSelectedDate),
                ),
              )
                  .then((_) {
                if (!mounted) return;

                // When returning from PastDatePage
                debugPrint('🔄 [TodosHomePage] Returned from PastDatePage');

                // Reset navigation state
                setState(() {
                  _isRedirecting = false;
                  _lastRedirectedDate = null;
                });

                // Reset to today's date to prevent loops
                final todayDate = normalizeDate(DateTime.now());
                ref.read(selectedDateProvider.notifier).setDate(todayDate);
                ref.read(dailyTodoProvider.notifier).forceReload();

                debugPrint(
                    '🔄 [TodosHomePage] Reset date to today: $todayDate');
              });
            }
          });
        }
      });
    }

    // Filter todos based on DailyTodo data
    return dailyTodoAsync.when(
      data: (dailyTodo) {
        List<Todo> activeTodos = [];
        if (dailyTodo != null) {
          // Check if the DailyTodo date matches the selected date
          final selectedDate = ref.watch(selectedDateProvider);
          final normalizedDailyTodoDate = normalizeDate(dailyTodo.date);
          final normalizedSelectedDate = normalizeDate(selectedDate);

          // Log date comparison to diagnose issues
          if (!normalizedDailyTodoDate
              .isAtSameMomentAs(normalizedSelectedDate)) {
            debugPrint(
                '⚠️ [TodosHomePage] Date mismatch: DailyTodo=${dailyTodo.date}, Selected=$selectedDate');
            // Force a reload of the DailyTodo for the correct date
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint(
                  '🔄 [TodosHomePage] Syncing DailyTodo to selected date: $selectedDate');
              ref.read(dailyTodoProvider.notifier).dateChanged(selectedDate);
            });
          }

          // Use the todos directly from the DailyTodo object
          // The DailyTodoSyncService ensures these todos are properly filtered
          // This includes todos created on this date, scheduled for this day, or rollovers
          activeTodos = List<Todo>.from(dailyTodo.todos);

          // Get the day of week for the current selected date (1-7 where 1=Monday)
          final selectedDayOfWeek = selectedDate.weekday;

          // If we're on today's date, only show uncompleted todos
          if (!isPastDate) {
            activeTodos = activeTodos.where((todo) => !todo.completed).toList();
          }

          // Log all the scheduled todos for this day to help with debugging
          final scheduledForToday = activeTodos
              .where((todo) => todo.scheduled.contains(selectedDayOfWeek))
              .toList();

          debugPrint(
              '📋 [TodosHomePage] Showing ${activeTodos.length} todos for date: ${dailyTodo.date} (day $selectedDayOfWeek)');
          debugPrint(
              '📋 [TodosHomePage] Current DailyTodo has ${dailyTodo.todos.length} todos total (active, completed, and deleted)');

          if (scheduledForToday.isNotEmpty) {
            debugPrint(
                '📅 [TodosHomePage] Scheduled for today (day $selectedDayOfWeek): ${scheduledForToday.length}');
            for (final todo in scheduledForToday) {
              debugPrint(
                  '  → ${todo.title} (scheduled for ${todo.scheduledText})');
            }
          }
        } else {
          debugPrint(
              '⚠️ [TodosHomePage] No DailyTodo available for selected date');
        }

        // Build the main scaffold
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Date picker header
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SwipeableDatePicker(
                          height: 70,
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

                // Todo list
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
                              onDelete2: _deleteTodo,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Floating action button(s)
          floatingActionButton: _showCompleteUndoButton || _showDeleteUndoButton
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show undo button for completed todos if needed
                    if (_showCompleteUndoButton)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: FloatingActionButton.extended(
                          heroTag: 'undoCompleteButton',
                          onPressed: _undoCompleteTodo,
                          label: const Text('Undo Complete'),
                          icon: const Icon(Icons.undo),
                        ),
                      ),

                    // Show undo button for deleted todos if needed
                    if (_showDeleteUndoButton)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: FloatingActionButton.extended(
                          heroTag: 'undoDeleteButton',
                          onPressed: _undoDeleteTodo,
                          label: const Text('Undo Delete'),
                          icon: const Icon(Icons.undo),
                        ),
                      ),
                  ],
                )
              : FloatingActionButton(
                  heroTag: 'todosHomePageAddButton',
                  onPressed: () => showTodoFormModal(context),
                  child: const Icon(Icons.add),
                ),
        );
      },

      // Loading state
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      // Error state
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
