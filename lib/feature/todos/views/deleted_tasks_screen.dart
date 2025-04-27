import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import '../providers/todos_provider.dart';
import '../models/todo.dart';
import '../providers/todo_goal_provider.dart';
import '../../daily_summary/widgets/calendar_heatmap.dart';
import '../../daily_summary/widgets/daily_summary_detail.dart';
import '../../daily_summary/models/daily_summary.dart';
import '../../daily_summary/providers/daily_summary_providers.dart';

@RoutePage()
class DeletedTasksPage extends ConsumerStatefulWidget {
  const DeletedTasksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DeletedTasksPage> createState() => _DeletedTasksPageState();
}

class _DeletedTasksPageState extends ConsumerState<DeletedTasksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DailySummary? _selectedSummary;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoListProvider);
    final deleted = todos.where((Todo todo) => todo.status == 2).toList();
    
    // Get the last 10 weeks of summaries
    final summariesAsync = ref.watch(lastNWeeksSummariesProvider(10));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar View'),
            Tab(text: 'List View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Calendar View Tab
          summariesAsync.when(
            data: (summaries) {
              // If no summaries available, generate mock data
              final displaySummaries = summaries.isNotEmpty 
                  ? summaries 
                  : _generateMockSummaries();
              
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Task Deletion History',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          CalendarHeatmap(
                            summaries: displaySummaries,
                            weeksToShow: 10,
                            completedColor: Colors.green.withOpacity(0.3),
                            deletedColor: Colors.red,
                            onCellTap: (summary) {
                              setState(() {
                                _selectedSummary = summary;
                              });
                            },
                          ),
                          if (_selectedSummary != null)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: DailySummaryDetail(
                                summary: _selectedSummary!,
                                completedColor: Colors.green.withOpacity(0.7),
                                deletedColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          
          // List View Tab
          deleted.isEmpty
              ? const Center(child: Text('No deleted tasks yet'))
              : ListView.builder(
                  itemCount: deleted.length,
                  itemBuilder: (context, index) {
                    final todo = deleted[index];
                    return ListTile(
                      title: Text(todo.title),
                      subtitle: todo.description != null 
                          ? Text(todo.description!)
                          : null,
                      trailing: todo.endedOn != null
                          ? Text(
                              'Deleted: ${DateFormat('MMM d, yyyy').format(todo.endedOn!)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            )
                          : null,
                    );
                  },
                ),
        ],
      ),
    );
  }
  
  /// Generate mock summaries for demonstration purposes
  List<DailySummary> _generateMockSummaries() {
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch;
    final todoGoal = ref.read(todoGoalProvider);
    
    return List.generate(70, (index) {
      final date = now.subtract(Duration(days: index));
      final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
      
      // More deleted tasks on weekends, fewer on weekdays (opposite of completed)
      final isWeekend = dayOfWeek > 5;
      final baseDeleted = isWeekend ? 3 : 1;
      
      // Use a pseudo-random number based on the date to ensure consistent values
      final dateHash = date.day * 31 + date.month * 12 + date.year + random;
      final deletedCount = baseDeleted + (dateHash % 3);
      final completedCount = (dateHash % 2);
      final createdCount = completedCount + deletedCount + (dateHash % 3);
      
      return createDailySummary(
        date: date,
        todoCompletedCount: completedCount,
        todoDeletedCount: deletedCount,
        todoCreatedCount: createdCount,
        todoGoal: todoGoal,
      );
    });
  }
}
