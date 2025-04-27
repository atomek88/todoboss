import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';
import '../providers/todo_form_providers.dart';
import '../widgets/todo_form_modal.dart';

/// Shows a modal bottom sheet to add or edit a todo
void showTodoFormModal(BuildContext context, {Todo? todo, TodoType initialType = TodoType.default_todo}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true, // Allow dismiss by tapping outside
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6, // Increased size to accommodate type selector
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TodoFormModal(
          todo: todo,
          scrollController: scrollController,
          initialType: initialType,
        ),
      ),
    ),
  ).then((_) {
    // When modal is dismissed, check if we need to create a new todo
    if (todo == null) {
      // Get the current values from the providers
      final todoNotifier = ProviderScope.containerOf(context).read(todoListProvider.notifier);
      final formValues = ProviderScope.containerOf(context).read(todoFormValuesProvider);
      final todoType = ProviderScope.containerOf(context).read(todoTypeProvider);
      
      final titleText = formValues['title'] as String;
      
      // Create and add the todo if title is not empty
      if (titleText.isNotEmpty) {
        // Set rollover and scheduled based on todo type
        bool rollover = false;
        Set<int> scheduled = {};
        
        if (todoType == TodoType.scheduled) {
          scheduled = ProviderScope.containerOf(context).read(todoScheduledDaysProvider);
          // Validate scheduled days
          if (scheduled.isEmpty) {
            return; // Don't create a scheduled todo with no days selected
          }
          rollover = false; // Scheduled todos always have rollover=false
        } else {
          // Default todo
          rollover = ProviderScope.containerOf(context).read(todoRolloverProvider);
        }
        
        final newTodo = Todo.create(
          title: titleText,
          description: formValues['description'] as String,
          priority: formValues['priority'] as int,
          rollover: rollover,
          scheduled: scheduled,
        );
        
        talker.debug('[TodoFormModal] Creating new todo: ${newTodo.title}');
        talker.debug('[TodoFormModal] Type: $todoType, Rollover: $rollover, Scheduled: $scheduled');
        
        todoNotifier.addTodo(newTodo);
      }
    }
  });
}

/// Shows a modal bottom sheet specifically for adding a scheduled/recurring task
void showScheduledTaskModal(BuildContext context) {
  showTodoFormModal(context, initialType: TodoType.scheduled);
}

/// Shows a modal bottom sheet specifically for adding a default task with rollover enabled
void showRolloverTaskModal(BuildContext context) {
  // First set up the rollover provider to be true
  ProviderScope.containerOf(context).read(todoRolloverProvider.notifier).state = true;
  // Then show the default todo modal
  showTodoFormModal(context, initialType: TodoType.default_todo);
}

/// Shows a modal bottom sheet specifically for adding a recurring task
/// @deprecated Use showScheduledTaskModal instead
void showRecurringTaskModal(BuildContext context) {
  talker.debug('[DEPRECATED] showRecurringTaskModal is deprecated, use showScheduledTaskModal instead');
  showScheduledTaskModal(context);
}
