import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/daily_todo.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/repositories/daily_todos_repository.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/core/providers/date_provider.dart';

/// Helper to format a date key for caching
String formatDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Provider for the DailyTodoRepository
final todoDateRepositoryProvider = Provider<DailyTodoRepository>((ref) {
  final storageService = StorageService();
  return DailyTodoRepository(storageService);
});

/// Cache manager for DailyTodos to improve performance
final todoDateCacheProvider = Provider<DailyTodoCacheManager>((ref) {
  // Create a new cache manager that auto-invalidates after a certain time
  return DailyTodoCacheManager();
});

/// Provider for getting a DailyTodo for a specific date with caching
final todoDateForSelectedDateProvider = FutureProvider<DailyTodo>((ref) async {
  final repository = ref.watch(todoDateRepositoryProvider);
  final cache = ref.watch(todoDateCacheProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Try to get from cache first
  final cacheKey = formatDateKey(selectedDate);
  final cachedDate = cache.getDailyTodo(cacheKey);

  if (cachedDate != null) {
    return cachedDate;
  }

  // Not in cache, fetch from repository
  final todoDate = await repository.getDailyTodoForDate(selectedDate);

  // Store in cache for future use
  cache.cacheDailyTodo(cacheKey, todoDate);

  return todoDate;
});

// Cache entry class for storing data with timestamps
class _CacheEntry<T> {
  final T value;
  DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Cache manager for DailyTodos to improve performance
class DailyTodoCacheManager {
  // LRU cache with expiration for DailyTodos
  final Map<String, _CacheEntry<DailyTodo>> _cache = {};
  final int _maxSize = 30; // Max number of dates to cache
  final Duration _expiration =
      const Duration(minutes: 5); // Cache expiration time

  DailyTodoCacheManager() {
    // Set up a periodic cleaner for expired cache entries
    Timer.periodic(const Duration(minutes: 1), (_) => _cleanExpiredEntries());
  }

  /// Get a DailyTodo from the cache if it exists and isn't expired
  DailyTodo? getDailyTodo(String dateKey) {
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

  /// Cache a DailyTodo with the current timestamp
  void cacheDailyTodo(String dateKey, DailyTodo todoDate) {
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

/// Provider for the current DailyTodo state with caching
final todoDateProvider =
    StateNotifierProvider<DailyTodoNotifier, AsyncValue<DailyTodo?>>((ref) {
  final repository = ref.watch(todoDateRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final todosProvider = ref.watch(todoListProvider.notifier);
  final cache = ref.watch(todoDateCacheProvider);

  return DailyTodoNotifier(ref, repository, selectedDate, todosProvider, cache);
});

/// Notifier for managing DailyTodo states with caching
class DailyTodoNotifier extends StateNotifier<AsyncValue<DailyTodo?>> {
  final DailyTodoRepository _repository;
  DateTime _currentDate;
  final TodoListNotifier _todosProvider;
  final Ref _ref;
  final DailyTodoCacheManager _cache;

  // Debounce timer for rapid date changes
  Timer? _dateChangeDebounceTimer;

  DailyTodoNotifier(this._ref, this._repository, this._currentDate,
      this._todosProvider, this._cache)
      : super(const AsyncValue.loading()) {
    _loadDailyTodo();

    // Listen for date changes
    _ref.listen<DateTime>(selectedDateProvider, (previous, current) {
      if (!isSameDay(previous!, current)) {
        _currentDate = current;
        _loadDailyTodo();
      }
    });
  }

  @override
  void dispose() {
    _dateChangeDebounceTimer?.cancel();
    super.dispose();
  }

  /// Load the DailyTodo for the current date with caching and debouncing
  Future<void> _loadDailyTodo() async {
    try {
      // Cancel any existing debounce timer
      _dateChangeDebounceTimer?.cancel();

      // Set loading state only if we don't already have data for this date
      final normalizedDate = normalizeDate(_currentDate);
      final cacheKey = formatDateKey(normalizedDate);

      // Try to get from cache first
      final cachedDate = _cache.getDailyTodo(cacheKey);

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
          final todoDate = await _repository.getDailyTodoForDate(
            normalizedDate,
            defaultGoal: todoGoal,
          );

          // Cache the result
          _cache.cacheDailyTodo(cacheKey, todoDate);

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

  /// Force the DailyTodo into loading state to ensure UI updates
  void forceLoading() {
    state = const AsyncValue.loading();
  }

  /// Force an immediate reload of the DailyTodo without debouncing
  /// This ensures we get fresh data immediately when needed
  Future<void> forceReload() async {
    debugPrint(
        '📅 [DailyTodoNotifier] Forcing immediate reload for date: $_currentDate');

    // Set loading state first for immediate UI feedback
    state = const AsyncValue.loading();

    try {
      // Get the DailyTodo with the latest global goal
      final todoGoal = _ref.read(todoGoalProvider);
      final todoDate = await _repository.getDailyTodoForDate(_currentDate,
          defaultGoal: todoGoal);

      // Get the todos specifically for this date using todoIds
      final todosForDate = <Todo>[];

      // If we have todo IDs for this date, fetch those specific todos
      if (todoDate.todoIds.isNotEmpty) {
        debugPrint(
            '📅 [DailyTodoNotifier] Getting ${todoDate.todoIds.length} todos for date: ${todoDate.id}');

        // Get each todo by ID
        for (final todoId in todoDate.todoIds) {
          final todo = await _todosProvider.getTodoById(todoId);
          if (todo != null) {
            todosForDate.add(todo);
            debugPrint(
                '📅 [DailyTodoNotifier] Added todo: ${todo.title} (${todo.id}) with status: ${todo.status}');
          }
        }
      } else {
        // If no todoIds in DailyTodo, try to find todos created on this date
        final allTodos = await _todosProvider.getAllTodos();
        final todosCreatedOnDate = allTodos.where((todo) {
          final todoDate = normalizeDate(todo.createdAt);
          return todoDate == normalizeDate(_currentDate);
        }).toList();

        // Add these todos to the list for this date
        todosForDate.addAll(todosCreatedOnDate);
        debugPrint(
            '📅 [DailyTodoNotifier] Backfilling with ${todosCreatedOnDate.length} todos created on date: ${todoDate.id}');

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
            '📅 [DailyTodoNotifier] Also adding ${additionalTodos.length} todos completed/deleted on date: ${todoDate.id}');

        // Now that we've backfilled, add all these todoIds to the DailyTodo for future reference
        if (todosForDate.isNotEmpty) {
          // Add all these todos to the DailyTodo for future queries
          DailyTodo updatedDailyTodo = todoDate;
          for (final todo in todosForDate) {
            if (!updatedDailyTodo.todoIds.contains(todo.id)) {
              updatedDailyTodo = updatedDailyTodo.addTodoId(todo.id);
            }
          }

          // Save the updated DailyTodo with the new todoIds
          if (updatedDailyTodo.todoIds.length > todoDate.todoIds.length) {
            await _repository.saveDailyTodo(updatedDailyTodo);
            debugPrint(
                '📅 [DailyTodoNotifier] Added ${updatedDailyTodo.todoIds.length - todoDate.todoIds.length} todo IDs to date ${todoDate.id}');
          }
        }
      }

      // Update counts based on the todos for this date only
      final updatedDailyTodo = await _repository.updateDailyTodoCounters(
          _currentDate, todosForDate,
          defaultGoal: todoGoal);

      // Update the state with the reloaded DailyTodo
      if (updatedDailyTodo != null) {
        state = AsyncValue.data(updatedDailyTodo);
        debugPrint(
            '📅 [DailyTodoNotifier] Force reload complete: ${updatedDailyTodo.id} with ' +
                'completed=${updatedDailyTodo.completedTodosCount}, ' +
                'deleted=${updatedDailyTodo.deletedTodosCount}, ' +
                'goal=${updatedDailyTodo.taskGoal}, ' +
                'tracking=${updatedDailyTodo.todoIds.length} todos');
      } else {
        // If we couldn't get the updated DailyTodo, just use what we have
        state = AsyncValue.data(todoDate);
        debugPrint(
            '📅 [DailyTodoNotifier] Force reload partial: ${todoDate.id}');
      }
    } catch (e) {
      debugPrint('📅 [DailyTodoNotifier] Force reload failed: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update the state when a new date is selected with immediate feedback
  void dateChanged(DateTime newDate) {
    // Normalize to avoid time component issues
    final normalizedDate = normalizeDate(newDate);

    debugPrint(
        '📅 [DailyTodoNotifier] Date change requested: $_currentDate → $normalizedDate');

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
          '📅 [DailyTodoNotifier] Ignoring duplicate date change request');
    }
  }

  /// Set the task goal for the current date
  Future<void> setTaskGoal(int goal) async {
    try {
      final currentDailyTodo = state.value;
      if (currentDailyTodo == null) {
        debugPrint(
            '📅 [DailyTodoNotifier] Cannot set goal - no current DailyTodo');
        return;
      }

      // Skip update if the goal hasn't changed
      if (currentDailyTodo.taskGoal == goal) {
        debugPrint(
            '📅 [DailyTodoNotifier] Goal already set to $goal, skipping update');
        return;
      }

      debugPrint(
          '📅 [DailyTodoNotifier] Setting task goal for ${_currentDate.toString().split(' ')[0]} from ${currentDailyTodo.taskGoal} to $goal');

      final updatedDailyTodo =
          await _repository.setTaskGoal(_currentDate, goal);
      if (updatedDailyTodo != null) {
        talker.debug(
            '📅 [DailyTodoNotifier] Successfully updated task goal to $goal');
        state = AsyncValue.data(updatedDailyTodo);
      } else {
        talker.error(
            '📅 [DailyTodoNotifier] Failed to update task goal - null response from repository');
      }
    } catch (e) {
      talker.error('📅 [DailyTodoNotifier] Error setting task goal', e);
    }
  }

  /// Update counters based on todos
  Future<void> updateCounters(List<Todo> todos) async {
    try {
      final currentDailyTodo = state.value;
      if (currentDailyTodo == null) return;

      // Get the current global goal
      final todoGoal = _ref.read(todoGoalProvider);

      // Pass the global goal to ensure it's used in updates
      final updatedDailyTodo = await _repository
          .updateDailyTodoCounters(_currentDate, todos, defaultGoal: todoGoal);

      if (updatedDailyTodo != null) {
        talker.debug(
            '📅 [DailyTodoNotifier] Updated counters for ${currentDailyTodo.id} with goal: $todoGoal');
        state = AsyncValue.data(updatedDailyTodo);
      }
    } catch (e) {
      talker.error('📅 [DailyTodoNotifier] Error updating counters', e);
    }
  }
}

// Provider for getting all past DailyTodos
final pastDailyTodosProvider = FutureProvider<List<DailyTodo>>((ref) async {
  final repository = ref.watch(todoDateRepositoryProvider);
  return repository.getPastDailyTodos();
});
