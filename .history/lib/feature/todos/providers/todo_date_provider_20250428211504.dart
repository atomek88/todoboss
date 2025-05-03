import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/todo_date.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/repositories/todo_date_repository.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/core/providers/date_provider.dart';

/// Helper to format a date key for caching
String formatDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Provider for the TodoDateRepository
final todoDateRepositoryProvider = Provider<TodoDateRepository>((ref) {
  final storageService = StorageService();
  return TodoDateRepository(storageService);
});

/// Cache manager for TodoDates to improve performance
final todoDateCacheProvider = Provider<TodoDateCacheManager>((ref) {
  // Create a new cache manager that auto-invalidates after a certain time
  return TodoDateCacheManager();
});

/// Provider for getting a TodoDate for a specific date with caching
final todoDateForSelectedDateProvider = FutureProvider<TodoDate>((ref) async {
  final repository = ref.watch(todoDateRepositoryProvider);
  final cache = ref.watch(todoDateCacheProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Try to get from cache first
  final cacheKey = formatDateKey(selectedDate);
  final cachedDate = cache.getTodoDate(cacheKey);

  if (cachedDate != null) {
    return cachedDate;
  }

  // Not in cache, fetch from repository
  final todoDate = await repository.getTodoDateForDate(selectedDate);

  // Store in cache for future use
  cache.cacheTodoDate(cacheKey, todoDate);

  return todoDate;
});

// Cache entry class for storing data with timestamps
class _CacheEntry<T> {
  final T value;
  DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Cache manager for TodoDates to improve performance
class TodoDateCacheManager {
  // LRU cache with expiration for TodoDates
  final Map<String, _CacheEntry<TodoDate>> _cache = {};
  final int _maxSize = 30; // Max number of dates to cache
  final Duration _expiration =
      const Duration(minutes: 5); // Cache expiration time

  TodoDateCacheManager() {
    // Set up a periodic cleaner for expired cache entries
    Timer.periodic(const Duration(minutes: 1), (_) => _cleanExpiredEntries());
  }

  /// Get a TodoDate from the cache if it exists and isn't expired
  TodoDate? getTodoDate(String dateKey) {
    final entry = _cache[dateKey];

    if (entry == null) {
      return null;
    }

    // Check if entry is expired
    if (DateTime.now().difference(entry.timestamp) > _expiration) {
      _cache.remove(dateKey);
      return null;
    }

    // Update timestamp to keep this entry fresh (LRU behavior)
    entry.timestamp = DateTime.now();
    return entry.value;
  }

  /// Cache a TodoDate with the current timestamp
  void cacheTodoDate(String dateKey, TodoDate todoDate) {
    // Ensure we don't exceed max size by removing least recently used
    if (_cache.length >= _maxSize) {
      final oldest = _findOldestEntry();
      if (oldest != null) {
        _cache.remove(oldest);
      }
    }

    // Add to cache
    _cache[dateKey] = _CacheEntry(todoDate, DateTime.now());
  }

  /// Invalidate a specific cache entry
  void invalidate(String dateKey) {
    _cache.remove(dateKey);
  }

  /// Invalidate the entire cache
  void invalidateAll() {
    _cache.clear();
  }

  /// Invalidate cache for a specific date
  void invalidateDate(DateTime date) {
    final key = formatDateKey(date);
    invalidate(key);
  }

  /// Find the oldest entry in the cache (for LRU removal)
  String? _findOldestEntry() {
    if (_cache.isEmpty) return null;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.timestamp;
      }
    }

    return oldestKey;
  }

  /// Clean expired entries from the cache
  void _cleanExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > _expiration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}

/// Provider for the current TodoDate state with caching
final todoDateProvider =
    StateNotifierProvider<TodoDateNotifier, AsyncValue<TodoDate?>>((ref) {
  final repository = ref.watch(todoDateRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final todosProvider = ref.watch(todoListProvider.notifier);
  final cache = ref.watch(todoDateCacheProvider);

  return TodoDateNotifier(ref, repository, selectedDate, todosProvider, cache);
});

/// Notifier for managing TodoDate states with caching
class TodoDateNotifier extends StateNotifier<AsyncValue<TodoDate?>> {
  final TodoDateRepository _repository;
  DateTime _currentDate;
  final TodoListNotifier _todosProvider;
  final Ref _ref;
  final TodoDateCacheManager _cache;

  // Debounce timer for rapid date changes
  Timer? _dateChangeDebounceTimer;

  TodoDateNotifier(this._ref, this._repository, this._currentDate,
      this._todosProvider, this._cache)
      : super(const AsyncValue.loading()) {
    _loadTodoDate();

    // Listen for date changes
    _ref.listen<DateTime>(selectedDateProvider, (previous, current) {
      if (!isSameDay(previous!, current)) {
        _currentDate = current;
        _loadTodoDate();
      }
    });
  }

  @override
  void dispose() {
    _dateChangeDebounceTimer?.cancel();
    super.dispose();
  }

  /// Load the TodoDate for the current date with caching and debouncing
  Future<void> _loadTodoDate() async {
    try {
      // Cancel any existing debounce timer
      _dateChangeDebounceTimer?.cancel();

      // Set loading state only if we don't already have data for this date
      final normalizedDate = normalizeDate(_currentDate);
      final cacheKey = formatDateKey(normalizedDate);

      // Try to get from cache first
      final cachedDate = _cache.getTodoDate(cacheKey);

      if (cachedDate != null) {
        // Use cached data immediately
        state = AsyncValue.data(cachedDate);
        return;
      }

      // No cache hit, show loading state
      state = const AsyncValue.loading();

      // Add debounce to prevent rapid loading during date changes
      _dateChangeDebounceTimer =
          Timer(const Duration(milliseconds: 200), () async {
        try {
          // Get the latest goal setting
          final todoGoal = _ref.read(todoGoalProvider);

          // Fetch from repository
          final todoDate = await _repository.getTodoDateForDate(
            normalizedDate,
            defaultGoal: todoGoal,
          );

          // Cache the result
          _cache.cacheTodoDate(cacheKey, todoDate);

          // Update the state
          if (mounted) {
            state = AsyncValue.data(todoDate);
          }
        } catch (e) {
          if (mounted) {
            state = AsyncValue.error(e, StackTrace.current);
          }
        }
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Force the TodoDate into loading state to ensure UI updates
  void forceLoading() {
    state = const AsyncValue.loading();
  }

  /// Force an immediate reload of the TodoDate without debouncing
  /// This ensures we get fresh data immediately when needed
  Future<void> forceReload() async {
    debugPrint(
        '📅 [TodoDateNotifier] Forcing immediate reload for date: $_currentDate');

    // Set loading state first for immediate UI feedback
    state = const AsyncValue.loading();

    try {
      // Get the TodoDate with the latest global goal
      final todoGoal = _ref.read(todoGoalProvider);
      final todoDate = await _repository.getTodoDateForDate(_currentDate,
          defaultGoal: todoGoal);

      // Get the todos specifically for this date using todoIds
      final todosForDate = <Todo>[];

      // If we have todo IDs for this date, fetch those specific todos
      if (todoDate.todoIds.isNotEmpty) {
        debugPrint(
            '📅 [TodoDateNotifier] Getting ${todoDate.todoIds.length} todos for date: ${todoDate.id}');

        // Get each todo by ID
        for (final todoId in todoDate.todoIds) {
          final todo = await _todosProvider.getTodoById(todoId);
          if (todo != null) {
            todosForDate.add(todo);
            debugPrint(
                '📅 [TodoDateNotifier] Added todo: ${todo.title} (${todo.id}) with status: ${todo.status}');
          }
        }
      } else {
        // If no todoIds in TodoDate, try to find todos created on this date
        final allTodos = await _todosProvider.getAllTodos();
        final todosCreatedOnDate = allTodos.where((todo) {
          final todoDate = normalizeDate(todo.createdAt);
          return todoDate == normalizeDate(_currentDate);
        }).toList();

        // Add these todos to the list for this date
        todosForDate.addAll(todosCreatedOnDate);
        debugPrint(
            '📅 [TodoDateNotifier] Backfilling with ${todosCreatedOnDate.length} todos created on date: ${todoDate.id}');

        // Consider also adding todos that were completed on this date
        final todosCompletedOnDate = allTodos.where((todo) {
          if (todo.endedOn == null) return false;
          final endDate = normalizeDate(todo.endedOn!);
          return endDate == normalizeDate(_currentDate) &&
              todo.status > 0; // Completed or deleted
        }).toList();

        // Add completed/deleted todos to the list too
        final additionalTodos = todosCompletedOnDate
            .where((completedTodo) =>
                !todosCreatedOnDate.any((t) => t.id == completedTodo.id))
            .toList();
        todosForDate.addAll(additionalTodos);

        debugPrint(
            '📅 [TodoDateNotifier] Also adding ${additionalTodos.length} todos completed/deleted on date: ${todoDate.id}');

        // Now that we've backfilled, add all these todoIds to the TodoDate for future reference
        if (todosForDate.isNotEmpty) {
          // Add all these todos to the TodoDate for future queries
          TodoDate updatedTodoDate = todoDate;
          for (final todo in todosForDate) {
            if (!updatedTodoDate.todoIds.contains(todo.id)) {
              updatedTodoDate = updatedTodoDate.addTodoId(todo.id);
            }
          }

          // Save the updated TodoDate with the new todoIds
          if (updatedTodoDate.todoIds.length > todoDate.todoIds.length) {
            await _repository.saveTodoDate(updatedTodoDate);
            debugPrint(
                '📅 [TodoDateNotifier] Added ${updatedTodoDate.todoIds.length - todoDate.todoIds.length} todo IDs to date ${todoDate.id}');
          }
        }
      }

      // Update counts based on the todos for this date only
      final updatedTodoDate = await _repository.updateTodoDateCounters(
          _currentDate, todosForDate,
          defaultGoal: todoGoal);

      // Update the state with the reloaded TodoDate
      if (updatedTodoDate != null) {
        state = AsyncValue.data(updatedTodoDate);
        debugPrint(
            '📅 [TodoDateNotifier] Force reload complete: ${updatedTodoDate.id} with ' +
                'completed=${updatedTodoDate.completedTodosCount}, ' +
                'deleted=${updatedTodoDate.deletedTodosCount}, ' +
                'goal=${updatedTodoDate.taskGoal}, ' +
                'tracking=${updatedTodoDate.todoIds.length} todos');
      } else {
        // If we couldn't get the updated TodoDate, just use what we have
        state = AsyncValue.data(todoDate);
        debugPrint(
            '📅 [TodoDateNotifier] Force reload partial: ${todoDate.id}');
      }
    } catch (e) {
      debugPrint('📅 [TodoDateNotifier] Force reload failed: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update the state when a new date is selected with immediate feedback
  void dateChanged(DateTime newDate) {
    // Normalize to avoid time component issues
    final normalizedDate = normalizeDate(newDate);

    debugPrint(
        '📅 [TodoDateNotifier] Date change requested: $_currentDate → $normalizedDate');

    // Only update if the date actually changed to avoid unnecessary reloads
    if (_currentDate.day != normalizedDate.day ||
        _currentDate.month != normalizedDate.month ||
        _currentDate.year != normalizedDate.year) {
      // Set loading state immediately for UI feedback
      state = const AsyncValue.loading();

      // Update the current date
      _currentDate = normalizedDate;

      // Force immediate reload instead of debounced loading
      forceReload();
    } else {
      debugPrint(
          '📅 [TodoDateNotifier] Ignoring duplicate date change request');
    }
  }

  /// Set the task goal for the current date
  Future<void> setTaskGoal(int goal) async {
    try {
      final currentTodoDate = state.value;
      if (currentTodoDate == null) {
        debugPrint(
            '📅 [TodoDateNotifier] Cannot set goal - no current TodoDate');
        return;
      }

      // Skip update if the goal hasn't changed
      if (currentTodoDate.taskGoal == goal) {
        debugPrint(
            '📅 [TodoDateNotifier] Goal already set to $goal, skipping update');
        return;
      }

      debugPrint(
          '📅 [TodoDateNotifier] Setting task goal for ${_currentDate.toString().split(' ')[0]} from ${currentTodoDate.taskGoal} to $goal');

      final updatedTodoDate = await _repository.setTaskGoal(_currentDate, goal);
      if (updatedTodoDate != null) {
        talker.debug(
            '📅 [TodoDateNotifier] Successfully updated task goal to $goal');
        state = AsyncValue.data(updatedTodoDate);
      } else {
        talker.error(
            '📅 [TodoDateNotifier] Failed to update task goal - null response from repository');
      }
    } catch (e) {
      talker.error('📅 [TodoDateNotifier] Error setting task goal', e);
    }
  }

  /// Update counters based on todos
  Future<void> updateCounters(List<Todo> todos) async {
    try {
      final currentTodoDate = state.value;
      if (currentTodoDate == null) return;

      // Get the current global goal
      final todoGoal = _ref.read(todoGoalProvider);

      // Pass the global goal to ensure it's used in updates
      final updatedTodoDate = await _repository
          .updateTodoDateCounters(_currentDate, todos, defaultGoal: todoGoal);

      if (updatedTodoDate != null) {
        talker.debug(
            '📅 [TodoDateNotifier] Updated counters for ${currentTodoDate.id} with goal: $todoGoal');
        state = AsyncValue.data(updatedTodoDate);
      }
    } catch (e) {
      talker.error('📅 [TodoDateNotifier] Error updating counters', e);
    }
  }
}

// Provider for getting all past TodoDates
final pastTodoDatesProvider = FutureProvider<List<TodoDate>>((ref) async {
  final repository = ref.watch(todoDateRepositoryProvider);
  return repository.getPastTodoDates();
});
