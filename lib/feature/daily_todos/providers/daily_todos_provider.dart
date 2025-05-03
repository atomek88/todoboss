import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/daily_todos/models/daily_todo.dart';
import 'package:todoApp/feature/daily_todos/repository/daily_todos_repository.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todo_goal_provider.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/daily_todos/services/daily_todo_sync_service.dart';

/// Helper to format a date key for caching
String formatDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Provider for the DailyTodoRepository
final dailyTodoRepositoryProvider = Provider<DailyTodoRepository>((ref) {
  final storageService = StorageService();
  return DailyTodoRepository(storageService);
});

/// Cache manager for DailyTodos to improve performance
final dailyTodoCacheProvider = Provider<DailyTodoCacheManager>((ref) {
  // Create a new cache manager that auto-invalidates after a certain time
  return DailyTodoCacheManager();
});

/// Provider for getting a DailyTodo for a specific date with caching
final dailyTodoForSelectedDateProvider = FutureProvider<DailyTodo>((ref) async {
  final repository = ref.watch(dailyTodoRepositoryProvider);
  final cache = ref.watch(dailyTodoCacheProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Try to get from cache first
  final cacheKey = formatDateKey(selectedDate);
  final cachedDate = cache.getDailyTodo(cacheKey);

  if (cachedDate != null) {
    return cachedDate;
  }

  // Not in cache, fetch from repository
  final dailyTodo = await repository.getDailyTodoForDate(selectedDate);

  // Store in cache for future use
  cache.cacheDailyTodo(cacheKey, dailyTodo);

  return dailyTodo;
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
  void cacheDailyTodo(String dateKey, DailyTodo dailyTodo) {
    // Ensure we don't exceed max size by removing least recently used
    if (_cache.length >= _maxSize) {
      final oldest = _findOldestEntry();
      if (oldest != null) {
        _cache.remove(oldest);
      }
    }

    // Add to cache
    _cache[dateKey] = _CacheEntry(dailyTodo, DateTime.now());
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
final dailyTodoProvider =
    StateNotifierProvider<DailyTodoNotifier, AsyncValue<DailyTodo?>>((ref) {
  final repository = ref.watch(dailyTodoRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final todosProvider = ref.watch(todoListProvider.notifier);
  final cache = ref.watch(dailyTodoCacheProvider);

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
          final dailyTodo = await _repository.getDailyTodoForDate(
            normalizedDate,
            defaultGoal: todoGoal,
          );

          // Cache the result
          _cache.cacheDailyTodo(cacheKey, dailyTodo);

          // Update the state
          if (mounted) {
            state = AsyncValue.data(dailyTodo);
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
      var dailyTodo = await _repository.getDailyTodoForDate(_currentDate,
          defaultGoal: todoGoal);

      // Get all todos to filter against
      final allTodos = await _todosProvider.getAllTodos();

      // Use the sync service to get properly filtered todos for this date
      // This handles creation date, scheduled days, and rollovers
      final updatedDailyTodo =
          await DailyTodoSyncService.syncTodosForDate(dailyTodo, allTodos);

      // Log detailed breakdown of which todos match which filter criteria
      DailyTodoSyncService.logTodoFilterDetails(allTodos, _currentDate);

      // Save the updated DailyTodo
      await _repository.saveDailyTodo(updatedDailyTodo);

      // Update the state with the properly filtered DailyTodo
      state = AsyncValue.data(updatedDailyTodo);

      debugPrint(
          '📅 [DailyTodoNotifier] Force reload complete: ${updatedDailyTodo.id} with ' +
              'completed=${updatedDailyTodo.completedTodosCount}, ' +
              'deleted=${updatedDailyTodo.deletedTodosCount}, ' +
              'goal=${updatedDailyTodo.taskGoal}, ' +
              'tracking=${updatedDailyTodo.todos.length} todos');
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

  /// Refresh the DailyTodo for a specific date and ensure sync across providers
  Future<void> refreshTodoForDate(DateTime date, Todo todo) async {
    try {
      // Normalize the date for consistent comparison
      final normalizedDate = normalizeDate(date);
      final currentDate = normalizeDate(DateTime.now());
      final selectedDate = _ref.read(selectedDateProvider);

      talker.debug(
          '📅 [DailyTodoNotifier] Refreshing todo: ${todo.title} for date: $normalizedDate');
      talker.debug(
          '📅 [DailyTodoNotifier] Current date: $currentDate, Selected date: $selectedDate');

      // First, ensure the todo is updated in the main repository
      _ref.read(todoListProvider.notifier).updateTodo(todo.id, todo);

      // Update the daily todo for the specified date
      final updatedDailyTodo =
          await _repository.updateDailyTodoCounters(normalizedDate, [todo]);

      if (updatedDailyTodo != null) {
        talker.debug(
            '📅 [DailyTodoNotifier] Refreshed counters for $normalizedDate with todo: ${todo.title}');

        // Update state if the refreshed date matches the current selected date
        if (normalizedDate.isAtSameMomentAs(selectedDate)) {
          state = AsyncValue.data(updatedDailyTodo);
          talker.debug('📅 [DailyTodoNotifier] Updated state for current view');
        } else {
          talker.debug(
              '📅 [DailyTodoNotifier] Date mismatch, requesting reload of current date');
          // Force a reload for the current selected date to sync the views
          forceReload();
        }
      }
    } catch (e) {
      talker.error('📅 [DailyTodoNotifier] Error refreshing counters', e);
    }
  }
}

// Provider for getting all past DailyTodos
final pastDailyTodosProvider = FutureProvider<List<DailyTodo>>((ref) async {
  final repository = ref.watch(dailyTodoRepositoryProvider);
  return repository.getPastDailyTodos();
});
