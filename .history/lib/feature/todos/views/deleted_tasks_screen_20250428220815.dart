import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../../daily_summary/widgets/improved_calendar_heatmap.dart';
import '../../daily_summary/widgets/daily_summary_detail.dart';
import '../../daily_summary/models/daily_summary.dart';
import '../../daily_summary/providers/daily_summary_providers.dart';

@RoutePage()
class DeletedTasksPage extends ConsumerStatefulWidget {
  const DeletedTasksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DeletedTasksPage> createState() => _DeletedTasksPageState();
}

class _DeletedTasksPageState extends ConsumerState<DeletedTasksPage> {
  DailySummary? _selectedSummary;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the real data provider with all historical todo summaries
    final summariesAsync = ref.watch(allTodoSummariesProvider);
    // Get the earliest date with todos
    final firstDateAsync = ref.watch(firstDailyTodoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Deletion History'),
      ),
      body: summariesAsync.when(
        data: (summaries) {
          return firstDateAsync.when(
            data: (firstDate) {
              // Calculate how many weeks to show based on first date
              final now = DateTime.now();
              final daysDifference = now.difference(firstDate).inDays;
              final weeksToShow =
                  (daysDifference / 7).ceil() + 1; // Add one extra week

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Task History',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                // Legend
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('Deleted',
                                        style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star,
                                        size: 12, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    const Text('Goal Met',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ImprovedCalendarHeatmap(
                            summaries: summaries,
                            weeksToShow: weeksToShow,
                            completedColor: Colors.green.withOpacity(0.3),
                            deletedColor: Colors.red,
                            showMonthLabels: true,
                            cellSize: 36,
                            backgroundColor: Theme.of(context).cardColor,
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
                                completedColor: Colors.green.withOpacity(0.3),
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
            error: (error, stack) =>
                Center(child: Text('Error calculating date range: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
