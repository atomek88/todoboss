import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';

class IOSTaskStats extends StatelessWidget {
  final int completedCount;
  final int deletedCount;

  const IOSTaskStats({
    Key? key,
    required this.completedCount,
    required this.deletedCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            onPressed: () {
              context.pushRoute(const CompletedTasksRoute());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.check_mark_circled,
                    color: CupertinoColors.white, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Completed ($completedCount)',
                    style: const TextStyle(color: CupertinoColors.white),
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
          child: CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            onPressed: () {
              context.pushRoute(const DeletedTasksRoute());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.delete_simple,
                    color: CupertinoColors.white, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Deleted ($deletedCount)',
                    style: const TextStyle(color: CupertinoColors.white),
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
