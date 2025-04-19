import 'package:riverpod/riverpod.dart';

final todosServiceProvider = Provider<TodosService>((ref) => TodosService());

List<Override> serviceOverrides() => [];
