import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/feature/shared/navigation/app_router.gr.dart';
import '../providers/todos_provider.dart';
import '../models/todo.dart';
import '../widgets/todo_form_modal.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/undo_button.dart';

@RoutePage()
class TodosHomePage extends ConsumerStatefulWidget {
  const TodosHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TodosHomePage> createState() => _TodosHomePageState();
}

class _TodosHomePageState extends ConsumerState<TodosHomePage> {
  // Store the last deleted todo for undo functionality
  Todo? _lastDeletedTodo;
  int? _lastDeletedIndex;
  bool _showDeleteUndoButton = false;
  
  // Store the last completed todo for undo functionality
  Todo? _lastCompletedTodo;
  int? _lastCompletedIndex;
  bool _showCompleteUndoButton = false;

  @override
  Widget build(BuildContext context) {
    // Get current date for AppBar
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final currentDate = '${months[now.month - 1]} ${now.day}';
    
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((Todo todo) => todo.status == 1).length;
    final deletedCount = todos.where((Todo todo) => todo.status == 2).length;
    final activeTodos = todos.where((Todo todo) => todo.status == 0).toList();
    
    // Maximum number of todos for the counter
    const maxTodos = 20;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentDate),
            const SizedBox(width: 8),
            const Text('To-Do'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.pushRoute(const ProfileWrapperRoute());
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deleted',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      AnimatedCounter(
                          count: deletedCount, total: maxTodos, color: Colors.grey),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text('Completed',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    AnimatedCounter(count: completedCount, total: maxTodos, color: Colors.teal),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: activeTodos.isEmpty
                ? const Center(child: Text('No active tasks'))
                : ListView.builder(
                    itemCount: activeTodos.length,
                    itemBuilder: (context, index) {
                      final todo = activeTodos[index];
                      // Find the original index in the full todos list
                      final originalIndex = todos.indexWhere((t) => t.id == todo.id);
                      
                      return TodoListItem(
                        todo: todo,
                        index: originalIndex,
                        onComplete: (todo, index) {
                          // Store the completed todo for potential undo
                          setState(() {
                            _lastCompletedTodo = todo;
                            _lastCompletedIndex = index;
                            _showCompleteUndoButton = true;
                          });
                          
                          ref.read(todoListProvider.notifier).completeTodo(index);
                          
                          // Use Future.delayed to show the snackbar after the animation completes
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${todo.title}" marked as completed'),
                                ),
                              );
                            }
                          });
                        },
                        onDelete: (todo, index) {
                          // Store the deleted todo for potential undo
                          setState(() {
                            _lastDeletedTodo = todo;
                            _lastDeletedIndex = index;
                            _showDeleteUndoButton = true;
                          });
                          
                          // Delete the todo
                          ref.read(todoListProvider.notifier).deleteTodo(index);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${todo.title}" moved to trash')),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Undo button for completed todos
          if (_showCompleteUndoButton)
            UndoButton(
              label: 'Undo Complete',
              onPressed: () {
                if (_lastCompletedTodo != null && _lastCompletedIndex != null) {
                  // Create a copy of the todo with status set back to active
                  final restoredTodo = Todo.withId(
                    id: _lastCompletedTodo!.id,
                    title: _lastCompletedTodo!.title,
                    description: _lastCompletedTodo!.description,
                    priority: _lastCompletedTodo!.priority,
                    rollover: _lastCompletedTodo!.rollover,
                    status: 0, // Set back to active
                    createdAt: _lastCompletedTodo!.createdAt,
                    endedOn: null, // Clear completion date
                  );
                  
                  // Update the todo
                  ref.read(todoListProvider.notifier).updateTodo(
                    _lastCompletedIndex!,
                    restoredTodo,
                  );
                  
                  // Hide the undo button
                  setState(() {
                    _showCompleteUndoButton = false;
                    _lastCompletedTodo = null;
                    _lastCompletedIndex = null;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task marked as active')),
                  );
                }
              },
              onDurationEnd: () {
                if (mounted) {
                  setState(() {
                    _showCompleteUndoButton = false;
                    _lastCompletedTodo = null;
                    _lastCompletedIndex = null;
                  });
                }
              },
              // Use the same grey styling for consistency
              backgroundColor: Colors.grey[700],
            ),
          
          // Undo button for deleted todos
          if (_showDeleteUndoButton)
            UndoButton(
              label: 'Undo Delete',
              onPressed: () {
                if (_lastDeletedTodo != null && _lastDeletedIndex != null) {
                  // Restore the deleted todo
                  ref.read(todoListProvider.notifier).restoreTodo(
                        _lastDeletedIndex!,
                        _lastDeletedTodo!,
                      );
                  
                  // Hide the undo button
                  setState(() {
                    _showDeleteUndoButton = false;
                    _lastDeletedTodo = null;
                    _lastDeletedIndex = null;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todo restored')),
                  );
                }
              },
              onDurationEnd: () {
                if (mounted) {
                  setState(() {
                    _showDeleteUndoButton = false;
                    _lastDeletedTodo = null;
                    _lastDeletedIndex = null;
                  });
                }
              },
            ),
          FloatingActionButton(
            onPressed: () {
              showTodoFormModal(context);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int count;
  final int total;
  final Color color;
  const AnimatedCounter({super.key, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    // For deleted tasks, don't show the total
    final displayText = color == Colors.grey ? '$count' : '$count/$total';
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        displayText,
        key: ValueKey(count),
        style:
            TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
