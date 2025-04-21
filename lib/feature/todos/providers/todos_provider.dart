import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>(
    (ref) => TodoListNotifier());

class TodoListNotifier extends StateNotifier<List<Todo>> {
  static const _storageKey = 'todos';

  TodoListNotifier() : super([]) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getString(_storageKey);
    if (todosJson != null) {
      final List<dynamic> decoded = jsonDecode(todosJson);
      state =
          decoded.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addTodo(Todo todo) {
    state = [...state, todo];
    _saveTodos();
  }

  void updateTodo(int index, Todo updated) {
    final newList = [...state];
    newList[index] = updated;
    state = newList;
    _saveTodos();
  }

  void deleteTodo(int index) {
    final newList = [...state];
    newList[index] =
        newList[index].copyWith(status: 2, endedOn: DateTime.now());
    state = newList;
    _saveTodos();
  }
  
  void restoreTodo(int index, Todo todo) {
    final newList = [...state];
    // Restore the todo by setting its status back to active (0)
    newList[index] = todo.copyWith(status: 0, endedOn: null);
    state = newList;
    _saveTodos();
  }

  void completeTodo(int index) {
    final newList = [...state];
    newList[index] =
        newList[index].copyWith(status: 1, endedOn: DateTime.now());
    state = newList;
    _saveTodos();
  }
}
