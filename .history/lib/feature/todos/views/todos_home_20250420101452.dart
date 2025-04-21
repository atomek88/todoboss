import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/feature/shared/navigation/app_router.gr.dart';
import '../providers/todos_provider.dart';
import '../models/todo.dart';
import 'package:flutter/scheduler.dart';

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
  bool _showUndoButton = false;

  Color _priorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }
  
  String _priorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Low';
    }
  }

  /// Shows a modal for adding or editing a todo task
  /// 
  /// If [todo] and [index] are provided, it will be in edit mode
  /// Otherwise, it will be in add mode for creating a new task
  void _showTaskModal(BuildContext parentContext, {Todo? todo, int? index}) {
    final bool isEditing = todo != null && index != null;
    final String modalTitle = isEditing ? 'Edit Task' : 'Create New Task';
    final String actionButtonText = isEditing ? 'Save Changes' : 'Create';
    
    // Initialize controllers with existing values if editing
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descriptionController = TextEditingController(text: todo?.description ?? '');
    bool rollover = todo?.rollover ?? false;
    int priority = todo?.priority ?? 0;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modalTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: rollover,
                        onChanged: (value) {
                          setState(() {
                            rollover = value ?? false;
                          });
                        },
                      ),
                      const Flexible(
                        child: Text('Rollover to next day if not completed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Priority: '),
                      const SizedBox(width: 8),
                      Text(
                        _priorityLabel(priority),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _priorityColor(priority),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: priority.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    activeColor: _priorityColor(priority),
                    label: _priorityLabel(priority),
                    onChanged: (value) {
                      setState(() {
                        priority = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(modalContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            if (isEditing) {
                              // Update existing todo
                              final updatedTodo = Todo(
                                title: titleController.text,
                                description: descriptionController.text.isNotEmpty
                                    ? descriptionController.text
                                    : null,
                                priority: priority,
                                rollover: rollover,
                                status: todo.status,
                                createdAt: todo.createdAt,
                                endedOn: todo.endedOn,
                              );
                              
                              ref.read(todoListProvider.notifier).updateTodo(index!, updatedTodo);
                              Navigator.pop(modalContext);
                              
                              // Show success message
                              Future.microtask(() {
                                if (mounted) {
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(
                                      content: Text('"${updatedTodo.title}" updated successfully'),
                                    ),
                                  );
                                }
                              });
                            } else {
                              // Create new todo
                              final newTodo = Todo(
                                title: titleController.text,
                                description: descriptionController.text.isNotEmpty
                                    ? descriptionController.text
                                    : null,
                                priority: priority,
                                rollover: rollover,
                              );
                              
                              ref.read(todoListProvider.notifier).addTodo(newTodo);
                              Navigator.pop(modalContext);
                              
                              // Show success message
                              Future.microtask(() {
                                if (mounted) {
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(
                                      content: Text('"${newTodo.title}" added successfully'),
                                    ),
                                  );
                                }
                              });
                            }
                          } else {
                            // Show validation error
                            showDialog(
                              context: modalContext,
                              builder: (context) => AlertDialog(
                                title: const Text('Error'),
                                content: const Text('Please enter a title for the task'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Text(actionButtonText),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                      const Text('Completed',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      AnimatedCounter(
                          count: completedCount, total: maxTodos, color: Colors.teal),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text('Deleted',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    AnimatedCounter(count: deletedCount, total: maxTodos, color: Colors.grey),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Dismissible(
                          key: Key(todo.id),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20.0),
                            color: Colors.green,
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.startToEnd,
                          dismissThresholds: const {DismissDirection.startToEnd: 0.4},
                          movementDuration: const Duration(milliseconds: 200),
                          resizeDuration: const Duration(milliseconds: 100),
                          confirmDismiss: (direction) async {
                            // Find the original index in the full todos list
                            final originalIndex = todos.indexWhere((t) => t.id == todo.id);
                            if (originalIndex != -1) {
                              ref.read(todoListProvider.notifier).completeTodo(originalIndex);
                              // Use Future.delayed to show the snackbar after the animation completes
                              // and to ensure we're not using ScaffoldMessenger during animation
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${todo.title}" marked as completed'),
                                  ),
                                );
                              });
                            }
                            return true;
                          },
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: _priorityColor(todo.priority),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(todo.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: todo.description != null
                                  ? Text(todo.description!)
                                  : null,
                              onTap: () => _showTaskModal(context, todo: todo, index: todos.indexOf(todo)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.format_list_bulleted),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      print('add subtasks to console');
                                    },
                                    tooltip: 'Add subtasks',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      // Find the original index in the full todos list
                                      final originalIndex = todos.indexWhere((t) => t.id == todo.id);
                                      if (originalIndex != -1) {
                                        // Store the todo before deleting for potential undo
                                        _lastDeletedTodo = todo;
                                        _lastDeletedIndex = originalIndex;
                                        
                                        // Delete the todo
                                        ref
                                            .read(todoListProvider.notifier)
                                            .deleteTodo(originalIndex);
                                            
                                        // Show the undo button
                                        setState(() {
                                          _showUndoButton = true;
                                        });
                                        
                                        // Hide the undo button after 5 seconds
                                        Future.delayed(const Duration(seconds: 5), () {
                                          if (mounted) {
                                            setState(() {
                                              _showUndoButton = false;
                                              _lastDeletedTodo = null;
                                              _lastDeletedIndex = null;
                                            });
                                          }
                                        });
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '"${todo.title}" moved to trash')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                    },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showUndoButton)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  if (_lastDeletedTodo != null && _lastDeletedIndex != null) {
                    // Create a new todo with the same properties but status set to active (0)
                    final restoredTodo = Todo(
                      title: _lastDeletedTodo!.title,
                      description: _lastDeletedTodo!.description,
                      priority: _lastDeletedTodo!.priority,
                      rollover: _lastDeletedTodo!.rollover,
                      status: 0, // Set to active
                      createdAt: _lastDeletedTodo!.createdAt,
                    );
                    
                    // Add the restored todo
                    ref.read(todoListProvider.notifier).addTodo(restoredTodo);
                    
                    // Hide the undo button
                    setState(() {
                      _showUndoButton = false;
                      _lastDeletedTodo = null;
                      _lastDeletedIndex = null;
                    });
                    
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${restoredTodo.title}" restored'),
                        ),
                      );
                    });
                  }
                },
                label: const Text('Undo'),
                icon: const Icon(Icons.undo),
                backgroundColor: Colors.grey[700],
              ),
            ),
          FloatingActionButton(
            onPressed: () => _showTaskModal(context),
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
