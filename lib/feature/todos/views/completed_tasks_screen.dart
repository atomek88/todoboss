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
class CompletedTasksPage extends ConsumerStatefulWidget {
  const CompletedTasksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CompletedTasksPage> createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends ConsumerState<CompletedTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DailySummary? _selectedSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // No need to initialize the daily summary service in this screen
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoListProvider);
    final completed = todos.where((Todo todo) => todo.status == 1).toList();
    final todoGoal = ref.watch(todoGoalProvider);

    // Generate mock data for the heatmap if no real data is available yet
    final summariesAsync = ref.watch(lastNWeeksSummariesProvider(10));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
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
              final displaySummaries =
                  summaries.isNotEmpty ? summaries : _generateMockSummaries();

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
                              'Task Completion History',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          CalendarHeatmap(
                            summaries: displaySummaries,
                            weeksToShow: 10,
                            completedColor: Colors.green,
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
                                  summary: _selectedSummary!),
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
          completed.isEmpty
              ? const Center(child: Text('No completed tasks yet'))
              : ListView.builder(
                  itemCount: completed.length,
                  itemBuilder: (context, index) {
                    final todo = completed[index];
                    return ListTile(
                      title: Text(todo.title),
                      subtitle: todo.description != null
                          ? Text(todo.description!)
                          : null,
                      trailing: todo.endedOn != null
                          ? Text(
                              'Completed: ${DateFormat('MMM d, yyyy').format(todo.endedOn!)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
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

      // More completed tasks on weekdays, fewer on weekends
      final isWeekend = dayOfWeek > 5;
      final baseCompleted = isWeekend ? 1 : 3;

      // Use a pseudo-random number based on the date to ensure consistent values
      final dateHash = date.day * 31 + date.month * 12 + date.year + random;
      final completedCount = baseCompleted + (dateHash % 5);
      final deletedCount = (dateHash % 3);
      final createdCount = completedCount + deletedCount + (dateHash % 2);

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
