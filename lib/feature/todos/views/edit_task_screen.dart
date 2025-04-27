import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../models/todo.dart';
import '../providers/todo_form_providers.dart';
import '../helpers/todo_modal_helpers.dart';

/// This screen is now a wrapper that opens the appropriate modal
/// based on the todo type

@RoutePage()
class EditTaskPage extends ConsumerStatefulWidget {
  final Todo? todo;
  const EditTaskPage({Key? key, this.todo}) : super(key: key);

  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  @override
  void initState() {
    super.initState();
    // Show the appropriate modal based on the todo type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTodoModal();
    });
  }
  
  // Determine the todo type and show the appropriate modal
  void _showTodoModal() {
    final todo = widget.todo;
    
    if (todo == null) {
      // For new todos, show the standard form
      showTodoFormModal(context);
    } else {
      // For existing todos, determine the type
      TodoType todoType;
      
      if (todo.isScheduled) {
        todoType = TodoType.scheduled;
      } else {
        todoType = TodoType.default_todo;
      }
      
      // Show the form with the appropriate type
      showTodoFormModal(context, todo: todo, initialType: todoType);
    }
    
    // Pop this screen after the modal is dismissed
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while we prepare to show the modal
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Todo' : 'Edit Todo'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
