import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';

class TaskStats extends StatelessWidget {
  final int completedCount;
  final int deletedCount;

  const TaskStats({
    Key? key,
    required this.completedCount,
    required this.deletedCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            ),
            onPressed: () {
              context.pushRoute(const CompletedTasksRoute());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Completed ($completedCount)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            ),
            onPressed: () {
              context.pushRoute(const DeletedTasksRoute());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Deleted ($deletedCount)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
