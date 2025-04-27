import 'package:todoApp/core/globals.dart';
import 'dart:async';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/todo_isar.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:isar/isar.dart';

class TodoRepository {
  static const String _prefKey =
      'todos_last_sync'; // For tracking last sync time

  final StorageService _storageService;
  Isar? _isar;
  final _initCompleter = Completer<void>();
  bool _isInitialized = false;

  TodoRepository(this._storageService) {
    _initialize();
  }

  /// Initialize the repository and get the Isar instance
  Future<void> _initialize() async {
    try {
      if (_isInitialized) return;
      _isar = await _storageService.getIsar();
      _isInitialized = true;
      _initCompleter.complete();
    } catch (e) {
      talker.error('[TodoRepository] Error initializing repository', e);
      _initCompleter.completeError(e);
    }
  }

  /// Wait for initialization to complete
  Future<void> get initialized => _initCompleter.future;

  // Save multiple todos to Isar database
  Future<bool> saveTodos(List<Todo> todos) async {
    try {
      await initialized;
      // Convert domain models to Isar models
      final todoIsars = todos.map(TodoIsar.fromDomain).toList();

      // Save to Isar in a transaction
      await _isar!.writeTxn(() async {
        await _isar!.collection<TodoIsar>().putAll(todoIsars);
      });

      // Track sync time in SharedPreferences
      await _storageService
          .putObject(_prefKey, {'lastSync': DateTime.now().toIso8601String()});

      return true;
    } catch (e) {
      talker.error('[TodoRepository] Error saving todos', e);
      return false;
    }
  }

  // Get all todos from Isar database
  Future<List<Todo>> getAllTodos() async {
    try {
      await initialized;
      final todoIsars = await _isar!.collection<TodoIsar>().where().findAll();
      final todos = todoIsars.map((todoIsar) => todoIsar.toDomain()).toList();

      if (todos.isEmpty) {
        talker.warning('[TodoRepository] No todos found in database');
        return [];
      }

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
          talker.debug(
              '[TodoRepository]   Scheduled days: ${todo.scheduledText}');
        }
      }
      talker.info('[TodoRepository] ========================');

      return todos;
    } catch (e) {
      talker.error('[TodoRepository] Error getting all todos', e);
      return [];
    }
  }

  // Add a new todo
  Future<bool> addTodo(Todo todo) async {
    try {
      await initialized;
      final todoIsar = TodoIsar.fromDomain(todo);

      await _isar!.writeTxn(() async {
        await _isar!.collection<TodoIsar>().put(todoIsar);
      });

      return true;
    } catch (e) {
      talker.error('[TodoRepository] Error adding todo', e);
      return false;
    }
  }

  // Update an existing todo
  Future<bool> updateTodo(Todo updatedTodo) async {
    try {
      await initialized;
      // Convert to Isar model
      final todoIsar = TodoIsar.fromDomain(updatedTodo);

      // Find existing todo by UUID
      final existingTodo = await _isar!
          .collection<TodoIsar>()
          .filter()
          .uuidEqualTo(updatedTodo.id)
          .findFirst();

      if (existingTodo != null) {
        // Preserve Isar ID for update
        todoIsar.id = existingTodo.id;

        await _isar!.writeTxn(() async {
          await _isar!.collection<TodoIsar>().put(todoIsar);
        });

        return true;
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
      await initialized;
      // Find by UUID
      final todoIsar = await _isar!
          .collection<TodoIsar>()
          .filter()
          .uuidEqualTo(id)
          .findFirst();

      if (todoIsar != null) {
        await _isar!.writeTxn(() async {
          await _isar!.collection<TodoIsar>().delete(todoIsar.id);
        });
        return true;
      }

      return false;
    } catch (e) {
      talker.error('[TodoRepository] Error deleting todo', e);
      return false;
    }
  }

  // Get a todo by ID
  Future<Todo?> getTodoById(String id) async {
    try {
      final todos = await getAllTodos();
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
  Future<List<Todo>> getTodosByStatus(TodoStatus status) async {
    try {
      // Get all todos first
      final todos = await getAllTodos();

      // Filter by status
      return todos.where((todo) => todo.status == status).toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting todos by status', e);
      return [];
    }
  }

  // Get todos with subtasks
  Future<List<Todo>> getTodosWithSubtasks() async {
    try {
      // Get all todos
      final todos = await getAllTodos();

      // Filter for todos with subtasks
      return todos.where((todo) => todo.subtasks!.isNotEmpty).toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting todos with subtasks', e);
      return [];
    }
  }

  // Get scheduled todos
  Future<List<Todo>> getScheduledTodos() async {
    try {
      // Get all todos
      final todos = await getAllTodos();

      // Filter for scheduled todos
      return todos.where((todo) => todo.scheduled != null).toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting scheduled todos', e);
      return [];
    }
  }

  // Get todos scheduled for today
  Future<List<Todo>> getTodosScheduledForToday() async {
    try {
      // Get all todos
      final todos = await getAllTodos();
      final today = DateTime.now().weekday;
      return todos
          .where((todo) => todo.isScheduledForDay(today) && todo.status == 0)
          .toList();
    } catch (e) {
      talker.error('[TodoRepository] Error getting todos for today', e);
      return [];
    }
  }
}
