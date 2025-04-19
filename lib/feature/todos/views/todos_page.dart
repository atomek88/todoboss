import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';
import 'package:todoApp/feature/todos/views/todo_main.dart';

@RoutePage()
class TodosWrapperPage extends StatelessWidget {
  const TodosWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(const TodosPage(), const IOSTodosPage());
  }
}
