import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/daily_todos/widgets/daily_stats_card.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';
import 'package:todoApp/shared/widgets/undo_button.dart';

/// A component that displays todos for the current or future date
/// This is used by the UnifiedTodosPage for non-past dates
class TodosHomeView extends ConsumerStatefulWidget {
  const TodosHomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<TodosHomeView> createState() => _TodosHomeViewState();
}

class _TodosHomeViewState extends ConsumerState<TodosHomeView> {
  // State variables for undo functionality
  Todo? _lastDeletedTodo;
  Todo? _lastCompletedTodo;
  bool _showDeleteUndoButton = false;
  bool _showCompleteUndoButton = false;

  @override
  void initState() {
    super.initState();
    // Sync daily todo goal with the current date
    _syncGoalWithDailyTodo();
  }

  // Listener for goal changes to sync with DailyTodo objects
  void _syncGoalWithDailyTodo() {
    final selectedDate = ref.read(selectedDateProvider);
    final currentDate = ref.read(currentDateProvider);
    final normalizedSelectedDate = normalizeDate(selectedDate);
    final normalizedCurrentDate = normalizeDate(currentDate);

    // Only sync if the selected date is today or in the future
    if (!normalizedSelectedDate.isBefore(normalizedCurrentDate)) {
      final dailyTodoNotifier = ref.read(dailyTodoProvider.notifier);
      final goalValue = ref.read(dailyTodoProvider).valueOrNull?.taskGoal ?? 5;
      dailyTodoNotifier.setTaskGoal(goalValue);
      debugPrint('🏹 [TodosHomeView] Synced goal value: $goalValue');
    }
  }

  // Toggle a todo's completion status
  void _toggleTodo(String id) {
    final todos = ref.read(todoListProvider);
    final todo = todos.firstWhere((t) => t.id == id,
        orElse: () => throw Exception('Todo not found'));

    // Save copy for undo functionality
    if (!todo.completed) {
      setState(() {
        _lastCompletedTodo = todo;
        _showCompleteUndoButton = true;
      });
    }

    // Update status
    final updatedTodo = todo.copyWith(
      completed: !todo.completed,
      // The freezed copyWith only allows setting null for nullable fields
      // No completedAt parameter needed as it's handled in the repository
    );

    // Update in repository
    ref.read(todoListProvider.notifier).updateTodo(id, updatedTodo);

    // Update counters in DailyTodo
    _updateDailyTodoCounters();

    // Provide feedback
    HapticFeedback.mediumImpact();
    debugPrint('✅ [TodosHomeView] Toggled todo: ${todo.title}');
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

    // Update DailyTodo counters
    _updateDailyTodoCounters();

    // Provide feedback
    HapticFeedback.mediumImpact();
    debugPrint('🗑️ [TodosHomeView] Deleted todo: ${todo.title}');
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

    debugPrint('↩️ [TodosHomeView] Undid todo completion');
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

    debugPrint('↩️ [TodosHomeView] Undid todo deletion');
  }

  // Update counters in the DailyTodo
  void _updateDailyTodoCounters() {
    // Force a refresh of the current DailyTodo to update counters
    // Using forceReload instead of refreshCounters based on the refactored API
    ref.read(dailyTodoProvider.notifier).forceReload();
  }

  @override
  Widget build(BuildContext context) {
    // Get the date from provider for filtering
    final selectedDate = ref.watch(selectedDateProvider);
    final currentDate = ref.watch(currentDateProvider);

    // Check if we're viewing a past date
    final isPastDate = selectedDate.isBefore(normalizeDate(currentDate));

    // Get active todos
    final dailyTodoAsync = ref.watch(dailyTodoProvider);

    return dailyTodoAsync.when(
      data: (dailyTodo) {
        List<Todo> activeTodos = [];
        if (dailyTodo != null) {
          // Check if the DailyTodo date matches the selected date
          final normalizedDailyTodoDate = normalizeDate(dailyTodo.date);
          final normalizedSelectedDate = normalizeDate(selectedDate);

          // Log date comparison to diagnose issues
          if (!normalizedDailyTodoDate
              .isAtSameMomentAs(normalizedSelectedDate)) {
            debugPrint(
                '⚠️ [TodosHomeView] Date mismatch: DailyTodo=${dailyTodo.date}, Selected=$selectedDate');

            // Force a reload of the DailyTodo for the correct date
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint(
                  '🔄 [TodosHomeView] Syncing DailyTodo to selected date: $selectedDate');
              ref.read(dailyTodoProvider.notifier).dateChanged(selectedDate);
            });
          }

          // Use the todos directly from the DailyTodo object
          activeTodos = List<Todo>.from(dailyTodo.todos);

          // Get the day of week for the current selected date (1-7 where 1=Monday)
          final selectedDayOfWeek = selectedDate.weekday;

          // If we're on today's date or future, only show uncompleted todos
          if (!isPastDate) {
            activeTodos = activeTodos.where((todo) => !todo.completed).toList();
          }

          debugPrint(
              '📋 [TodosHomeView] Showing ${activeTodos.length} todos for date: ${dailyTodo.date} (day $selectedDayOfWeek)');
          debugPrint(
              '📋 [TodosHomeView] Current DailyTodo has ${dailyTodo.todos.length} todos total');
        } else {
          debugPrint(
              '⚠️ [TodosHomeView] No DailyTodo available for selected date');
        }

        return Column(
          children: [
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

            // Floating action buttons for undo
            if (_showCompleteUndoButton || _showDeleteUndoButton)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show undo button for completed todos if needed
                    if (_showCompleteUndoButton)
                      UndoButton(
                        onPressed: _undoCompleteTodo,
                        label: 'Undo Complete',
                        onDurationEnd: () {
                          // Auto-dismiss after duration
                          setState(() {
                            _showCompleteUndoButton = false;
                          });
                        },
                      ),

                    // Show undo button for deleted todos if needed
                    if (_showDeleteUndoButton)
                      UndoButton(
                        onPressed: _undoDeleteTodo,
                        label: 'Undo Delete',
                        onDurationEnd: () {
                          // Auto-dismiss after duration
                          setState(() {
                            _showDeleteUndoButton = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
