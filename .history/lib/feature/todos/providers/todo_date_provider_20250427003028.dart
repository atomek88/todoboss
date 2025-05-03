
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/todo_date.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/repositories/todo_date_repository.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/shared/providers/selected_date_provider.dart';

// Provider for the TodoDateRepository
final todoDateRepositoryProvider = Provider<TodoDateRepository>((ref) {
  final storageService = StorageService();
  return TodoDateRepository(storageService);
});

// Provider for getting a TodoDate for a specific date
final todoDateForSelectedDateProvider = FutureProvider<TodoDate>((ref) async {
  final repository = ref.watch(todoDateRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return repository.getTodoDateForDate(selectedDate);
});

// Provider for the current TodoDate state
final todoDateProvider = StateNotifierProvider<TodoDateNotifier, AsyncValue<TodoDate?>>((ref) {
  final repository = ref.watch(todoDateRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final todosProvider = ref.watch(todoListProvider.notifier);
  return TodoDateNotifier(repository, selectedDate, todosProvider);
});

/// Notifier for managing TodoDate states
class TodoDateNotifier extends StateNotifier<AsyncValue<TodoDate?>> {
  final TodoDateRepository _repository;
  DateTime _currentDate;
  final TodoListNotifier _todosProvider;
  
  TodoDateNotifier(this._repository, this._currentDate, this._todosProvider) 
      : super(const AsyncValue.loading()) {
    _loadTodoDate();
  }
  
  /// Load the TodoDate for the current date
  Future<void> _loadTodoDate() async {
    try {
      state = const AsyncValue.loading();
      final todoDate = await _repository.getTodoDateForDate(_currentDate);
      
      // Track the loaded TodoDate
      debugPrint('📅 [TodoDateNotifier] Loaded TodoDate for ${todoDate.id}');
      // Now we'll handle todo filtering through the selectedDateProvider
      
      talker.debug('📅 [TodoDateNotifier] Loaded TodoDate for ${todoDate.id}');
      state = AsyncValue.data(todoDate);
    } catch (e) {
      talker.error('📅 [TodoDateNotifier] Error loading TodoDate', e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Update the selected date
  Future<void> updateSelectedDate(DateTime date) async {
    if (_currentDate.year == date.year && 
        _currentDate.month == date.month && 
        _currentDate.day == date.day) {
      return; // Same date, do nothing
    }
    
    _currentDate = date;
    await _loadTodoDate();
  }
  
  /// Set the task goal for the current date
  Future<void> setTaskGoal(int goal) async {
    try {
      final currentTodoDate = state.value;
      if (currentTodoDate == null) return;
      
      final updatedTodoDate = await _repository.setTaskGoal(_currentDate, goal);
      if (updatedTodoDate != null) {
        talker.debug('📅 [TodoDateNotifier] Updated task goal to $goal');
        state = AsyncValue.data(updatedTodoDate);
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
      
      final updatedTodoDate = await _repository.updateTodoDateCounters(_currentDate, todos);
      if (updatedTodoDate != null) {
        talker.debug('📅 [TodoDateNotifier] Updated counters for ${currentTodoDate.id}');
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
