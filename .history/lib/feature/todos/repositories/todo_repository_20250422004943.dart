import 'dart:convert';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/todos/models/todo.dart';

class TodoRepository {
  static const String _prefKey = 'todos_data';
  static const String _hiveBoxName = 'todos_box';
  static const String _hiveKey = 'todos_list';

  final StorageService _storageService;

  TodoRepository(this._storageService);

  // Save todos to both SharedPreferences and Hive
  Future<bool> saveTodos(List<Todo> todos) async {
    try {
      final todosJson = jsonEncode(todos.map((todo) => todo.toJson()).toList());
      return await _storageService.saveData(
        prefKey: _prefKey,
        hiveBoxName: _hiveBoxName,
        hiveKey: _hiveKey,
        jsonData: todosJson,
      );
    } catch (e) {
      talker.error('[TodoRepository] Error saving todos', e);
      return false;
    }
  }

  // Get todos with fallback mechanism
  Future<List<Todo>> getTodos() async {
    try {
      final jsonString = await _storageService.loadData(
        prefKey: _prefKey,
        hiveBoxName: _hiveBoxName,
        hiveKey: _hiveKey,
      );

      if (jsonString == null || jsonString.isEmpty) {
        talker.warning('[TodoRepository] No todos found in any storage');
        return [];
      }

      final List<dynamic> todosData = jsonDecode(jsonString);
      final todos = todosData.map((data) => Todo.fromJson(data)).toList();

      // Log all todos loaded
      talker.info('[TodoRepository] ===== TODOS LOADED =====');
      talker.info('[TodoRepository] Total todos: ${todos.length}');
      for (final todo in todos) {
        talker.debug(
            '[TodoRepository] Todo: ${todo.id} - ${todo.title} - Priority: ${todo.priority} - Status: ${todo.status} - Rollover: ${todo.rollover}');
        if (todo.hasSubtasks) {
          talker.debug(
              '[TodoRepository]   Has ${todo.subtasks!.length} subtasks');
        }
        if (todo.isScheduled) {
          talker.debug('[TodoRepository]   Scheduled: ${todo.scheduled}');
        }
      }
      talker.info('[TodoRepository] ========================');

      return todos;
    } catch (e) {
      talker.error('[TodoRepository] Error getting todos', e);
      return [];
    }
  }

  // Add a new todo
  Future<bool> addTodo(Todo todo) async {
    try {
      final todos = await getTodos();
      todos.add(todo);
      return await saveTodos(todos);
    } catch (e) {
      talker.error('[TodoRepository] Error adding todo', e);
      return false;
    }
  }

  // Update an existing todo
  Future<bool> updateTodo(Todo updatedTodo) async {
    try {
      final todos = await getTodos();
      final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);

      if (index != -1) {
        todos[index] = updatedTodo;
        return await saveTodos(todos);
      }

      return false;
    } catch (e) {
      talker.error('[TodoRepository] Error updating todo', e);
      return false;
    }
  }

  // Delete a todo
  Future<bool> deleteTodo(String id) async {
    try {
      final todos = await getTodos();
      todos.removeWhere((todo) => todo.id == id);
      return await saveTodos(todos);
    } catch (e) {
      talker.error('[TodoRepository] Error deleting todo', e);
      return false;
    }
  }

  // Get a todo by ID
  Future<Todo?> getTodoById(String id) async {
    try {
      final todos = await getTodos();
      return todos.firstWhere(
        (todo) => todo.id == id,
        orElse: () => throw Exception('Todo not found'),
      );
    } catch (e) {
      talker.error('[TodoRepository] Error getting todo by ID', e);
      return null;
    }
  }

  // Get todos by status
  Future<List<Todo>> getTodosByStatus(int status) async {
    try {
      final todos = await getTodos();
      return todos.where((todo) => todo.status == status).toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting todos by status', e);
      return [];
    }
  }

  // Get todos with subtasks
  Future<List<Todo>> getTodosWithSubtasks() async {
    try {
      final todos = await getTodos();
      return todos.where((todo) => todo.hasSubtasks).toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting todos with subtasks', e);
      return [];
    }
  }

  // Get scheduled todos
  Future<List<Todo>> getScheduledTodos() async {
    try {
      final todos = await getTodos();
      return todos.where((todo) => todo.isScheduled).toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting scheduled todos', e);
      return [];
    }
  }
}
