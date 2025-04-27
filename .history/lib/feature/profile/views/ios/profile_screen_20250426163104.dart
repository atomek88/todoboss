import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Slider, Material, MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/users/providers/user_provider.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/feature/todos/widgets/recurring_task_modal.dart';
import 'package:todoApp/feature/profile/widgets/ios_profile_form.dart';
import 'package:todoApp/feature/profile/widgets/ios_task_stats.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';
import 'package:todoApp/shared/utils/theme/theme_extension.dart';

@RoutePage()
class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((todo) => todo.status == 1).length;
    final deletedCount = todos.where((todo) => todo.status == 2).length;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profile'),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: Material(
        // Add Material widget as ancestor for Slider
        type: MaterialType
            .transparency, // Make it transparent to keep Cupertino look
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IOSProfileForm(
                  user: user,
                  onSave: (firstName, lastName) async {
                    if (user == null) {
                      // Create new user
                      await ref
                          .read(userProvider.notifier)
                          .createUser(firstName, lastName);
                      _showCupertinoAlert(
                          context, 'Profile created successfully');
                    } else {
                      // Update existing user
                      await ref.read(userProvider.notifier).updateUser(
                            (currentUser) => currentUser.copyWith(
                              firstName: firstName,
                              lastName: lastName,
                            ),
                          );
                      _showCupertinoAlert(
                          context, 'Profile updated successfully');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showRecurringTaskModal(context);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.calendar,
                                color: CupertinoColors.white, size: 18),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Recurring',
                                style: TextStyle(color: CupertinoColors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          print('users can add a carrot here');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.add,
                                color: CupertinoColors.white, size: 18),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Carrot',
                                style: TextStyle(color: CupertinoColors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                IOSTaskStats(
                  completedCount: completedCount,
                  deletedCount: deletedCount,
                ),
                const SizedBox(height: 16),
                // Scheduled Tasks Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Navigate to the scheduled tasks screen
                    context.router.push(const RecurringTodosRoute());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                              CupertinoColors.systemBlue, context)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: CupertinoDynamicColor.resolve(
                                  CupertinoColors.systemBlue, context)
                              .withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar_badge_plus,
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.systemBlue, context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Scheduled Tasks',
                          style: TextStyle(
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.systemBlue, context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.systemBlue, context),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Task Milestone Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final todoGoal = ref.watch(todoGoalProvider);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Task Milestone',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text(
                              'Current goal: $todoGoal tasks',
                              style: const TextStyle(
                                  color: CupertinoColors.systemGrey),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final todoGoal = ref.watch(todoGoalProvider);
                        return Slider(
                          value: todoGoal.toDouble(),
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: todoGoal.toString(),
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (value) {
                            ref
                                .read(todoGoalProvider.notifier)
                                .updateTodoGoal(value.toInt());
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCupertinoAlert(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
