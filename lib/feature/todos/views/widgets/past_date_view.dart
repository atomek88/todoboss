import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/todos/widgets/todo_list_item.dart';

/// A component that displays todos for a past date
/// This is used by the UnifiedTodosPage for past dates
class PastDateView extends ConsumerWidget {
  const PastDateView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the currently selected date from provider
    final selectedDate = ref.watch(selectedDateProvider);
    final normalizedSelectedDate = normalizeDate(selectedDate);
    
    // Get the DailyTodo for this specific date
    final dailyTodoAsync = ref.watch(dailyTodoProvider);
    
    // Get all todos from the repository
    final allTodos = ref.watch(todoListProvider);
    
    return dailyTodoAsync.when(
      data: (dailyTodo) {
        // Check if DailyTodo is null
        if (dailyTodo == null) {
          debugPrint('⚠️ [PastDateView] DailyTodo is null, forcing reload');
          
          // Force reload after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            ref.read(dailyTodoProvider.notifier).dateChanged(selectedDate);
          });
          
          return const Center(child: CircularProgressIndicator());
        }
        
        // Ensure dates match
        final dailyTodoDate = normalizeDate(dailyTodo.date);
        if (!dailyTodoDate.isAtSameMomentAs(normalizedSelectedDate)) {
          debugPrint(
              '⚠️ [PastDateView] Date mismatch: DailyTodo=${dailyTodo.date}, Selected=$normalizedSelectedDate, forcing sync');
          
          // Force sync after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            ref.read(dailyTodoProvider.notifier).dateChanged(selectedDate);
          });
          
          return const Center(child: CircularProgressIndicator());
        }
        
        // Filter todos for this specific date
        final todosForDate = allTodos.where((todo) {
          final todoDate = normalizeDate(todo.createdAt);
          return todoDate.isAtSameMomentAs(normalizedSelectedDate);
        }).toList();
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10.0,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSummaryRow(
                      context,
                      'Created',
                      '${dailyTodo.todos.length}',
                      Icons.add_circle_outline
                    ),
                    const SizedBox(height: 8.0),
                    _buildSummaryRow(
                      context,
                      'Completed',
                      '${dailyTodo.completedTodosCount}',
                      Icons.check_circle_outline
                    ),
                    const SizedBox(height: 8.0),
                    _buildSummaryRow(
                      context, 
                      'Goal',
                      '${dailyTodo.taskGoal}', 
                      Icons.flag_outlined
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Task list header
              Row(
                children: [
                  const Icon(Icons.list_alt, size: 18),
                  const SizedBox(width: 8.0),
                  Text(
                    'Tasks (${todosForDate.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 8.0),
              
              // Todo list (read-only for past dates)
              Expanded(
                child: _buildTodoList(context, todosForDate, true),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
  
  /// Build a summary row for the stats card
  Widget _buildSummaryRow(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  /// Build the todo list
  Widget _buildTodoList(BuildContext context, List<Todo> todos, bool isReadOnly) {
    if (todos.isEmpty) {
      return Center(
        child: Text(
          'No tasks for this date',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoListItem(
          todo: todo,
          isReadOnly: isReadOnly,
        );
      },
    );
  }
}
