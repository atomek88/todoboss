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
    // Always depend on DailyTodo as the central data source
    final dailyTodoAsync = ref.watch(dailyTodoProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final currentDate = ref.watch(currentDateProvider);
    final todos = ref.watch(todoListProvider);
    
    // Normalize dates for comparison
    final normalizedSelectedDate = normalizeDate(selectedDate);
    final normalizedCurrentDate = normalizeDate(currentDate);
    
    // Check if selected date is in the past
    final isPastDate = normalizedSelectedDate.isBefore(normalizedCurrentDate);

    // Ensure DailyTodo date matches the selected date
    dailyTodoAsync.whenData((dailyTodo) {
      if (dailyTodo != null) {
        final dailyTodoDate = normalizeDate(dailyTodo.date);
        
        // Check if DailyTodo date is different from selected date
        if (!dailyTodoDate.isAtSameMomentAs(normalizedSelectedDate)) {
          debugPrint('⚠️ [TodosHomePage] Date mismatch detected: DailyTodo=${dailyTodo.date}, Selected=$normalizedSelectedDate');
          
          // Debounce date synchronization to avoid rapid changes
          _dateStabilizationTimer?.cancel();
          _dateStabilizationTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              debugPrint('🔄 [TodosHomePage] Synchronizing DailyTodo to selected date: $normalizedSelectedDate');
              ref.read(dailyTodoProvider.notifier).dateChanged(normalizedSelectedDate);
            }
          });
        }
      }
    });
    
    // Handle navigation to PastDatePage for past dates
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
      _dateChangeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isRedirecting) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PastDatePage(date: normalizedSelectedDate),
            ),
          ).then((_) {
            if (!mounted) return;
            
            // Reset navigation state
            setState(() {
              _isRedirecting = false;
              _lastRedirectedDate = null;
            });
            
            // Reset to today's date to prevent navigation loops
            final todayDate = normalizeDate(DateTime.now());
            ref.read(selectedDateProvider.notifier).setDate(todayDate);
            ref.read(dailyTodoProvider.notifier).forceReload();
          });
        }
      });
    }
  });
}
    
    // Filter todos based on DailyTodo data
    return dailyTodoAsync.when(
      data: (dailyTodo) {
        // If DailyTodo is null or we have no todos, show empty state
        if (dailyTodo == null) {
          return _buildScaffold(context, []);
        }
        
        // Filter todos based on the DailyTodo date
        final activeTodos = todos.where((todo) {
          if (isPastDate) {
            // For past dates, check if the todo was created on that date
            final todoDate = normalizeDate(todo.createdAt);
            final dailyTodoDate = normalizeDate(dailyTodo.date);
            return todoDate.isAtSameMomentAs(dailyTodoDate);
          } else {
            // For current date, show active todos
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
  
        // Return the UI scaffold with the filtered todos
        return _buildScaffold(context, activeTodos, floatingActionButtons);
      },
      error: (error, _) => Text('Error: $error'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  // Toggle a todo's completion state
  void _toggleTodo(String id) {
    final todos = ref.read(todoListProvider);
    final todoIndex = todos.indexWhere((todo) => todo.id == id);
    
    if (todoIndex >= 0) {
      final todo = todos[todoIndex];
      final updatedTodo = todo.copyWith(completed: !todo.completed);
      
      // Store for undo functionality
      setState(() {
        _lastCompletedTodo = todo;
        _lastCompletedId = id;
        _showCompleteUndoButton = true;
      });
      
      // Update in repository
      ref.read(todoListProvider.notifier).updateTodo(updatedTodo);
      
      // Update daily counters
      _updateDailyTodoCounters();
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      debugPrint('✅ [TodosHome] Toggled completion for todo: ${todo.title}');
    }
  }
  
  // Delete a todo
  void _deleteTodo(String id) {
    final todos = ref.read(todoListProvider);
    final todoIndex = todos.indexWhere((todo) => todo.id == id);
    
    if (todoIndex >= 0) {
      final todo = todos[todoIndex];
      
      // Store for undo functionality
      setState(() {
        _lastDeletedTodo = todo;
        _lastDeletedId = id;
        _showDeleteUndoButton = true;
      });
      
      // Delete from repository
      ref.read(todoListProvider.notifier).deleteTodo(id);
      
      // Update daily counters
      _updateDailyTodoCounters();
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      debugPrint('🗑️ [TodosHome] Deleted todo: ${todo.title}');
    }
  }
  
  // Undo the last completed todo action
  void _undoCompleteTodo() {
    if (_lastCompletedTodo != null && _lastCompletedId != null) {
      // Restore to the original state
      ref.read(todoListProvider.notifier).updateTodo(_lastCompletedTodo!);
      
      // Update daily counters
      _updateDailyTodoCounters();
      
      // Reset undo state
      setState(() {
        _lastCompletedTodo = null;
        _lastCompletedId = null;
        _showCompleteUndoButton = false;
      });
      
      debugPrint('↩️ [TodosHome] Undid completion change');
    }
  }
  
  // Undo the last deleted todo action
  void _undoDeleteTodo() {
    if (_lastDeletedTodo != null) {
      // Add back to repository
      ref.read(todoListProvider.notifier).addTodo(_lastDeletedTodo!);
      
      // Update daily counters
      _updateDailyTodoCounters();
      
      // Reset undo state
      setState(() {
        _lastDeletedTodo = null;
        _lastDeletedId = null;
        _showDeleteUndoButton = false;
      });
      
      debugPrint('↩️ [TodosHome] Undid delete operation');
    }
  }

  Widget _buildScaffold(BuildContext context, List<Todo> todos, List<Widget> floatingActionButtons) {
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
              child: todos.isEmpty
                  ? const Center(child: Text('No tasks for this date'))
    );
  }
}
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
