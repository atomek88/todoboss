import 'package:riverpod/riverpod.dart';
import 'package:todoApp/feature/todos/services/todo_service.dart';

final todosServiceProvider = Provider<TodosService>((ref) => TodosService());

List<Override> serviceOverrides() => [];
